---
title: What this course is, and the AWS it runs against
version: 1
---

**This course is about defending what you run in somebody else's data centre.** It takes the
`cloud` course's vocabulary — regions, managed services, the line between your half of the work and
the provider's — and asks the question a security engineer asks of each piece: what goes wrong here,
how would you know, and how do you prove it is fixed.

The wrong picture to arrive with is that the cloud is a data centre with better marketing, so the
same defences carry over unchanged. Some do. But most of the failures this course is about have no
on-premises equivalent: a storage bucket answering anybody on the internet, a key typed into a
repository in 2019 that still works, a contractor's account nobody revoked that can grant itself
everything. **Each of them is one setting, and each was set by the customer, not the provider.**
Lesson 2 makes that sentence the spine of the course.

## How the seventeen lessons run

| lessons | what they cover |
|---|---|
| 1 to 5 | what changes in the cloud, who is responsible for what, and how the three big providers name the same things |
| 6 to 8 | identity and network: least privilege, keys and secrets, isolation |
| 9 to 11 | data: exposed storage, personal storage at work, encryption with managed keys |
| 12 to 14 | how infrastructure is written and shipped: infrastructure as code, serverless, the deployment flow |
| 15 to 17 | how you know and how you prove it: logs, posture scanning, compliance and residency |

Every lesson is written from the defender's side. Where a lesson needs a flaw, you put it into your
own lab, watch the response that shows it, fix it, and watch the response change. Nothing here is a
recipe for reaching anybody else's system.

## A clinic, and four people

The examples follow one small company: a clinic that books appointments online and keeps its
patients' records in AWS. Medical records are what makes the stakes concrete, because the
`security-fundamentals` course's lesson 17 already showed you that Brazil's LGPD treats health data
as *sensitive* personal data, with stricter rules than an e-mail address.

Four people work on its account. **ana** is you, the security engineer who just joined. **caio**
writes the booking application. **bia** is an analyst who reads reports. **dani** was a contractor
who left in March, and lesson 6 is about what she left behind.

## The AWS these lessons talk to

**You need no AWS account for any lesson, and no card.** The AWS in this course is **moto**, an
open-source program that answers the AWS API on a port of your own computer. You talk to it with the
real AWS command line, the one AWS publishes, so every command you type here is a command you could
type against a real account. moto keeps what it is told in memory, runs no machine, carries no
traffic and forgets everything when it stops.

It is an imitation, and for a security course the important thing about an imitation is **what it
checks and what it only stores**. Lesson after lesson you will meet the same gap, so here it is in
one place:

| | moto 5.2.3 |
|---|---|
| an identity policy allowing or denying an action | **checks it**, when you start it with checking on (lesson 6) |
| an anonymous request for an object a bucket policy or ACL makes public | **checks it**: the object is served or refused as AWS would |
| a condition in a policy (source address, MFA, region) | stores it, ignores it |
| S3 Block Public Access, the four switches of lesson 9 | stores them, enforces none |
| service control policies of an organisation | stores them, enforces none |
| a key scheduled for deletion | still decrypts, where AWS would refuse |
| CloudTrail recording what happened | creates the trail, records nothing |

**A lesson never lets moto's silence stand in for AWS's answer.** Where AWS would refuse something
moto allowed, the prose says so beside the transcript, and the claim comes from AWS's documentation
rather than from a run. The same goes for Azure and Google Cloud, which have no imitation here at
all: lesson 5 and the sections that compare providers are taught from their documentation and
marked as not run.

The next three sections build that lab on your computer. Take them in order the first time; after
that, the last of the three is the one to come back to when something does not answer.
