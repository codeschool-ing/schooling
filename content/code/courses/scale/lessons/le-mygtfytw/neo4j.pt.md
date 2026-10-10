---
title: Neo4j, quem foi aonde
version: 1
---

O Neo4j é um banco de grafos: **nós** com rótulos e propriedades, e **relações** entre eles, cada uma
com um tipo. A linguagem de consulta dele, o Cypher, desenha padrões com parênteses e setas, como a
aula 4 mostrou.

Os dados, salvos como `graph.cypher`: dez shows, sessenta compradores, e uma relação `BOUGHT` entre um
comprador e um show sempre que uma conta fixa sobre os ids deles manda, para que o grafo seja o mesmo
em qualquer máquina. A última linha conta as relações:

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

`UNWIND` transforma uma lista em linhas, então `UNWIND range(1, 10) AS s CREATE …` cria dez nós.
`DETACH DELETE` na primeira linha esvazia o banco, para que o arquivo possa rodar duas vezes.

## Subindo e carregando

O Neo4j precisa de uma senha desde a primeira subida, dada em `NEO4J_AUTH`; o heap dele é limitado
para caber no laboratório. O `cypher-shell`, dentro da imagem, espera num laço até o servidor
responder e então roda o arquivo:

```
ana@lab:~/tickets$ docker run -d --name neo4j --memory 1g -e NEO4J_AUTH=neo4j/lab-password -e NEO4J_server_memory_heap_max__size=512m neo4j:5.26.31
748602fb04aa661ebe0ba08ed3ede1380516ceae872a05358f1cd2306881d641
ana@lab:~/tickets$ until docker exec neo4j cypher-shell -u neo4j -p lab-password 'RETURN 1' >/dev/null 2>&1; do sleep 3; done
ana@lab:~/tickets$ docker cp graph.cypher neo4j:/tmp/graph.cypher
ana@lab:~/tickets$ docker exec neo4j cypher-shell -u neo4j -p lab-password -f /tmp/graph.cypher
tickets
164
```

164 relações `BOUGHT` entre sessenta compradores e dez shows.

## A caminhada

A recomendação da aula 4: do Show 1, de volta pelas relações `BOUGHT` até os compradores, para a
frente pelas `BOUGHT` até os outros shows deles, contando quantos compradores cada outro show divide.
Depois a mesma consulta com `PROFILE` na frente, que a roda e informa quanto custou:

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

**O Show 8 divide 11 compradores com o Show 1**, o Show 5 divide 10, o Show 4 divide 6. O resumo do
`PROFILE` diz que a consulta custou **182 acessos ao banco** (*db hits*), a unidade de trabalho do
Neo4j: cada nó ou relação tocado. Duas partes compõem isso. Achar o Show 1 leu os dez nós `Show`,
porque nada indexa o `name`; com um milhão de shows esse primeiro passo precisaria de
`CREATE INDEX FOR (s:Show) ON (s.name)`. Tudo depois dele, **a caminhada em si, toca só as relações
ao longo dos caminhos que segue**, então o custo dela depende dos compradores do Show 1 e dos
ingressos deles, não de quantos outros shows e compradores o grafo tem. `Time` está em milissegundos
e varia entre rodadas; os acessos não.

A mesma pergunta no PostgreSQL da bilheteria é um auto-join de `tickets` pelos compradores, e para um
salto ela também seria rápida. A diferença cresce com o comprimento do caminho, como a aula 4 disse,
e com o quanto o ponto de partida é seletivo.
