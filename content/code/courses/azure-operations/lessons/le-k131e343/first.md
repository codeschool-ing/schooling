---
title: What to act on first
version: 1
---

**The order is set by what an attacker could reach, not by the length of the list or the size of the
points.** Every recommendation has a **severity** from Defender, and severity alone is not enough: a
high-severity finding on a test VM with no network path to anything is less urgent than a medium one on
the database behind the checkout. The shop sorts by three questions, in order:

1. **Is it reachable from the internet?** A resource with a public endpoint is where an attack starts.
2. **What does it hold or reach?** Customer data, secrets, or the identity that can change production.
3. **Is there a known way in?** A vulnerability with a published exploit, a key that never expires, a
   rule open to `0.0.0.0/0`.

A finding that answers yes to all three goes first, whatever its points. **Defender CSPM's attack path
analysis** is this reasoning done by the tool: it builds a graph of resources, identities and network
paths and shows the chains that lead from the internet to something sensitive. Where the paid plan is
on, that list is the shop's starting point; where it is not, the three questions are.

An example, written by the course, of how the shop would order four findings:

| finding | reachable | holds | way in | order |
|---|---|---|---|---|
| storage account `stshopexports` allows public blob access | yes | order exports | anonymous read | 1 |
| SQL server `sql-shop` firewall allows Azure services | indirectly | customer data | any Azure tenant's app | 2 |
| Key Vault `kv-shop-prod` without purge protection | no | secrets | deletion, not theft | 3 |
| VM `vm-reports` missing endpoint protection | no | nothing sensitive | none known | 4 |

Two follow-ups make the order stick. **Fix the template, not the resource**: a recommendation fixed by
hand in the portal comes back with the next deployment, so the fix goes into the Bicep, and lessons 17 and
20 do exactly that for the vault and the database. And **use Azure Policy to stop the next one**: once
public blob access is fixed, a policy that denies it keeps it fixed. Lesson 24 writes a policy.
