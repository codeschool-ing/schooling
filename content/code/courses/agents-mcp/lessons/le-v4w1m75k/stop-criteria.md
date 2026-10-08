---
title: Every way a run ends
version: 2
---

A run ends for one of a small number of reasons, and the host should know which. `agent.py` distinguishes five, and each produces a different outcome:

| ends because | outcome | in `agent.py` |
|---|---|---|
| the model called `finish` | `answered`, with the answer and its sources | the normal end |
| the step limit was reached | `stopped`, with the reason and a handoff | `--max-steps` |
| the token budget was spent | `stopped` | `--max-tokens` |
| the time budget ran out | `stopped` | `--max-seconds` |
| the model replied without calling any tool | `stopped`: `replied without calling finish` | a reply with text only |

Lesson 3's loop guard adds a sixth (the same call twice), and a production host adds more: an error the host cannot hand back to the model, a customer who cancels, an operator who presses stop.

## Why a finish tool and not `end_turn`

Lessons 1 to 4 ended a run when the model stopped asking for tools, `stop_reason` other than `tool_use`, and took the reply's text as the answer. That works, and it has two weaknesses. **A reply without a tool call is ambiguous**: it may be a final answer, a question back to the customer, or a model that gave up mid-thought. And **a text answer carries no structure**: no sources, no confidence, no flag for "pass this to a person".

A `finish` tool removes both. The run is over only when the model says so explicitly, through a call the host validates against a schema like any other: `answer` must be a non-empty string, `sources` a list. Section 03's first run is that check working, on an empty answer. A reply with no tool call at all becomes a distinct outcome, `stopped`, rather than an answer by default. And the schema can grow fields the host needs, such as `needs_human: true` for an answer the model is unsure of, without parsing prose.

## A finish beside other calls

Section 04's token run ended in a way none of the five rows describe well: the model called two tools **and** `finish` in one reply. The answer was written before either tool had returned, so it could not rest on them, and it did not; it named a book the shop does not sell. `agent.py` ran the calls in order and returned at `finish`, and the run counts as `answered`. It is lesson 3's rule about text ReAct again, in another shape: **an answer that arrives with the actions it depends on was written without their results.** The fix is one check in the host: a reply that calls `finish` and anything else gets an error for the `finish` (*"call finish on its own, after the results you need"*) and its other calls run as usual.

## Stopping is not failing

Of the five ways to end, four are `stopped`. That is the design working: **a limit that fires is the host doing its job**, and the run's outcome says so plainly instead of dressing a partial result up as an answer. What the run hands over when it stops is section 06's subject.
