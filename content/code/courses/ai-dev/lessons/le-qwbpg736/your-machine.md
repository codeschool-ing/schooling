---
title: A model on your own computer
version: 2
---

Nothing in this course runs on a machine we host. **You run a language model on your own
computer, with Ollama, and every program in the course talks to it.** Ollama is a free program
that downloads open models and answers requests for them on your machine, in the same formats the
big providers use, so the code you write here is the code you would write against them. It needs
no account and no card.

Every transcript in the course was recorded that way: Ubuntu 24.04 on a computer with four
processor cores, 15 GB of memory and no graphics card, a user called `ana` on a machine called
`dev`, and Ollama 0.40.0 serving **`llama3.2:3b`**, Meta's Llama 3.2 with three billion
parameters. Your prompt will carry your own name. The model's replies will not match the lesson's
word for word, even on an identical computer, and section 08 of this lesson shows why; what each
lesson asks you to look at in them will be there.

## Three ways to have it

| | what it is | what it costs your computer |
| --- | --- | --- |
| **installed** (recommended) | Ollama and Python on the computer you use every day: directly on Linux or a Mac, and on Windows inside WSL, Microsoft's Linux layer | about 4 GB of disk for Ollama, the model and the libraries; 2.6 GB of memory while the model answers, given back a few minutes after the last question |
| in a virtual machine | Ubuntu Server 24.04 LTS in VirtualBox on Windows or Linux, UTM on a Mac, or Hyper-V on Windows Pro, with the same steps inside it | the VM's own share, reserved while it runs: 4 processor cores, 8 GB of memory and 25 GB of disk; and the model runs on the processor only, because a VM does not see the graphics card |
| online | a paid API key from a provider such as Anthropic or OpenAI, and the same programs with their variables changed | Python and the libraries, but no model, so a few hundred megabytes; and **money**, per token, from a card you register with the provider |

**Installed is the recommendation because a model wants all the computer it can get.** A virtual
machine takes a fixed share of the memory and hides the graphics card, which is often what makes a
model fast: on an Apple-silicon Mac or with an NVIDIA card, Ollama uses it without being asked. And
Ollama keeps to itself. It is one program, one service and one directory of models, and removing
it removes all three.

**A virtual machine is the path if you would rather keep your own system untouched.** Give it at
least the sizes in the table; with less memory than 8 GB the model and Ubuntu fight over it. The
next section's steps then run inside the VM, exactly as written.

**Online works for most of the course, and it is the only path here that costs money.** The
programs read the provider's address and key from four variables (the next section sets them for
Ollama), so you follow the next section without Ollama, change those and the model name, and nothing
else. Set a spending limit in the
provider's console before the first request. Lesson 2 shows what requests cost, so you can check
the course's arithmetic against your own bill. Some sections cannot be repeated this way, because
they ask Ollama for something no hosted API gives out: the probabilities the model assigned to each
next token, in section 06 of this lesson, are one. **No lesson depends on a provider's free
allowance**; one may exist when you read this, and it is the provider's to change.

## How much computer is enough

The recommended model wants **8 GB of memory in the whole computer**, so that 2.6 GB of it can go
to the model while your browser and editor keep the rest. With 4 GB, or on an old machine where
every answer crawls, use the smaller model of the same family:

```sh
ollama pull llama3.2:1b
```

```
ana@dev:~$ ollama run llama3.2:1b "Say hello to a developer in one short sentence."
Hello, how can I assist you today as a developer?
ana@dev:~$ ollama ps
NAME           ID              SIZE      PROCESSOR    CONTEXT    RUNNER      UNTIL              
llama3.2:1b    baf6a787fdff    1.5 GB    100% CPU     4096       llamacpp    4 minutes from now    
llama3.2:3b    a80c4f17acd5    2.6 GB    100% CPU     4096       llamacpp    4 minutes from now    
ana@dev:~$ ollama list
NAME           ID              SIZE      MODIFIED      
llama3.2:1b    baf6a787fdff    1.3 GB    7 minutes ago    
llama3.2:3b    a80c4f17acd5    2.0 GB    7 minutes ago    
```

It is 1.3 GB to download and 1.5 GB in memory. It is also faster, and its answers are worse: it
follows instructions less closely, as its hello above shows, and makes more things up. Asking each model for the
same two sentences, and reading Ollama's own count of how long the writing took:

```
ana@dev:~$ curl -s http://127.0.0.1:11434/api/generate -d '{"model": "llama3.2:3b", "prompt": "Explain in two sentences what a unit test is.", "stream": false}' | python3 -c 'import json, sys; r = json.load(sys.stdin); print(r["eval_count"], "tokens in", round(r["eval_duration"] / 1e9, 1), "seconds")'
74 tokens in 7.0 seconds
ana@dev:~$ curl -s http://127.0.0.1:11434/api/generate -d '{"model": "llama3.2:1b", "prompt": "Explain in two sentences what a unit test is.", "stream": false}' | python3 -c 'import json, sys; r = json.load(sys.stdin); print(r["eval_count"], "tokens in", round(r["eval_duration"] / 1e9, 1), "seconds")'
78 tokens in 4.3 seconds
```

About 11 tokens a second against 18, on four processor cores. Every lesson's point still shows on
the smaller model. To use it, write `llama3.2:1b` wherever a program in this course says
`llama3.2:3b`.

Speed is the other cost, and it depends on your computer more than on anything in this course. At
11 tokens a second, a reply of a hundred words takes the recording machine about twelve seconds.
With a graphics card, expect a fraction of that.
