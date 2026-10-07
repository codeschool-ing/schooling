---
title: When the setup fails
version: 1
---

Most people who give up on a course like this give up here, on an error from a machine they have
only just built. These are the failures that actually happen, roughly in the order you would meet
them. Where the machine this course was recorded on produced one, it is shown as that machine
printed it.

**Ollama's installer stops with *This version requires zstd for extraction*.** It happened on the
machine this course was recorded on, which is why `zstd` is in the `apt-get` line. Install it and
run the installer again; nothing was half-installed.

**Ollama is installed and nothing answers.**

```
ana@vm:~/rag$ ollama list
Error: could not connect to ollama server, run 'ollama serve' to start it
ana@vm:~/rag$ python -c "from vectors import embed; embed(\"hello\")" 2>&1 | tail -1
openai.APIConnectionError: Connection error.
```

The program is on disk and the server is not running. On the VM the installer made it a service,
and `sudo systemctl start ollama` starts it; `systemctl status ollama` says why it stopped, if it
did. Inside a container or anywhere without systemd, `ollama serve &` runs it by hand. The Python
programs fail in the same situation with a long traceback whose last line is the one shown: the
SDK could not connect, and it says so after retrying twice.

**The model's name is not quite the one you pulled.**

```
ana@vm:~/rag$ python -c "from openai import OpenAI; OpenAI().chat.completions.create(model=\"llama3.2\", messages=[{\"role\": \"user\", \"content\": \"hi\"}])" 2>&1 | tail -1
openai.NotFoundError: Error code: 404 - {'error': {'message': "model 'llama3.2' not found", 'type': 'not_found_error', 'param': None, 'code': None}}
```

`llama3.2` with no tag means `llama3.2:latest`, which is a different download from `llama3.2:3b`.
`ollama list` shows the names exactly as a program has to write them.

**A new terminal cannot find the libraries.**

```
ana@vm:~/rag$ python3 -c "import openai"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
ModuleNotFoundError: No module named 'openai'
```

The libraries are inside `~/rag/.venv`, and this terminal never ran `env.sh`. Either the line that
adds it to `~/.bashrc` was skipped, or the terminal was opened before it was added. `. ~/rag/env.sh`
fixes the terminal you are in.

**`psql` says the role does not exist.**

```
ana@vm:~/rag$ createdb rag
createdb: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
ana@vm:~/rag$ createdb rag
ana@vm:~/rag$ psql -d rag -c "CREATE EXTENSION vector"
CREATE EXTENSION
```

PostgreSQL has no role with your login's name: the `createuser` line was skipped, or it was run
under another login. Run it again, then `createdb rag`. If `CREATE EXTENSION vector` answers that the
extension *is not available*, the `postgresql-16-pgvector` package is missing; install it, and the
same command works.

**Ollama refuses to load the model for lack of memory.** The message says how much the model needs
and how much is free. Close what else is running in the VM, give the VM more memory in Multipass
(`multipass stop vm`, then `multipass set local.vm.memory=8G`), or use `llama3.2:1b`. This one did
not happen on the machine the course was recorded on, so it is described rather than shown.

**A reply takes a minute.** The first request after a pause loads the model, and on four processors
with no graphics card a long prompt takes seconds per thousand tokens to read. That is the price of
running a model locally, and lesson 9 sets a timeout on every call because of it. If every reply is
slow on a computer with a graphics card, check `ollama ps`: a `PROCESSOR` column reading `100% CPU`
means Ollama did not find the card, and a split such as `40%/60% CPU/GPU` means the model did not fit
in the card's memory and part of it runs on the processor.

**`pip install` fails to build a package.** The versions in `requirements.txt` were recorded on
Python 3.12, the one Ubuntu 24.04 ships. A newer Python may have no ready-built package for one of
them, and pip then tries to compile it and fails. Use Ubuntu 24.04 in the VM, which is the reason
the VM is the recommended path.
