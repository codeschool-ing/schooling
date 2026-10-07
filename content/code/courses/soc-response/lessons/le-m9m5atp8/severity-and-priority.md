---
title: Severity, priority and the order of the queue
version: 1
---

**Severity** is the rule's statement, written in advance: what this alert means if true (lesson 6).
**Priority** is the analyst's decision, made now: in what order to work the queue. They are different
because priority uses what the rule could not know: which asset, which data, what is happening right now.

A common way to set priority is **impact against urgency**:

| | urgency low: contained, or long over | urgency high: still happening, or about to spread |
|---|---|---|
| **impact high**: important data or systems | P2 | **P1** |
| **impact low**: a test box, no sensitive data | P4 | P3 |

Thursday's escalation sits in the top right. **Impact is high**: `files` holds the clients' tax files,
which is personal data, and a copy may have left. **Urgency is high**: a key was added to bruno's account
at 03:05, so whoever used it can come back, and nothing in the logs says they stopped. That makes it
**P1**: somebody works on it now, and the people lesson 11 names are called.

Priority also moves. The same incident drops to P2 the moment the key is removed and the address blocked,
and rises again if a second host shows the same pattern. A priority set once and never revisited is a
label, not a decision.
