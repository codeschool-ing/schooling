---
title: Installing Ollama, Python and the libraries
version: 1
---

These steps are for Ubuntu 24.04, which is what you have on the first two paths of the previous
section: on Linux directly, inside WSL on Windows, or in the virtual machine. A Mac takes a
different first step and then the same ones, and the end of this section says where they part.

Open a terminal. Everything below is typed in it.

## The system's own packages

```sh
sudo apt update
sudo apt install -y python3-venv curl zstd
```

`python3-venv` lets Python make an isolated environment for the course's libraries, `curl`
downloads the next installer and talks to the model by hand, and `zstd` unpacks Ollama. Ubuntu
leaves the last one out of a minimal install, and the installer stops without it; the section on
failures shows what that looks like.

## Ollama, and the two models

Ollama's installer is a shell script on its own site. Download it, and read it if you like before
you run it, because it installs a service and asks for `sudo`:

```sh
curl -fsSL https://ollama.com/install.sh -o install-ollama.sh
sh install-ollama.sh
```

It ends with `>>> The Ollama API is now available at 127.0.0.1:11434.` and, on a computer with
`systemd`, starts Ollama as a service that comes back on every boot. Now download the two models
the course uses:

```sh
ollama pull llama3.2:3b
ollama pull all-minilm
```

**`llama3.2:3b`** writes the assistant's answers, and from lesson 9 it grades them too.
**`all-minilm`** turns a piece of text into 384 numbers, so that the assistant can find the
documents closest to a question; it is the same small model, all-MiniLM-L6-v2, that `rag` and
`embeddings-vectors` use.

```
ana@dev:~$ ollama --version
ollama version is 0.40.0
ana@dev:~$ ollama list
NAME                 ID              SIZE      MODIFIED               
all-minilm:latest    1b226e2802db    45 MB     Less than a second ago    
llama3.2:3b          a80c4f17acd5    2.0 GB    4 seconds ago             
ana@dev:~$ ollama run llama3.2:3b "Say hello to a customer in one short sentence."
"Hello, welcome to our store! How can I assist you today?"
ana@dev:~$ ollama ps
NAME           ID              SIZE      PROCESSOR          CONTEXT    RUNNER      UNTIL              
llama3.2:3b    a80c4f17acd5    2.9 GB    30%/70% CPU/GPU    4096       llamacpp    4 minutes from now    
```

`ollama ps` lists the models in memory now. **2.9 GB is what the model takes while it answers**, and
`4 minutes from now` is when Ollama will unload it if nobody asks anything else. The `PROCESSOR`
column says how the model is split between the processor and a graphics card. On the recording
machine, which has none, it read `30%/70% CPU/GPU` all the same, while Ollama's own log at start-up
found only the processor; on yours it will say what yours has. Your hello will be worded differently:
`ollama run` draws its words at random, which the assistant in section 07 does not.

## A Python environment for the course

The course's programs are Python. Their libraries go into a **virtual environment** of their own,
in `~/llmobs`, rather than into the system's Python:

```sh
python3 -m venv ~/llmobs
source ~/llmobs/bin/activate
pip install openai==3.24.0 numpy==2.4.6 opentelemetry-sdk==1.45.0 opentelemetry-exporter-otlp-proto-http==1.45.0 openinference-instrumentation-openai==0.1.63
```

**The versions are pinned** because these libraries change every few weeks, and a lesson written
against one version and run against another fails in ways that look like your mistake. They are
OpenAI's SDK (`openai`), which talks to Ollama as well as to OpenAI, `numpy` for the arithmetic of
the search, OpenTelemetry's SDK and its exporter, which write the traces this course is about, and
an instrumentation library that section 09 tries. Later lessons add their own, each with a `pip
install` line where it is first used.

## Pointing the SDK at Ollama, and a key of your own

Ollama answers in the same format as OpenAI's API, so the SDK talks to it unmodified. The SDK reads
where to send requests, and with what key, from the environment. Three variables, added to the end
of the environment's own activation script so that they are set whenever the environment is:

```sh
cat >> ~/llmobs/bin/activate <<EOF
export OPENAI_BASE_URL=http://127.0.0.1:11434/v1
export OPENAI_API_KEY=ollama
export PSEUDONYM_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(16))')
EOF
source ~/llmobs/bin/activate
```

Ollama ignores the API key, but the SDK refuses to start without one, so it is set to a word that
says where it goes. The third variable is a secret of your own: thirty-two random characters,
written once. The assistant uses it to record **who** asked a question without recording their
name, and lesson 2 opens it. **Every new terminal starts with `source ~/llmobs/bin/activate`**; the
prompt then begins with `(llmobs)`, which this course's transcripts leave out.

The check that all of it fits together is one request through the SDK:

```
ana@dev:~$ python --version
Python 3.12.3
ana@dev:~$ env | grep ^OPENAI_ | sort
OPENAI_API_KEY=ollama
OPENAI_BASE_URL=http://127.0.0.1:11434/v1
ana@dev:~$ python -c 'from openai import OpenAI; r = OpenAI().chat.completions.create(model="llama3.2:3b", max_tokens=10, messages=[{"role": "user", "content": "Reply with the word ready."}]); print(r.choices[0].finish_reason, r.usage.prompt_tokens, r.usage.completion_tokens, repr(r.choices[0].message.content))'
stop 31 3 'ready.'
```

That is the same call, word for word, that would go to OpenAI's servers with the first two
variables changed. `usage` is the field this course reads most, and section 06 starts with it.

## On a Mac

Download Ollama for macOS from `ollama.com/download` and drag it to Applications; it runs as an
app with an icon in the menu bar, and uses the graphics side of an Apple-silicon chip on its own.
Install Python 3.12 from `python.org`. Then, in Terminal, pull the two models and follow every step
from "A Python environment for the course" on. macOS's shell is `zsh`, and the activation script
works in it unchanged.

## On Windows

Open PowerShell as administrator and install WSL with Ubuntu:

```sh
wsl --install -d Ubuntu-24.04
```

Restart when it asks, open *Ubuntu 24.04* from the Start menu, choose a user name and a password,
and follow this section from the top, inside it. Ollama installed inside WSL uses an NVIDIA card
through WSL's own driver support, and runs on the processor otherwise. **This command was not run
for this course**, which was recorded on Linux.
