---
title: What moto is, and what it is not
version: 1
---

**moto answers like AWS and enforces much less.** It is a Python program written to test other
programs: it receives the same requests the real services receive, at the same paths and in the same
format, and returns answers in the shape AWS documents. Behind those answers is a dictionary in
memory. A bucket is an entry in it, an object is bytes in it, and a database is a record with a
name and a status. That is enough to learn the interface of a service, and it is not enough to learn
its behaviour, and this course says which one each lesson is showing.

Three demonstrations make the difference concrete. The first two are about who is allowed in, and
the third is about work moto does not do:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-moto-demo
make_bucket: quitanda-moto-demo
ana@laptop:~/aws$ echo hello > note.txt && aws s3 cp note.txt s3://quitanda-moto-demo/note.txt
upload: ./note.txt to s3://quitanda-moto-demo/note.txt          
ana@laptop:~/aws$ AWS_ACCESS_KEY_ID=nobody-issued-this AWS_SECRET_ACCESS_KEY=wrong aws s3 ls s3://quitanda-moto-demo
2026-10-16 12:31:09          6 note.txt
ana@laptop:~/aws$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:4567/quitanda-moto-demo/note.txt
403
ana@laptop:~/aws$ aws athena start-query-execution --query-string "SELECT count(*) FROM orders" --result-configuration OutputLocation=s3://quitanda-moto-demo/athena/
{
    "QueryExecutionId": "768774a0-842f-4668-afd6-741d06d99814"
}
ana@laptop:~/aws$ aws athena get-query-execution --query-execution-id 768774a0-842f-4668-afd6-741d06d99814 --query 'QueryExecution.[Status.State,Statistics.DataScannedInBytes]' --output text
SUCCEEDED	0
ana@laptop:~/aws$ aws athena get-query-results --query-execution-id 768774a0-842f-4668-afd6-741d06d99814 --query 'ResultSet.Rows'
[]
```

**A key nobody issued was accepted.** The listing was signed with `nobody-issued-this`, a key no
account has ever had, and moto answered as if it were yours. Against S3 the same request fails with
`InvalidAccessKeyId`. The `curl` line is the other half: a plain HTTP request with no signature at
all, and moto answered `403`, because the bucket is private and an anonymous request to a private
bucket is refused. **moto checks that a request is signed, and by default not who signed it**, and it
evaluates no policy, so every action a policy should deny succeeds. Lesson 4 turns on the part of
moto that does evaluate identity policies, because a lesson about who may read a bucket cannot be
taught by a server that lets every signed request in.

**The query succeeded, scanned 0 bytes and returned nothing.** There is no table called `orders`
anywhere, and Athena would have failed with an error naming it. moto records the query, marks it
`SUCCEEDED`, and runs no SQL. The same is true of a Glue job, which "succeeds" without running a line
of Spark, of an RDS database, which is `available` at once and has no database engine behind it, and
of a Redshift cluster. Where a lesson needs the behaviour of one of those, it gets it from somewhere
real: DuckDB for the SQL, the price sheet for the money, and AWS's own documentation for the rest,
with the prose saying plainly that the part was not run.

## What it does do, faithfully

The services whose behaviour is data structures rather than machines are where moto is at its best,
and they are a large part of this course:

| service | what moto really does |
|---|---|
| S3 | stores the bytes, lists by prefix, keeps versions, refuses to delete a locked object |
| DynamoDB | evaluates key conditions, filters and conditional writes; keeps a stream of changes |
| Kinesis Data Streams | hashes a partition key onto a shard and keeps records in order per shard |
| Data Firehose | delivers what it receives into S3, under a dated prefix |
| Glue Data Catalog | keeps databases, tables, partitions and the versions of a table |

And three things it never does, whatever the service: **it sends no bill, waits for nothing, and
fails only when told to.** A cluster that takes twenty minutes to start on AWS is ready on the same
line. A disk does not fill, a zone does not go down, a shard is never throttled. Lessons that are
about those failures teach them from the documented behaviour.

**Treat a success from moto as "the request was well formed", never as "this would work".** It is
the most useful sentence in this course and the easiest to forget.
