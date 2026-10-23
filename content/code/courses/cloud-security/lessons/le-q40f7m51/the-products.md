---
title: The tools that do this for a living
version: 1
---

**Every provider sells the loop of this lesson as a service, and several open-source tools run it
across all three.** None was run for this course: the providers' services need real accounts, and
the open-source scanners were written against the real APIs rather than against moto. What follows
comes from each project's own documentation, and the point of reading it is to recognise the same
four parts you built — the inventory, the rules, the findings and the exceptions — under other names.

## Inside AWS

| service | what it is, in this lesson's terms |
|---|---|
| **AWS Config** | the inventory with a memory. It records every change to a resource's configuration, so it can say *when* a bucket became public, which `scan.py` cannot. **Config rules** are the rules, run on every change or on a schedule, and a **conformance pack** is a set of them deployed together |
| **AWS Security Hub** | the findings in one place. Its posture checks run standards such as the CIS AWS Foundations Benchmark and AWS's own Foundational Security Best Practices, and it collects findings from other services, GuardDuty's among them |
| **AWS Organizations** | not a scanner, but what lets the two above cover every account of a company from one place, instead of one account at a time |

Config is billed per configuration item recorded and per rule evaluation, which is lesson 1's point
about the bill again: **the visibility exists, it is off until you turn it on, and it costs money
when you do.**

## In the other two clouds

- **Microsoft Defender for Cloud** assesses Azure subscriptions against its recommendations and the
  Microsoft cloud security benchmark, and sums them into a **secure score**. It can also read AWS and
  Google Cloud accounts once they are connected to it.
- **Google Security Command Center** gathers findings for an organisation; its **Security Health
  Analytics** is the part that reads configuration, with detectors such as a bucket open to
  `allUsers` or a firewall rule open to the world.

## Open source, across clouds

- **Prowler** runs hundreds of checks against AWS, and also Azure, Google Cloud and Kubernetes,
  mapped to the CIS Benchmarks and to frameworks such as ISO 27001 and PCI DSS. It runs from a laptop
  with read-only credentials.
- **ScoutSuite**, from NCC Group, reads an account through the API and writes a report you open in a
  browser, organised by service.

Both are `scan.py` with the edges filled in: every region, every service, hundreds of rules,
reports in formats other tools read. Both need what `scan.py` needs: **a role that can read
everything and change nothing**. AWS's managed policies `SecurityAudit` and `ViewOnlyAccess` exist
for this, and giving a scanner more than that turns the tool that looks for exposure into an exposure
of its own.

## Choosing, for a clinic

A company of four people with one account does not need a product on day one. It needs the four
rules of this lesson running every morning and an inbox that reads them. The provider's service
earns its price when the account multiplies, when the auditor of lesson 17 asks for a history of
changes, or when nobody has time to keep a home-made rule list current. **Whichever runs, the work
after the finding is the same**: an owner, a fix or a dated exception, and a second scan as proof.
