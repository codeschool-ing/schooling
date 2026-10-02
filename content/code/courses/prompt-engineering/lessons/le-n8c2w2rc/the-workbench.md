---
title: The workbench this course runs on
version: 1
---

Every command in this course was run, and every line of output under it is what the command
printed. They ran in one directory, `~/pe`, on a Linux machine:

```
ana@lab:~/pe$ ls
bin
corpus.txt
handbook
node_modules
reviews
ana@lab:~/pe$ head -4 corpus.txt
the coffee is strong .
the soup of the day is tomato .
the cake is gone by noon .
bruno orders a coffee .
ana@lab:~/pe$ toylm info
corpus:        761 words in corpus.txt
vocabulary:    72 distinct words
trigram rows:  152 contexts, 212 counts
bigram rows:   72 contexts, 152 counts
parameters:    436 stored counts
```

**There is no large language model on this machine, and none was reachable from it.** That is a
plain fact about how the course was recorded, and it decides how the course is written:

- what a **real** program printed is shown as a transcript, with the `ana@lab:~/pe$` prompt in
  front of the command. Those are captures, and you can reproduce every one;
- what a large model **might** reply is shown in a plain block with no prompt, and the sentence
  before it says it was written by this course as an illustration. Models change month to month,
  and a reply invented and presented as a capture would be the exact failure lesson 5 warns you
  about.

The tools in `bin` are small and are printed in full in `lab.sh`, the file that builds the
workbench:

| tool | what it is | first used in |
|---|---|---|
| `toylm` | the trigram model of `corpus.txt`, with the sampling controls a model API has | this lesson |
| `tok` | a **real** tokenizer, the encodings OpenAI publishes for its models | this lesson, below; lesson 3 explains it |
| `validate`, `repair` | checking a reply against a JSON Schema, and recovering a wrapped one | lessons 15 and 19 |
| `retrieve` | keyword search over `handbook/`, the staff handbook of a café | lesson 5 |
| `agent` | the loop that runs tools for a model, with its limits and refusals | lesson 6 |
| `vote`, `tot`, `ape` | self-consistency, a tree of thoughts, scoring prompts | lessons 27, 28 and 31 |

`tok` is the one tool here that a production system also uses. It does not call a model:

```
ana@lab:~/pe$ tok show "The café opens at seven."
"The" " café" " opens" " at" " seven" "."
976 30469 24061 540 12938 13
6 tokens, 24 characters (o200k_base)
```

**The café, its handbook and its reviews were written for the course**, and Café Aurora does not
exist. The e-mail addresses end in `example.com`, the domain reserved for examples.

::: track ai security
The tools are written in Python and JavaScript, and you met Python in the `python` course. Reading
one is a good way to check what a lesson claims: `toylm` is about two hundred lines, and the
function that turns counts into percentages is four of them.
:::

::: track *
You do not need to read or write code in this course. Each lesson says what a command does and
what to look at in what it printed. The tools are Python and JavaScript, and they are in `lab.sh`
for anyone who wants to check a claim against the program that made it.
:::

## Following along

To run the same commands you need a Linux machine (a virtual machine is fine, and so is WSL on
Windows) with Python 3.11 or later and Node.js 20 or later:

```
ana@lab:~/pe$ python3 --version; node --version
Python 3.11.15
v20.20.0
```

`sudo bash lab.sh tools` fetches the two libraries the tools need, and `sudo bash lab.sh reset`
builds `~/pe` for a user called `ana`. Each lesson that shows a transcript has a `captures.sh`
beside it that runs every command in that lesson, in order.

**When you prompt a real model yourself**, through a chat window or an API key of your own, your
replies will differ from the illustrations in this course, and they will differ between two runs
of the same prompt. That is not a sign something is wrong. Lesson 13 is about exactly that.
