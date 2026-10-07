---
title: Your machine, and three ways to have one
version: 1
---

The two sections before this one read `toylm` from transcripts. From here on, run the commands
yourself. Prompt engineering is learnt the way a recipe is: by changing one thing and seeing what
came out. This section sets up the computer, and the next one builds the directory every lesson
works in.

The machine needs three things:

- **a Linux terminal with Python 3 and Node.js**, for the small programs the lessons print whole:
  a model you can read, a real tokenizer, a schema checker and a few more;
- **Ollama**, a free program that runs a language model on your own computer, with no account and
  no card;
- **one model for it, `llama3.2:3b`**: Meta's Llama 3.2 with three billion parameters, small enough
  for an ordinary laptop. Every AI course here uses the same one, so you set it up once.

## Three ways to have one

| path | what you get | what it costs | the transcripts |
|---|---|---|---|
| **installed** (recommended) | Ubuntu 24.04 on your computer, or in WSL on Windows | about 4 GB of disk, and 3 GB of memory while the model answers | match as printed |
| **a virtual machine** | Ubuntu Server 24.04, apart from your own system | the same, plus the guest's own system and memory | match as printed, slower |
| **online** | a Linux machine you rent by the hour | nothing on your computer; a bill per hour | close, not exact |

**Installed is the recommended path**, which is the opposite of what most courses here say, and the
model is the reason. It is the heaviest thing in the course by far, and it runs fastest on the bare
computer. A virtual machine takes a fixed share of the memory for itself and, on most hypervisors,
cannot reach the graphics card at all. The rest of the setup is two ordinary packages and one
directory in your home folder, all of which come off again cleanly.

- **On Linux**, run the commands below. They were run on Ubuntu 24.04; another distribution has the
  same programs under its own package names.
- **On Windows**, install WSL with Ubuntu 24.04 (`wsl --install -d Ubuntu-24.04` in a PowerShell
  opened as administrator, then a restart) and type everything below into the Ubuntu window.
- **On macOS**, Ollama has its own app at ollama.com, and Python and Node.js come from Homebrew
  (`brew install python node`). That was not run for this course, so a version in a transcript
  will differ from yours, and the programs themselves work the same.

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
sudo apt-get install -y python3-venv nodejs npm curl zstd
```

Then Ollama, with the installer its makers publish. It puts the program in `/usr/local`, and makes it
a service that starts with the machine:

```sh
curl -fsSL https://ollama.com/install.sh | sh
```

Then the model. This downloads 2.0 GB, once:

```sh
ollama pull llama3.2:3b
```

Check what you have:

```
ana@lab:~$ python3 --version; node --version; ollama --version
Python 3.12.3
v18.19.1
ollama version is 0.40.0
ana@lab:~$ ollama list
NAME           ID              SIZE      MODIFIED    
llama3.2:3b    a80c4f17acd5    2.0 GB    2 hours ago    
ana@lab:~$ ask "Say hello in three words." --temperature 0 --plain
Hello there friend.
ana@lab:~$ ollama ps
NAME           ID              SIZE      PROCESSOR          CONTEXT    RUNNER      UNTIL              
llama3.2:3b    a80c4f17acd5    2.9 GB    30%/70% CPU/GPU    4096       llamacpp    4 minutes from now    
ana@lab:~$ du -sh /usr/local/lib/ollama
2.1G	/usr/local/lib/ollama
```

`ollama list` is what is on the disk, and `ollama ps` is what is in memory: the model loads the
first time something asks it a question, takes **2.9 GB** while it is loaded, and is unloaded five
minutes after the last question. That is the number to compare with your computer. The program
itself took another 2.1 GB, most of it libraries for NVIDIA graphics cards, which it uses if there is
one.

The `PROCESSOR` column says where the work ran. The computer these lessons were recorded on has no
graphics card, and Ollama counted the processor's own matrix unit as an accelerator, which is why
it does not read `100% CPU`. On yours it says `100% CPU`, or names the share your graphics card
took.

`ask` is a program the next section gives you. Until then, `ollama run llama3.2:3b` opens a
conversation with the model in the terminal; type a question, and Ctrl+D leaves.

### With less memory

On a computer with 8 GB of memory or less, take the smaller model in the same family:

```sh
ollama pull llama3.2:1b
```

It downloads 1.3 GB and took 2.0 GB of memory on the same machine. Its answers are noticeably
worse, which is a lesson of its own, and they will differ more from the transcripts here. The next
section says how to make `ask` use it.

### With an API key instead

The other path is a model you pay for, from a provider of your choice. `ask` speaks the same
protocol most of them serve, called chat completions, and three variables in `~/.bashrc` point it
somewhere else: `ASK_URL`, the address of the provider's API; `ASK_MODEL`, the model's name there;
and `ASK_KEY`, your key. The provider's documentation gives the first two. Every request costs
money, and lesson 3 shows how to work out how much before you send anything. **Nothing in the course needs it.** The local model is enough to finish
every lesson.
