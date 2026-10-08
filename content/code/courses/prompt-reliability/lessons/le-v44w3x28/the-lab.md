---
title: Your lab, and three ways to build it
version: 2
---

A prompt that worked when you tried it has been tested once. **This course is about testing it the
other thirty-nine times**: writing down what a good answer is, running the prompt over messages it
has not seen, and counting. Everything after this section is a way of making that count more
honest, cheaper or harder to fool.

Counting needs a model you can call hundreds of times without thinking about it. A lesson here
makes anything from forty calls to a few hundred. So the course recommends a model that runs on
your own computer: **Ollama**, a free program that downloads open models and answers requests on
your machine, with **`llama3.2:3b`**, a small model from Meta. No account, no card, no API key, and
the same model in every AI course of this school, so if you set it up once you have it for all of
them.

The lab is three things:

- **Ollama and `llama3.2:3b`**, installed in this section;
- **Python 3**, which runs the harness and needs nothing beyond its standard library;
- **`~/triage`**, a directory with the harness, the test set and the prompts, built in the next
  section.

## Three ways to have one

| path | what you get | what it costs | the transcripts |
|---|---|---|---|
| **installed** (recommended) | Ollama on the computer you already use | 2.0 GB of disk for the model, plus Ollama itself, and 2.9 GB of memory while it answers | close; your replies may differ in wording |
| **a virtual machine** | Ubuntu Server 24.04 LTS with Ollama inside it | the same, plus the virtual machine's own disk and memory; no graphics card, so slower | close, as installed |
| **online** | a paid model behind an API, reached with your own key | money per token, and the course's numbers will not be yours | different |

**Installed is the recommended path.** Ollama is one program and a directory of models; it
changes nothing else on your system, and it uses your graphics card when it finds one it can use,
which a virtual machine cannot give it. The model needs memory more than anything: loaded, it took 2.9 GB on the machine these lessons
were captured on, which a computer with 8 GB has to spare. One with less should take the smaller
model described below.

Every capture in this course was taken on Ubuntu 24.04 with Ollama 0.40.0, on a machine with
four processor cores and no graphics card. **A language model is not a calculator**: with the
settings the harness uses, the same prompt gives the same reply every time on one machine. A
different machine, a different version of Ollama or a different build of the model can word a reply
differently, and now and then label it differently. So your counts may be a few away from the
ones printed here. What each lesson shows should still hold: if a change fixed thirteen replies
here and two on your machine, the lesson is about why it moved at all.

## Installed

On Linux, Ollama's own script installs it and sets it up as a service that starts with the
computer:

```sh
curl -fsSL https://ollama.com/install.sh | sh
```

On macOS and Windows, download the installer from ollama.com and run it. **Those two were not run
for this course.** On Windows, the commands in this course are typed in a Linux terminal: install
WSL with Ubuntu 24.04 (`wsl --install -d Ubuntu-24.04` in PowerShell), and install Ollama inside
it with the Linux line above, so the model and the harness live in the same place.

Then download the model. It is a single command, and the first time it fetches about two
gigabytes:

```sh
ollama pull llama3.2:3b
```

Check what you have:

```
ana@lab:~/triage$ python3 --version
Python 3.12.3
ana@lab:~/triage$ ollama --version
ollama version is 0.40.0
ana@lab:~/triage$ ollama list
NAME           ID              SIZE      MODIFIED       
llama3.2:3b    a80c4f17acd5    2.0 GB    57 minutes ago    
ana@lab:~/triage$ du -sh /usr/local/lib/ollama
2.1G	/usr/local/lib/ollama
```

`ollama list` shows what is on the disk, and `du` what Ollama itself took: 2.1 GB, most of it
libraries for graphics cards. Python 3 is already on Ubuntu and macOS; on another system, install it
from python.org. Version 3.8 or later is enough.

### A weaker computer

If your computer has less than 8 GB of memory, or a reply takes more than half a minute, use
**`llama3.2:1b`**, the same family at a third of the size:

```sh
ollama pull llama3.2:1b
```

