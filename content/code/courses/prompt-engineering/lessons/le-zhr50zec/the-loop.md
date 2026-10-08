---
title: The loop, and who decides what happens in it
version: 2
---

It is tempting to picture an agent as a model that has been handed the keys: it decides what to
do, and it does it. The model decides what to **ask for**. **Everything else is decided by the
program running the loop**: which tools exist, which of them this task may use, how many rounds
the loop may take, and what counts as finished. Five runs, each one ending a different way, show
where those decisions sit.

## A tool that does not exist

Four of the five runs below play back turns from a file, so that each rule shows on its own. Each file holds the `model>` lines its run prints, one block per turn, separated by `---`, and the
weather one starts with a `#` note saying what the question was. A
model can ask for anything it can name, including a tool nobody built. Here the turn asks for the
weather:

```
ana@lab:~/pe$ agent runs/weather.txt
tools allowed: calculator, reviews, search, today
step 1
  model> Action: weather[São Paulo]
  tool>  error: there is no tool called weather
step 2
  model> Answer: I cannot check the weather from here, so I cannot say.
done: an answer after 2 steps
```

`agent` has no `weather` tool, so it ran nothing and **sent back an error the model can read**:
there is no tool called weather. The next turn uses it and says honestly that it cannot check. A
loop that ignored the unknown request, or returned an empty result, would leave the model to fill
the silence with a likely forecast (lesson 5). A clear error is information, and the model can act
on it.

## A tool that is not allowed

`--allow` replaces the list of tools a task may use. The default is the four that only read something:
`calculator`, `reviews`, `search` and `today`. The same cake order, with only the calculator
allowed:

```
ana@lab:~/pe$ agent runs/order.txt --allow calculator
tools allowed: calculator
step 1
  model> Action: today[]
  tool>  refused: today is not allowed in this task
step 2
  model> Action: calculator[3 * 42.50]
  tool>  127.5
step 3
  model> Answer: Tomorrow is Saturday 3 October. Three cakes cost R$ 127.50.
done: an answer after 3 steps
```

The request for the date was **refused by the program**, and the calculator still ran. The refusal
does not depend on the model agreeing to anything: `today` was not on the list, so it did not run.

Now read the answer. It still says "Saturday 3 October", because the turns were played back
whatever happened. **A real model at step 3 would have no date in front of it**, only the refusal.
Here is what one did, with the same allow-list:

```
ana@lab:~/pe$ agent --live "Bruno wants three whole cakes at R\$ 42.50 each, to collect tomorrow. What day is tomorrow, and what is the total?" --allow calculator
tools allowed: calculator
step 1
  model> Action: today[] 
  model> Action: calculator[3 * 42.50]
  tool>  refused: today is not allowed in this task
step 2
  model> Action: calculator[42.50 * 3]
  tool>  127.5
step 3
  model> Answer: You will collect three whole cakes at R$ 127.50 each tomorrow.
done: an answer after 3 steps
```

It asked for the date and was refused; asked the calculator and got 127.5; and answered. The
answer names no day, which is honest, since it had none, and it does not say it could not find
one, which is less so. It also says the cakes are R$ 127.50 **each**: the right number, attached to
the wrong thing. The allow-list controlled what the agent could do, and it did nothing to make the
answer true. Both still have to be checked, by different means.

`agent` has a fifth tool, `send_email`, which changes something outside the conversation
and is never on the default list. Lesson 7 shows why a tool like that is treated differently.

## A run that hits its limit

`--max-steps` is the number of turns the loop will play before it gives up. With a limit of one:

```
ana@lab:~/pe$ agent runs/order.txt --max-steps 1
tools allowed: calculator, reviews, search, today
step 1
  model> Action: today[]
  tool>  Friday 2 October 2026
stopped: 1 step and no answer
```

One step, one tool call, and no answer: **the run is reported as stopped, not as answered**. A
limit exists because a model can keep asking, with a slightly different search each time or the
same call again, and every turn costs tokens (lesson 3). Somebody has to decide how many rounds a
task is worth, and the program is where that decision can be enforced.

The same thing happens when the model's turns run out before an `Answer:`. This file has two
actions and nothing after them:

```
ana@lab:~/pe$ agent runs/unfinished.txt
tools allowed: calculator, reviews, search, today
step 1
  model> Action: today[]
  tool>  Friday 2 October 2026
step 2
  model> Action: calculator[3 * 42.50]
  tool>  127.5
stopped: 2 steps and no answer
```

`stopped: 2 steps and no answer`. The loop counts the steps that were actually played, and it
never turns "no answer" into an answer by itself.

## Why the limits are in the program

Every decision above could have been written as a sentence in the prompt: "only use the
calculator", "stop after one step", "do not invent tools". Sentences like that help a model behave
well, and the program does not rely on them. **A prompt is a request to the model; a check in the
program is a fact about what can happen**, whatever the model was persuaded of by the text in front
of it. Lesson 7 is about the text that does the persuading, and lesson 29 about how a model decides
which tool to ask for next.
