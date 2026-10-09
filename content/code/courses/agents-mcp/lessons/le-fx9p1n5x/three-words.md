---
title: Automation, assistant, agent
version: 2
---

The three words are used as if they were rungs on a ladder of intelligence, with automation at the bottom and agents at the top. **They are not a ladder.** A script can be the right answer to a problem an agent would make worse, and an agent can run on the same model as an assistant. What separates them is one question, and it is a question about control rather than about cleverness: **who decides the next step, and when?**

- **Automation.** The programmer decided every step before the program ran. The program reads an order, checks a rule, prints a line. Given an input nobody anticipated, it stops or does the wrong thing, because nothing inside it can choose another path.
- **Assistant.** A model produces one answer, and a person reads it and decides what happens. The model may be very capable; it still never acts. The decision sits with whoever reads the draft.
- **Agent.** The model chooses the next step, a program carries it out, the result goes back to the model, and the model chooses again, until it decides to answer. **The decision sits inside a loop, and the model holds it.**

The definition says nothing about how good the model is, how many tools it has or whether a customer talks to it directly. Those are real questions, and lessons 2 to 6 come back to them, but none of them changes which of the three a system is. A loop with one tool, where the model decides when to call it and when to stop, is an agent. A pipeline that calls the best model on the market five times in a fixed order is automation with model calls inside it.

## A test you can apply to code

Product pages do not settle it, because "agent" is a word that sells. Code does. Find the line that decides what the program does next, and ask whether it reads the model's reply:

- `for order in orders: close_window(order)`: the next step is the next order. Automation.
- `print(reply.text)` and nothing after it: a person decides. Assistant.
- `if reply.stop_reason == "tool_use": run(reply.tool_calls)`: the next step is whatever the model asked for. Agent.

The `agent.py` that section 05 runs is forty lines, and that `if` is the line that makes it an agent.

## Why the distinction earns a lesson

Each of the three fails differently, costs differently and is tested differently, and lesson 2 is about choosing between them. An automation's failure is a path nobody wrote. An assistant's failure is a wrong draft, and a person usually catches it. **An agent's failure is an action**, taken by a program, on the strength of a model's mistake, often before anybody has read a word. That last property is what lessons 5, 17 and 18 spend their time containing.
