---
title: A questionnaire answer is a claim until something backs it
version: 1
---

Every answer in `providers.json` came from the provider. Some of them point at something Tarefa can
read and hold the provider to; others are only what the provider said. `--evidence` lists the answers
that **pass a requirement with nothing behind them**:

```
ana@lab:~/guard$ guard vendor --evidence
provider-a  OUT  should 4/4  unbacked 1  fails incident_hours = 72
            unbacked: SHOULD exit_deletion
provider-b  OUT  should 2/4  unbacked 0  fails training = true
provider-c  in   should 3/4  unbacked 5
            unbacked: MUST training
            unbacked: MUST retention_days
            unbacked: SHOULD subprocessors
            unbacked: SHOULD pinning
            unbacked: SHOULD exit_deletion
```

`provider-c` passes two of its MUSTs on its word alone. It says it does not train on customer data
and keeps prompts for 30 days, and neither statement is in any document Tarefa has. Those are exactly
the two answers the decision rests on, so **before signing, both go into the contract** as clauses,
and the evidence column changes from `null` to a clause number. A provider that will not write down
what it said in the questionnaire has answered a different question.

The SHOULDs without evidence matter less and are still worth a line in the decision: `provider-c`'s
promise to delete everything at the end of the contract, unbacked, is the promise Tarefa will need on
the day it leaves.

## What each kind of evidence is worth

- **A contract clause** binds the provider, and a breach of it is something Tarefa can act on.
- **An audit report** is an independent party saying the controls existed over a period. It is worth
  reading the period and the scope, because a report about the provider's billing system says nothing
  about where prompts are kept.
- **A page on the provider's website** describes today's practice, and the provider can change it
  tomorrow without telling anybody. It is better than nothing and less than a clause.
- **A sales conversation** is not evidence.

## An assessment ages

Providers change their terms, their regions and their subprocessors. The assessment is repeated **at
least once a year, and whenever the provider announces a change to its terms**, by running the same
list against the new answers. And the exit is planned on the first day rather than the last: which
model version the assistant pins, how the data is deleted and confirmed, and what Tarefa would switch
to. **A provider Tarefa cannot leave is a provider whose next price rise Tarefa cannot refuse**, and
that is a security question as much as a commercial one, because the day a provider stops meeting a
MUST is the day leaving has to be possible.
