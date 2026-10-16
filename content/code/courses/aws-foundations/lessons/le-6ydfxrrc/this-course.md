---
title: What this course is, and the AWS it runs against
version: 1
---

This course is the ground floor of AWS: **how the accounts are arranged, who may do what in them,
what the bill says and how a packet gets from one place to another**. It assumes the `cloud` course,
or what it teaches, so a region, a virtual machine and an access policy are words you already have.
What this course adds is the way AWS in particular builds them, under the names its documentation,
its command line and its job adverts use.

Twenty-six lessons, in four parts:

| lessons | what they cover |
|---|---|
| 1 to 5 | where things are, and the accounts that hold them: regions, the account, AWS Organizations, service control policies, the landing zone |
| 6 to 12 | identity: principals, policies, how a request is judged, roles, credentials for machines, single sign-on, and access keys |
| 13 to 15 | money: budgets and tags, reading a bill, and the report that says who spent what |
| 16 to 26 | the network, and the tools: VPCs, routes, filters, endpoints, peering, DNS, load balancers, CloudFront, the road from a datacentre, the command line and the API under it |

## No AWS account

**Nothing in this course needs an AWS account, a card or a key.** An account costs money the moment
something is left running, and a lesson recorded against one account would be the record of one
afternoon in it. So the AWS every lesson talks to is **moto**: an open-source program, written in
Python, that answers the AWS API on a port of your own computer. You run it in one terminal and use
the real AWS command line in another. The command line cannot tell the difference; it sends the
same signed requests it would send to AWS, and moto answers them in AWS's own format.

The same arrangement serves the three AWS courses that follow this one, `aws-compute`,
`aws-operations` and `aws-data`. This lesson builds it once, and each of those courses opens by
checking that yours still answers.

::: track cloud-engineering
In your track `aws-compute` and `aws-operations` come next, and both run against the lab you build
here. Keep `~/aws` when you finish: the next course checks it rather than building it again.
:::

::: track data
In your track `aws-data` comes next, and it runs against the lab you build here. Keep `~/aws` when
you finish: that course checks it rather than building it again.
:::

::: track devops
In your track this is the one AWS course, so it has to stand on its own, and it does: nothing in
it waits for a later course to explain it.
:::

::: track *
If you go on to `aws-compute`, `aws-operations` or `aws-data`, each runs against the lab you build
here. Keep `~/aws` when you finish, and they will check it rather than build it again.
:::

## What moto is not

moto answers like AWS and **enforces much less than AWS does**, and a course that hid that would
teach the wrong thing. Four differences matter here, and the lessons that meet them say so again:

- **It does not judge permissions unless you ask it to.** Out of the box, every call succeeds, even
  one a policy should deny. Lesson 7 turns on moto's checking, and from then on a user without
  permission is refused. What moto checks is the user's own policies, a role's trust policy and an
  explicit deny; it does **not** check permission boundaries, service control policies, session
  policies or a bucket's own policy beyond its objects, and it treats every condition in a policy as met. Lessons 4 and
  8 teach those from AWS's documentation and say which lines were not run.
- **It carries no traffic.** A VPC in moto is a record with an id and a CIDR range. A security group
  stores its rules and filters nothing, because nothing flows. Lessons 16 to 24 build the network
  for real, as configuration, and reason about the packets rather than send them.
- **It sends no bill and knows no price.** Every price in these lessons comes from **AWS's public
  price list**, a set of JSON files anybody may download, read by a short program the last section
  of this lesson shows you. Each price carries the date of the list it came from.
- **It has no console.** There is nothing to screenshot, and a drawn imitation of AWS's console
  would be a fake. Where the console matters, a lesson says in words what you will find there.

Where moto cannot show what AWS does, the lesson teaches the behaviour from AWS's documentation and
**says plainly that this part was not run**. Everything else, every command and every line of
output in a terminal, was run in a lab built exactly the way the next three sections tell you to
build yours. The prompt reads `ana@laptop:~/aws$`.

## A real account, if you want one

You never need one here. If you do want to try what you learnt against AWS itself, the section
**"A real account, and the order to protect it in"** below says how to open one safely, and it comes
before anything else for a reason: the first hour of a new account is when it is cheapest to
protect and most expensive to leave open.
