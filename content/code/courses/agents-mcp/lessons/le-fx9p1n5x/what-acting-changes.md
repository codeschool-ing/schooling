---
title: What changes when the program acts
version: 1
---

Handing the path to a model is not free, and the costs are easy to state now that `agent.py` has run.

**The path is unknown until it has happened.** Three steps for Bia, two for the payment question, and with a real model it could be four on Tuesday and three on Thursday for the same words. Code that depends on a fixed number of steps, a fixed cost or a fixed order of calls is code written for automation.

**The cost of an answer is known only afterwards.** Each step resends the conversation, and the number of steps is the model's choice. A budget therefore has to be enforced while the agent runs, in tokens, steps or seconds, and lesson 5 writes those limits.

**Arguments nobody wrote reach your functions.** `get_order` was called with `M-1042` because the model put it there. A model that misreads a message calls the right tool with the wrong order, and the function cannot tell. Lesson 4 is about checking arguments before anything runs.

**Mistakes compound.** In an assistant, a wrong draft is read by somebody who can throw it away. In an agent, a wrong step becomes the input of the next one: look up the wrong order, and the next search is about the wrong problem, and the answer is confidently about somebody else's parcel. **Nobody reads anything until the end**, and sometimes nobody reads it then.

**Some steps cannot be taken back.** Reading an order can be repeated as often as you like. A refund, an email or a deleted file happens once. `agent.py` has no such tool, deliberately; lesson 17 adds one and puts a person in front of it.

## Testing changes too

A test that runs Bia's question once and compares the answer proves that one path works. In this lab that is exactly what it proves, because the stand-in model always answers the same way. **A real model can choose another path on the next run**, so an agent is tested over many inputs and many runs, against properties rather than exact strings: the answer cites the order's real date; no refund was issued; the run stopped within its limit. Lesson 7 writes such tests, and lesson 18 measures a success rate.
