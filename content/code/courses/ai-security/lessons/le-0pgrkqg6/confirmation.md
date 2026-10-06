---
title: The calls a person confirms, and what the confirmation is
version: 1
---

Some actions are allowed for the agent and still should not happen without a person. `issue_refund`
is the example: it is within the agent's task, and it **moves money and cannot be undone**, which is
the text the manifest attaches to it. So the gate holds it:

```
ana@lab:~/guard$ guard gate data/proposed-calls.jsonl --confirm c3
a confirmation names the person who gave it: add --by NAME
ana@lab:~/guard$ guard gate data/proposed-calls.jsonl --confirm c3 --by ana.lima | grep c3
c3  issue_refund   ALLOW  confirmed by ana.lima
```

A confirmation without a name is refused. **A confirmation is an administrative act, and it records
who took it**, for the same reason every other one does: when a refund is questioned a month later,
"the system allowed it" answers nothing and "ana.lima confirmed it at 14:02" answers the question.

## Which calls need a person

The rule of thumb is about consequences, not about tools:

- **irreversible**: money moved, a message sent, a record deleted;
- **outside the platform**: anything that reaches a person or system Tarefa does not control;
- **large**: an effect much bigger than the typical call, even if it is reversible.

Reading is almost never on the list. A lookup that returns the wrong order wastes a turn; a refund to
the wrong job is a cost and a support case.

## A confirmation shows what will happen, exactly

The person confirming is the last check, and they can only check what they are shown. A confirmation
screen that says *"The assistant wants to issue a refund. Allow?"* asks for trust, not for a
decision. One that shows **the tool, every argument and its effect in plain words**, such as *"Refund
R$ 1.200,00 to Marcos Teixeira for job 4471, the whole amount paid"*, lets the person notice the job
number is wrong.

Two failure modes come with confirmation, and both are about people:

- **Fatigue.** A person asked to confirm forty routine actions a day confirms the forty-first without
  reading it. Keep the list of confirmed actions short, so that each one is worth reading.
- **Confirming what the gate already refused.** `c4` asks for R$ 9.000,00 against R$ 1.200,00 paid,
  and the gate refuses it before anybody is asked. A limit that a person could override by clicking
  would turn the limit into a suggestion; a confirmation adds a check, it never removes one.
