---
title: The provider's half, as far as you can see it
version: 1
---

**You cannot test the provider's half, so you read what an independent auditor wrote about it, and
the most useful page of that report is the one listing what the auditor assumed *you* would do.**
This section is taught from the providers' documentation: the reports themselves sit behind an
account, and nothing in it was run.

## The reports

Each of the three large providers publishes the same family of attestations, and each keeps them in
a portal of its own: **AWS Artifact** in the AWS console, the **Service Trust Portal** at Microsoft,
and **Compliance Reports Manager** at Google Cloud. Some are public; most need an account, and some
need you to accept a non-disclosure agreement before you download them.

| report | what it says |
|---|---|
| **ISO/IEC 27001** certificate | an information security management system exists and was certified; ISO/IEC 27017 and 27018 add controls for cloud services and for personal data in them |
| **SOC 2 Type II** | an auditor tested named controls over a period of months and says whether they worked |
| **SOC 3** | a short public summary of the SOC 2, with none of the detail |
| **PCI DSS** attestation of compliance | which services may hold card data, and under what conditions |

A certificate tells you a system exists. **A SOC 2 Type II is the one a security engineer reads**,
because it says what was tested, how, over which months, and what failed.

## Reading a SOC 2 Type II

Four parts of it decide whether it answers your question:

1. **The scope.** Which services and which regions the audit covered. A service missing from the list
   was not examined, however famous it is.
2. **The period.** The months the controls were observed over. A report covering last year says
   nothing about a change made this year.
3. **The opinion and the exceptions.** The auditor's opinion comes first, and further in, each tested
   control with the result. A test where some samples failed is listed as an *exception*, with the
   provider's answer beside it.
4. **The complementary user entity controls.** A list, usually near the end, of controls the provider
   assumes its customers operate, without which its own controls do not achieve their goal.

The fourth is the shared responsibility line written in an auditor's language. Items like "customers
are responsible for granting and reviewing access to their own users" or "for configuring encryption
of the data they store" are the rows above the line, and a report that passed is a report that passed
**on the assumption that you do them**. When somebody says "the provider is certified", the honest
reply is that the certificate counts on you.

## What no report can tell you

A report describes the provider, across all its customers, in the past. It cannot say anything about
your account: not one of your buckets, keys or network rules is in it. So the two kinds of evidence
of this lesson's first section are not alternatives. The report covers what you cannot see, the API
covers what you can, and **an audit of your own system needs both**: the provider's report for the
rows below the line, and your own transcripts for the rows above it. Lesson 17 assembles exactly that
pile for an auditor.
