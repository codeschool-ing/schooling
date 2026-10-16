---
title: A leader, compute nodes and slices
version: 1
---

**Redshift is not a large PostgreSQL.** It accepts SQL that looks like PostgreSQL's, and it answers
on port 5439 to the same drivers, and underneath it is built the other way round. PostgreSQL keeps
a table's rows together on one machine and is fast at fetching one row by its key. Redshift spreads
a table's rows across many machines, keeps each column apart from the others, and is fast at
reading millions of rows to add them up. A query that asks for one order by its id is the wrong
question for it, and the question it is built for, total sales per store per day over a year, is a
slow one for PostgreSQL.

## The parts of a cluster

**A provisioned cluster is one leader node and one or more compute nodes.** The leader is the only
part a client talks to. It parses the SQL, plans it, compiles the plan into code and sends that code
to the compute nodes, then gathers what they return and sends the answer. The compute nodes hold
the data and do the work.

**Each compute node is divided into slices**, and the slice is the unit that actually runs a query.
A slice owns a share of the node's memory and of the table data, and every slice works on its own
share at the same time as the others. An `ra3.xlplus` node has two slices, so the two-node cluster
this lesson prices has four, and a query against it is four pieces of work running side by side.
**A query finishes when its slowest slice finishes**, which is why the next section is about how the
rows are shared out.

**Storage is columnar.** Each column of a table is written separately, in blocks of 1 MB,
compressed with an encoding chosen for that column's values. A query that reads three columns of a
twenty-column table reads three columns' blocks and leaves the other seventeen on disk. Lesson 19
makes the same argument for Parquet files in S3, and it is the same idea.

**Every block carries a zone map**: the smallest and the largest value of its column in that block,
kept in memory. A filter such as `dt = '2026-10-05'` compares the date with each block's minimum and
maximum, and any block whose range cannot contain it is never read. How much that saves depends
entirely on the order the rows were written in, which is the section on sort keys.

