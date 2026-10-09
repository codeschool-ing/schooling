---
title: Where the model runs, and the path to pick
version: 1
---

This course sends e-mail to language models and reads what comes back, and the platform runs no
model for you. The one you use is one you put somewhere yourself. The recommendation is the same in
every AI course here: **Ollama**, a free program that runs open models on your own computer, with
**`llama3.2:3b`**, a three-billion-parameter model from Meta. Ollama needs no account and no card,
and nothing you send it leaves the machine.

It can live in three places:

| path | what you get | what it costs your computer |
|---|---|---|
| **installed** (recommended) | Ollama and Python on the computer you already use | 2.0 GB of disk for the model, and 2.6 GB of memory while it answers |
| **in a virtual machine** | Ubuntu Server 24.04, with Ollama inside it, apart from your system | a 30 GB disk image, and 6 GB of memory while it runs, the model's 2.6 GB among them |
| **online** | a Linux machine you rent, reached from your browser or a terminal | nothing on your computer; an hourly price set by whoever rents it |

The two sizes come from the next section's own transcripts: `ollama list` reports what the model
takes on disk, and `ollama ps` what it takes in memory once loaded.

## Installed, which is the one to pick

Ollama runs on Windows, macOS and Linux, and every lesson after this one assumes it is on the
machine in front of you, answering at `http://127.0.0.1:11434`. A computer with **8 GB of memory**
runs `llama3.2:3b` with room left for a browser and an editor. It does not need a graphics card:
the transcripts in this course were taken on one with none, four processors and 16 GB, and every
answer came back in a few seconds. A graphics card makes it faster, and Ollama finds one by itself.

**With 4 GB, take the smaller model**, `llama3.2:1b`: 1.3 GB on disk and 1.5 GB in memory. It
answers the same questions less well, which lesson 5 measures, and every program in the course runs
with it if you change the model's name.

## In a virtual machine

Pick this if the computer is one you may not install software on, or if you want Linux anyway.

1. **A hypervisor**, the program that runs it: VirtualBox on Windows and Linux, UTM on a Mac, or
   Hyper-V on Windows if it is already switched on.
2. **Ubuntu Server 24.04 LTS**, from ubuntu.com. On a Mac with Apple silicon, the ARM image.
3. **A machine with 6 GB of memory**, 4 processors and a 30 GB disk that grows as it is written.
   The model needs its 2.6 GB inside the guest, and the guest needs its own memory besides.
4. **Sign in, and follow the Linux instructions** in the next sections, which were recorded on
   exactly this system.

A virtual machine does not reach your graphics card, so the model runs on the processor and is
slower than the same model installed. On Windows, **WSL** with Ubuntu 24.04 is the lighter version:
`wsl --install -d Ubuntu-24.04` in a PowerShell opened as administrator, then the Linux
instructions. `virtualization` builds and tunes a virtual machine properly, in lesson 4.

## Online

A Linux machine rented by the hour from any cloud company works like the virtual machine path,
without using your computer at all: Ubuntu Server 24.04, at least 8 GB of memory, and the Linux
instructions. Switch it off between sessions, because it is billed while it runs. No lesson
depends on one company's offer, free or paid.

## And a key instead of a model

There is a second way to get answers, and it replaces Ollama rather than the computer: **an API key
of your own** from a provider such as Anthropic or OpenAI. Every program in the course reads its
address and key from one file, `desk.env`, which section 04 writes, so a key is a two-line change.
It is **never required**, it is billed per request, and lessons 6 to 9 say what each provider
charges. The transcripts here are all `llama3.2:3b`, and with a key your answers come from a
different model, so they will differ more than the next paragraph allows for.

**A model's answer differs from run to run.** The same question gives you different wording, and
sometimes a different answer, from the one printed in a lesson. That is not a fault in your setup.
Lesson 5 section 08 measures it, and says when it matters.
