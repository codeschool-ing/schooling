---
title: A budget in code
version: 1
---

Every limit in the previous section belongs to the provider. A program needs limits of its own, decided by what an answer is worth, and enforced in the loop where the numbers are.

The loop already has the two that matter most. `cost_run.py` stops after six steps, and every agent in this course had a step limit; and every reply carries `usage`, so the program knows after each request exactly how many tokens the run has used. A budget is a few lines that compare one with the other:

- **A step limit**, which every agent in this course has had. It bounds the time and the growth of the conversation.
- **A token budget per run**: add `input_tokens`, cache writes and reads, and `output_tokens` after each request, and stop with a clear outcome when the sum passes a ceiling. The ceiling comes from the work: a support answer that needs 50,000 tokens is a loop gone wrong, not a hard question.
- **A time budget per run**, for the person waiting: when a customer has waited ten seconds, an honest "a colleague will reply by email" is better than a correct answer in thirty.
- **A record per conversation**: the run id of lesson 17's audit, with its token totals and time, so the expensive conversations can be found and read. The averages hide the one conversation that cost a hundred times the rest.

What a budget must never do is fail silently. A run that stops for budget should end like lesson 7's stuck runs: with a reason, a message the customer can understand, and a handoff to a person. A limit that only truncates is a limit that hides the problem it found.

This is the last lesson of the course. Everything an agent does passes through the same few places: the loop, the tools, the model's requests, the host's decisions, the servers' boundaries. The way to know an agent is to measure it at each of them, which is what every capture in these eighteen lessons has done.
