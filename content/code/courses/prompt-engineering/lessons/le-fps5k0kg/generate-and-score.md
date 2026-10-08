---
title: Propose many prompts, score each one, keep the best
version: 2
---

The usual way to improve a prompt is to read it, decide what sounds clearer, and rewrite it. That
works up to a point, and it rests on an assumption: that the prompt which reads best to you is the
one that works best on the model. Lesson 30 showed that the best prompt need not be words at all.
**Automatic prompt engineering drops the assumption and measures instead: generate many candidate
prompts, score each one on examples whose answers you know, and keep the one that scores highest.**

The method has four parts. Proposing needs a model that writes prompts; scoring needs the
model you will use, run by a program that counts:

1. Propose. A model is shown a few examples of the task and asked to write instructions that
   would produce them, many times over.
2. Score. Each candidate is run on a set of labelled examples, and a metric counts how many of
   its answers are right.
3. Keep. The highest score wins.
4. Refine, if you want. The model is asked for variations of the winner, and those are scored
   in turn.

The name comes from a 2022 paper, "Large Language Models Are Human-Level Prompt Engineers", which
called the method APE.

## Asking a model for instructions

The proposing step is itself a prompt, a *meta-prompt*: a prompt whose output is a prompt. It shows
input and output pairs and asks for the instruction that would produce them. Saved as
`~/pe/prompts/meta.txt` and sampled five times, at a temperature above 0 (lesson 13):

```
ana@lab:~/pe$ cat prompts/meta.txt
I gave a friend an instruction and four inputs. The friend read the
instruction and wrote one output for each input. Here are the pairs:

Input: coffee     Output: hot
Input: tea        Output: hot
Input: bread      Output: fresh
Input: terrace    Output: open

What was the instruction? Reply with the instruction alone, in one line.
ana@lab:~/pe$ ask - --temperature 0.8 --seed 1 --samples 5 --max-tokens 40 < prompts/meta.txt
[seed 1] A "hot day" is a hot piece of bread that is left out to get fresh under an open sky.
[seed 2] The instruction appears to be: "If the input is coffee or tea, the output is hot; if the input is bread, the output is fresh; if the input is terrace, the output is
[seed 3] The instruction is: "If you drink it, it's hot. If you eat it, it's fresh. If you go there, it's open."
[seed 4] Input the name of the food or drink and output its typical temperature, and for other inputs, input the name and output its typical state or condition.
[seed 5] The instruction is "Cook the [food]" and the food is assumed to be the ones mentioned in the inputs.
```

Five proposals, and they are not equally good. Seed 3 states a rule that fits all four pairs. Seed 4
is wordier and fits them too. Seed 2 copies the pairs back as a rule and was cut off by the limit;
seeds 1 and 5 are nonsense. That is fine: **the proposer's job is variety, and the scorer's job is
judgement**, and nothing about the proposals has been trusted yet.

## Scoring, for real

`ape` does the scoring half. It takes a file of prompt templates, one per line, with `{x}` where
the input goes, and a file of examples, the input and the expected first word separated by a tab.
It fills each template with each input, lets the model continue at temperature 0, and gives a point
when the first word of the reply is the expected one. The model is `toylm`, or with `--ask` the
model `ask` sends to. Save it as `~/pe/bin/ape` and make it executable:

```python
#!/usr/bin/env python3
"""ape CANDIDATES TESTS [--ask]: score prompt templates against labelled examples.

Automatic prompt engineering in its smallest form. CANDIDATES has one prompt
template per line, with {x} where the input goes. TESTS has one example per
line, the input and the expected first word separated by a tab. Each
template is filled with each input, the model continues it at temperature 0,
and the template scores one point for every reply whose first word is the
expected one, ignoring case. The model is toylm, or with --ask the model ask
sends to; the method does not change with the model.
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
use_ask = "--ask" in sys.argv
args = [a for a in sys.argv[1:] if a != "--ask"]
cands = [l.rstrip("\n") for l in open(args[0], encoding="utf-8") if l.strip()]
tests = [l.rstrip("\n").split("\t") for l in open(args[1], encoding="utf-8") if l.strip()]


def reply(prompt):
    if use_ask:
        command = [os.path.join(HERE, "ask"), prompt, "--temperature", "0", "--max-tokens", "5",
                   "--plain"]
    else:
        command = [os.path.join(HERE, "toylm"), "generate", prompt, "--temperature", "0",
                   "--max-tokens", "3"]
    out = subprocess.run(command, capture_output=True, text=True).stdout
    words = out.splitlines()[0].split() if out.strip() else []
    return words[0].strip(".,!:").lower() if words else ""


results = []
for c in cands:
    got = [(x, want, reply(c.replace("{x}", x))) for x, want in tests]
    score = sum(1 for _, want, r in got if r == want)
    results.append((score, c, got))
    print("%d/%d  %s" % (score, len(tests), c))
    for x, want, r in got:
        if r != want:
            print("        %-7s wanted %-7s got %s" % (x, want, r or "(nothing)"))
best = max(results, key=lambda r: r[0])
print("best: %s" % best[1])
```

