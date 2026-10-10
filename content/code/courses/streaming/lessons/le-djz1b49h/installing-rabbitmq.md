---
title: Installing RabbitMQ, and an emulator for SQS and SNS
version: 1
---

**RabbitMQ is in Ubuntu's archive, and so is the Erlang runtime it is written in.** Ubuntu 24.04 has
RabbitMQ 3.12; the RabbitMQ team publishes newer versions from its own repositories, and everything
this lesson does works the same on them. Install it, and the Python client for it:

```sh
sudo apt-get install -y rabbitmq-server
pip install pika==1.4.4
```

On a virtual machine, the install starts the server straight away under systemd, as a service
that also starts at every boot, listening for clients on port 5672. **That start did not happen on
the machine this course was recorded on**, which has no systemd; there the server was started by
hand with `sudo rabbitmq-server -detached`, which does the same job without a service manager. On
yours, check it is up:

```
ubuntu@stream:~/work$ sudo rabbitmq-diagnostics ping
```

`rabbitmqctl` and `rabbitmq-diagnostics` talk to the server as an administrator, which is why they
need `sudo`: they refuse to run as an ordinary user. **pika** is the client your programs use, and
it connects as RabbitMQ's built-in user `guest`, whose password is `guest` and which is allowed to
connect from `localhost` only. That restriction is the whole of its security, and it is enough for
a server that listens on a machine nobody else uses. A server anybody else can reach gets its own
users and deletes `guest`, as RabbitMQ's own production checklist says.

## SQS and SNS, without an AWS account

Amazon SQS and SNS are services: there is nothing to install, and using them needs an AWS account
and a bill. This course runs them through **moto**, a Python library that imitates AWS's APIs, run
as a local server. It is an **emulator, not AWS**: it answers the same requests with the same
shapes, and it implements the behaviour this lesson looks at, but timings, limits and prices are
Amazon's to decide, and nothing measured against moto says anything about them. `boto3` is AWS's
own Python client, the one you would use against the real thing:

```sh
pip install 'moto[server]==5.2.3' boto3==1.43.111
```

The `[server]` extra brings the web server that lets moto run as a separate process, and it pulls in
several dozen packages with it; they all stay inside `~/venv`. Nothing is started yet. The SQS
section later in this lesson starts it, in the second shell.
