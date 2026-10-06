---
title: When a result changes the plan
version: 1
---

A plan is a guess about the work, made before the work. Some results make the guess wrong, and the useful response is to say so in the plan rather than to carry on with steps that no longer make sense.

```
ana@lab:~/agents$ python agent.py "Is my order M-1049 delivered, and can I still return it?"
[1] plan
      [ ] Look up order M-1049
      [ ] Check the return window
      [ ] Answer
[2] get_order({"order_id": "M-1049"}) -> ERROR LookupError: no order M-1049
[3] plan
      [x] Look up order M-1049
      [-] Check the return window
      [ ] Ask the customer for the order number
{
 "status": "answered",
 "steps": 4,
 "tokens": 2484,
 "answer": "I cannot find an order M-1049, so I cannot check its return window yet. Could you send the order number from your confirmation email? It starts with M- and has four digits.",
 "sources": [
  "get_order M-1049"
 ]
}
```

The plan had three steps: look up M-1049, check its return window, answer. The lookup failed, `no order M-1049`. Checking a return window for an order that does not exist is pointless, so step 3 rewrote the plan: the lookup is `done` (it ran, and its answer is that there is no such order), the window check is `dropped`, and a new step asks the customer for the right number. Step 4 finished with exactly that.

**`dropped` is the important status.** Without it, the model's only options would be to mark the step `done`, which is false, or to leave it `todo` forever, which makes the run look unfinished. With it, the plan records a decision: this step was considered and abandoned, at this point, after this result. A person reading the outcome later can see why the answer does not mention a return window.

## When to replan, and when to stop

Replanning is the right response when a result changes the path but the goal is still reachable. It is the wrong response when the goal itself is gone, or when the agent keeps rewriting the plan without making progress. A host can catch the second case cheaply: count plan updates that are not followed by a new tool result, and stop after a few. That is the "no progress" row of lesson 3's table, applied to plans.

Notice also what the model did not do. It did not guess that the customer meant M-1048 or M-1046, the closest ids that exist. **An agent that "corrects" an id on its own is an agent that acts on somebody else's order**, which lesson 17 treats as a permission problem.
