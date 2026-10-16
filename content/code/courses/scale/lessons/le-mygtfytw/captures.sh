#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of scale. Each block of output
# starts with `##### <name>`; the prose quotes the blocks byte for byte.
#
#   bash captures.sh [block ...] > captures.out   (as root, after lab.sh prepare)
#
# STAGED rather than typed:
#   - ~/tickets is written by `lab.sh stage 5`; the six files this lesson
#     uses are read out of its sections like every other;
#   - the images were pulled from mirror.gcr.io and tagged with their Docker
#     Hub names: mongo:8.0.32, amazon/dynamodb-local:3.3.0,
#     amazon/aws-cli:2.31.0, cassandra:5.0.9, neo4j:5.26.31, influxdb:2.9.1;
#   - `ddb` is the alias the section defines; this script defines it as a
#     function with the same words, and prints `ddb …` as typed;
#   - the waits for Cassandra and Neo4j to accept connections are the loops
#     the sections show, run for real; their duration varies.
# Container ids, Cassandra's start-up time and Neo4j's timings differ on
# every run. Recorded 2026-10-10 on the machine lab.sh describes.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/lib.sh"
bash "$LAB" stage 5 || exit 1
cd "$HOME/tickets"
for c in mongo dynamo cassandra neo4j influx; do docker rm -f $c >/dev/null 2>&1; done
ddb() { docker run --rm --network container:dynamo -v "$PWD":/aws -w /aws -e AWS_ACCESS_KEY_ID=local -e AWS_SECRET_ACCESS_KEY=local -e AWS_DEFAULT_REGION=sa-east-1 amazon/aws-cli:2.31.0 dynamodb --endpoint-url http://localhost:8000 "$@"; }
export -f ddb

cap_mongo_up() {
  run 'docker run -d --name mongo --memory 1g mongo:8.0.32'
  sleep 6
  run 'docker cp shows.js mongo:/tmp/shows.js'
  run 'docker exec mongo mongosh --quiet tickets /tmp/shows.js'
}

cap_mongo_find() {
  run "docker exec mongo mongosh --quiet tickets --eval 'db.shows.findOne({_id: \"show-1\"})'"
  run "docker exec mongo mongosh --quiet tickets --eval 'db.shows.find({\"venue.name\": \"Teatro Ipê\"}, {name: 1, starts_at: 1}).sort({starts_at: 1, _id: 1}).limit(3)'"
}

PLAN='const p = db.shows.find({"venue.name": "Teatro Ipê"}).explain("executionStats"); printjson({stage: p.queryPlanner.winningPlan.inputStage?.stage ?? p.queryPlanner.winningPlan.stage, examined: p.executionStats.totalDocsExamined, returned: p.executionStats.nReturned})'
cap_mongo_plan() {
  run "docker exec mongo mongosh --quiet tickets --eval '$PLAN'"
  run "docker exec mongo mongosh --quiet tickets --eval 'db.shows.createIndex({\"venue.name\": 1})'"
  run "docker exec mongo mongosh --quiet tickets --eval '$PLAN'"
}

cap_mongo_rename() {
  run "docker exec mongo mongosh --quiet tickets --eval 'db.shows.updateMany({\"venue.name\": \"Arena Sul\"}, {\$set: {\"venue.name\": \"Arena Sul Hall\"}})'"
  run 'docker rm -f mongo'
}

cap_ddb_up() {
  run 'docker run -d --name dynamo amazon/dynamodb-local:3.3.0'
  sleep 3
  run 'ddb create-table --table-name tickets --attribute-definitions AttributeName=buyer,AttributeType=S AttributeName=ticket,AttributeType=S --key-schema AttributeName=buyer,KeyType=HASH AttributeName=ticket,KeyType=RANGE --billing-mode PAY_PER_REQUEST --query TableDescription.TableStatus --output text'
  run 'ddb batch-write-item --cli-input-yaml file://tickets.yaml'
}

cap_ddb_query() {
  run "ddb query --table-name tickets --key-condition-expression 'buyer = :b AND begins_with(ticket, :s)' --expression-attribute-values '{\":b\": {\"S\": \"ana\"}, \":s\": {\"S\": \"show-1#\"}}' --return-consumed-capacity TOTAL"
}

cap_ddb_keys() {
  run "ddb query --table-name tickets --key-condition-expression 'ticket = :t' --expression-attribute-values '{\":t\": {\"S\": \"show-1#seat-42\"}}'"
  run "ddb scan --table-name tickets --filter-expression 'begins_with(ticket, :s)' --expression-attribute-values '{\":s\": {\"S\": \"show-1#\"}}' --return-consumed-capacity TOTAL --query '{Count: Count, ScannedCount: ScannedCount, CapacityUnits: ConsumedCapacity.CapacityUnits}'"
  run 'docker rm -f dynamo'
}

cap_cass_up() {
  run 'docker run -d --name cassandra --memory 1536m -e MAX_HEAP_SIZE=512M -e HEAP_NEWSIZE=128M cassandra:5.0.9'
  run "until docker exec cassandra cqlsh -e 'DESCRIBE KEYSPACES' >/dev/null 2>&1; do sleep 5; done"
  run 'docker cp scans.cql cassandra:/tmp/scans.cql'
  run 'docker exec cassandra cqlsh -f /tmp/scans.cql'
  run "docker exec cassandra cqlsh -e \"SELECT scanned_at, ticket, gate FROM tickets.scans WHERE show_id = 'show-1' LIMIT 3\""
}

cap_cass_token() {
  run "docker exec cassandra cqlsh -e 'SELECT show_id, token(show_id) FROM tickets.scans PER PARTITION LIMIT 1'"
}

cap_cass_filter() {
  run "docker exec cassandra cqlsh -e \"SELECT ticket FROM tickets.scans WHERE gate = 'B'\""
  run "docker exec cassandra cqlsh -e \"CONSISTENCY QUORUM; SELECT count(*) FROM tickets.scans WHERE show_id = 'show-1'\""
  run 'docker stats --no-stream --format "{{.Name}} {{.MemUsage}}" cassandra'
  run 'docker rm -f cassandra'
}

NEO="docker exec neo4j cypher-shell -u neo4j -p lab-password"
cap_neo_up() {
  run 'docker run -d --name neo4j --memory 1g -e NEO4J_AUTH=neo4j/lab-password -e NEO4J_server_memory_heap_max__size=512m neo4j:5.26.31'
  run "until $NEO 'RETURN 1' >/dev/null 2>&1; do sleep 3; done"
  run 'docker cp graph.cypher neo4j:/tmp/graph.cypher'
  run "$NEO -f /tmp/graph.cypher"
}

cap_neo_walk() {
  run "$NEO \"MATCH (s:Show {name: 'Show 1'})<-[:BOUGHT]-(b:Buyer)-[:BOUGHT]->(other:Show) RETURN other.name AS show, count(b) AS shared ORDER BY shared DESC, show LIMIT 3\""
  run "$NEO \"PROFILE MATCH (s:Show {name: 'Show 1'})<-[:BOUGHT]-(b:Buyer)-[:BOUGHT]->(other:Show) RETURN other.name AS show, count(b) AS shared ORDER BY shared DESC, show LIMIT 3\" | tail -6"
  run 'docker rm -f neo4j'
}

cap_influx_up() {
  run 'docker run -d --name influx --memory 1g -e DOCKER_INFLUXDB_INIT_MODE=setup -e DOCKER_INFLUXDB_INIT_USERNAME=ana -e DOCKER_INFLUXDB_INIT_PASSWORD=lab-password -e DOCKER_INFLUXDB_INIT_ORG=sabia -e DOCKER_INFLUXDB_INIT_BUCKET=sales -e DOCKER_INFLUXDB_INIT_RETENTION=30d -e DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=lab-token influxdb:2.9.1'
  sleep 8
  run 'python3 points.py > sales.lp'
  run 'head -3 sales.lp'
  run 'docker cp sales.lp influx:/tmp/sales.lp'
  run 'docker exec influx influx write -b sales -p s -f /tmp/sales.lp'
}

cap_influx_query() {
  run 'docker cp hourly.flux influx:/tmp/hourly.flux'
  run 'docker exec influx influx query -f /tmp/hourly.flux'
  run 'docker exec influx influx bucket list --name sales'
  run 'docker rm -f influx'
}

captures "$@"
for c in mongo dynamo cassandra neo4j influx; do docker rm -f $c >/dev/null 2>&1; done
