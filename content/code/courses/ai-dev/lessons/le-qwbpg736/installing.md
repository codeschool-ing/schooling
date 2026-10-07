---
title: Installing Ollama, Python and the libraries
version: 1
---

These steps are for Ubuntu 24.04, which is what you have on all three paths of the previous
section: on Linux directly, inside WSL on Windows, and in the virtual machine. A Mac takes a
different first step and then the same ones, and the end of this section says where they part.

Open a terminal. Everything below is typed in it.

## The system's own packages

```sh
sudo apt update
sudo apt install -y python3-venv git curl zstd
```

`python3-venv` lets Python make an isolated environment for the course's libraries, `git` keeps
the project's history, `curl` downloads the next installer and talks to the model by hand, and
`zstd` unpacks Ollama. Ubuntu leaves the last one out of a minimal install, and the installer
stops without it; the section on failures shows what that looks like.

## Ollama, and the model

Ollama's installer is a shell script on its own site. Download it, and read it if you like before
you run it, because it installs a service and asks for `sudo`:

```sh
curl -fsSL https://ollama.com/install.sh -o install-ollama.sh
sh install-ollama.sh
```

It ends with `>>> The Ollama API is now available at 127.0.0.1:11434.` and, on a computer with
`systemd`, starts Ollama as a service that comes back on every boot. Now download the model, about
2 GB:

```sh
ollama pull llama3.2:3b
```

And ask it something:

```
ana@dev:~$ ollama --version
ollama version is 0.40.0
ana@dev:~$ ollama list
NAME           ID              SIZE      MODIFIED               
llama3.2:3b    a80c4f17acd5    2.0 GB    Less than a second ago    
ana@dev:~$ ollama run llama3.2:3b "Say hello to a developer in one short sentence."
Hello!
ana@dev:~$ ollama ps
NAME           ID              SIZE      PROCESSOR    CONTEXT    RUNNER      UNTIL              
llama3.2:3b    a80c4f17acd5    2.6 GB    100% CPU     4096       llamacpp    4 minutes from now    
```

`ollama ps` lists the models in memory now. **2.6 GB is what the model takes while it answers**,
`100% CPU` says it ran on the processor because the recording machine has no graphics card, and
`4 minutes from now` is when Ollama will unload it if nobody asks anything else. Your reply will be
worded differently: a model draws its words at random, and section 08 of this lesson shows how.

## A Python environment for the course

The course's programs are Python, and they import the providers' own libraries. Those go into a
**virtual environment** of their own, in `~/aidev`, rather than into the system's Python:

```sh
python3 -m venv ~/aidev
source ~/aidev/bin/activate
pip install anthropic==1.11.0 openai==3.23.0 google-genai==2.27.0 mcp==2.2.0 numpy==2.4.6 wordllama==0.4.0.post1 tiktoken==0.14.0 pytest==9.1.1 hypothesis==6.168.3 jsonschema==4.26.0
```

**The versions are pinned** because these libraries change every few weeks, and a lesson written
against one version and run against another fails in ways that look like your mistake. They are
the three providers' SDKs (`anthropic`, `openai`, `google-genai`), the Model Context Protocol's
(`mcp`), OpenAI's tokenizer (`tiktoken`), a small embedding model (`wordllama`) with `numpy`, and
three libraries for testing and checking (`pytest`, `hypothesis`, `jsonschema`).

## Pointing the SDKs at Ollama

Ollama answers in the same format as Anthropic's API and OpenAI's, so their SDKs talk to it
unmodified. Each SDK reads where to send requests, and with what key, from the environment.
Four variables, added to the end of the environment's own activation script so that they are set
whenever the environment is:

```sh
cat >> ~/aidev/bin/activate <<'EOF'
export ANTHROPIC_BASE_URL=http://127.0.0.1:11434
export ANTHROPIC_API_KEY=ollama
export OPENAI_BASE_URL=http://127.0.0.1:11434/v1
export OPENAI_API_KEY=ollama
EOF
source ~/aidev/bin/activate
```

Ollama ignores the key, but both SDKs refuse to start without one, so it is set to a word that
says where it goes. **Every new terminal starts with `source ~/aidev/bin/activate`**; the prompt
then begins with `(aidev)`, which this course's transcripts leave out.

The check that all of it fits together is one request through the Anthropic SDK:

```
ana@dev:~$ python --version
Python 3.12.3
ana@dev:~$ env | grep -E "_(BASE_URL|API_KEY)=" | sort
ANTHROPIC_API_KEY=ollama
ANTHROPIC_BASE_URL=http://127.0.0.1:11434
OPENAI_API_KEY=ollama
OPENAI_BASE_URL=http://127.0.0.1:11434/v1
ana@dev:~$ python -c 'import anthropic; r = anthropic.Anthropic().messages.create(model="llama3.2:3b", max_tokens=40, messages=[{"role": "user", "content": "Reply with the word ready."}]); print(r.stop_reason, r.usage.output_tokens, repr(r.content[0].text))'
end_turn 3 'Ready.'
```

That is the same call, word for word, that would go to Anthropic's servers with the other two
variables. `stop_reason` and `usage` are the two fields this course reads most, and lesson 2 starts
with them.

## On a Mac

Download Ollama for macOS from `ollama.com/download` and drag it to Applications; it runs as an
app with an icon in the menu bar, and uses the graphics side of an Apple-silicon chip on its own.
Install Python 3.12 from `python.org`. Then, in Terminal, run `ollama pull llama3.2:3b` and every
step from "A Python environment for the course" on. macOS's shell is `zsh`, and the activation
script works in it unchanged.

## On Windows

Open PowerShell as administrator and install WSL with Ubuntu:

```sh
wsl --install -d Ubuntu-24.04
```

Restart when it asks, open *Ubuntu 24.04* from the Start menu, choose a user name and a password,
and follow this section from the top, inside it. Ollama installed inside WSL uses an NVIDIA card
through WSL's own driver support, and runs on the processor otherwise. **This command was
not run for this course**, which was recorded on Linux.
