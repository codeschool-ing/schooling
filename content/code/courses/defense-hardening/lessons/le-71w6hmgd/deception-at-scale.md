---
title: Deception at scale
version: 1
---

**Nothing in this section was run for this course.** The products and services below are described
from their own documentation.

The lab built three pieces of bait by hand. A firm with a thousand machines does the same thing
with tools that make bait cheap to scatter and alerts easy to route, and the ideas are the ones you
already know.

## Canarytokens

Thinkst's free **Canarytokens** service generates honeytokens of many kinds: a document that calls
home when opened, a URL that alerts when visited, fake cloud access keys that alert when somebody
tries them, a DNS name that alerts when resolved. Each one sends an e-mail or a webhook to whoever
made it, with the time and the address it came from. It is the honey account of this lesson made
into a service: the alert fires wherever the stolen thing is used. Using it means trusting a third
party with the alerts, which is a decision like any other external service.

## Deception platforms

Commercial **deception** products, Thinkst's own Canary devices among them, run decoy machines that
imitate real ones, a Windows file server or a network printer, with configuration through a console
and alerts to the firm's existing tools. What they sell is mostly what the section on placement
asked for: decoys that look right, cost little to place, and never become a way in themselves.

## Honey accounts in a directory

In a Windows domain, the honey account idea works particularly well. An account with an attractive
name, a description suggesting old administrator rights, and no use at all is created in Active
Directory; any attempt to log in as it, or to request access tickets for it, appears in the domain
controllers' security log and becomes an alert. Microsoft's own identity protection products
document this pattern under the name **honeytoken accounts**.

## The test of any of them

Every one of these is judged by the same three questions this lesson asked of its own bait: is it
where an intruder would look, does it never weaken what it sits beside, and does a person see the
alert within minutes. A deception product that fails the third is the same as the file on `web`
with nobody reading the log.
