#!/bin/bash
# Demo how to import data based on https://neo4j.com/docs/getting-started/current/cypher-intro/load-csv/
# Using data from https://github.com/neo4j-contrib/training/blob/master/advanced_cypher/guides/02_import_with_cypher.adoc
SCRIPT_PATH=$(dirname "$0")
source $SCRIPT_PATH/"common.sh"

POD="$(getLeader_name)"

# Create file to imports
#persons_csv="https://raw.githubusercontent.com/neo4j-contrib/training/master/advanced_cypher/data/people.csv"
#movies_csv="https://raw.githubusercontent.com/neo4j-contrib/training/master/advanced_cypher/data/movies.csv"
#actors_csv="https://raw.githubusercontent.com/neo4j-contrib/training/master/advanced_cypher/data/actors.csv"

persons_csv="file:///people.csv"
movies_csv="file:///movies.csv"
# actors_csv="file:///movies.csv"

echo "Creating Index and unique constraints"
run_cypher_query -q "$(__drop_database) " 
run_cypher_query -q "$(__create_uniqueconstraint "Person" "personId")"
run_cypher_query -q "$(__create_uniqueconstraint "Movie" "movieId")"
run_cypher_query -q "$(__create_index ':Genres(genres)')"

echo "Loading Persons data"
run_cypher_query -q "LOAD CSV WITH HEADERS FROM \"$persons_csv\" AS csvLine CREATE (p:Person {personId: toInteger(csvLine.personId), name: csvLine.name, birthYear: csvLine.birthYear}) " -p "$POD"

echo "Creating genres, movies,characters "
run_cypher_query -q "LOAD CSV WITH HEADERS FROM \"$movies_csv\" AS csvLine MERGE (genres:Genres {genres: csvLine.genres}) MERGE (movies:Movies {movieId: toInteger(csvLine.movieId), title: csvLine.title, releaseYear:toInteger(csvLine.releaseYear), genre: csvLine.genres}) CREATE (character:Character {movieId: toInteger(csvLine.movieId), personId: toInteger(csvLine.personId), character:csvLine.characters})" -p "$POD"

echo "Creating relationships "

run_cypher_query -q "MATCH (m:Movies), (g:Genres) WHERE m.genre=g.genres CREATE (m)-[r:GENRE]->(g)" -p "$POD"
run_cypher_query -q "MATCH (p:Person), (m:Movies), (c:Character) WHERE p.personId=c.personId and m.movieId=c.movieId      CREATE (p)-[r:Played]->(c) CREATE (c)-[w:Works]->(m)" -p "$POD"

echo "Deleting unique constraints "
run_cypher_query -q "$(__drop_uniqueconstraint 'Person' 'personId')" 
run_cypher_query -q "$(__drop_uniqueconstraint 'Movie' 'movieId')"


rm "$persons_csv"
rm "$movies_csv"
rm "$roles_csv"