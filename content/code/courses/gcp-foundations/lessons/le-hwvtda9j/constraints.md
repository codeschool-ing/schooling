---
title: A constraint, and the policy that sets it
version: 1
---

**IAM says who may do something. An organisation policy says what may be done at all, by anybody.**
Owner of a project is the widest role there is, and an owner still cannot create a service account key
in a project where a policy forbids keys, or a disk in Iowa where a policy allows only São Paulo. That
is the whole point: a guardrail that a powerful role could step over would not be a guardrail.

The vocabulary has two words, and they are easy to swap:

- a **constraint** is a rule Google defines, with a name, such as
  `iam.disableServiceAccountKeyCreation` or `gcp.resourceLocations`. It does nothing on its own;
- an **organisation policy** is a constraint set to a value and attached to a node of the tree: the
  organisation, a folder or a project.

## Three kinds of constraint

| kind | what it holds | example |
|---|---|---|
| **boolean** | on or off | `compute.requireOsLogin`: every machine uses IAM for SSH, or not |
| **list** | values allowed or denied | `gcp.resourceLocations`: the places resources may be created |
| **custom** | a condition written in CEL against a resource's fields, for the services that support it | "a firewall rule may not allow `0.0.0.0/0` on port 22" |

Google has been replacing many of the older boolean and list constraints with **managed constraints**,
whose names carry the word `managed`, such as `iam.managed.disableServiceAccountKeyCreation`. They do
the same job with two improvements: they can be tried in **dry run** first, and they follow the same
rules as custom constraints. A new estate should prefer the managed name where one exists; the older
one keeps working.

A list constraint can name a **value group** instead of listing values one by one.
`in:southamerica-locations` means every region and zone in South America, today's and tomorrow's,
which is what a rule about data residency usually means.

## What an organisation policy does not do

Two things surprise people the first time, and both are on purpose:

- **It is not retroactive.** A policy is checked when a resource is created or changed. A key that
  existed before keys were forbidden goes on existing, and a disk in Iowa created before the location
  rule goes on running there. Turning a policy on is the moment to go and look for what it would have
  refused, and lesson 25's inventory is how.
- **It does not grant anything.** Allowing `southamerica-east1` in a list does not give anybody a
  role there. It removes possibilities, and IAM decides who uses the ones that are left.

The role to set policies is **Organization Policy Administrator**, `roles/orgpolicy.policyAdmin`, held
on the organisation. It is deliberately separate from Owner: the people who run projects should not be
the people who decide what any project may do.

## Secure by default

An organisation created on or after **3 May 2024** starts with a handful of policies already enforced,
which Google calls *secure by default*. Among them: no service account key may be created or uploaded,
default service accounts get no automatic Editor role, IAM grants are limited to identities from the
organisation's own domain, and buckets use uniform access. An older organisation has none of them until
somebody sets them, which makes one habit worth having: **check which of these an estate has
before assuming it has them**.

Nothing in this section was run: no emulator answers the Organization Policy API. The section after
next writes three of these policies down and plans them.
