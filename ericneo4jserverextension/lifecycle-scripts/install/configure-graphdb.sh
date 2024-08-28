#!/bin/bash

# Test script to demo the use of common routines
# Params:
#    1  File used to add new users
#    2  File used to add new indexes

source ./"common.sh"

add_node_model() {
    NodeModel = $(get_cypher_query -q "$(__get_NodeModel)" -r "bolt+routing")
    if [[ ! -z $NodeModel ]]; then
        echo "NodeModel already present, not creating."
    else
        echo "NodeModel not present, creating."
        run_cypher_query  -q "CREATE (n:NodeModel {label: 'PersistenceObject', \` _internalId\`: 'long', \` _createdTime\`: 'Date', \` _lastUpdatedTime\`: 'Date', \` _level\`: 'short'})" 
        echo "Creating NodeModel constraints."
        get_cypher_query -q "$(__create_uniqueconstraint "NodeModel" "label")" 
        run_cypher_query -q "CREATE CONSTRAINT ON ( nodemodel:NodeModel ) ASSERT nodemodel.label IS UNIQUE"
        run_cypher_query -q "CREATE CONSTRAINT ON ( relationshipmodel:RelationshipModel ) ASSERT relationshipmodel.type IS UNIQUE"
    fi
}

# Create users from data file.
create_users_fromFile $1
POD="$(getLeader_name)"

# Add node model.
add_node_model

# Create indexes from data file.
create_index_fromFile $2