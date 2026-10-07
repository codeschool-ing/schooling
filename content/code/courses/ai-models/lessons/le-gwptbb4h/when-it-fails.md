---
title: When the setup fails
version: 1
---

Every failure below with a transcript happened while this course was being recorded, on the Ubuntu
Server 24.04 the virtual machine path installs, and each one names its own cause if you read the
last line first.

## The installer stops before it starts

```
ana@desk:~$ curl -fsSL https://ollama.com/install.sh | sh
>>> Installing ollama to /usr/local
ERROR: This version requires zstd for extraction. Please install zstd and try again:
  - Debian/Ubuntu: sudo apt-get install zstd
  - RHEL/CentOS/Fedora: sudo dnf install zstd
  - Arch: sudo pacman -S zstd
```

The script downloads Ollama as a `.tar.zst` file and needs `zstd` to unpack it. The message says
what to install, for three families of Linux. Install it, run the same line again, and the
installer finishes as section 03 shows.

## Nothing is listening

```
ana@desk:~$ ollama run llama3.2:3b "Hello"
Error: could not connect to ollama server, run 'ollama serve' to start it
ana@desk:~/desk$ python check.py 2>&1 | tail -1
openai.APIConnectionError: Connection error.
```

Both messages mean the same thing: **the server is not running.** The command `ollama` and the
Python libraries are only clients; the model is in the server, and here there was no server on
port 11434 to answer. On Windows and macOS, open the Ollama application, which starts it. On Linux
with systemd, `sudo systemctl start ollama`. On a machine without systemd, the case section 03's
warning described, run `ollama serve` in a terminal of its own and leave it open while you work.

The Python message is the shortest line of a long traceback, and `tail -1` is how to see it: the
last line of a Python error is the cause, and everything above it is where it travelled.

## The server will not start a second time

```
ana@desk:~$ ollama serve
Couldn't find '/home/ana/.ollama/id_ed25519'. Generating new private key.
Your new public key is: 

ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICEamexygLwNBCOIi+pUp0VVMDB07m/s03OagWMQnp5r

Error: listen tcp 127.0.0.1:11434: bind: address already in use
```

The first time it runs, Ollama makes itself a key pair in `~/.ollama`, which it uses only if you
sign in to ollama.com; nothing in this course needs it. The line that matters is the last: **port
11434 already has a server on it**, which is good news. One was running all along, started by the
installer or the application, and `ollama run` will reach it.

## A model that is not there

```
ana@desk:~$ ollama pull llama3.2:4b
pulling manifest
Error: pull model manifest: file does not exist
```

There is no `llama3.2:4b`. **The tag has to be one Ollama's library publishes**, and its page on
ollama.com lists them: `llama3.2` comes as `1b` and `3b`. The message says *file does not exist*
because the server asked the library for that tag's list of files and got nothing back.

## Python cannot find the library

```
ana@desk:~/desk$ python3 check.py
Traceback (most recent call last):
  File "/home/ana/desk/check.py", line 3, in <module>
    from openai import OpenAI
ModuleNotFoundError: No module named 'openai'
```

`python3` ran the system's Python, which has none of the six libraries; they are inside `.venv`.
**Activate the virtual environment** in every new terminal before working on the desk, with
`. .venv/bin/activate`, and the prompt then usually starts with `(.venv)`.

## The library has no key

```
ana@desk:~/desk$ python check.py
Traceback (most recent call last):
  File "/home/ana/desk/check.py", line 5, in <module>
    client = OpenAI()  # the address and the key come from desk.env
  File "/home/ana/desk/.venv/lib/python3.13/site-packages/openai/_client.py", line 274, in __init__
    raise OpenAIError(
        "Missing credentials. Please pass an `api_key`, `workload_identity`, `admin_api_key`, or set the `OPENAI_API_KEY` or `OPENAI_ADMIN_KEY` environment variable."
    )
openai.OpenAIError: Missing credentials. Please pass an `api_key`, `workload_identity`, `admin_api_key`, or set the `OPENAI_API_KEY` or `OPENAI_ADMIN_KEY` environment variable.
```

The virtual environment is active, and `desk.env` was not loaded, so the library has no key and no
address. It asks for a key first because it would have sent the request to OpenAI itself. Run
`. ./desk.env` in the same terminal, and check with `echo $OPENAI_BASE_URL`, which should print
Ollama's address.

## The computer is too small

On a machine with less memory than the model needs, Ollama refuses to load it or answers very
slowly, swapping to disk. This was not recorded: the machine the course was recorded on has 16 GB.
**Pull `llama3.2:1b`**, which needs 1.5 GB loaded, and use it in every program by changing the
model's name. Lesson 5 shows what it costs in quality, measured.

## Anything else

**Read the last line of what it printed before you search for it.** An installer that fails prints a
page, and Python prints a traceback; the cause is the line that says `ERROR`, `Error` or the
exception's name, and the lines around it are where it happened. A message that names a package or a
command to run, like the first one here, means exactly that.
