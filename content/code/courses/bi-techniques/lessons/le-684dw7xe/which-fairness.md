---
title: Which error rate has to be equal
version: 1
---

"Fair" has several precise meanings, and they are different measures of the table in the audit.

| measure | equal across groups means | the column in the audit |
|---|---|---|
| **flag rate** | each group is flagged equally often | flagged |
| **false-alarm rate** | people who stay are wrongly flagged equally often | false alarms among stayers |
| **recall** | people who leave are caught equally often | recall |
| **precision** | a flag is equally trustworthy in each group | not printed; caught ÷ flagged |

**They cannot all be equal at once** whenever the groups churn at different rates, which in real data
they nearly always do. This is a mathematical result, not a weakness of a particular model: when one
group leaves more often, a model with equal precision in both groups cannot also have equal
false-alarm rates and equal recall, unless it makes no mistakes at all. So the question is never "is the model fair?" but **"which of these does
this decision need to be equal?"**

The decision answers it, by saying which error hurts.

- **The loyalty club** closes a door on people flagged. The harm falls on loyal customers wrongly
  flagged, so the **false-alarm rate among stayers** is what has to be equal. The North fails at 22.0
  per cent against 6.2 to 9.2.
- **The retention offer of lesson 17** gives something to people flagged. The harm falls on leavers
  who are not flagged and so get no offer, so **recall** is what matters. On it the North sits at 58.8
  per cent, ten people out of 17, and cannot be told apart from the other regions.

**One model can be acceptable under one decision and unacceptable under another**, with no change to
its numbers. That is why an audit is done for a decision and not for a model, and why reusing a model
for a new purpose means doing the audit again.

Flag rate is the measure people reach for first, and here it misleads. The North is flagged 27.4 per
cent of the time and churns at 14.5. Forcing every region to be flagged at the same rate would treat
unequal situations as equal, and in a group that really did leave more often it would hide the
leavers from a retention offer meant for them.
