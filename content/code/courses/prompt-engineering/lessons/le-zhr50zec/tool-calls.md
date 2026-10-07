---
title: A request written as text, and a program that carries it out
version: 2
---

Assistants that look up the weather, run code or book a table seem to do those things themselves.
**A model cannot run anything. It writes text, and part of that text can be a request, in a format
agreed in advance, for a program to run a tool.** The program around the model reads the request,
runs the tool, and puts the result back into the text; then the model is asked to continue, with
the result in front of it.

Without that arrangement, two things you have met before go wrong. Asked for today's date, a model
can only write a likely date, which is lesson 5's problem; asked for 3 × 42.50, it does arithmetic
on chunks of digits, which is lesson 3's. A tool replaces the likely answer with a looked-up or
computed one.

## Telling the model what it can ask for

The model learns which tools exist from its input. In the simplest form the description is part
of the prompt, with the format the program will look for. Save this one as `~/pe/tools.txt`:

```sh
cat > ~/pe/tools.txt <<'EOF'
You answer customers of Café Aurora. You cannot know today's date or do
arithmetic yourself; a program does them for you. To use one, reply with
exactly one line and nothing else:
  Action: today[]
  Action: calculator[3 * 2.50]
The program replies with a line starting "Observation:". Never write an
Observation yourself. When you have every fact you need, reply with one line:
  Answer: your reply to the customer
EOF
```

Every line of it is there because a shorter version failed while this lesson was being written. A
version with `calculator[sum]` as its example got the word `sum` back, written into the request;
one that did not forbid it got the model writing the Observation itself, with a date it made up.
Given the description as its system message and a question, the model writes requests and stops:

```
ana@lab:~/pe$ ask "Bruno wants three whole cakes at R\$ 42.50 each, to collect tomorrow. What day is tomorrow, and what is the total?" --system "$(cat tools.txt)" --temperature 0
Action: today[]
Action: calculator[3 * 42.50]
-- llama3.2:3b, finish: stop, prompt 154 tokens, output 16 tokens
```

Two requests and nothing else, which is all a model can do. **Something has to run them**, and
hand the results back.

The APIs of the large providers have a field for this instead of a paragraph in the prompt. Each
tool is described by a name, a sentence saying what it does, and a JSON Schema for its input
(lesson 19 is about schemas). The model's reply then carries the tool call as a separate,
structured part, and your code sends the result back in a message of its own. The field names
differ between providers; a definition for the calculator looks like this, and this course keeps
to the text format above, because you can read every byte of it:

```json
{
  "name": "calculator",
  "description": "Arithmetic with numbers and + - * /. Returns the result as a number.",
  "input_schema": {
    "type": "object",
    "properties": {"expression": {"type": "string"}},
    "required": ["expression"]
  }
}
```

**The description is a prompt too.** The model decides whether and how to call a tool from that
one sentence, so "Arithmetic with numbers and + - * /" is doing real work: it tells the model
which operations it may send, and that `sqrt(2)` will not work.

## The program around the model

`agent` is that program. It sends the question to the model with `tools.txt` as the system
message, reads the reply, finds the first `Action:` line, checks that the tool is allowed, runs
it, and sends the result back as an `Observation:` for the next turn. It stops the model at the
word `Observation:` with a stop sequence (lesson 16), so the model cannot write a result of its
own. Save it as `~/pe/bin/agent` and make it executable:

