---
title: When two layers are really one
version: 1
---

Counting layers is easy and misleading. **Two controls are two layers only if they fail for
different reasons.** If one cause can defeat both, they are one layer drawn twice, and the Swiss
cheese has one slice with its holes printed on two pages.

Four ways layers collapse into one:

| shared cause | example | what it looks like |
|---|---|---|
| **the same secret** | the portal and the server's administrator account use the same password | one leak opens both |
| **the same person** | the one administrator who manages the firewall also approves its rule changes | one mistake, or one compromised account, passes both |
| **the same software** | two firewalls in a row from the same vendor, running the same version | one bug in that version opens both |
| **the same assumption** | the portal trusts anything from the office network, and so does the database | one infected office laptop passes both |

The last row is the one this course spends most time on. "Anything on the inside is trusted" is an
assumption shared by many layers at once, and it fails all of them together the moment something
on the inside is not trustworthy. Lesson 5 draws the network that assumption produces and lesson
7 is about removing it.

### Diversity

The fix is to make layers **independent**: different secrets, different people, different
mechanisms. In the lab's test in the previous section, the layers held because each relied on something
different. The login relied on ana's password; the permission check relied on the portal's own
rules about payslips; the file permission relied on the operating system; the log relied on
nothing at all, since it recorded what happened whatever the outcome. The leaked password defeated
the first and touched none of the others.

### More layers is not always better

Layers have costs: each one is something to configure, update and understand. A layer nobody
maintains decays into a hole with a reassuring name. And complexity is itself a source of
failures: a defence with twelve overlapping controls that nobody fully understands produces rules
that contradict each other, and the contradiction is the hole.

The aim is enough independent layers that no single failure is an incident, and few enough that
every one of them is understood by somebody who is responsible for it. The lab's portal has four,
and each of them fails for a different reason.
