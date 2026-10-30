---
title: What answers on your computer, and what does not
version: 1
---

**Nothing on your computer answers like Google Cloud's control plane.** For AWS there is an
open-source program that imitates a large part of the API; for Google Cloud there is nothing of the
kind. Google publishes emulators for a handful of data services, the community imitates Cloud
Storage, and that is all: no project, no IAM, no network, no build, no monitoring answers on
`localhost`. So this course does three different things, and it tells you every time which one it
is doing.

1. **It runs the real thing where the real thing runs locally.** A build step is a container, and
   Docker runs containers. Terraform computes a plan on your computer. An OpenTelemetry Collector
   is a program you can start. A Cloud Function's code runs under Google's Functions Framework.
   These are practised, and every transcript of them is real.
2. **It uses an emulator where one exists.** Pub/Sub is Google's own emulator; Cloud Storage is
   `fake-gcs-server`. Both keep what they are told and answer like the API, and neither enforces a
   permission, bills anything or keeps anything once it stops.
3. **It teaches the rest from Google's documentation, and marks it as not run.** An alert that
   fires, a WAF rule that blocks, a perimeter that refuses: none of that can happen without an
   account. Those passages carry no transcript and no invented output, and they say so.

## Where the line falls, lesson by lesson

| lessons | what runs on your computer | what does not, and is taught from the documentation |
|---|---|---|
| 1 to 4: build and delivery | the build's steps as containers; a local registry; rendering a release; signing and verifying an image | a trigger, Cloud Build itself, a release and its promotion, the admission check |
| 5 to 7: Terraform | the google provider, its plan, buckets in `fake-gcs-server`, the remote state and its lock | creating anything that is not a bucket; Config Connector; Infrastructure Manager |
| 8 to 12: observability | structured logs your program writes; an OpenTelemetry Collector receiving traces; plans of dashboards, sinks and metrics | Cloud Monitoring, Cloud Logging, Error Reporting, Trace and Profiler receiving any of it |
| 13 to 15: SLOs, alerts, incidents | the arithmetic of error budgets and burn rates; plans of the policies | an alert being evaluated, a page being sent |
| 16 to 20: security | plans of the policies; envelope encryption with a key on your disk | Cloud Armor, Secret Manager, Cloud KMS, VPC Service Controls and Security Command Center enforcing or finding anything |
| 21 to 25: cost | a budget notification carried by the Pub/Sub emulator to a function; billing rows queried with SQLite | a bill, a budget, a recommendation |

**Read the marked passages as seriously as the transcripts.** A plan Terraform printed proves that
the configuration is well formed and that the provider knows every argument in it. It proves
nothing about whether Google would accept it, whether your account may create it, or what it costs.

## Prices

The emulators know no prices. Every cost in this course is read from Google's public pricing pages
for the service, with the date it was read and the region the page gives it for, and lesson 1's
last section shows how. A price is the list price on that date: a discount, a credit or a tax is not
in it, and lesson 21 is about the discounts.

## A real account, if you want one

Nothing in this course needs a Google Cloud account, and nothing in it is easier with one. **If you
open one anyway**, `gcp-foundations` lesson 1 has the section on doing it safely, and the order is
the part to remember: protect the account with a second factor, then create a budget with an alert,
before anything else. The free trial and the free tier are one possibility for a small bill, never a
promise: what they cover changes, and a forgotten resource is billed whether or not you meant to
keep it. Those steps cannot be recorded without an account, so they were not run for this course
and no transcript of them is shown.

Two rules hold either way. **Never put a real service account key in a file this course has you
create**, and never paste one into a question or a forum. And the commands in these lessons were
written for the emulators: pointed at a real project, several of them create things that cost money
by the hour.
