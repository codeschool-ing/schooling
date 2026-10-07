---
title: When a run goes wrong, and who notices
version: 2
---

A trace that ends in `done` looks like success, and the loop has no other word for it. **The loop
can check the shape of every turn and the limits on every call; it cannot check that the reasoning
is right.** Six runs, each broken in a different place, show which failures land on which side of
that line. One is live; the turns of the other five were written by the course and played back, so
that each failure shows on its own. The tool replies and the loop's verdicts are what `agent`
printed.

## An observation the model ignores

The tools return the right facts, and the answer contradicts them:

```
ana@lab:~/pe$ agent runs/ignored.txt
tools allowed: calculator, reviews, search, today
step 1
  model> Thought: I need the rule about approval first.
  model> Action: search[refund approval manager]
  tool>  refunds.md     A refund above R$ 100 needs the shift manager's approval.
step 2
  model> Thought: Now the total for four soups.
  model> Action: calculator[4 * 27.90]
  tool>  111.6
step 3
  model> Thought: That is a normal refund.
  model> Answer: R$ 111.60 back to the card. No approval is needed.
done: an answer after 3 steps
```

Both facts needed for the right answer are on the screen, two lines apart, and the answer says the
opposite of the first one. The loop prints `done`, because a turn with an `Answer:` is all it looks
for. This is the failure ReAct makes visible without preventing it: **the evidence is in the trace,
so a person, or a second check, can catch it**. Look at the last Thought, too. "That is a normal
refund" names no fact at all, and a thought that cites nothing is the usual place where a run
leaves its evidence behind.

## An Action the loop cannot read

The loop finds the tool call with a pattern: `Action:`, a name, and the argument in square
brackets. A model that writes round brackets has written something a person reads perfectly well. To
the loop it is no call at all:

```
ana@lab:~/pe$ agent runs/paren.txt
tools allowed: calculator, reviews, search, today
step 1
  model> Thought: Four soups at R$ 27.90.
  model> Action: calculator(4 * 27.90)
stopped: the reply has neither an Action nor an Answer
```

The model in this course did the same thing for real, with the first version of the ReAct prompt,
which described the tools by placeholders instead of examples:

```
ana@lab:~/pe$ diff prompts/react-v1.txt prompts/react.txt
2,4c2,4
<   search[words]        the best matching line of the café's staff handbook
<   calculator[sum]      arithmetic with numbers and + - * /
< Use this format, and write one Action at a time:
---
>   search[refund approval]   the best matching line of the café's staff handbook
>   calculator[3 * 2.50]      arithmetic with numbers and + - * /
> Use this format. Write one Thought and one Action, then stop and wait:
6,8c6,9
< Action: one tool call
< Observation: (the tool's reply is written here for you)
< ... repeat as needed, then:
---
> Action: search[...] or calculator[...]
> The program then writes an Observation line with the tool's reply. When you
> have every fact you need, write:
> Thought: why you have the answer
ana@lab:~/pe$ agent --live "Four soups of the day, R\$ 27.90 each, paid by card, all served cold. How much goes back, how, and does anybody have to approve it?" --prompt prompts/react-v1.txt --max-steps 6
tools allowed: calculator, reviews, search, today
step 1
  model> Thought: I need to calculate the total cost of the soups and then find out how much I need to return, considering that it was paid by card.
  model> 
  model> Action: calculator[sum] with the cost of each soup (R$ 27.90) and the number of soups (4)
stopped: the reply has neither an Action nor an Answer
```

It copied the placeholder, `calculator[sum]`, and then explained in words what it wanted summed.
The loop could not read it and stopped. The second version of the prompt, the one in the section
before, shows a real call for each tool instead, and the model's first three Actions were readable; its fourth, `None needed`, was not a call either.

**Stopping is the right response**: guessing what a malformed line meant is how a loop ends up
running a call nobody wrote. A real system would send the model a short message saying what the
format is and try once more, the way lesson 19 repairs a reply that does not match its schema.

