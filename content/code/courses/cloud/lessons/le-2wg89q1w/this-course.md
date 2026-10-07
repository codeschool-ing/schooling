---
title: What this course is, and where its numbers come from
version: 1
---

This course is about **the shape of the cloud, not anybody's console**. A diagram of what a managed
database takes off your hands will still be right in ten years; a screenshot of the page where you
click to create one is wrong the next time the provider redesigns it. You will meet AWS, Azure,
Google Cloud and smaller providers by name, and lesson 3 compares them. What the lessons teach is what
their services have in common: a machine rented by the hour, a disk attached to it, a network drawn
around it, and the rules that say who may touch any of it.

**There is no cloud account anywhere in this course.** An account needs a card, costs money the
moment something is left running, and would have turned every page into the record of one afternoon
in one account. So nothing here is a screenshot of a console, a bill, or an answer a provider gave
to a command. Where a lesson shows configuration, such as a policy document or a boot script, it was
written for the lesson and says so, and what a provider would do with it is described rather than
shown. Where a lesson shows a terminal, the command ran on a laptop with no credentials, and the
prompt says `ana@laptop`. **Every one of those commands is one you can run on your own computer**,
and the next three sections set it up.

## The prices are a published list, read by a program

Cloud is sold by the unit, so a course about it with no prices would be a course about half of it.
**Every price in these lessons is a line of the AWS public price list**, which AWS publishes as JSON
files anybody can download without an account. A small program, `prices.py`, reads one pinned
version of each file and prints the lines the lessons quote. Here it is printing its header and one
block; three sections on, it is printed whole, and you run it yourself:

```
ana@laptop:~/cloud$ python3 prices.py lambda
AWS public price list, USD, excluding tax
  offer AmazonEC2        version 20260925174521
  offer AWSLambda        version 20260919002359
  offer AmazonS3         version 20260926015512
  offer AWSDataTransfer  version 20260916132208
  offer AmazonEFS        version 20260911124425
  offer AmazonVPC        version 20260917190528
                                        sa-east-1    us-east-1

Lambda, USD
  per 1 million requests                     0.20         0.20
  per GB-second, x86                 0.0000166667 0.0000166667
  per GB-second, Arm                 0.0000133334 0.0000133334
  free tier, requests                   1,000,000    1,000,000
  free tier, GB-seconds                   400,000      400,000
```

Three things in that header hold every time a lesson quotes a number. The prices are in US dollars
and exclude tax. Each comes from the **offer version** printed at the top, so running the program
next year prints the same sheet even though the prices themselves will have moved; for today's
prices you would change the versions. And there are two columns. `sa-east-1` is São Paulo, the AWS
region inside Brazil, which is where a company goes when its users are here or its data has to stay
in the country. `us-east-1` is Northern Virginia, the oldest AWS region, and it is **cheaper on most
lines of this sheet**, and dearer on none: a `t3.micro` machine costs 0.01680 dollars an hour in São Paulo and 0.01040 in
Virginia. Lesson 9 is about what the cheaper column costs you in distance, and lesson 10 about the
bill itself.

The block shown is Lambda's, a service lesson 8 is about, and it is a fair first sight of how the
cloud is sold: 20 cents per million requests, and a unit called the GB-second that nobody meets
anywhere else. AWS's list is the one used because it is published whole, in a form a program can
read, and not because the course recommends AWS. The other providers price the same kinds of thing
in the same kinds of unit, and **those units are what these lessons teach you to read**.

## Where this course leads, in your track

::: track cloud-engineering
This course is the vocabulary for the rest of your track. `docker` comes straight after it, then
`kubernetes`, `git` and `iac`, and then the three courses on the provider you pick at the fork. When
those courses name a service, this course is where you learnt which layers it takes off your hands.
:::

::: track data
In your track `pipelines-etl` and `docker` come next, and then one provider's foundations course and
its data course. Those name a managed warehouse, a managed stream and a managed scheduler, and each
is a point on the line this lesson draws: knowing where the line sits tells you what is still yours.
:::

::: track dba
In your track `nosql-operations` comes next. The angle to watch in this course is the managed
database: read lesson 5 with the disks under one in mind, and lesson 10 with its bill. It is the
trade this lesson describes, made on your own subject: the provider patches the engine, and the
schema, the queries and the users stay yours.
:::

::: track devops
You have done `docker` and `kubernetes` already, so a container is not new to you; this course is
where they meet a provider. Next come one provider's foundations course, then `iac`,
`testing-cicd`, `gitops` and `observability`. Terraform, in `iac`, is the tool that turns everything
this course draws into files.
:::

::: track devsecops security
`cloud-security` comes straight after this course, and it starts from the line this lesson draws:
the provider secures what is below it, and everything above it is yours to get right or wrong. Read
lesson 7, on identity, with most care. Identity and access is one of the two rows that stay yours in
every model.
:::

::: track networks-infra
Lesson 6 is the one closest to your trade: a network with subnets, routes and firewall rules, drawn
through an API instead of cabled. After this course come `git` and `python`, then
`networks-automation` and `iac`, which is where the network stops being configured by hand.
:::

::: track software-architecture
`iac` and `observability` come next in your track. In this course, lessons 8 and 9 are where the
architecture decisions live: whether to build on functions or on machines, and how many regions and
zones a system has to survive losing.
:::

::: track *
Whatever comes after this course for you, lessons 1, 7 and 10 are the ones every later cloud course
assumes: which model you are on, who may do what in the account, and what it costs.
:::
