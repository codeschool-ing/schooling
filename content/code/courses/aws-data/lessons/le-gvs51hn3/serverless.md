---
title: Serverless, and capacity measured in RPUs
version: 1
---

**Redshift Serverless is the same engine with no cluster to size.** Instead of choosing a node type
and a number of nodes, you set a capacity in Redshift Processing Units, RPUs, and Redshift brings
up that much compute when a query arrives and lets it go when the queries stop. The tables, the
SQL, the distribution and sort keys of the last two sections are all the same. What changes is who
decides how much machine there is, and how it is billed.

## A namespace and a workgroup

**A Serverless warehouse is two things with two names.** The **namespace** holds what the warehouse
*is*: its databases, schemas, tables, users and permissions, and the storage under them. The
**workgroup** holds what it *runs on*: the capacity, the network it sits in, the security groups,
the limits. They are separate so that one can change without the other; a workgroup can be deleted
and a new one attached to the same namespace, and the data does not move.

**The base capacity is what a query starts with**: 128 RPUs unless you set it, at least 8, and in
steps of 8. AWS documents an RPU as 16 GB of memory with the processing that goes with it. Redshift
may scale above the base while a heavy query runs, and a **maximum capacity** setting puts a ceiling
on that, which is the setting that keeps an expensive mistake from becoming an expensive month.

**It is billed by the RPU-hour, per second, only while queries run**, with a minimum of 60 seconds
each time compute starts. An hour with no queries costs nothing for compute. Storage is billed
apart, at the managed storage rate, whether anything runs or not. That is the whole difference from
a provisioned cluster, which charges for every hour it exists unless somebody pauses it, and the
next section turns it into numbers.

## What moto does with it

moto has no implementation of the Redshift Serverless API:

```
ana@laptop:~/aws$ aws redshift-serverless create-namespace --namespace-name quitanda

aws: [ERROR]: An error occurred (500) when calling the CreateNamespace operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
ana@laptop:~/aws$ aws redshift-serverless create-workgroup --workgroup-name quitanda-adhoc --namespace-name quitanda --base-capacity 8

aws: [ERROR]: An error occurred (500) when calling the CreateWorkgroup operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

**Both calls failed with a 500 from moto itself**, an internal error and not an answer AWS would
give, and the command line retried twice before giving up. Nothing about Serverless can be
practised in this lab, not even as a record. Everything in this section comes from AWS's documentation and was not run.

## Which one to choose

**Serverless suits work that comes and goes**: analysts who query during office hours, a dashboard
refreshed a few times a day, a team that does not yet know what its load will be. **A provisioned
cluster suits work that never stops**: loads arriving all day, reports running all night, a
warehouse busy most of its hours. The line between the two is a number of busy hours a day, and the
price sheet says where it falls.
