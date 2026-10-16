---
title: Your lab, in brief
version: 1
---

**This course is practised against moto, an open-source imitation of the AWS API, with the real
AWS command line and no AWS account.** Every command in it runs on your own computer, costs
nothing and reaches nobody. The four AWS courses of this school share one environment, and
`aws-foundations` builds it in its lesson 1, with each path explained and a section on what goes
wrong. If you did that course and kept the lab, skip to the check at the end of this section.
If not, the steps are below in brief, and they build exactly the same thing.

## What moto is, and what it is not

moto is a Python program that listens on a port of your computer and answers the way AWS answers.
Ask it to launch an instance and it returns an instance id, a state and an Availability Zone, in
the same JSON the real service returns. **What it does not do is run anything.** There is no
machine behind that id, no disk behind a volume and no container behind an ECS task: each one is a
record moto keeps in memory and forgets when it stops.

That makes it the right tool for most of this course, which is about the shape of things: what a
launch template holds, how a group decides how many instances to keep, what a task definition
says. It makes it the wrong tool for three things, and the lessons say so each time:

- **moto enforces much less than AWS.** By default it does not evaluate IAM policies at all, so a
  call a policy should deny succeeds. It accepts limits AWS would refuse and skips checks AWS
  makes.
- **Nothing it reports is a measurement.** A spot price, a CPU figure or a timing from moto is a
  placeholder. Every price in this course comes from AWS's published price list instead, read by a
  program the next section shows you whole.
- **Some services are not there.** App Runner is the one this course needs, and lesson 22 teaches
  it from AWS's documentation and says so.

Where a lesson needs code to really run, as with Lambda from lesson 14, it runs it on your own
computer with the runtime AWS publishes, and that lesson shows how.

## Three ways to have the lab

**Recommended: install it on Ubuntu 24.04**, on your own computer or in a virtual machine you
already have. It needs about 700 MB of disk and nothing else running. A **virtual machine**
(VirtualBox, or Multipass on Windows and macOS) costs a few gigabytes of disk and 2 GB of memory
while it runs, and gives you a clean Ubuntu to break. An **online environment** such as GitHub
Codespaces needs no installation and gives you a terminal in the browser, at the price of a monthly
allowance of hours that you should check before relying on it. `aws-foundations` lesson 1 walks
through all three; the commands below are the same in each.

## The commands

The packages come from Ubuntu's own archive, and this is the only step that needs `sudo`:

```sh
sudo apt-get update
sudo apt-get install -y python3 python3-venv curl unzip jq
```

The AWS command line, version 2.37.4, installed into your home directory. On an Arm processor,
which includes a virtual machine on a Mac with Apple silicon, the file name ends in `aarch64`
instead of `x86_64`:

```sh
mkdir -p ~/aws ~/.local/bin
cd ~/aws
curl -sS -o awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.37.4.zip
unzip -q awscliv2.zip
./aws/install -i ~/.local/aws-cli -b ~/.local/bin
rm -rf aws awscliv2.zip
```

moto, in a virtual environment of its own, so it touches nothing else on the machine:

```sh
python3 -m venv ~/aws/venv
~/aws/venv/bin/pip install -q 'moto[server]==5.2.3'
```

**Every time you open a terminal to work**, these lines go first. They put both tools on your path,
point the command line at moto rather than at AWS, give it the two words moto accepts as
credentials, and choose São Paulo as the region:

```sh
cd ~/aws
source venv/bin/activate
export PATH="$HOME/.local/bin:$PATH"
export AWS_ENDPOINT_URL=http://localhost:4567
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=sa-east-1 AWS_PAGER=
```

`AWS_PAGER=` stops the command line from opening long answers in a pager, so what you see is what
the lessons show. Your prompt gains `(venv)` at the front; the transcripts leave it out.

And moto itself runs in **a terminal of its own**, which you leave open while you work:

```sh
~/aws/venv/bin/moto_server -p 4567
```

It prints a line saying it is running on `http://127.0.0.1:4567` and then waits. Stopping it with
Ctrl+C empties it, which is a feature: **every lesson starts from an empty moto**, and the
transcripts were recorded that way.

## Checking it answers

In your working terminal:

```
ana@laptop:~/aws$ aws --version
aws-cli/2.37.4 Python/3.14.6 Linux/6.18.44-fc-v139 exe/x86_64.ubuntu.24
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:user/moto"
}
```

**`123456789012` is moto's account**, the one every resource in this course belongs to, and
`AKIAIOSFODNN7EXAMPLE` is the example key from AWS's own documentation, which no real account has.
Your `Linux/` part names your own kernel and will differ.

## When it does not answer

Three failures cover nearly everything. **moto is not running**, or is running in a terminal you
closed:

```
ana@laptop:~/aws$ aws sts get-caller-identity

aws: [ERROR]: Could not connect to the endpoint URL: "http://localhost:4567/"
```

Start it again in its own terminal. **The port is taken**, because a `moto_server` is already
running somewhere, and the new one stops at once:

```
ana@laptop:~/aws$ ~/aws/venv/bin/moto_server -p 4567
Address already in use
Port 4567 is in use by another program. Either identify and stop that program, or start the server with a different port.
```

The other one is probably in a terminal you forgot; `ss -ltnp | grep 4567` names the process.

And the third is the one worth understanding. **The endpoint line was not typed in this
terminal**, so the command line went to the real AWS, which knows nothing of the word `test`:

```
ana@laptop:~/aws$ aws sts get-caller-identity

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the GetCallerIdentity operation: The security token included in the request is invalid.
```

That refusal is AWS's, not moto's, and it is harmless: nothing was created and nothing was billed.
It is also the reason **you never give this command line a real key during the course**. Every
command here is written for moto, and the one line between it and a real account is an
environment variable a new terminal forgets.