```python
#!/usr/bin/env python3
"""agent: the loop that lets a model act.

  agent RUN [--max-steps N] [--allow TOOL,...]
  agent --live QUESTION [--prompt FILE] [--max-steps N] [--allow TOOL,...]

With RUN, the model's side of the conversation is read from a file, one turn
per block separated by '---', and played back: the turns are fixed, so the
loop's own behaviour can be watched exactly. With --live, each turn is asked
of the model through `ask`, with tools.txt (or FILE) as the system message and
QUESTION as the first message. Either way, the rest is the part an engineer builds:
reading the reply, finding the Action line, checking the tool is allowed,
running it, handing back an Observation, and stopping.

Tools: search[question]  calculator[expression]  today[]  reviews[]
       send_email[to | text]   (changes the world: never run without a person)
"""
import ast
import operator
import os
import re
import json
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SAFE = {"search", "calculator", "today", "reviews"}
ACTION = re.compile(r"^Action:\s*(\w+)\[(.*)\]\s*$")
OPS = {ast.Add: operator.add, ast.Sub: operator.sub, ast.Mult: operator.mul,
       ast.Div: operator.truediv, ast.USub: operator.neg}


def calc(expr):
    def ev(n):
        if isinstance(n, ast.Constant) and isinstance(n.value, (int, float)):
            return n.value
        if isinstance(n, ast.BinOp) and type(n.op) in OPS:
            return OPS[type(n.op)](ev(n.left), ev(n.right))
        if isinstance(n, ast.UnaryOp) and type(n.op) in OPS:
            return OPS[type(n.op)](ev(n.operand))
        raise ValueError("only numbers and + - * / are allowed")
    v = ev(ast.parse(expr, mode="eval").body)
    return str(round(v, 6)).rstrip("0").rstrip(".") if isinstance(v, float) else str(v)


def run_tool(name, arg, allowed):
    if name not in SAFE | {"send_email"}:
        return "error: there is no tool called %s" % name
    if name not in allowed:
        return "refused: %s is not allowed in this task" % name
    if name == "send_email":
        return "held: send_email changes something outside this conversation; nothing is sent until a person confirms it"
    if name == "calculator":
        try:
            return calc(arg)
        except (ValueError, SyntaxError, ZeroDivisionError) as e:
            return "error: %s" % e
    if name == "today":
        return os.environ.get("LAB_TODAY", "Friday 2 October 2026")
    if name == "search":
        out = subprocess.run([os.path.join(HERE, "retrieve"), arg, "--k", "1"],
                             capture_output=True, text=True).stdout.splitlines()
        hits = out[1:]
        return hits[0].split(None, 1)[1] if hits and not hits[0].startswith("no passage") else "nothing found"
    if name == "reviews":
        d = os.path.join(HERE, "..", "reviews")
        texts = [open(os.path.join(d, f), encoding="utf-8").read().strip() for f in sorted(os.listdir(d))]
        body = "\n".join("review %d: %s" % (i, t) for i, t in enumerate(texts, 1))
        return "<untrusted>\n%s\n</untrusted>" % body


def live(question, prompt, steps):
    """The model's turns, one at a time, each written after the last Observation."""
    with open(prompt, encoding="utf-8") as f:
        messages = [{"role": "system", "content": f.read()}, {"role": "user", "content": question}]
    for _ in range(steps):
        with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
            json.dump(messages, f)
        turn = subprocess.run([os.path.join(HERE, "ask"), "--chat", f.name, "--plain",
                               "--temperature", "0", "--stop", "Observation:"],
                              capture_output=True, text=True).stdout.strip()
        os.unlink(f.name)
        observation = yield turn
        messages.append({"role": "assistant", "content": turn})
        messages.append({"role": "user", "content": "Observation: %s" % observation})


def main():
    args = sys.argv[1:]
    steps, allowed = 5, set(SAFE)
    if "--max-steps" in args:
        i = args.index("--max-steps"); steps = int(args[i + 1]); del args[i : i + 2]
    if "--allow" in args:
        i = args.index("--allow"); allowed = set(args[i + 1].split(",")); del args[i : i + 2]
    prompt = os.path.join(HERE, "..", "tools.txt")
    if "--prompt" in args:
        i = args.index("--prompt"); prompt = args[i + 1]; del args[i : i + 2]
    if args[0] == "--live":
        turns = live(args[1], prompt, steps)
        result = None
    else:
        text = open(args[0], encoding="utf-8").read()
        blocks = [t.strip() for t in text.split("\n---\n")]
        turns = iter(["\n".join(l for l in t.splitlines() if not l.startswith("#")).strip() for t in blocks])
    print("tools allowed: %s" % ", ".join(sorted(allowed)))
    n = 0
    for n in range(1, steps + 1):
        try:
            turn = turns.send(result) if args[0] == "--live" and n > 1 else next(turns)
        except StopIteration:
            n -= 1
            break
        print("step %d" % n)
        action = None
        for line in turn.splitlines():
            print("  model> %s" % line)
            m = ACTION.match(line)
            if m and action is None:
                action = m.groups()
        if action is None:
            if any(l.startswith("Answer:") for l in turn.splitlines()):
                print("done: an answer after %d step%s" % (n, "" if n == 1 else "s"))
            else:
                print("stopped: the reply has neither an Action nor an Answer")
            return
        result = run_tool(action[0], action[1].strip(), allowed)
        for line in result.splitlines():
            print("  tool>  %s" % line)
    print("stopped: %d step%s and no answer" % (n, "" if n == 1 else "s"))


main()
```

