---
title: The lab is your own computer
version: 1
---

Nothing in this course runs on a machine we host. **You build the lab on your own computer, and
every command in every lesson is typed there.** It is small: one Python environment with the
libraries the course pins, one directory for the project, and one SQLite file holding the shop. No
database server, no container and no account anywhere.

Every transcript in the course was recorded that way, on Ubuntu 24.04 with four processor cores and
no graphics card, by a user called `ana` on a machine called `dev`. Your prompt will carry your own
names. The project lives in `~/ml` and the environment in `~/mlenv`, and if you use the same two
paths, every command in the course works for you as printed.

## Three ways to have it

| | what it is | what it costs your computer |
| --- | --- | --- |
| **installed** (recommended) | Python 3.12 and the course's libraries on the computer you use every day: directly on Linux, on a Mac, or on Windows inside WSL, Microsoft's Linux layer | 1.0 GB of disk by the last lesson, almost all of it the environment in `~/mlenv`; the largest program in the course, MLflow's page, holds about 480 MB of memory while it runs, started the way lesson 7 starts it |
| in a virtual machine | Ubuntu Server 24.04 LTS in VirtualBox on Windows or Linux, or UTM on a Mac, with the same steps inside it | the VM's own share, reserved while it runs: 2 processor cores, 4 GB of memory and 25 GB of disk |
| online | a Linux machine somebody else runs: a cloud development environment such as GitHub Codespaces, or a small server rented by the hour | nothing on your computer but a browser; an account with the provider, and their terms on how many hours are free |

**Installed is the recommendation because the lab is light and keeps to itself.** Everything the
course installs goes into two directories in your home, `~/mlenv` and `~/ml`, and deleting them
removes all of it; the only system packages are three Ubuntu ships anyway. Nothing here wants a
graphics card, a service that starts at boot or a port open to the network.

**A virtual machine is the path if you would rather keep your own system untouched**, or if your
computer runs something old enough that Python 3.12 will not install on it. Give it at least the
sizes in the table. The next section's steps then run inside the VM, exactly as written.

**Online works for the whole course, with one difference you will notice.** Lessons 7 and 8 start
two programs that answer on a port of the machine, MLflow's page and the model's web service, and
read them in a browser. On your own computer that address is `127.0.0.1`; on a machine somebody
else runs, the provider forwards the port to a link of its own, and its documentation says how. **No
lesson depends on a provider's free allowance**: one may exist when you read this, and it is the
provider's to change.

## What you need to know already

This course assumes `python` and `pipelines-etl`. You will read Python programs of fifty to a
hundred lines, run them, and change a line here and there; you will read SQL with a `WITH` and a
`GROUP BY` in it. You will not be asked to derive anything, and nothing needs more mathematics than
a percentage and an average.