A call the loop CAN read may still be one the tool cannot, and that is a different kind of failure.
`27,90` is how a price is written in Brazil, and to the calculator the comma makes it two numbers:

```
ana@lab:~/pe$ agent runs/comma.txt
tools allowed: calculator, reviews, search, today
step 1
  model> Thought: Four soups at R$ 27,90.
  model> Action: calculator[4 * 27,90]
  tool>  error: only numbers and + - * / are allowed
step 2
  model> Thought: The calculator wants a decimal point.
  model> Action: calculator[4 * 27.90]
  tool>  111.6
step 3
  model> Answer: R$ 111.60.
done: an answer after 3 steps
```

The error came back as an Observation, so the next turn could read it and fix the call. **A tool
that answers with a clear error message gives the model something to reason from**, where a tool
that fails silently, or returns `0`, gives it a wrong fact.

## A run that runs out of steps

`--max-steps` is the number of turns the loop will play before it gives up. Here is the good run
from the section before, with a limit of two:

```
ana@lab:~/pe$ agent runs/refund.txt --max-steps 2
tools allowed: calculator, reviews, search, today
step 1
  model> Thought: The handbook has the rules for refunds. I need the one about approval.
  model> Action: search[refund approval manager]
  tool>  refunds.md     A refund above R$ 100 needs the shift manager's approval.
step 2
  model> Thought: Above R$ 100 needs the shift manager. Now the total for four soups.
  model> Action: calculator[4 * 27.90]
  tool>  111.6
stopped: 2 steps and no answer
```

The run was on its way to the right answer and was cut off anyway. That is the price of a limit,
and it is worth paying. A model that keeps searching with slightly different words, or calls the
same tool again because it did not trust the first reply, would otherwise loop until somebody
noticed the bill (lesson 15). **A run stopped at the limit is reported as stopped, never as
answered**, so the caller can raise the limit, ask a person, or give up honestly.

## A tool that is refused

The default allow-list in `agent` holds the four tools that only read. `send_email` changes
something outside the conversation, so it is not on the list unless somebody puts it there:

```
ana@lab:~/pe$ agent runs/email.txt
tools allowed: calculator, reviews, search, today
step 1
  model> Thought: Above R$ 100 needs the manager. I will ask for approval by e-mail.
  model> Action: send_email[manager@example.com | Please approve a refund of R$ 111.60 for table 4.]
  tool>  refused: send_email is not allowed in this task
step 2
  model> Thought: I may not send e-mail in this task. A person has to ask the manager.
  model> Answer: R$ 111.60 to the card. Ask the shift manager to approve it before refunding.
done: an answer after 2 steps
```

The idea was reasonable and the refusal was still right. The task was to answer a question, and an
e-mail to the manager is an action somebody should decide to take. Even with `send_email` on the
list, `agent` only holds the call and sends nothing until a person confirms it.

## Why the loop holds the limits, and not the prompt

Every limit above lives in the program: the pattern that reads an Action, the list of allowed
tools, the step count, the hold on anything that changes the world. None of them is a sentence in
the prompt like "never send e-mail" or "stop after five steps".

The reason is lesson 7. **A sentence in the prompt is a request to the model, and the model's
behaviour depends on everything in its context**, including the text the tools bring back. A search
result, a review or a web page can contain instructions of its own, and a model that reads them may
follow them. A limit enforced by the loop does not care what the model was persuaded of: the call
is not on the list, so it does not run. Write the instructions in the prompt so the model behaves
well, and put the limits in the code so it does not matter when it does not.

::: track ai
The `agents-mcp` course builds this loop properly, with tools described in a standard
format, and keeps every one of these limits in the code.
:::

::: track *
You do not need to build the loop to use what this lesson showed. When a product says it uses an
agent, these are the questions to ask of it: what may it call, how many steps may it take, and who
confirms an action that changes something.
:::
