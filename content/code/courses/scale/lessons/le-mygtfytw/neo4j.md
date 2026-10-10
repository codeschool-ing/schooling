---
title: Neo4j, who went where
version: 1
---

Neo4j is a graph database: **nodes** with labels and properties, and **relationships** between them,
each with a type. Its query language, Cypher, draws patterns with brackets and arrows, as lesson 4
showed.

The data, saved as `graph.cypher`: ten shows, sixty buyers, and a `BOUGHT` relationship between a
buyer and a show whenever a fixed piece of arithmetic on their ids says so, so that the graph is the
same on every machine. The last line counts the relationships:

```
// graph.cypher
MATCH (n) DETACH DELETE n;
UNWIND range(1, 10) AS s
CREATE (:Show {id: s, name: 'Show ' + s});
UNWIND range(1, 60) AS b
CREATE (:Buyer {id: b});
MATCH (b:Buyer), (s:Show)
WHERE (b.id * 7 + s.id * 3) % 11 < 3
CREATE (b)-[:BOUGHT]->(s);
MATCH (:Buyer)-[r:BOUGHT]->(:Show) RETURN count(r) AS tickets;
```

`UNWIND` turns a list into rows, so `UNWIND range(1, 10) AS s CREATE …` creates ten nodes.
`DETACH DELETE` on the first line empties the database, so the file can be run twice.

## Starting it and loading

Neo4j needs a password from the first start, given as `NEO4J_AUTH`; its heap is limited so that it
fits the lab. `cypher-shell`, inside the image, waits in a loop until the server answers and then
runs the file:

```
ana@lab:~/tickets$ docker run -d --name neo4j --memory 1g -e NEO4J_AUTH=neo4j/lab-password -e NEO4J_server_memory_heap_max__size=512m neo4j:5.26.31
748602fb04aa661ebe0ba08ed3ede1380516ceae872a05358f1cd2306881d641
ana@lab:~/tickets$ until docker exec neo4j cypher-shell -u neo4j -p lab-password 'RETURN 1' >/dev/null 2>&1; do sleep 3; done
ana@lab:~/tickets$ docker cp graph.cypher neo4j:/tmp/graph.cypher
ana@lab:~/tickets$ docker exec neo4j cypher-shell -u neo4j -p lab-password -f /tmp/graph.cypher
tickets
164
```

164 `BOUGHT` relationships between sixty buyers and ten shows.

## The walk

The recommendation of lesson 4: from Show 1, back along `BOUGHT` to its buyers, forward along
`BOUGHT` to their other shows, counting how many buyers each other show shares. Then the same query
with `PROFILE` in front, which runs it and reports what it cost:

```
ana@lab:~/tickets$ docker exec neo4j cypher-shell -u neo4j -p lab-password "MATCH (s:Show {name: 'Show 1'})<-[:BOUGHT]-(b:Buyer)-[:BOUGHT]->(other:Show) RETURN other.name AS show, count(b) AS shared ORDER BY shared DESC, show LIMIT 3"
show, shared
"Show 8", 11
"Show 5", 10
"Show 4", 6
ana@lab:~/tickets$ docker exec neo4j cypher-shell -u neo4j -p lab-password "PROFILE MATCH (s:Show {name: 'Show 1'})<-[:BOUGHT]-(b:Buyer)-[:BOUGHT]->(other:Show) RETURN other.name AS show, count(b) AS shared ORDER BY shared DESC, show LIMIT 3" | tail -6
Planner: "COST"
Runtime: "SLOTTED"
Time: 66
DbHits: 182
Rows: 3
Memory (Bytes): 1392
ana@lab:~/tickets$ docker rm -f neo4j
neo4j
```

**Show 8 shares 11 buyers with Show 1**, Show 5 shares 10, Show 4 shares 6. `PROFILE`'s summary
says the query cost **182 database hits**, Neo4j's unit of work: each node or relationship touched.
Two parts make it up. Finding Show 1 read the ten `Show` nodes, because nothing indexes `name`; with
a million shows that first step would need `CREATE INDEX FOR (s:Show) ON (s.name)`. Everything after
it, **the walk itself, touches only the relationships along the paths it follows**, so its cost
depends on Show 1's buyers and their tickets, not on how many other shows and buyers the graph
holds. `Time` is in milliseconds and varies between runs; the hits do not.

The same question in the box office's PostgreSQL is a self-join of `tickets` through the buyers, and
for one hop it would be fast too. The difference grows with the length of the path, as lesson 4
said, and with how selective the starting point is.
