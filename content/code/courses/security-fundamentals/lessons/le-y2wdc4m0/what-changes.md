---
title: What changes, and what does not
version: 1
---

Adopting Zero Trust is not a project that finishes. It is a direction an organisation moves in,
resource by resource, and the changes it brings are easier to see as before and after:

| | trust by location | Zero Trust |
|---|---|---|
| what decides access | the network a request comes from | identity, device and context, per request |
| the perimeter | the main control | one layer among several |
| remote work | a VPN onto the trusted network | the same access path as from the office |
| a compromised laptop inside | inherits the network's trust | gets what its user's identity allows, from that device, if the device passes |
| internal traffic | often unencrypted | encrypted, like external traffic |
| logs | which address did what | which identity, on which device, did what |

### Identity becomes the perimeter

When location stops deciding, the thing that decides is the identity, which makes identity the most
attacked part of the system. That is why every serious Zero Trust design starts with strong
authentication, MFA for everyone (lesson 9), and a clean process for creating and removing accounts
(lesson 6's joiners, movers and leavers). A Zero Trust architecture with weak passwords has moved the
castle's wall to the front door and left the door unlocked.

### Microsegmentation

Lesson 5 ended with microsegmentation: every workload with its own boundary. It is the network half
of Zero Trust. Where the PEP in front of an application checks who is asking, microsegmentation
makes sure that even a compromised server can only open the connections its job requires, so the
assume-breach principle has something to enforce it at the network level too.

### Not a product

Vendors sell "Zero Trust" as a box, and no box delivers it. The principles describe how decisions
are made, and a product can help make some of them: an identity provider, a gateway that acts as a
PEP, a device-management service. **Buying all three and leaving the old flat network trusted
underneath them achieves nothing.** The test of a Zero Trust change is the lab's test: run the same
request from inside and outside, and check that the answer depends on who is asking.

A sensible order for an organisation like the shop: strong authentication and MFA everywhere first;
then put the most sensitive application, the payroll, behind a decision that checks identity and
device; then the rest, one resource at a time. `networks-security` lessons 20 and 21 go deeper into
the network side for students on a track that includes it, and `cloud-security` lesson 6 into the
identity side in the cloud.
