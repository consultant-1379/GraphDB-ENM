#!/bin/bash
CYPHER_SHELL=${NEO4J_HOME}/bin/cypher-shell
NAMESPACE=$NAMESPACE
ADMIN_USER=neo4j
ADMIN_PASSWORD=$ADMIN_PASSWORD
TIMEOUT=/usr/bin/timeout


usage() { echo "Usage: $0 [-n NUMBER_OF_NEO4J_SERVERS] " 1>&2; exit 1; }

while getopts ":n:" arg; do
    case "${arg}" in
        n)
            NUMBER_OF_NEO4J_SERVERS=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${NUMBER_OF_NEO4J_SERVERS}" ]; then
    usage
fi

for server in $(seq 0 $((${NUMBER_OF_NEO4J_SERVERS}-1))); do
  while true ; do
    ADDRESS="${NEO4J_PODNAME}-${server}.${NEO4J_causal__clustering_service}"
    check_cmd="${TIMEOUT} -s SIGUSR1 30s ${CYPHER_SHELL} -u ${ADMIN_USER} -p ${ADMIN_PASSWORD} --encryption=false -a ${ADDRESS} 'CALL ericsson.driver.ping(200);' 2>&1"
    check_cmd_log=$(echo ${check_cmd} | sed -e "s/${ADMIN_PASSWORD}/'******'/g")

    output=$(eval ${check_cmd})
    retcode=$?
    echo ${output} | grep TRUE > /dev/null 2>&1
    grep_true_retcode=$?
    if [ ${grep_true_retcode} -eq 0 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') - Neo4j cypher query ping(200) ran successfully. Command: ${check_cmd_log}."
      break
    else
      echo "$(date '+%Y-%m-%d %H:%M:%S') - Waiting for Neo4j"
      sleep 30
    fi
  done
done
