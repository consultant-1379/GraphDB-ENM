#!/bin/bash
#Common functions used in the graphdb agent 
# Environment variables supported:
# ADMIN_USER (default neo4j)
# NAMESPACE
# ADMIN_PASSWORD=Neo4jadmin123
# NUMBER_OF_CORES=3
# NEO4J_BOLT_PORT=7687
# NEO4J_HTTP_PORT=7474
# NEO4J_causal__clustering_service (full neo4j causal service name)

SCRIPT_PATH=$(dirname "$0")
source "$SCRIPT_PATH/queries.txt"

#Constants
_CYPHER_SHELL=$(which cypher-shell)
BOLT="bolt"
ERROR_RUNNING_CYPHER_QUERY_CODE=3
RET_EXIT_FAIL=-20
FAIL_NOT_FOUND=-30
PODNAME="$NEO4J_PODNAME"
ROLES="reader editor publisher architect admin"

usage() {
  echo "Usage: $0 [-q Query] {-p pod} {-n namespace}" 1>&2;
  echo "   q: Cypher Query to be executed"
  echo "   n: namespace default: $NAMESPACE"
  echo "   p: specific pod, if not defined service is used instead: ${NEO4J_causal__clustering_service}"
  exit -1;
}

# Reads params to be used in the run_cypher_query functions
# -p includes the query to be executed
# -n if you require to include a diferent namespace
# -p if you request to execute the query in an specific pod.
#    if pod is included the protocol by default will be bolt
#    if pod is not defined the query will be executed on the service using the protocol bolt+routing
getParams() {
    unset QUERY
    unset PODQUERY
    while getopts ":q:p:n:h:" o; do
      case "${o}" in
      n)
        NAMESPACE=${OPTARG}
        ;;
      p)
        PODQUERY=${OPTARG}
        ;;
      q)
        QUERY=${OPTARG}
        ;;
      h |*)
        usage
        ;;
      esac
    done
    shift $((OPTIND-1))
    OPTIND=1

   if [[ -z "${QUERY}" ]]; then
     usage
   fi
    if [[ -z $PODQUERY ]]; then
      export NEO4J_SRV="${NEO4J_causal__clustering_service}"
      BOLT="bolt+routing"
    else
      export NEO4J_SRV="$PODQUERY.${NEO4J_causal__clustering_service}"
      BOLT="bolt"
    fi
}

# Execute a cypher query- ADMIN_USER and ADMIN_PASSWORD and environment variables
run_cypher_query() {
   getParams "$@"
    $_CYPHER_SHELL -u  $ADMIN_USER -p $ADMIN_PASSWORD -a $BOLT://"${NEO4J_SRV}:${NEO4J_BOLT_PORT}" "$QUERY"
    ret_code=$?
    return $ret_code
}

#Execute a cypher query and return the result - ADMIN_USER and ADMIN_PASSWORD and environment variables
get_cypher_query() {
   getParams "$@"
    RESULT=`$_CYPHER_SHELL -u  $ADMIN_USER -p $ADMIN_PASSWORD --format plain -a $BOLT://"${NEO4J_SRV}:${NEO4J_BOLT_PORT}" "$QUERY"`
    echo $RESULT
}

# Execute a cypher query with 5 retries- ADMIN_USER and ADMIN_PASSWORD and environment variables
run_cypher_query_with_retry(){
   getParams "$@"
   MAX_ATTEMPTS=5
   attempt=0
   for ((i=1;i<=$MAX_ATTEMPTS ;i++));
   do
       run_cypher_query "$@"
       ret_code=$?
       if [ $ret_code -eq 0 ]; then
          exit_code=0
          break
       else
         echo "Failed to run cypher query retry $attempt of $MAX_ATTEMPTS. return code: ${ret_code}"
         exit_code=${ERROR_RUNNING_CYPHER_QUERY_CODE}

       fi
   done
   return $exit_code
}
export -f run_cypher_query

# Search on a list for an specific string splitted between spaces.
# Used to validate the role specified in the users
contains() {
  [[ $1 =~ (^|[[:space:]])$2($|[[:space:]]) ]] && return 0 || return 1
}

# Validates if the file provided is a valid json file or not. It uses JQ as validator
is_json(){
  if cat $1 | jq -e . >/dev/null 2>&1; then return 0; else return 1; fi
}

