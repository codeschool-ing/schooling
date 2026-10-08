---
title: Installing the tools
version: 1
---

Everything below runs in a terminal on Ubuntu 24.04, as your own user, and only the first block
asks for `sudo`. **Everything else lands in two places: the directory `~/cloud`, which is where
you work for the rest of the course, and `~/.local`, where the AWS command line goes.** Deleting
those two, and `~/.cache/cloud-prices` once the next section has filled it, removes the lab
completely.

## The packages from Ubuntu

Python, `curl` and `jq` come from Ubuntu's own archive, with `unzip` and `git` to fetch the two
tools that do not:

```sh
sudo apt-get update
sudo apt-get install -y python3 python3-venv curl jq unzip git
```

**`python3-venv` is the one people leave out**, because Ubuntu ships Python without it. Without it
the virtual environment in the third block fails, and the section on failures shows the message.

## The AWS command line

AWS publishes its command line as a zip file with an installer inside. These commands download one
fixed version, the one every transcript in this course was recorded with, and install it into your
home directory, so it needs no `sudo`:

```sh
mkdir -p ~/cloud ~/.local/bin
cd ~/cloud
curl -sS -o awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.37.4.zip
unzip -q awscliv2.zip
./aws/install -i ~/.local/aws-cli -b ~/.local/bin
rm -rf aws awscliv2.zip
```

A newer version works for everything this course does. The version line and the wording of a few
error messages will differ from the lessons, and nothing else will. On a computer with an Arm
processor, which includes a virtual machine on a Mac with Apple silicon, the file is
`awscli-exe-linux-aarch64-2.37.4.zip` instead.

**You will never give this command line a key.** It is used for what it can do with none: print the
shape of a request, check a file, refuse a call it cannot sign, and talk to the imitation of S3 that
lesson 5 runs.

## Two Python tools, in one virtual environment

A virtual environment is a directory holding its own copy of Python's package installer, so what
you install there touches nothing else on the machine. Two tools go into this one. **moto**
imitates the S3 interface for lesson 5, and the packages **cloud-init** needs to check a boot
configuration in lesson 4. Cloud-init itself is not published on PyPI, so it comes from its own
source code, at version 26.2, with a three-line script that runs it:

```sh
python3 -m venv ~/cloud/venv
git clone -q --depth 1 --branch 26.2 https://github.com/canonical/cloud-init ~/cloud/cloud-init
~/cloud/venv/bin/pip install -q 'moto[server]==5.2.3' -r ~/cloud/cloud-init/requirements.txt
cat > ~/.local/bin/cloud-init <<'EOF'
#!/bin/sh
PYTHONPATH="$HOME/cloud/cloud-init" exec "$HOME/cloud/venv/bin/python3" -m cloudinit.cmd.main "$@"
EOF
chmod +x ~/.local/bin/cloud-init
```

The script sets `PYTHONPATH` to the source directory, so Python finds cloud-init's code there, and
starts it with the environment's Python, which holds the packages cloud-init depends on.

## Every time you open a terminal

Two lines put the tools on your path, and every lesson assumes you typed them:

```sh
cd ~/cloud
export PATH="$HOME/.local/bin:$PATH" && source venv/bin/activate
```

The first is where the course's files go. The second adds `~/.local/bin`, where `aws` and
`cloud-init` are, and switches to the virtual environment, which puts `moto_server` on the path
and makes `python3` the environment's own. Your prompt gains `(venv)` at the front; the transcripts
in the lessons leave it out.

Then check each tool answers:

```
ana@laptop:~/cloud$ aws --version
aws-cli/2.37.4 Python/3.14.6 Linux/6.18.44-fc-v77 exe/x86_64.ubuntu.24
ana@laptop:~/cloud$ jq --version
jq-1.7
ana@laptop:~/cloud$ python3 --version
Python 3.12.3
ana@laptop:~/cloud$ moto_server --help | head -1
usage: moto_server [-h] [-H HOST] [-p PORT] [-r] [-s] [-c SSL_CERT]
ana@laptop:~/cloud$ cloud-init schema --help | head -1
usage: /home/ana/cloud/cloud-init/cloudinit/cmd/main.py schema
ana@laptop:~/cloud$ du -sh ~/cloud ~/.local/aws-cli
319M	/home/ana/cloud
273M	/home/ana/.local/aws-cli
```

**`aws` brings its own Python**, 3.14.6, inside the 273 MB it installed, and that is why its
version line names a different one from Ubuntu's 3.12.3. **Some 600 MB of disk is the cost so
far.** The next section adds the price list, which is larger.