**RA3 nodes keep the data in managed storage, not on the node.** The table lives in Redshift Managed
Storage, which AWS keeps in S3 behind the scenes, and each node holds the blocks it is using on a
local SSD. So compute and storage are priced apart: nodes by the hour and storage by the GB-month,
and adding a node changes how fast the cluster works without changing what it stores. The older
node families kept the data on the node's own disks, and the only way to store more was to buy more
nodes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A provisioned Redshift cluster. An SQL client talks only to the leader node, on port 5439. The leader plans and compiles the query and sends it to two ra3.xlplus compute nodes, each with two slices, slices 0 to 3, each holding its share of the rows. Beneath them all, Redshift Managed Storage, in S3, holds the data and is billed per GB-month.\" data-fig=\"l14-cluster\"><defs><marker id=\"l14-cluster-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-cluster-ah-1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l14-cluster-ah-2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker></defs><rect x=\"290\" y=\"12\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">SQL client</text><polyline points=\"360,46 360,70\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l14-cluster-ah-0)\"></polyline><text x=\"372\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">:5439</text><rect x=\"220\" y=\"72\" width=\"280\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">leader node</text><text x=\"360\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">plans, compiles, gathers the answers</text><polyline points=\"360,122 360,136 200,136 200,152\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l14-cluster-ah-1)\"></polyline><rect x=\"60\" y=\"154\" width=\"280\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">compute node 1</text><text x=\"200\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ra3.xlplus</text><rect x=\"76\" y=\"198\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"136\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">slice 0</text><text x=\"136\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">its share of the rows</text><rect x=\"204\" y=\"198\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"264\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">slice 1</text><text x=\"264\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">its share of the rows</text><polyline points=\"200,258 200,282\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l14-cluster-ah-2)\"></polyline><polyline points=\"360,122 360,136 520,136 520,152\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l14-cluster-ah-1)\"></polyline><rect x=\"380\" y=\"154\" width=\"280\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">compute node 2</text><text x=\"520\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ra3.xlplus</text><rect x=\"396\" y=\"198\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"456\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">slice 2</text><text x=\"456\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">its share of the rows</text><rect x=\"524\" y=\"198\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"584\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">slice 3</text><text x=\"584\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">its share of the rows</text><polyline points=\"520,258 520,282\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l14-cluster-ah-2)\"></polyline><rect x=\"60\" y=\"284\" width=\"600\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"302\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Redshift Managed Storage, in S3: the data, billed per GB-month</text></svg>", "caption": "Four slices work at the same time, and the query finishes when the slowest one does. The data lives in managed storage, and the nodes keep the blocks they are using on SSD."}
```

## What moto records

With moto running in its own terminal and the four lines of lesson 1's "Your lab, in brief" typed
in this one, create the cluster this lesson is about:

```
ana@laptop:~/aws$ aws redshift create-cluster --cluster-identifier quitanda-dw --node-type ra3.xlplus --number-of-nodes 2 --master-username quitanda_admin --master-user-password Lab-only-0 --db-name quitanda --query "Cluster.[ClusterStatus,NodeType,NumberOfNodes]" --output text
creating	ra3.xlplus	2
ana@laptop:~/aws$ aws redshift describe-clusters --query "Clusters[].[ClusterIdentifier,ClusterStatus,Endpoint.Address]" --output text
quitanda-dw	available	quitanda-dw.2e9a0ac50a38.sa-east-1.redshift.amazonaws.com
ana@laptop:~/aws$ aws redshift create-cluster --cluster-identifier quitanda-typo --node-type ra3.xlpluss --number-of-nodes 2 --master-username quitanda_admin --master-user-password Lab-only-0 --query Cluster.ClusterStatus --output text
creating
```

**The cluster said `creating` and was `available` one command later.** On AWS a new cluster takes
several minutes to come up. The node type `ra3.xlpluss`, with one letter too many, was accepted as
well, which AWS would refuse; moto checks the shape of the request and not whether the machine
exists. There are no nodes behind either cluster and nothing answers at the endpoint it printed.

moto also implements the Redshift Data API, the way to send SQL to a cluster over HTTPS without a
database driver, and that shows the limit more plainly than anything else here:

```
ana@laptop:~/aws$ aws redshift-data execute-statement --cluster-identifier quitanda-dw --database quitanda --sql "CREATE TABLE stores (store_id SMALLINT NOT NULL, name VARCHAR(64) NOT NULL) DISTSTYLE ALL" --query Id --output text
38da6ade-4ccd-44f6-88f2-a41d1646f771
ana@laptop:~/aws$ sleep 5; aws redshift-data describe-statement --id 38da6ade-4ccd-44f6-88f2-a41d1646f771 --query '[Status,HasResultSet,QueryString]' --output text
STARTED	False	CREATE TABLE stores (store_id SMALLINT NOT NULL, name VARCHAR(64) NOT NULL) DISTSTYLE ALL
ana@laptop:~/aws$ aws redshift-data execute-statement --cluster-identifier quitanda-dw --database quitanda --sql "SELECT dt, count(*) FROM orders GROUP BY dt" --query Id --output text
d8036238-69de-4810-b250-ab063a7ece79
ana@laptop:~/aws$ aws redshift-data get-statement-result --id d8036238-69de-4810-b250-ab063a7ece79 --query 'Records[*].[[0].longValue,[1].stringValue,[2].stringValue]' --output text
10	Alpha st	Vancouver
50	Beta st	Toronto
100	Gamma av	Seattle
```

**The SQL was accepted, and five seconds later it was still `STARTED`**: there is nothing in moto
that would ever finish it. Then a `SELECT` against a table nobody created came back with three rows,
a number, a street and a city, which are moto's own sample answer to any statement. Nothing in
this course runs Redshift's SQL. The DDL in the next two sections is written to be read, and what it
does is taught from AWS's documentation and from two small models that are labelled as models.
