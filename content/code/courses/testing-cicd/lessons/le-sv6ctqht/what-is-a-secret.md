---
title: What counts as a secret
version: 1
---

A **secret** is any value that grants access to something, so that whoever holds it can act as you.
Passwords and API tokens are the obvious ones. The less obvious ones matter as much: a database
connection string with a password in it, a private key for signing, a webhook URL with a token in
its query, a cloud provider's credentials file, the session cookie of an administrator.

`shipquote` has one. `SHIPQUOTE_CARRIER_TOKEN` is the key the shop presents to its carrier; with it,
anybody could ask the carrier for prices on the shop's account, and with a real carrier, create
shipments and run up a bill. In the lab it is `lab-live-token`, a value made up for the course that
opens nothing but the stand-in on 127.0.0.1, and this lesson handles it as if it were real.

## Why a pipeline is where secrets leak

Lesson 8 ended with credentials per environment, and a pipeline is the thing that holds them all: the
staging token, the production token, the key that deploys, the key that publishes a release. It also
runs code from many people and many places, prints logs that many people read, and keeps artifacts
and caches for days. **Every one of those is a path by which a secret leaves the place it belongs.**

The rest of the lesson takes the paths one at a time, as a defender: how each leak happens, how to
find one that already did, and what makes it harmless when it happens anyway.

| path | section |
|---|---|
| committed to the repository | 03 |
| readable on the machine that runs the program | 04 |
| handed to a job carelessly | 05 |
| printed in a log | 06 |
| a token that can do more than its job needs | 07 |
| code nobody reviewed, running with the secrets in reach | 08 |
| a credential that lasts for ever | 09 |
| a leak, and what to do first | 10 |

## Three properties of a well-kept secret

1. **It is not in the code.** Not in the repository, not in the artifact, not in a container image.
   It reaches the program at run time, from the environment, as lesson 8 section 03 described.
2. **It can do only its job.** A token that reads prices should not be able to create shipments.
3. **It expires, or can be replaced in minutes.** A secret that cannot be rotated without an outage
   or a meeting is a secret nobody will rotate after a leak.
