---
title: Your lab, and three ways to have one
version: 2
---

From lesson 2 on, this course asks you to type. What you type into is **your lab**: your own
computer, or a virtual one on it, running Terraform, the AWS CLI and an emulated AWS. The platform
gives you no machine. These last sections of lesson 1 build the lab, and nothing before them needed
it, because this lesson's transcripts are Ana's and are there to be read.

**There is no cloud account in this course, and nothing in it is billed.** The AWS that Terraform
talks to is **moto**, the emulator the cloud course used for S3. It is a Python program that answers
the AWS APIs on a port of your computer, keeps what it is told in memory, and forgets everything when
it stops. It is a faithful imitation of the *API*: it checks arguments, invents ids, remembers what
was created and answers questions about it. It runs no machine and carries no packet. An instance it
launches is a record with an id and a state, which is exactly what Terraform reads back, so every
plan, apply, state file and error you produce is the one Terraform would produce against AWS. What
you will not see is a web server answering on a machine Terraform made; lessons 18 and 20, which need
machines that run, use Docker containers instead, and lesson 18 builds them.

## Three paths

| | what it is | what it costs your computer |
|---|---|---|
| **a virtual machine** (recommended) | Ubuntu Server 24.04 in a hypervisor on your computer | 2 processors, 4 GB of memory and 25 GB of disk while it runs; a computer with 8 GB of memory runs it comfortably |
| **installed** | the tools directly on Linux, on macOS, or on Windows inside WSL 2 | about 3 GB of disk by lesson 20, and a dozen programs in your own system |
| **online** | a cloud development environment, or a small Linux server rented by the hour | nothing locally; money, once whatever is free runs out |

**The virtual machine is the one this course recommends**, for three reasons. Every transcript in it
was recorded on Ubuntu 24.04, so a VM running the same system prints the same lines. Over twenty
lessons you install about a dozen tools, and in a VM they go into a machine you can delete, not into
the one you work on. And lesson 18 runs three Docker containers as servers and reaches them by their
addresses, which works inside a Linux VM and does not work with Docker Desktop on macOS or Windows,
where the containers live in a hidden VM of Docker's own.

Which hypervisor depends on your computer:

- **Windows**: Hyper-V, built into the Pro, Enterprise and Education editions, or VirtualBox on any
  edition.
- **macOS**: UTM. On a Mac with Apple silicon, download the ARM (`arm64`) image of Ubuntu Server;
  every tool in this course publishes that build.
- **Linux**: virt-manager, the window in front of libvirt and QEMU, or VirtualBox.

On all three, **Multipass**, from Canonical, makes an Ubuntu VM in one command, with no installer
to click through: `multipass launch 24.04 --name iac --cpus 2 --memory 4G --disk 25G`, then
`multipass shell iac` to get a terminal in it. Whichever you use, install the system with OpenSSH
when the installer offers it, so you can work in the VM from your own computer's terminal.

**Installed** is the right choice if you already work on Linux or in WSL 2, and it costs only disk.
On macOS the package commands differ, the next section says how, and lesson 18 needs the VM anyway,
for the Docker reason above.

**Online** means a cloud development environment such as GitHub Codespaces or Gitpod, or a small
Linux server from any provider. Both run Ubuntu and the next section's steps work in them unchanged.
Each comes with some free hours or free credit, and the terms of that are the provider's and change;
**no lesson in this course needs any of them**, so treat them as a convenience you may pay for and
never as a requirement.

**And a real AWS account is optional.** The configurations in these lessons are written for AWS,
and pointing them at it is a matter of unsetting one variable, which the next sections show. From
then on every `apply` creates something that costs money until a `destroy` removes it, and lesson 16
is about that cost.
