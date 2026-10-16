---
title: Graphs, when the question is a path
version: 1
---

A **graph database** stores **nodes**, things, and **relationships** between them, each with a
type and properties of its own. The point is not that relationships can be stored, since a
relational table does that with foreign keys. **The point is that following one is cheap and costs
the same however big the graph is**: each node holds direct references to its relationships, so a
query walks from node to node without searching an index at each step.

The fourth access pattern of section 03 is a walk: from a show, to the people who bought tickets
for it, to the other shows they bought tickets for. In the graph it is drawn as it is asked:

```
(:Show {name: "Sabiá Festival"})<-[:BOUGHT]-(:Buyer)-[:BOUGHT]->(:Show)
```

That is Cypher, Neo4j's query language, and it reads as a picture: nodes in parentheses,
relationships as arrows. A full query adds what to return:

```
MATCH (s:Show {name: "Sabiá Festival"})<-[:BOUGHT]-(b:Buyer)-[:BOUGHT]->(other:Show)
WHERE other <> s
RETURN other.name, count(b) AS shared
ORDER BY shared DESC
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A graph walk. The show Sabiá Festival on the left is connected by BOUGHT relationships to three buyers. Two of the buyers also have BOUGHT relationships to the show Noite de Choro, and one to Rock na Praça. The walk counts the paths: Noite de Choro is reached twice, Rock na Praça once.\"><circle cx=\"90\" cy=\"115\" r=\"46\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"90\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">Sabiá</text><text x=\"90\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">Festival</text><path d=\"M136 115 L308 45\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M308 45 L303.3 50.2 L301.0 44.6 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><circle cx=\"330\" cy=\"45\" r=\"22\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></circle><text x=\"330\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">buyer</text><path d=\"M136 115 L308 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M308 115 L301.7 118.0 L301.7 112.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><circle cx=\"330\" cy=\"115\" r=\"22\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></circle><text x=\"330\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">buyer</text><path d=\"M136 115 L308 185\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M308 185 L301.0 185.4 L303.3 179.8 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><circle cx=\"330\" cy=\"185\" r=\"22\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></circle><text x=\"330\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">buyer</text><text x=\"220\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">BOUGHT</text><circle cx=\"600\" cy=\"70\" r=\"40\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"600\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">Noite de Choro</text><text x=\"600\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">2</text><circle cx=\"600\" cy=\"170\" r=\"40\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"600\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">Rock na Praça</text><text x=\"600\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">1</text><path d=\"M352 45 L560 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M560 70 L553.4 72.3 L554.1 66.2 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M352 115 L560 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M560 70 L554.5 74.3 L553.2 68.4 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M352 185 L560 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M560 170 L553.9 173.5 L553.5 167.4 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"465\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">shared buyers per show</text></svg>", "caption": "From a show, through its buyers, to their other shows. Each step follows a stored reference."}
```

## Against the same question in SQL

In the box office's tables the same question is a self-join of `tickets` through the buyers: the
show's tickets, joined to every ticket of the same buyers, grouped by show. One hop is a join a
relational database does well. **The cost appears with depth.** "Friends of friends of friends" is
three self-joins, each multiplying the rows the next one sees, while a graph walk touches only the
nodes along the paths it follows. Questions of variable depth, "any chain of connections up to six
long", are natural in a graph and awkward in SQL.

## Where it fits, and where it does not

Graphs fit questions about **connections**: recommendations, fraud rings that share cards and
addresses, permissions inherited through groups, dependencies between services. They fit poorly
for what this course is mostly about: **counting and summing large sets**, and spreading data over
many servers. A graph is hard to shard, because any partition cuts relationships and every cut
relationship is a hop across the network. Neo4j scales reads with replicas and keeps each graph's
writes on one primary, which is lesson 2's arrangement with a different data model.
