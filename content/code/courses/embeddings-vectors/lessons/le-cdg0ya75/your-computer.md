---
title: Your computer is the lab
version: 1
---

Everything in this course runs on your own computer: the embedding models, the vector databases,
and a small server that stands in for the providers' APIs. Nothing here needs an account or a
card. What it does need is a Linux terminal, and this section is about where that terminal lives.

## What the course needs

- **Ubuntu 24.04.** Every transcript in the course was recorded on it, by Ana, a developer at the
  bookshop the lessons are about, in a directory called `~/emb`. Your prompt will show your own
  name and machine instead of `ana@lab`, and nothing else in the output should differ.
- **About 2 GB of disk** for Python's libraries, the model and the data. The next section measures
  it.
- **About 4 GB of memory free.** The largest program in the course, lesson 11's search over a
  million vectors, reached 3 GB on the machine the course was recorded on, and nothing else went
  past 1.4 GB.
- **An internet connection during the setup**, to download the libraries and the model. After
  that, three things reach the network once each: in lesson 7 the tokeniser table `tiktoken` reads
  and the price sheet, and in lesson 12 Chroma's own copy of the model.

Any computer from the last ten years has that. What differs is the way you get Ubuntu onto it, and
there are three.

## Three ways to get there

**Recommended: installed, on the computer you already use.** On a Linux computer, if it runs Ubuntu
24.04, there is nothing to do. On Windows 10 or 11, WSL runs Ubuntu inside Windows, with a
terminal of its own. Open PowerShell as administrator, type `wsl --install -d Ubuntu-24.04`,
restart when it asks, open *Ubuntu 24.04* from the Start menu, and choose a user name and a
password. That terminal is where every command in the course goes. WSL needs the disk above plus
Ubuntu's own files, and it takes memory from Windows only while it runs.

**A virtual machine**, for a Mac, or for anybody who would rather keep the course apart from their
own system. Install **Ubuntu Server 24.04 LTS** as a guest: in VirtualBox on Windows or Linux, and
in UTM on a Mac. Give it 2 processors, 25 GB of disk and at least 4 GB of memory, 5 if your computer
can spare them. That memory is taken from your computer for as long as the machine runs, so it
wants a computer with 8 GB or more. Lesson 4
of the course `virtualization` creates a machine in VirtualBox step by step, if you have not done
it before.

**Online**, when your own computer cannot do either. A small Linux machine rented from a cloud
provider, or a GitHub Codespace, gives you a terminal in the browser. Choose Ubuntu 24.04 where you
are offered a choice. Some of them have a free allowance; none of this course depends on it, and
once it runs out the machine is billed by the hour, so stop it when you are not studying.

All three end the same way: a terminal on Ubuntu 24.04. The next section starts there.
