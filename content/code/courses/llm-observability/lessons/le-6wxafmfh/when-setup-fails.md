---
title: When the setup fails
version: 1
---

Most people who give up on a course like this give up here, on an error about a program they have
only just installed. These are the failures the recording machine actually produced while this
lesson was being written, in the order you would meet them, each as it printed it and with what
it means.

## The installer stops at zstd

```
ana@dev:~$ curl -fsSL https://ollama.com/install.sh -o install-ollama.sh
ana@dev:~$ sh install-ollama.sh
>>> Installing ollama to /usr/local
ERROR: This version requires zstd for extraction. Please install zstd and try again:
  - Debian/Ubuntu: sudo apt-get install zstd
  - RHEL/CentOS/Fedora: sudo dnf install zstd
  - Arch: sudo pacman -S zstd
```

Ollama is downloaded compressed with `zstd`, and a minimal Ubuntu does not have it. The message
says the fix: `sudo apt install zstd`, then run the installer again. Section 03's first command
installs it before you get here.

## Ollama is installed and nothing answers

```
ana@dev:~$ ollama --version
Warning: could not connect to a running Ollama instance
Warning: client version is 0.40.0
ana@dev:~$ ollama list
Error: could not connect to ollama server, run 'ollama serve' to start it
```

`ollama` is two programs in one file: the command you type, and a server that holds the models and
answers on `127.0.0.1:11434`. The command works and the server is not running. On a normal Ubuntu
the installer registers the server as a service and starts it; **where there is no `systemd` it
cannot**, and the installer says so in one line near its end, `WARNING: systemd is not running`,
which is easy to scroll past. The recording machine is a container and has no `systemd`. Older
installations of WSL do not either.

Where `systemd` exists, `sudo systemctl start ollama` starts the service. Where it does not, open a
second terminal, run `ollama serve` in it, and leave it open: it is the server, and it prints a
line for every request it answers. Closing that terminal stops it.

## `ollama serve` says the address is in use

```
ana@dev:~$ timeout 5 ollama serve
Couldn't find '/home/ana/.ollama/id_ed25519'. Generating new private key.
Your new public key is: 

ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIQcQrwd08NN5DSOjJVWaJBpieMmy5keDn875YkH3BmE

Error: listen tcp 127.0.0.1:11434: bind: address already in use
```

`timeout 5` in front would have stopped this second server after five seconds; it did not get that
far. **A server is already running**, which is good news: the service started after all, or another
terminal is running one. Only one program can listen on a port. Close this one and use the one
that is there. The key above is generated the first time Ollama runs as you, and identifies your
installation to Ollama's own site if you ever publish a model; nothing in this course uses it.

## pip refuses to install

```
ana@dev:~$ python3 -m pip install openai==3.24.0
error: externally-managed-environment

× This environment is externally managed
╰─> To install Python packages system-wide, try apt install
    python3-xyz, where xyz is the package you are trying to
    install.
    
    If you wish to install a non-Debian-packaged Python package,
    create a virtual environment using python3 -m venv path/to/venv.
    Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    sure you have python3-full installed.
    
    If you wish to install a non-Debian packaged Python application,
    it may be easiest to use pipx install xyz, which will manage a
    virtual environment for you. Make sure you have pipx installed.
    
    See /usr/share/doc/python3.12/README.venv for more information.

note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
hint: See PEP 668 for the detailed specification.
```

That is pip outside the environment, refusing to install into the Python that Ubuntu itself
depends on. It is right to refuse. **Do not pass `--break-system-packages`**, which means what it
says. Activate the environment with `source ~/llmobs/bin/activate` and run the same command.

## A program cannot find `openai`

```
ana@dev:~$ python3 -c "import openai"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
ModuleNotFoundError: No module named 'openai'
```

The libraries are installed in `~/llmobs`, and this terminal is not using it: it is a new terminal,
and nobody ran `source ~/llmobs/bin/activate` in it. The prompt has no `(llmobs)` in front. Run the
`source` line, and the three variables of section 03 come back with it. On Ubuntu, a plain `python`
exists only inside the environment, so `python: command not found` is the same mistake.

## Ollama stops while a program is talking to it

```
ana@dev:~/obs$ python -c 'from openai import OpenAI; OpenAI().chat.completions.create(model="llama3.2:3b", messages=[{"role": "user", "content": "Hello"}])' 2>&1 | tail -n 1
openai.APIConnectionError: Connection error.
```

`Connection error` with nothing else means nothing answered at the address in `OPENAI_BASE_URL`.
The server stopped, or never started after a reboot, or the terminal running `ollama serve` was
closed. `ollama list` tells you which in one line, as in the second failure above. The SDK tried
twice more before it gave up, which is why the error takes a few seconds to appear; lesson 4 is
about those retries.

## Slow is not broken

The first question after a while takes longer than the next ones, because Ollama loads the model
into memory first and unloads it after five minutes of nobody asking. Lesson 4 measures that wait.
If every answer takes minutes, or the whole computer stalls while the model writes, the model is
too big for the memory you have: section 02 says how much the recommended one needs, and which
smaller one to use instead.
