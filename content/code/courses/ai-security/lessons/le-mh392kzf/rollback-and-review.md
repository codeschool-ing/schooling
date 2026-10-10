---
title: Going back, and what a review of a prompt checks
version: 1
---

When a change to a prompt goes wrong in production, the fastest safe move is to **put back the last
approved version**, and then work out what happened. Retyping it from memory is how a second mistake
is made during the first. `approve` kept a copy of every approved text, and `rollback` copies one back:

```
ana@lab:~/guard$ guard prompts rollback data/prompts/classify.txt aa32449d3f
restored data/prompts/classify.txt to approved version aa32449d3f
ana@lab:~/guard$ guard prompts status; echo "exit status $?"
data/prompts/classify.txt    aa32449d3f  approved by ana.lima on 2026-10-01
data/helpdesk/hc-fees.md     ff40a81202  approved by ana.lima on 2026-10-01
data/helpdesk/hc-payouts.md  0fe2b8eec1  approved by ana.lima on 2026-10-01
data/helpdesk/hc-refunds.md  f32fa16253  approved by ana.lima on 2026-10-01
data/model.json              3138932013  approved by ana.lima on 2026-10-01
exit status 0
```

The prompt is at `aa32449d3f` again, approved, and the exit status is 0. The rollback refused nothing
here because the version asked for had been approved; a version that never was cannot be restored by
this command, so a rollback cannot become a way to deploy an unreviewed text.

## What a reviewer of a prompt looks at

A review of a prompt change asks the questions a review of code asks, plus two that belong to models:

| question | what answers it |
|---|---|
| what changed? | the diff of the file, in the pull request |
| does it still do its job? | the cases of lesson 23, run against the new version: here, the twelve tickets |
| does it weaken a defence? | the cases that measure the defences of lessons 14 to 16 |
| is the model the one tested? | `data/model.json`, at an approved version |
| who approved it, and why? | the register, with a name and a reason |

## Pin the model as well as the prompt

`data/model.json` says `llama3.2:3b` at temperature 0 and seed 1, and it is under review like the
prompt. A provider's model name that always points at its newest release changes under the assistant
on the provider's schedule, and every measurement above becomes a measurement of a model that is no
longer there. **Pin the dated or numbered version a provider offers**, as lesson 19 asked for in its
questionnaire, and move to a new one through the same review: change the file, run the cases, approve
with a name.

## What this does not cover

A version tells you which text ran; it does not tell you the text was good. The approval is a person's
judgement, recorded, and the measurement is twelve tickets. **Both are only as good as the cases they
run**, which is lesson 23's subject.