Four tools only read something. `today` returns a fixed date, so that every run in the course
agrees on what day it is; `search` returns the best line of the handbook; `reviews` comes in
lesson 7. The fifth, `send_email`, is held, never run. Here is the cake order, live:

```
ana@lab:~/pe$ agent --live "Bruno wants three whole cakes at R\$ 42.50 each, to collect tomorrow. What day is tomorrow, and what is the total?"
tools allowed: calculator, reviews, search, today
step 1
  model> Action: today[] 
  model> Action: calculator[3 * 42.50]
  tool>  Friday 2 October 2026
step 2
  model> Answer: You can collect your cakes tomorrow, which is Saturday 3 October 2026, and the total will be R$ 127.50.
done: an answer after 2 steps
```

Read the lines by who wrote them. The `model>` lines are the model's turns. **The `tool>` line was
printed by a real tool**: the date came from `today`. The model wrote both requests in its first
turn, and `agent` ran the first, as `tools.txt` said it would; the calculator never ran. So the
total in the answer, R$ 127.50, is the model's own arithmetic. It happens to be right, and nothing
in the run checked it. The day after Friday 2 October is Saturday 3 October, and that step was the
model's too. **A tool supplies a fact only when it runs**, and only the `tool>` lines say which
facts came from one.

## Playing a run back

`agent` can also read the model's side from a file, one turn per block, separated by `---`; lines
starting with `#` are notes and are skipped. **The turns are then fixed**, and every run of the
loop does the same thing, which is how a program like this one is tested: the model's side is held
still, so that what the program does can be checked exactly. The next section uses that to look
at each rule on its own. Here is the same order, as the turns a model might write for it:

```
ana@lab:~/pe$ cat runs/order.txt
# Question: Bruno wants three whole cakes at R$ 42.50 each, to collect
# tomorrow. What day is tomorrow, and what is the total?
Action: today[]
---
Action: calculator[3 * 42.50]
---
Answer: Tomorrow is Saturday 3 October. Three cakes cost R$ 127.50.
ana@lab:~/pe$ agent runs/order.txt
tools allowed: calculator, reviews, search, today
step 1
  model> Action: today[]
  tool>  Friday 2 October 2026
step 2
  model> Action: calculator[3 * 42.50]
  tool>  127.5
step 3
  model> Answer: Tomorrow is Saturday 3 October. Three cakes cost R$ 127.50.
done: an answer after 3 steps
```

Here both tools ran, because the file asks for them one turn at a time. Playback shows what the
program does with a turn; only a live run shows what a model writes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three boxes from left to right. Inside a dashed boundary labelled the program around the model are the model, which writes text and runs nothing, and the loop. The model sends the loop the line Action: calculator[3 * 42.50]. The loop checks whether the tool is allowed and runs it. Outside the boundary are the tools, the only part that acts. The calculator returns 127.5 to the loop, and the loop adds the result to the text the model reads next.\"><defs><marker id=\"tool-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"30\" width=\"444\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"28\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the program around the model</text><rect x=\"30\" y=\"90\" width=\"124\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"92\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the model</text><text x=\"92\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">writes text, runs nothing</text><rect x=\"330\" y=\"90\" width=\"112\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"386\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the loop</text><text x=\"242\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Action: calculator[3 * 42.50]</text><path d=\"M154 104 L328 104\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tool-ah)\"></path><path d=\"M328 146 L156 146\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tool-ah)\"></path><text x=\"242\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the result, added to the text</text><rect x=\"586\" y=\"90\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"646\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">the tools</text><text x=\"646\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the only part that acts</text><path d=\"M442 104 L584 104\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tool-ah)\"></path><text x=\"514\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">allowed?</text><text x=\"514\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">then run it</text><path d=\"M584 146 L444 146\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tool-ah)\"></path><text x=\"514\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">127.5</text></svg>", "caption": "What a tool call is. The model only writes a line asking for a tool; the program around it decides whether to run it, runs it, and puts what came back into the text the model reads next."}
```

## What "agent" means here

The word is used loosely, for anything from a chatbot with a search box to a system that runs for
hours. In this course **an agent is a model running in a loop like this one**: it may ask for a
tool, the program runs it, and the loop goes round until the model writes an answer or a limit is
reached. The loop is the subject of the next section, and the program, not the model, holds every
limit in it.
