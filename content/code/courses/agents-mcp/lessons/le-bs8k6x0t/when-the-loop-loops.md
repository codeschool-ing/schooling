---
title: When the loop does not end
version: 1
---

The customer asks whether Marginalia sells signed first editions of *Dom Casmurro*. The help centre has nothing that answers it, and the stand-in, scripted to show a common failure, searches again for the same thing. **These replies were written by the course**; the search results, the guard and the trace are real.

```
ana@lab:~/agents$ python react_native.py "Do you sell signed first editions of Dom Casmurro?"
host: step 2 repeats search_help({"query": "signed copies"}); stopping
ana@lab:~/agents$ python show_trace.py
step 1  stop_reason=tool_use  input_tokens=176
  said:     The help centre should say whether signed copies are sold.
  called:   search_help({"query": "signed copies"})
  returned: [{"title": "Orders for schools and libraries", "body": "Institutions buy
step 2  stop_reason=tool_use  input_tokens=386
  said:     Those articles do not mention signed copies; I will search for signed copies.
  called:   search_help({"query": "signed copies"})
  returned: refused: repeat
```

Step 1 searched for `signed copies` and got three articles about other things: orders for schools, lending e-books, damaged books. Step 2's thought says so, and then asks for the same search with the same words. The guard in `react_native.py` keeps a set of calls already made, as a tool name and its arguments with sorted keys; the second call was already in it, so the host stopped the run and wrote why. **Without the guard, this run would have repeated the search until the step limit, paying for a growing request each time**: the trace already shows the input rising from 176 to 386 tokens between the two steps.

## Why models loop

A model chooses the next step from the conversation so far. If nothing in it changed, the same choice is likely again: the search returned nothing useful, so searching is still the obvious move, and the query that seemed best before still seems best. Real loops are rarely this blunt. More often a model alternates between two queries, or reads the same order with different capitalisation, which an exact-match guard misses.

## What a host can do

| failure | what to do in the host |
|---|---|
| the same call, same arguments | refuse it, or stop the run (this section) |
| near-identical calls | normalise arguments before comparing: trim, lower-case, sort keys |
| a call the model has no tool for | return an error naming the tools that exist |
| no progress for several steps | stop after N steps without a new tool or a new result (lesson 5) |
| answering before looking anything up | require at least one tool call for questions about orders, and check the answer cites a result |

Stopping is not the same as failing politely. A stopped run still owes somebody an answer, and the useful one here is honest: *"the help centre does not say; I am passing this to a person."* Lesson 5 is about what an agent returns when a limit fires, and it is the other half of every guard in this table.
