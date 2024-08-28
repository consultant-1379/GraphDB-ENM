#!/bin/bash

# Demo use of common functions
#Create and remove some users based on queries and commons
SCRIPT_PATH=$(dirname "$0")
source $SCRIPT_PATH/"common.sh"

## Identify the Leader Pod
POD="$(getLeader_name)"
run_cypher_query -q 'CALL ericsson.driver.ping(200);'
run_cypher_query -q "$(__delete_user 'hello')" -p "$POD"
run_cypher_query -q "$(__create_user 'hello' 'bye' false)" -p "$POD"
run_cypher_query -q "$(__create_user 'demo' 'demo' false)" -p "$POD"
run_cypher_query_with_retry -q "$(__create_user 'demo2' 'demo' false)"  -p "$POD"

run_cypher_query -q "$(__delete_user 'hello')" -p "$POD"
run_cypher_query -q "$(__delete_user 'demo2')" -p "$POD"