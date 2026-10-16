---
title: Installing the lab
version: 1
---

Everything below runs in a terminal on Ubuntu 24.04, as your own user, and only the first block asks
for `sudo`. **Everything else lands in two places: `~/aws`, where you work for the rest of the
course, and `~/.local`, where the AWS command line goes.** Deleting those two, and
`~/.cache/aws-prices` once the last section of this lesson has filled it, removes the lab completely.

If you did the `cloud` course and kept its lab, the AWS command line is already in `~/.local`, at
the same version. If `aws --version` prints `aws-cli/2.37.4`, you can skip the second block.
The `cloud` course's moto ran on another port and in another directory; this one is new.

## The packages from Ubuntu

Python, `curl` and `jq` come from Ubuntu's own archive, with `unzip` to open the AWS installer:

```sh
sudo apt-get update
sudo apt-get install -y python3 python3-venv curl jq unzip
```

**`python3-venv` is the one people leave out**, because Ubuntu ships Python without it. Without it
the third block fails, and the section on failures says what that looks like.

## The AWS command line

AWS publishes its command line as a zip file with an installer inside. These commands download one
fixed version, the one every transcript in this course was recorded with, and install it into your
home directory, so it needs no `sudo`:

```sh
mkdir -p ~/aws ~/.local/bin
cd ~/aws
curl -sS -o awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.37.4.zip
unzip -q awscliv2.zip
./aws/install -i ~/.local/aws-cli -b ~/.local/bin
rm -rf aws awscliv2.zip
```

A newer version works for everything this course does; the version line and the wording of a few
messages will differ from the lessons, and nothing else will. On a computer with an Arm processor,
which includes a virtual machine on a Mac with Apple silicon, the file is
`awscli-exe-linux-aarch64-2.37.4.zip` instead.

## moto, in a virtual environment

A virtual environment is a directory holding its own copy of Python's package installer, so what you
install there touches nothing else on the machine. moto goes into one at `~/aws/venv`, pinned to the
version the lessons were recorded with. The `[server]` part asks for the pieces that let moto
answer over the network rather than only inside a Python program:

```sh
python3 -m venv ~/aws/venv
~/aws/venv/bin/pip install -q 'moto[server]==5.2.3'
```

## One file that points everything at moto

The AWS command line decides where to send a request, and with which credentials, from a handful
of environment variables. One short file sets all of them, and every lesson starts by reading it:

```sh
cat > ~/aws/env.sh <<'EOF'
# The AWS courses' lab. Read it into every terminal: source ~/aws/env.sh
export PATH="$HOME/.local/bin:$PATH"
. "$HOME/aws/venv/bin/activate"
export AWS_ENDPOINT_URL=http://localhost:4567
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=sa-east-1
export AWS_PAGER=
export MOTO_IAM_LOAD_MANAGED_POLICIES=true
cd "$HOME/aws"
EOF
```

Line by line, after the comment:

| line | what it does |
|---|---|
| `PATH` | puts `~/.local/bin`, where `aws` is, on the path |
| `activate` | switches to the virtual environment, which puts `moto_server` on the path |
| `AWS_ENDPOINT_URL` | **sends every request to moto, on port 4567 of this computer, instead of to AWS** |
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | moto's placeholder credentials, `test` and `test`. moto accepts them and AWS refuses them, so a request that escapes to AWS by mistake fails rather than doing something |
| `AWS_DEFAULT_REGION` | `sa-east-1`, São Paulo, the region every lesson works in |
| `AWS_PAGER` | prints long answers straight to the terminal instead of opening them in a pager |
| `MOTO_IAM_LOAD_MANAGED_POLICIES` | makes moto carry the permission policies AWS itself maintains, which lesson 7 reads |

**Never put a real key in this file**, or in any file this course asks you to create. The two
`test` values are not secrets; a real key is. A file in your home directory gets copied into
backups, shared folders and screenshots without anybody deciding to.

## Every time you open a terminal

One line, in each of the two terminals:

```sh
source ~/aws/env.sh
```

Your prompt gains `(venv)` at the front; the transcripts in the lessons leave it out.

In the **first terminal**, start moto on port 4567. It keeps that terminal busy for as long as it
runs, which is the point: the requests appear there as they arrive.

```sh
moto_server -p 4567
```

In the **second terminal**, check that each tool answers, and then send moto its first request:

```
ana@laptop:~/aws$ aws --version
aws-cli/2.37.4 Python/3.14.6 Linux/6.18.44-fc-v139 exe/x86_64.ubuntu.24
ana@laptop:~/aws$ python3 -c 'import moto; print(moto.__version__)'
5.2.3
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:user/moto"
}
ana@laptop:~/aws$ aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : <not set>                : None             : None
access_key : ****************test     : env              : 
secret_key : ****************test     : env              : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
ana@laptop:~/aws$ cd ~ && du -sh aws .local/aws-cli
301M	aws
273M	.local/aws-cli
ana@laptop:~/aws$ ps -C moto_server -o rss=,comm=
83424 moto_server
```

`aws sts get-caller-identity` asks the question every AWS session can answer: who am I? Against AWS
it names the account and the user or role behind the credentials. Against moto it names moto's
default account, `123456789012`, and a user called `moto`, because moto accepts any credentials and
attributes them to that user. `aws configure list` says where each setting came from, and `env`
in the third column is this file doing its job.

In the first terminal, moto printed a line when that request arrived:

```
ana@laptop:~/aws$ moto_server -p 4567
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on http://127.0.0.1:4567
Press CTRL+C to quit
127.0.0.1 - - [16/Oct/2026 12:32:26] "POST / HTTP/1.1" 200 -
```

**A `POST` to `/` answered with `200` is one API call.** For as long as you keep that terminal
in view, you can see every request the command line sends. Lesson 26 opens one of them and reads
what is inside.

The last lines of the second terminal are the cost of the lab: the disk the two installations take,
and the memory moto holds while it runs, in kilobytes. Stop moto with **Ctrl+C** in its terminal
when you finish a session; the next lesson starts it again, empty.
