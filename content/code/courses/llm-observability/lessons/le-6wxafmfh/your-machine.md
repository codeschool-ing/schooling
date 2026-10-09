---
title: A model on your own computer
version: 2
---

Nothing in this course runs on a machine we host. **You run a language model on your own
computer, with Ollama, and every program in the course talks to it.** Ollama is a free program
that downloads open models and answers requests for them on your machine, in the same format the
big providers use, so the code you write here is the code you would write against them. It needs
no account and no card.

Every transcript in the course was recorded that way. The machine runs Ubuntu 24.04 on four
processor cores and 15 GB of memory, with no graphics card, a user called `ana` and the host name
`dev`. Ollama 0.40.0 serves **`llama3.2:3b`**, Meta's Llama 3.2 with three billion parameters,
which writes the answers. Your prompt will carry your own name.

The assistant in this course asks the model at **temperature 0**, which makes it choose its most
likely word every time, so on one computer the same question gets the same answer. On yours it may
be worded differently, and now and then it will be a different answer altogether: the arithmetic
underneath rounds differently on a different processor. What each lesson asks you to look at in
the replies will be there, and where a lesson counts something over many replies, your counts will
be close to the lesson's rather than equal to them.

## Three ways to have it

| | what it is | what it costs your computer |
| --- | --- | --- |
| **installed** (recommended) | Ollama and Python on the computer you use every day: directly on Linux or a Mac, and on Windows inside WSL, Microsoft's Linux layer | about 4.5 GB of disk for Ollama, the two models and the first libraries, and a few hundred megabytes more as later lessons add theirs; 2.9 GB of memory while the model answers, given back a few minutes after the last question |
| in a virtual machine | Ubuntu Server 24.04 LTS in VirtualBox on Windows or Linux, UTM on a Mac, or Hyper-V on Windows Pro, with the same steps inside it | the VM's own share, reserved while it runs: 4 processor cores, 8 GB of memory and 30 GB of disk; and the model runs on the processor only, because a VM does not see the graphics card |
| online | a paid API key from OpenAI, and the same programs with their variables and model names changed | Python and the libraries, a few hundred megabytes, but no model; and **money**, per token, from a card you register with the provider |

**Installed is the recommendation because a model wants all the computer it can get.** A virtual
machine takes a fixed share of the memory and hides the graphics card, which is often what makes a
model fast: on an Apple-silicon Mac or with an NVIDIA card, Ollama uses it without being asked. And
Ollama keeps to itself. It is one program, one service and one directory of models, and removing
it removes all three.

**A virtual machine is the path if you would rather keep your own system untouched.** Give it at
least the sizes in the table; with less memory than 8 GB the model and Ubuntu fight over it. The
next section's steps then run inside the VM, exactly as written.

**Online works for most of the course, and it is the only path here that costs money.** The programs
use OpenAI's SDK and read the address and key from two variables, which the next section sets for
Ollama. Leave the address out and set your own key instead, and they talk to OpenAI. Two names
change as well: the chat model in `releases.json`, and the embedding model in `index.py`, where
OpenAI's `text-embedding-3-small` takes the place of `all-minilm`. Every similarity in the course
then comes out different, so the floor in `releases.json` has to be chosen again; lesson 5 shows
what a floor set wrong does. Set a spending limit in the provider's console before the first
request. **No lesson depends on a provider's free allowance**; one may exist when you read this, and
it is the provider's to change.

Lesson 6 also runs Docker, for the tracing tool whose screens it shows. It says what that adds, and
it can be read without it.

## How much computer is enough

The recommended model wants **8 GB of memory in the whole computer**, so that 2.9 GB of it can go
to the model while your browser and editor keep the rest. With 4 GB, or on an old machine where
every answer crawls, use the smaller model of the same family:

```sh
ollama pull llama3.2:1b
```

```
ana@dev:~$ ollama run llama3.2:1b "Say hello to a customer in one short sentence."
"Hello, how can I assist you today?"
ana@dev:~$ ollama ps
NAME           ID              SIZE      PROCESSOR          CONTEXT    RUNNER      UNTIL              
llama3.2:1b    baf6a787fdff    2.0 GB    25%/75% CPU/GPU    4096       llamacpp    4 minutes from now    
llama3.2:3b    a80c4f17acd5    2.9 GB    30%/70% CPU/GPU    4096       llamacpp    4 minutes from now    
ana@dev:~$ ollama list
NAME                 ID              SIZE      MODIFIED       
llama3.2:1b          baf6a787fdff    1.3 GB    7 seconds ago     
all-minilm:latest    1b226e2802db    45 MB     29 seconds ago    
llama3.2:3b          a80c4f17acd5    2.0 GB    33 seconds ago    
```

It is 1.3 GB to download and 2.0 GB in memory. It is also faster, and its answers are worse: it
follows instructions less closely, as the quotation marks it put around its hello show, and makes
more things up. Asking each model for the same two sentences, and reading Ollama's own count of how
long the writing took:

```
ana@dev:~$ curl -s http://127.0.0.1:11434/api/generate -d '{"model": "llama3.2:3b", "prompt": "Explain in two sentences what a gift card is.", "stream": false}' | python3 -c 'import json, sys; r = json.load(sys.stdin); print(r["eval_count"], "tokens in", round(r["eval_duration"] / 1e9, 1), "seconds")'
66 tokens in 6.2 seconds
ana@dev:~$ curl -s http://127.0.0.1:11434/api/generate -d '{"model": "llama3.2:1b", "prompt": "Explain in two sentences what a gift card is.", "stream": false}' | python3 -c 'import json, sys; r = json.load(sys.stdin); print(r["eval_count"], "tokens in", round(r["eval_duration"] / 1e9, 1), "seconds")'
85 tokens in 2.3 seconds
```

About 11 tokens a second against 37, on four processor cores. Every lesson's point still shows on
the smaller model, though the counts in the later lessons will be further from the lesson's. To use
it, write `llama3.2:1b` in `releases.json` wherever it says `llama3.2:3b`.

The week of traffic in lesson 3 is the longest wait in the course: about three hundred questions,
which the recording machine answered in seventeen minutes with the recommended model. With a
graphics card, expect a fraction of that.