It is 1.3 GB on disk. Every command in the course takes `--set model=llama3.2:1b`, or you can
change the model in `DEFAULTS` at the top of `pl.py` once. Here is the best prompt of this lesson
run with it, and what both models took in memory once they had answered:

```
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --out runs/v3-1b.jsonl --set model=llama3.2:1b
40 calls, prompt 1d9c6ec4, llama3.2:1b, written to runs/v3-1b.jsonl
ana@lab:~/triage$ ollama ps
NAME           ID              SIZE      PROCESSOR          CONTEXT    RUNNER      UNTIL              
llama3.2:1b    baf6a787fdff    2.0 GB    25%/75% CPU/GPU    4096       llamacpp    4 minutes from now    
llama3.2:3b    a80c4f17acd5    2.9 GB    30%/70% CPU/GPU    4096       llamacpp    3 minutes from now    
ana@lab:~/triage$ pl check runs/v3-1b.jsonl
check      pass  fail
json         36     4
fields       36     4
labels       36     4
category     14    26
urgency       9    31
all           9    31
```

2.0 GB of memory against 2.9, and **9 replies of 40 passing where `llama3.2:3b` passes 28**. It
runs, and it is a much weaker model: expect the counts in these lessons to be far lower on it. The
checks are what this course is about, and they work the same way.

## In a virtual machine

If you would rather keep everything apart from your own system, build a virtual machine with
**Ubuntu Server 24.04 LTS**: VirtualBox on Windows and Linux, UTM on a Mac. Give it at least 8 GB
of memory and 20 GB of disk, and inside it follow the Linux steps above. `virtualization` lesson 4
builds one in VirtualBox step by step.

A virtual machine gets no graphics card, so every reply is computed on the processor. That is how
this course was captured, and a run of forty messages took a few minutes; it works, and it is
slower than it would be on the computer underneath.

## Online, with your own key

The last path is a commercial model behind an API: you create an account with a provider, add a
payment method, and get a key. The harness talks to a model through one function, `call()`, and
this version of it speaks the OpenAI-compatible chat API that most providers offer:

```python
def call(prompt, params):
    """One request to an OpenAI-compatible API, paid for with your own key."""
    body = {"model": params["model"], "temperature": float(params["temperature"]),
            "seed": int(params["seed"]), "max_tokens": int(params["num_predict"]),
            "messages": [{"role": "user", "content": prompt}]}
    req = urllib.request.Request(os.environ["PL_BASE"] + "/chat/completions",
                                 json.dumps(body).encode(),
                                 {"Content-Type": "application/json",
                                  "Authorization": "Bearer " + os.environ["PL_KEY"]})
    start = time.time()
    try:
        with urllib.request.urlopen(req, timeout=600) as r:
            reply = json.load(r)
    except urllib.error.HTTPError as e:
        die("the API answered %d: %s" % (e.code, e.read().decode().strip()))
    choice, usage = reply["choices"][0], reply.get("usage", {})
    return {"text": choice["message"]["content"], "stop": choice["finish_reason"],
            "tokens_in": usage.get("prompt_tokens", 0),
            "tokens_out": usage.get("completion_tokens", 0),
            "seconds": round(time.time() - start, 2)}
```

Replace the `call()` in `pl.py` with it, set `PL_BASE` to the provider's address and `PL_KEY` to
your key, and pass the provider's model name with `--set model=...`. It was tested against Ollama's
own OpenAI-compatible address, `http://127.0.0.1:11434/v1`, and not against any provider; check
the address, the model names and the prices in your provider's documentation.

**This path costs money on every call**, and a lesson that runs a prompt over forty messages ten
times is four hundred calls. Some providers offer a free allowance; the course never depends on one,
because a free allowance is a term somebody else can change. A commercial model is also much
stronger than `llama3.2:3b`, so some of the failures these lessons count will not happen to you,
which is good news for your prompt and less good for the lesson.

## Where this course starts

`prompt-engineering` introduced the techniques: few-shot examples in its lessons 20 and 21,
temperature in lesson 13, injection in lesson 7. **This course takes several of them again on
purpose**, with a different question. There the question was what a technique is. Here it is
whether it still works on the fortieth message, and how you would know if it stopped.
