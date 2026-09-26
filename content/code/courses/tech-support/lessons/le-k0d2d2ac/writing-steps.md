---
title: Writing a step someone can follow
version: 1
---

Most runbooks fail on their steps, and the failures have names:

| a weak step | why it fails | written well |
|---|---|---|
| "Check the printer." | check what, how, and then what? | "`lpstat -p QUEUE`. Expected: `disabled`, with a reason." |
| "Restart CUPS if needed." | who decides "needed"? and a restart interrupts whatever every other queue is printing | not a step of this runbook: if the queue will not start, escalate |
| "Enable the queue and verify." | two actions, and "verify" is not a result | step 4 and step 5, each with what it should show |
| "Fix the jam." | the technician may be in another building | "Ask whoever is next to the printer to…, and wait until they confirm." |

**Every step has an expected result**, because that is how the person following it knows whether to go
on. And **every runbook is tested by someone who did not write it**, following it exactly, on a real
occurrence or a staged one. The author cannot test it: they fill each gap from memory without noticing
it is there.
