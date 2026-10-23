---
title: Installing the lab
version: 1
---

Everything below runs in a terminal on Ubuntu 24.04, as your own user, and only the first block asks
for `sudo`. **The rest lands in two places: `~/aws`, where you work for the whole course, and
`~/.local`, where the AWS command line goes.** Deleting those two removes the lab completely.

If `aws --version` already prints `aws-cli/2.37.4`, the second block is done; if
`~/aws/venv/bin/moto_server` exists, so are the third and the fourth. Skip to the last part of this
section and check that the lab answers.

## The packages from Ubuntu

Python, `curl` and `jq` come from Ubuntu's own archive, with `unzip` to open the AWS installer:

```sh
sudo apt-get update
sudo apt-get install -y python3 python3-venv curl jq unzip
```

**`python3-venv` is the one people leave out**, because Ubuntu ships Python without it. Without it
the third block fails, and the next section shows what that looks like.

## The AWS command line

AWS publishes its command line as a zip file with an installer inside. These commands fetch one fixed
version, the one every transcript was recorded with, and install it into your home directory, so
nothing here needs `sudo`:

```sh
mkdir -p ~/aws ~/.local/bin
cd ~/aws
curl -sS -o awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.37.4.zip
unzip -q awscliv2.zip
./aws/install -i ~/.local/aws-cli -b ~/.local/bin
rm -rf aws awscliv2.zip
```

A newer version does everything this course asks; its version line and the wording of a few messages
will differ from the transcripts. On an Arm processor, which includes a virtual machine on a Mac with
Apple silicon, the file is `awscli-exe-linux-aarch64-2.37.4.zip` instead.

## moto, in a virtual environment

A virtual environment is a directory with its own copy of Python's package installer, so what goes in
it touches nothing else on the machine. moto goes into one at `~/aws/venv`, pinned to the version the
lessons were recorded with. `[server]` asks for the parts that let moto answer over the network
rather than only inside a Python program:

```sh
python3 -m venv ~/aws/venv
~/aws/venv/bin/pip install -q 'moto[server]==5.2.3'
```

## One file that points everything at moto

The AWS command line decides where a request goes, and with which credentials, from a handful of
environment variables. One short file sets them all, and every lesson starts by reading it:

```sh
cat > ~/aws/env.sh <<'EOF'
# The lab for the AWS courses and cloud-security. Read it into every terminal: source ~/aws/env.sh
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
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | moto's placeholder credentials, `test` and `test` |
| `AWS_DEFAULT_REGION` | `sa-east-1`, São Paulo, the region every lesson works in |
| `AWS_PAGER` | prints long answers straight to the terminal instead of opening a pager |
| `MOTO_IAM_LOAD_MANAGED_POLICIES` | gives moto the permission policies AWS itself maintains, such as `AdministratorAccess` |

**The two `test` values are the first security decision of the course.** moto accepts them and AWS
refuses them, so a request that escapes to AWS by mistake fails instead of doing something. **Never
put a real key in this file**, or in any file the course asks you to create: a file in your home
directory is copied into backups, shared folders and screenshots without anybody deciding to, and
lesson 7 is about what happens next.

## Every time you open a terminal

One line, in each of the two terminals:

```sh
source ~/aws/env.sh
```

Your prompt gains `(venv)` at the front; the transcripts leave it out.

In the **first terminal**, start moto on port 4567. It holds that terminal for as long as it runs,
which is the point, since the requests appear there as they arrive:

```sh
moto_server -p 4567
```

In the **second terminal**, check that each tool answers, then send moto its first request:

```
ana@laptop:~/aws$ aws --version
aws-cli/2.37.4 Python/3.14.6 Linux/6.18.44-fc-v153 exe/x86_64.ubuntu.24
ana@laptop:~/aws$ python3 -c 'import moto; print(moto.__version__)'
5.2.3
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:user/moto"
}
ana@laptop:~/aws$ cd ~ && du -sh aws .local/aws-cli
302M	aws
273M	.local/aws-cli
```

`aws sts get-caller-identity` asks the one question every set of AWS credentials can answer: **who
am I?** Against AWS it names the account and the user or role behind the key. Against moto it names
moto's default account, `123456789012`, and a user called `moto`, since moto accepts any key at all
until lesson 6 turns its checking on. The last two lines are what the lab costs your disk.

In the first terminal, moto printed one line when the request arrived:

```
ana@laptop:~/aws$ moto_server -p 4567
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on http://127.0.0.1:4567
Press CTRL+C to quit
127.0.0.1 - - [23/Oct/2026 00:29:59] "POST / HTTP/1.1" 200 -
```

**A `POST` to `/` answered with `200` is one API call**, and `127.0.0.1` is where it came from. When
you finish a session, stop moto with **Ctrl+C** in its terminal. The next lesson starts it again,
empty.
