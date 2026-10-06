---
title: The audit says who
version: 1
---

Every decision in this lesson's runs wrote a line, the canary test's into its own directory:

```
ana@lab:~/agents$ cat canary/role-audit.jsonl role-audit.jsonl | cut -c1-215
{"run": "9b187743", "actor": "agent:support", "resource": "help://t01", "approved": true}
{"run": "9b187743", "actor": "agent:support", "held": "Gift wrapping costs 3.00 per book. PINEAPPLE"}
{"run": "78579500", "actor": "agent:support", "tool": "refunds__refund", "arguments": {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}, "approved": false, "reason": "not offered"}
{"run": "1da19d33", "actor": "agent:refunds", "tool": "refunds__refund", "arguments": {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}, "approved": true, "is_error": false}
```

Each line names the **actor**, `agent:support` or `agent:refunds`, and the **run** it belongs to, so the lines of one conversation can be read together. The held reply is there with its text. The refused refund is there with its arguments and the reason, `not offered`. The approved refund is there too, and it is the refunds agent's, not the support agent's.

This is `internal/audit`'s rule applied to an agent: **an action is recorded with the actor that took it, and an entry without one is not written**. Here the host is the only component that sees every decision, so the host writes the record, with three properties lesson 15 named: it includes refusals, it includes arguments, and it is personal data to be kept and deleted like any other.

Two things the platform's audit does that this file does not, and a production agent should: it is **append-only** (the platform's table refuses updates and deletions by trigger, so a correction is a new entry), and it names the **person** behind the agent where there is one. When the refunds agent refunds because a member of staff approved it, the record should carry both: the agent that acted, and who said yes.
