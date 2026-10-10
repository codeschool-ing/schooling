---
title: Thoughts are not an audit
version: 2
---

The thought in a ReAct step reads like an explanation: *"I need to check the return policy of the books and understand how the refund would work."* It is tempting to treat that sentence as the reason the next call was made, and to rely on it when something goes wrong. **It is evidence, not proof.**

A model's written reasoning is more text the model produced. Studies of chain-of-thought faithfulness have found models whose stated reasoning leaves out what actually changed their answer, such as a hint planted in the prompt; the sentence reads as a cause and was generated alongside the decision rather than before it. So a trace's `said` column tells you what the model claimed, and the `called` and `returned` columns tell you what happened. **When the two disagree, the calls are the record.**

## Three things follow for an agent

**Check claims against results, not against thoughts.** A thought that says *"the order was delivered"* is worth something only if a `get_order` result above it says `delivered`. Lesson 7's tests check answers against tool results, never against the model's own account.

**Log the thoughts anyway.** They are the fastest way to see where a run went off course. In section 03's first run, step 1's thought said *"I need to find the order with id M-1047 and check if it can be returned"*, and the line after it was an invented observation that answered exactly that; the thought shows what the model wanted to be true before any tool had run. Being unreliable as proof does not make them useless as a lead.

**Expect some reasoning to be hidden.** Models that reason at length before answering (sold as extended thinking or reasoning models) often return that reasoning summarised, encrypted or not at all, and some APIs require it to be passed back unchanged in the next request. An agent built on one of them gets fewer thoughts to read, and the calls become the whole trace.

## Showing thoughts to a customer

Whether the customer sees the thoughts is a product decision with a security edge. A thought can repeat what a tool returned, including another customer's data in a badly scoped tool, or a line of the system prompt. **Show the answer, keep the thoughts in the trace**, and treat the trace with the care section 06 described.
