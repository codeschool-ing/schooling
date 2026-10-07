---
title: Your machine, and three ways to have one
version: 1
---

Every lesson from here on runs commands on a real computer: small programs that check a model's
replies, and in a few lessons a real model writing those replies. This section sets up that
computer. The next one builds the directory every lesson works in.

The machine needs three things:

- **a Linux terminal with Python 3**, for the programs the lessons print whole. They use nothing
  but Python's own library, so there is no package to install for them;
- **Ollama**, a free program that runs a language model on your own computer, with no account and
  no card;
- **one model for it, `llama3.2:3b`**: Meta's Llama 3.2 with three billion parameters, small enough
  for an ordinary laptop. Every AI course here uses the same one, so if you set it up for
  `prompt-engineering` you have it already.

## Three ways to have one

| path | what you get | what it costs | the transcripts |
|---|---|---|---|
| **installed** (recommended) | Ubuntu 24.04 on your computer, or in WSL on Windows | about 2 GB of disk for the model, and 3 GB of memory while it answers | match as printed |
| **a virtual machine** | Ubuntu Server 24.04, apart from your own system | the same, plus the guest's own system and memory | match as printed, slower |
| **online** | a Linux machine you rent by the hour | nothing on your computer; a bill per hour | close, not exact |

**Installed is the recommended path**, and the model is the reason. It is the heaviest thing in the
course by far, and it runs fastest on the bare computer. A virtual machine takes a fixed share of the
memory for itself and, on most hypervisors, cannot reach the graphics card at all. The rest of the
setup is one directory in your home folder, which comes off again with one `rm`.

- **On Linux**, run the commands below. They were run on Ubuntu 24.04; another distribution has the
  same programs under its own package names.
- **On Windows**, install WSL with Ubuntu 24.04 (`wsl --install -d Ubuntu-24.04` in a PowerShell
  opened as administrator, then a restart) and type everything below into the Ubuntu window.
- **On macOS**, Ollama has its own app at ollama.com, and macOS already has a Python 3 once the
  command-line tools are installed (`xcode-select --install`). That was not run for this course, so a
  version in a transcript will differ from yours, and the programs work the same.

**A virtual machine** is the path for a computer you would rather not change. Use Ubuntu Server
24.04 LTS as the guest: VirtualBox on Windows and Linux, UTM on macOS. Give it at least 6 GB of
memory and 25 GB of disk, because the model needs about 3 GB of that memory to itself. Expect the
replies to come more slowly than they would outside it.

**Online**, any cloud provider rents a Linux machine by the hour, and GitHub Codespaces gives one in
the browser. Pick one with at least 8 GB of memory. A free allowance may cover part of the course,
on terms the company sets and can change, so plan as if you will pay. It was not run for this
course.

## Installing it

Everything below is typed in a terminal on the machine you chose. First Ubuntu's own packages:

```sh
sudo apt-get update
sudo apt-get install -y python3 curl zstd
```

Then Ollama, with the installer its makers publish. It puts the program in `/usr/local`, and on a
machine that runs `systemd`, which Ubuntu does, it makes it a service that starts with the machine:

```sh
curl -fsSL https://ollama.com/install.sh | sh
```

Then the model. This downloads 2.0 GB, once:

```sh
ollama pull llama3.2:3b
```

Check what you have:

```
ana@lab:~$ python3 --version; ollama --version
Python 3.12.3
ollama version is 0.40.0
ana@lab:~$ ollama list
NAME           ID              SIZE      MODIFIED       
llama3.2:3b    a80c4f17acd5    2.0 GB    18 minutes ago    
ana@lab:~$ ollama run llama3.2:3b "Say hello in five words."
Hello, it's nice to chat.

ana@lab:~$ ollama ps
NAME           ID              SIZE      PROCESSOR          CONTEXT    RUNNER      UNTIL              
llama3.2:3b    a80c4f17acd5    2.9 GB    30%/70% CPU/GPU    4096       llamacpp    4 minutes from now    
```

`ollama list` is what is on the disk, and `ollama ps` is what is in memory: the model loads the first
time something asks it a question, takes **2.9 GB** while it is loaded, and is unloaded five minutes
after the last question. That is the number to compare with your computer.

The `PROCESSOR` column says where the work ran. The computer these lessons were recorded on has no
graphics card, and Ollama counted the processor's own matrix unit as an accelerator, which is why it
does not read `100% CPU`. On yours it says `100% CPU`, or names the share your graphics card took.

### With less memory

On a computer with 8 GB of memory or less, take the smaller model in the same family:

```sh
ollama pull llama3.2:1b
```

It downloads 1.3 GB and took 2.0 GB of memory on the same machine. Its answers are noticeably worse, and they will differ
more from the transcripts here. The next section says how to point the course's programs at it.

### With an API key instead

The other path is a model you pay for, from a provider of your choice. The one program in this course
that talks to a model speaks chat completions, the protocol most providers serve, and three
variables point it somewhere else; the next section names them. Every request costs money. **Nothing
in the course needs it.** The local model is enough to finish every lesson.