# Validates if the file provided is a valid CSV file or not.
is_csv(){
  iscsv="$(awk ' BEGIN{FS=","}!n{n=NF;}n!=NF||NF<2{failed=1;exit}END{print failed}' $1)"
  if [[ -z ${iscsv} ]]; then
     return 0
  else
     return 1
  fi
}

# Reads the content of the JSON file and creates a json array with the details included
import_fromJson(){
   declare -n jsonArr="$1"
   is_json $2
   cat $2 | jq -c '.[]'
   if is_json $2; then
      readarray -t jsonArr <<<$(cat $2 | egrep -v "(^#.*|^$)" | jq -c '.[]')
   else
       echo "Failed to parse JSON $2, or got false/null"
   fi
}

# Reads the content of the CSV's file and creates a json array with the details included
import_fromCSV() {
   declare -n csvArr="$1"
   readarray -t csvArr <<< $(
    awk '
    BEGIN {
        FS=","
    }
    {
        if(NR==1) {
        # read headers
            for (i=0; i<NF; i++) {
                headers[i] = $(i+1)
            }
        } else {
            for (i=0; i<NF; i++) {
                fields[NR][i] = $(i+1)
            }
        }
    }

    END {
       line=""
       for (f in fields) {
            line=""
            for (j=0; j<NF; j++) {
                line=line"\""headers[j]"\":\""fields[f][j]"\""
                if (j!=NF-1) line=line","
            }
            print "{" line "}"
        }

    }' $2)
}

# Create user: username, password, role, requirePasswordChange (true/false)
# Role:
#   reader
#       Read-only access to the data graph (all nodes, relationships, properties).
#   editor
#       Read/write access to the data graph.
#       Write access limited to creating and changing existing properties key, node labels, and relationship types of the graph.
#   publisher
#       Read/write access to the data graph.
#   architect
#       Read/write access to the data graph.
#       Set/delete access to indexes along with any other future schema constructs.
#   admin
#       Read/write access to the data graph.
#       Set/delete access to indexes along with any other future schema constructs.
#       View/terminate queries.
create_user () {
  username="$1"
  password="$2"
  role="$(echo "$3" | awk '{print tolower($0)}')"
  requirePasswordChange="$4"

  role="${role%\"}"
  role="${role#\"}"

  contains "$ROLES" "$role"
  result=$?

  if [[ $result != 0 ]]; then
     echo "Invalid role: $role for user $username"
     return -1
  fi

  for((i=0;i<$NUMBER_OF_CORES;++i)); do
     POD="$PODNAME-$i"
     run_cypher_query -q "$(__create_user ${username} ${password} ${requirePasswordChange})"  -p "$POD"
     retcode=$?
    if [ ${retcode} -eq 124 ]; then
        echo "Creating user " $username " timed out"
        RETVAL=1
    elif [ ${retcode} -eq 0 ]; then
        echo "User " $username " created successfully"
        RETVAL=0
    else
        echo "Creating user " $username " failed"
        RETVAL=1
    fi
     run_cypher_query -q "$(__assign_role "${role}" ${username})" -p "$POD"
     retcode=$?
     if [ ${retcode} -eq 124 ]; then
        echo "Assigning role '$role' to user '$username' timed out"
        RETVAL=1
     elif [ ${retcode} -eq 0 ]; then
        echo "Assigning role '$role' to user '$username' succeeded"
        RETVAL=0
     else
        echo "Assigning role '$role' to user '$username' failed"
        RETVAL=1
     fi

  done

}

# Main command to create users based on an either a json or csv file.
create_users_fromFile() {
  declare -a myarray
  USERS_FILE=$1
  if [[ ! -f "$USERS_FILE" ]]; then
    echo "$USERS_FILE does not exist"
    return -1
  fi
  if is_json $USERS_FILE; then
     import_fromJson myarray $USERS_FILE
  elif is_csv $USERS_FILE; then
     import_fromCSV myarray $USERS_FILE
  else
     echo "Invalid file to load users: $USERS_FILE "
     exit -1
  fi
  for user in "${!myarray[@]}"; do
     username=$(echo "${myarray[user]}" | jq .username)
     password=$(echo "${myarray[user]}" | jq .password)
     role=$(echo "${myarray[user]}" | jq .role)
     requirePasswordChange=$(echo "${myarray[user]}" | jq .requirePasswordChange)
     create_user  $username $password $role $requirePasswordChange
  done
}

# Given the index name it deleted from the database 
delete_index () {
   INDEX="$(echo "$1" | awk '{print tolower($0)}')"
   if [[ "${INDEX}" == *"index on "* ]]; then
      INDEX="$(awk '{print substr($0,index($0,":"))}' <<< $INDEX)"
   fi
   run_cypher_query -q "$(__drop_index "${INDEX}")" && exit_code=$?
   if [[ $exit_code != 0 ]]; then
     echo "Failed to delete user defined index: ${INDEX}"
     return 3
   else
     echo "Deleted user defined index: ${INDEX}"
     return 0
   fi
}

# Creates and index, it first validates if the index was previously created and if so it's removed first
create_index () {
   # changed to lowercase
   INDEX="$(echo "$1" | awk '{print tolower($0)}')"
   if [[ "${INDEX}" == *"index on "* ]]; then
      INDEX="$(awk '{print substr($0,index($0,":"))}' <<< $INDEX)"
   fi
   if [[ ! -z $3 ]]; then
      if [[ "$3" == "true" ]]; then
         delete_index "${INDEX}" && ret_code=$?
      fi
   fi
   run_cypher_query -q "$(__create_index "${INDEX}")" && ret_code=$?
   if [[ "${ret_code}" -eq "${ERROR_RUNNING_CYPHER_QUERY_CODE}" ]]; then
     echo "Failed to create new user defined index: $INDEX"
     exit_code=3
   fi
   echo "Created new user defined index: $INDEX"

   return $exit_code
}

# Reads the file content including the indexes to be created 
# The file is splitted by a | and indicates the name of the index (To look for) and the instruction to be executed to create the index  ie:
#       INDEX ON :FM:OpenAlarm(fdn)|INDEX ON :`FM:OpenAlarm`(fdn)
#       INDEX ON :FM:OpenAlarm(alarmNumber, objectOfReference)|INDEX ON :`FM:OpenAlarm`(alarmNumber, objectOfReference)
create_index_fromFile() {

  declare -a myarray
  INDEXES_FROM_FILE="$1"
  if [[ ! -f "$INDEXES_FROM_FILE" ]]; then
    echo "$INDEXES_FROM_FILE does not exist"
    return -1
  fi
  POD="$(getLeader_name)"

  INDEXES_FROM_SERVER="$(get_cypher_query -q "CALL db.indexes() YIELD description" | awk '{print tolower($0)}' )"
  INDEXES="$(eval 'for word in '$INDEXES_FROM_SERVER'; do if [[ $word == *"index on"* ]]; then echo $word; fi; done')"
  while IFS=\| read -r INDEX_NAME INDEX_QUERY || [[ -n "$INDEX_QUERY" ]]; do
    if [[ ! -z "${INDEX_NAME}" ]]; then
      if grep -q "$INDEX_NAME" <<< $INDEXES_FROM_SERVER; then
          echo "User defined index already exists: $INDEX_NAME"
      else
          create_index "${INDEX_QUERY}" "${INDEX_NAME}" "true"
      fi
    fi
  done < <(tail -n +1 $INDEXES_FROM_FILE)

}

# Returns the role name for an specific pod name
getRole() {
   POD="$1"
   OUTPUT="$(get_cypher_query -q "$(__get_role)" -p $POD)"
   echo $OUTPUT
}

# Returns the complete full name of the pod Leader 
getLeader_fullname() {
  OUTPUT="$(get_cypher_query -q "$(__get_cluster)")"
  IFS=',' read -ra ADDR <<< "$OUTPUT"
  LEADER=""
  for i in "${!ADDR[@]}"; do
      if [[ ${ADDR[$i]} == *"LEADER"* ]];then
         var=$((i-1))
         LEADER=$(awk '{ POD=substr($0, index ($0,"//")+2,100); print substr(POD,0,index(POD,":")-1)}' <<< "${ADDR[$var]}")
         break
      fi
  done
  echo $LEADER
}

# Returns the name of the pod Leader 
getLeader_name() {
  POD="$(getLeader_fullname)"
  IFS='.' read -ra ADDR <<< "$POD"
  echo  "${ADDR[0]}"
}
