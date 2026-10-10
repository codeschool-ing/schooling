---
title: The audit says who
version: 2
---

Every decision in this lesson's runs wrote a line. The canary test wrote into its own directory, so the command prints the first reply held there, then every line of the other runs:

```
ana@lab:~/agents$ grep -h held canary/role-audit.jsonl | head -1 | cut -c1-215; cat role-audit.jsonl | cut -c1-215
{"run": "1ab4d49b", "actor": "agent:support", "held": "PINEAPPLE"}
{"run": "010192eb", "actor": "agent:support", "tool": "shop__get_order", "arguments": {"order_id": "M-1047"}, "approved": true, "is_error": false}
{"run": "6f747d07", "actor": "agent:support", "tool": "refunds__refund", "arguments": {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}, "approved": false, "reason": "not offered"}
{"run": "b42bc648", "actor": "agent:refunds", "tool": "refunds__refund", "arguments": {"order_id": "M-1047", "cents": "0", "reason": "damaged item arrived"}, "approved": true, "is_error": true}
```

Each line names the **actor**, `agent:support` or `agent:refunds`, and the **run** it belongs to, so the lines of one conversation can be read together. The held reply is there with its text, `PINEAPPLE`. The refused refund is there with its arguments and the reason, `not offered`, from the stand-in's run. The approved refund is there too, the refunds agent's and not the support agent's, with `"is_error": true`: a record of a person saying yes to 0 cents, which is the line somebody reviewing this host would most want to find.

This is `internal/audit`'s rule applied to an agent: **an action is recorded with the actor that took it, and an entry without one is not written**. Here the host is the only component that sees every decision, so the host writes the record, with three properties lesson 15 named: it includes refusals, it includes arguments, and it is personal data to be kept and deleted like any other.

Two things the platform's audit does that this file does not, and a production agent should: it is **append-only** (the platform's table refuses updates and deletions by trigger, so a correction is a new entry), and it names the **person** behind the agent where there is one. When the refunds agent refunds because a member of staff approved it, the record should carry both: the agent that acted, and who said yes.
