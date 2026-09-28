---
title: Running a PKI without becoming its weak point
version: 1
---

A CA is a small program and a large responsibility: whoever holds its key can impersonate every name
it covers to every machine that trusts it. The practices that keep it trustworthy are organisational
more than technical, and each one answers a way CAs have actually failed.

| practice | answers |
|---|---|
| **root offline**, issuing CA online, as this lesson built | a compromised server taking the root with it |
| **keys in hardware** (an HSM or a smart card) for the CAs | a key copied off a disk without anybody noticing |
| **a written policy** of what is checked before signing | a CA signing whatever it is sent |
| **short lifetimes and automated renewal** | revocation nobody checks; certificates that expire unnoticed |
| **name constraints** on an internal CA: only names under `corp.example.com` | an internal CA used to impersonate public sites |
| **an inventory** of what was issued, to what, with expiry dates | the 3 a.m. outage caused by a certificate everybody forgot |

Two of these deserve a second sentence. **Name constraints** turn a company CA from a key that could
vouch for any name on the internet into one that can only vouch for the company's own: installing it
on staff machines stops being a risk to everything else they visit. And the **inventory** is the most
common failure of all, far more common than any attack: certificates expire on schedule, and the
services that stop that day are the ones nobody listed.

## Public trust is watched

Public CAs are held to a further check: **Certificate Transparency**. Every certificate they issue is
recorded in public append-only logs, and browsers reject certificates that were not logged. A company
can monitor the logs for its own domains and learn within hours if any CA anywhere issued a
certificate for one of its names that it did not ask for. That is a detection control, in the sense of
lessons 14 to 16, applied to the PKI itself.
