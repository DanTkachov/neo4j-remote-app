#!/bin/bash
neo4j start
cypher-shell -a neo4j+ssc//localhost:7687
#until curl --fail --silent https://0.0.0.0:7473/; do
#  echo 'Waiting for Neo4j...'
#  sleep 1
#done
sleep 5
# Run the cypher-shell command and capture its output in a variable
echo "LOAD CSV WITH HEADERS FROM 'file:///disease.csv' AS row MERGE (n:disease {name: row.name, ko: row.ko, description: row.description, disease_category:row.disease_category});" | cypher-shell
echo "LOAD CSV WITH HEADERS FROM 'file:///drug.csv' AS row MERGE (n:drug {name: row.name, ko: row.ko});" | cypher-shell
echo "LOAD CSV WITH HEADERS FROM 'file:///pathogen.csv' AS row MERGE (n:pathogen {name: row.name, ko: row.ko, taxonomy: row.taxonomy});" | cypher-shell
echo "CREATE CONSTRAINT FOR (n:disease) REQUIRE n.ko IS UNIQUE;" | cypher-shell
echo "CREATE CONSTRAINT FOR (n:drug) REQUIRE n.ko IS UNIQUE;" | cypher-shell
echo "CREATE CONSTRAINT FOR (n:pathogen) REQUIRE n.ko IS UNIQUE;" | cypher-shell
echo "LOAD CSV WITH HEADERS FROM 'file:///drug_disease.csv' AS row MERGE (n1:drug {ko: row.from}) MERGE (n2:disease {ko: row.to}) MERGE (n1)-[r:treats]->(n2);" | cypher-shell
echo "LOAD CSV WITH HEADERS FROM 'file:///pathogen_disease.csv' AS row MERGE (n1:pathogen {ko: row.from}) MERGE (n2:disease {ko: row.to}) MERGE (n1)-[r:causes]->(n2);" | cypher-shell
# Print the captured response
service neo4j status
cat /var/log/neo4j/neo4j.log
echo "MATCH (n:disease) RETURN n LIMIT 5;" | cypher-shell

#cat /etc/neo4j/neo4j.conf

netstat -tuln
exec /usr/bin/shiny-server