The candidates below are what a person might write, plus two plain ones:

```
ana@lab:~/pe$ cat candidates.txt
Describe the {x} in one word:
question : what is the {x} like ? answer :
{x}
it is a cold day and the {x} is
the {x} is
ana@lab:~/pe$ cat tests.tsv
coffee	hot
tea	hot
bread	fresh
terrace	open
ana@lab:~/pe$ ape candidates.txt tests.tsv
0/4  Describe the {x} in one word:
        coffee  wanted hot     got is
        tea     wanted hot     got is
        bread   wanted fresh   got is
        terrace wanted open    got is
0/4  question : what is the {x} like ? answer :
        coffee  wanted hot     got yes
        tea     wanted hot     got yes
        bread   wanted fresh   got yes
        terrace wanted open    got yes
0/4  {x}
        coffee  wanted hot     got is
        tea     wanted hot     got is
        bread   wanted fresh   got is
        terrace wanted open    got is
4/4  it is a cold day and the {x} is
4/4  the {x} is
best: it is a cold day and the {x} is
```

The instruction a person would write first scored nothing. So did the question in the format the
café's own file uses, which looks like the cleverest of the five. **The templates that won are the
ones that suit this model, and nobody would have picked them by reading.**

The reason is in what `toylm` can see. It looks at the last two words (lesson 1), so after the
question template it sees `answer :` and nothing else, and it answers `yes` whatever the item was.
The instruction ends in `word:`, and that is not a pair it has ever seen:

```
ana@lab:~/pe$ toylm next "describe the coffee in one word :"
context: bigram after ':'
  is        25.0%  ##########
  yes       25.0%  ##########
  at        16.7%  #######
  when      16.7%  #######
  tomato     8.3%  ###
  what       8.3%  ###
```

It falls back to what follows a colon anywhere in its file, and `is` and `yes` tie at the top. Only
the two templates ending in `the {x} is` put the item where the model can see it.

A large model sees far more than two words. The same five templates, the same four examples, scored
on the local model:

```
ana@lab:~/pe$ ape candidates.txt tests.tsv --ask
0/4  Describe the {x} in one word:
        coffee  wanted hot     got rich
        tea     wanted hot     got delicate
        bread   wanted fresh   got crusty
        terrace wanted open    got elegant
0/4  question : what is the {x} like ? answer :
        coffee  wanted hot     got rich
        tea     wanted hot     got delicious?
        bread   wanted fresh   got it
        terrace wanted open    got the
0/4  {x}
        coffee  wanted hot     got coffee
        tea     wanted hot     got tea
        bread   wanted fresh   got bread
        terrace wanted open    got a
1/4  it is a cold day and the {x} is
        tea     wanted hot     got steaming
        bread   wanted fresh   got freshly
        terrace wanted open    got covered
2/4  the {x} is
        bread   wanted fresh   got the
        terrace wanted open    got a
best: the {x} is
```

The ranking turned over. The instruction a person would write first is followed perfectly, *rich,
delicate, crusty, elegant*, one word each and every one a fair description, and it scores nothing,
because the four labels were written for `toylm`'s file. The two templates that won on `toylm`
score 1 and 2, and the second is still `best`, at half marks.
**The prompt that suits a model is a fact about that model, found by testing it**, and so is the
score: it measures the model, the prompt and the labels together. The next reading section is about
the third.
