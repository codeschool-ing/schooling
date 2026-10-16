---
title: What moto answers, and what it only pretends
version: 1
---

**moto answers like AWS and enforces much less.** It was written so that programs which call AWS can
be tested without an account, and for that job it has to accept a request, keep what the request
said, and give back the answer AWS would give. It does not have to do the work behind the answer,
and for most of what this course is about, it does not. A course on operations is mostly a course on
that work: an alarm that fires, a deployment that rolls back, a policy that refuses. So the course
uses moto for what it does well, and says plainly, every time, where it stops.

## Where the line falls, service by service

| what the course does | what moto does | what moto does not do |
|---|---|---|
| pipelines, builds, deployments | stores the pipeline, the build project, the deployment | run a build, move a deployment past `Created`, start a pipeline |
| CloudFormation | creates and deletes a stack from a template | compute a change set for an existing stack, detect drift |
| metrics | stores data points, returns sums, averages, minima and maxima | percentiles, metric math |
| alarms | stores the alarm and lets you set its state by hand | evaluate it, change its state on its own, notify anybody, composite alarms |
| logs | stores events, returns them | apply a filter pattern, run a Logs Insights query, turn a metric filter into a metric |
| identity | with one switch, checks a caller's policies by action | check the `Resource` of a statement, read a key policy or a bucket policy |
| KMS and Parameter Store | encrypts and decrypts, stores a `SecureString` | refuse a key scheduled for deletion; it stores the "encrypted" value with the plaintext inside it |
| security findings | answers an image scan | find anything: the one finding it returns is a placeholder |
| prices | nothing | prices: every number in this course comes from AWS's public price list, with its date |

Each of those rows comes back in the lesson it belongs to, with the transcript that shows it. Where
moto cannot show the real behaviour, the lesson teaches it from AWS's documentation and says, in so
many words, that this part was not run. **Read those sentences as seriously as the transcripts.** A
call that succeeded against moto proves that the request was well formed, and nothing about whether
AWS would have allowed it.

## The one switch

By default moto lets every caller do everything. Started with `INITIAL_NO_AUTH_ACTION_COUNT` set, it
lets that many requests through unchecked, enough to create a user and give it a policy, and from
then on refuses any action the caller's policies do not allow. Lesson 17 uses it, because a lesson
about who may read a secret is a lesson about a refusal. It checks the **action** and not the
resource, so a policy limited to one secret behaves, under moto, like a policy that names no secret
at all. That lesson shows it.

## A real account, if you want one

Nothing in this course needs a real AWS account, and nothing in it is easier with one. **If you open
one anyway**, `aws-foundations` lesson 1 has the section on doing it safely, and the order is the
part to remember: protect the root user with a second factor, then create a budget with an alert,
before anything else. The free tier is one possibility for a small bill, never a promise: what
it covers changes, and a forgotten resource is billed whether or not you meant to keep it. Those
steps cannot be recorded without an account, so they were not run for this course and no transcript
of them is shown.

Two rules hold either way. **Never put a real access key in a file this course has you create**, and
never paste one into a question or a forum. And the commands in these lessons were written for moto:
pointed at a real account, several of them create things that cost money by the hour.
