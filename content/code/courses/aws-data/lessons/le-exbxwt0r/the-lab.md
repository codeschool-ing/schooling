---
title: Your lab, in brief
version: 1
---

**This course is practised against moto, on your own computer, with the real AWS command line and
no AWS account.** It is the same environment all four AWS courses use, and lesson 1 of
`aws-foundations` builds it step by step, with the three ways to have it and a section on what goes
wrong. If you did that lesson and kept the lab, skip to "Every time you open a terminal" below. If
you did not, or you deleted it, the steps are here in brief. The platform runs nothing for you: no
machine, no shell in the browser, no account.

**Ubuntu 24.04 is where every transcript was recorded**, and three ways to have it work. Installed
is the one recommended, either as your system or under WSL on Windows (`wsl --install -d
Ubuntu-24.04` in an administrator PowerShell). A virtual machine is the path on a Mac: Ubuntu Server
24.04 in UTM, VirtualBox or Multipass, with 2 processors, 4 GB of memory and 15 GB of disk. An online
shell rented by the hour works too, because nothing here needs more than a terminal with the
network, but no lesson depends on any company's free allowance. On your own disk the whole lab comes
to about 800 MB, and nothing in it runs unless you start it.

## The packages from Ubuntu

```sh
sudo apt-get update
sudo apt-get install -y python3 python3-venv curl unzip jq
```

## The AWS command line

Version 2.37.4, into your home directory, so it needs no `sudo`:

```sh
mkdir -p ~/aws ~/.local/bin
cd ~/aws
curl -sS -o awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.37.4.zip
unzip -q awscliv2.zip
./aws/install -i ~/.local/aws-cli -b ~/.local/bin
rm -rf aws awscliv2.zip
```

On an Arm processor, which includes a virtual machine on a Mac with Apple silicon, the file is
`awscli-exe-linux-aarch64-2.37.4.zip`.

## moto, in a virtual environment

```sh
python3 -m venv ~/aws/venv
~/aws/venv/bin/pip install -q 'moto[server]==5.2.3'
```

## Two more, for this course

**This is the one step `aws-foundations` does not have.** Athena and Redshift Spectrum run SQL over
files in S3, and moto accepts such a query and runs nothing, as the section after next shows. So the
lessons from 15 on read the same files with **DuckDB**, a database engine that lives inside a Python
program. They write them with **PyArrow**, the library that reads and writes Parquet:

```sh
~/aws/venv/bin/pip install -q duckdb==1.5.6 pyarrow==25.0.1
```

## Two terminals

**moto runs in a terminal of its own**, and stays in the foreground there, printing one line per
request it answers. Open a terminal and type:

```sh
cd ~/aws && source venv/bin/activate
moto_server -p 4567
```

Leave it running. `Ctrl+C` stops it, and **stopping it forgets everything**: every bucket, table and
stream it held. Each lesson in this course starts from an empty moto and builds what it needs, so
you can stop it at the end of a sitting with nothing lost that a lesson does not rebuild.

## Every time you open a terminal

In a second terminal, the one you type into for the rest of the course:

```sh
cd ~/aws
export PATH="$HOME/.local/bin:$PATH" && source venv/bin/activate
export AWS_ENDPOINT_URL=http://localhost:4567 AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=sa-east-1 AWS_PAGER=
```

The first line is where the course's files go. The second puts `aws` on the path and switches to the
virtual environment. **The third is the whole trick**: `AWS_ENDPOINT_URL` sends every request the
command line makes to moto instead of to Amazon, and the two keys are the word `test`, which moto
accepts and AWS refuses. The fourth puts you in São Paulo, and the empty `AWS_PAGER` stops the
command line from opening a long answer in `less`, the one setting here that is a convenience
rather than part of the shared lab.

## Check that it answers

```
ana@laptop:~/aws$ aws --version
aws-cli/2.37.4 Python/3.14.6 Linux/6.18.44-fc-v139 exe/x86_64.ubuntu.24
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:user/moto"
}
ana@laptop:~/aws$ aws s3 ls
ana@laptop:~/aws$ du -sh ~/aws ~/.local/aws-cli
516M	/home/ana/aws
273M	/home/ana/.local/aws-cli
```

**The account is `123456789012`, and that is the proof you are talking to moto**: it is the example
number AWS's own documentation uses, and moto gives it to every account it imitates. The empty
answer to `aws s3 ls` is an empty S3. If you see a twelve-digit number of your own instead, or an
error, the next section is the one to read.
