---
title: Ollama and the course's model
version: 1
---

**Ollama** is two things: a server that keeps models in memory and answers requests on port 11434,
and a command, `ollama`, that talks to it. Lesson 14 is about it in detail. Here it only has to be
installed and answering.

## Installing it

**Windows and macOS:** the installer from ollama.com/download. It puts the server in the background,
starts it with the computer, and adds the `ollama` command to the terminal. Neither was run for this
course, which was recorded on Linux.

**Linux,** and the virtual machine and online paths: Ollama's own script. It needs `zstd` to
unpack what it downloads, and a minimal Ubuntu may not have it, so install that first; on a machine
that already has it, the line changes nothing:

```
ana@desk:~$ sudo apt-get install -y -q zstd > /dev/null && zstd --version
debconf: delaying package configuration, since apt-utils is not installed
*** Zstandard CLI (64-bit) v1.5.5, by Yann Collet ***
ana@desk:~$ curl -fsSL https://ollama.com/install.sh | sh
>>> Installing ollama to /usr/local
>>> Downloading ollama-linux-amd64.tar.zst
######################################################################## 100.0%
>>> Adding ollama user to video group...
>>> Adding current user to ollama group...
>>> Creating ollama systemd service...
WARNING: systemd is not running
WARNING: Unable to detect NVIDIA/AMD GPU. Install lspci or lshw to automatically detect and install GPU dependencies.
>>> The Ollama API is now available at 127.0.0.1:11434.
>>> Install complete. Run "ollama" from the command line.
ana@desk:~$ ollama --version
ollama version is 0.40.0
```

The two warnings are about this machine and not about the install. *systemd is not running* means
the script could not register the server as a service that starts with the computer; on an ordinary
Ubuntu, in a virtual machine or on a rented one, systemd is running and the line is not there. If
you see it, start the server yourself, in a terminal of its own, with `ollama serve`, and leave that
terminal open. *Unable to detect NVIDIA/AMD GPU* means there is no graphics card to use, so the
model runs on the processor.

## The model

`ollama pull` downloads a model by name and tag. The tag after the colon is the size, and writing it
out matters: lesson 14 shows that a name without a tag means whatever Ollama's library calls
`latest` that day.

```
ana@desk:~$ ollama pull llama3.2:3b
pulling manifest
pulling dde5aa3fc5ff: 100% ▕█████████████████████████████████████ ▏ 2.0 GB/2.0 GB  208 MB/s      0s
pulling 34bb5ab01051: 100% ▕██████████████████████████████████████▏  561 B
verifying sha256 digest
writing manifest
success
```

The first time you ask, the server loads the model from disk into memory, which takes a few seconds,
and then answers:

```
ana@desk:~$ ollama run llama3.2:3b 'In one sentence: what does an online bookshop do?'
An online bookshop allows customers to browse, purchase, and have books shipped to their
homes, often with features such as personalized recommendations, customer reviews, and e-books
available for digital download.
```

**Your answer will be worded differently.** A model chooses each word with some randomness, which
lesson 5 section 08 measures, so the same question gives a different sentence on every machine and
on every run. What should match is the kind of answer: one sentence about selling books online.

Two commands say what the model costs your computer. `ollama list` is the disk, and `ollama ps` is
the memory, for as long as the model stays loaded:

```
ana@desk:~$ ollama list
NAME           ID              SIZE      MODIFIED       
llama3.2:3b    a80c4f17acd5    2.0 GB    23 seconds ago    
ana@desk:~$ ollama ps
NAME           ID              SIZE      PROCESSOR    CONTEXT    RUNNER      UNTIL              
llama3.2:3b    a80c4f17acd5    2.6 GB    100% CPU     4096       llamacpp    4 minutes from now    
```

**2.0 GB on disk and 2.6 GB in memory.** The memory is larger because the server sets aside room for
the conversation as well as the weights, which lesson 3 works out. *4 minutes from now* is when
Ollama will unload it if nobody asks anything, and lesson 14 changes that. `100% CPU` means it is
running on the processor.

## The smaller one

On a computer with 4 GB of memory, pull `llama3.2:1b` as well, and use it wherever a lesson says
`llama3.2:3b`:

```
ana@desk:~$ ollama pull llama3.2:1b
pulling manifest
pulling 74701a8c35f6: 100% ▕██████████████████████████████████████▏ 1.3 GB
pulling 966de95ca8a6: 100% ▕██████████████████████████████████████▏ 1.4 KB
pulling fcc5a6bec9da: 100% ▕██████████████████████████████████████▏ 7.7 KB
pulling a70ff7e570d9: 100% ▕██████████████████████████████████████▏ 6.0 KB
pulling 4f659a1e86d7: 100% ▕██████████████████████████████████████▏  485 B
verifying sha256 digest
writing manifest
success
ana@desk:~$ ollama list
NAME           ID              SIZE      MODIFIED       
llama3.2:1b    baf6a787fdff    1.3 GB    10 seconds ago    
llama3.2:3b    a80c4f17acd5    2.0 GB    54 seconds ago    
ana@desk:~$ ollama ps
NAME           ID              SIZE      PROCESSOR    CONTEXT    RUNNER      UNTIL              
llama3.2:1b    baf6a787fdff    1.5 GB    100% CPU     4096       llamacpp    4 minutes from now    
llama3.2:3b    a80c4f17acd5    2.6 GB    100% CPU     4096       llamacpp    4 minutes from now    
```

1.3 GB on disk and 1.5 GB in memory, and two models can be loaded at once if the memory is there.
