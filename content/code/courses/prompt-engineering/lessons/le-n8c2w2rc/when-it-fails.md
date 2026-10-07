---
title: When the setup fails
version: 1
---

Five failures account for most of it, and each one names itself in the first line it prints. All
five were produced on the machine these lessons were recorded on, by doing the thing wrong on
purpose. A sixth, running out of memory, comes at the end.

## The installer stops before it starts

```
ana@lab:~$ curl -fsSL https://ollama.com/install.sh | sh
>>> Installing ollama to /usr/local
ERROR: This version requires zstd for extraction. Please install zstd and try again:
  - Debian/Ubuntu: sudo apt-get install zstd
  - RHEL/CentOS/Fedora: sudo dnf install zstd
  - Arch: sudo pacman -S zstd
```

The Ollama download is compressed with `zstd`, and a fresh Ubuntu does not have it. This one
happened for real the first time this course was set up, which is why `zstd` is on the `apt-get`
line. Install it, as the message says, and run the installer again.

## Nothing answers

```
ana@lab:~$ ollama list
Error: could not connect to ollama server, run 'ollama serve' to start it
ana@lab:~$ ask "Say hello in three words."
ask: cannot reach http://localhost:11434/v1 ([Errno 111] Connection refused). Is the model server running?
ana@lab:~$ ollama list
NAME           ID              SIZE      MODIFIED      
llama3.2:3b    a80c4f17acd5    2.0 GB    2 minutes ago    
```

Both say the same thing in two ways: the program that serves the model is not running, so nothing
is listening at `localhost:11434`. The installer made it a service, and a service can be stopped,
or never started by a machine that booted without it. Start it, and check:

```sh
sudo systemctl start ollama
```

The last `ollama list` above is after it came back. (The machine the transcripts come from has no
`systemd`, so the server was started there by the script that records them. On Ubuntu and on WSL,
`systemctl` is the command.)

Do not start it with `ollama serve` as yourself instead. That works, and it serves a different,
empty set of models: the ones in your own home directory and not the service's, where `ollama pull`
put `llama3.2:3b`. The model then seems to have vanished.

## The model is not there

```
ana@lab:~$ ASK_MODEL=lama3.2:3b ask "Say hello in three words."
ask: http://localhost:11434/v1 answered 404: {"error":{"message":"model 'lama3.2:3b' not found","type":"not_found_error","param":null,"code":null}}
```

The server is up and has no model by that name. Here it is a typo, `lama` for `llama`, made in the
variable `ASK_MODEL`. The other way to get this message is to forget `ollama pull`. `ollama list`
shows the exact names you have, and those are the names `ask` and `ollama run` accept.

## A program will not run

```
ana@lab:~/pe$ toylm info
bash: line 1: /home/ana/pe/bin/toylm: Permission denied
ana@lab:~/pe$ chmod +x ~/pe/bin/toylm
ana@lab:~/pe$ toylm info | head -1
corpus:        761 words in corpus.txt
ana@lab:~/pe$ toylm info
bash: line 1: toylm: command not found
ana@lab:~/pe$ tail -2 ~/.bashrc
# prompt-engineering
export PATH="$HOME/pe/bin:$HOME/pe/.venv/bin:$PATH"
```

The first one is a program saved without `chmod +x`: the file is there and the shell will not run
it. The second is a terminal opened **before** the two lines went into `~/.bashrc`, so its `PATH`
does not include `~/pe/bin`. Open a new terminal, or type `source ~/.bashrc` in the one you have.
If that does not fix it, the last two lines of `~/.bashrc` are the ones to check.

## And the computer runs out of memory

If the model is slow to the point of uselessness, or the whole computer stalls while it answers,
look at the memory `ollama ps` reports against what the computer has free with everything else
open. Closing a browser often frees more than the model needs. If it still does not fit, take
`llama3.2:1b` as described above.

If something fails that is not here, read the first error it printed before anything else. The
lines after it are usually its consequences.
