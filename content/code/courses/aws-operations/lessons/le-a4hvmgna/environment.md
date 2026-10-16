---
title: Your AWS, on your own computer
version: 1
---

This course is practised against **moto**, an open-source program that answers the AWS API on a
port of your own computer, with the real AWS command line pointed at it. There is no AWS account
anywhere in it, nothing is billed, and the platform runs nothing for you: every command in these
lessons is one you type in your own terminal. **Lesson 1 of `aws-foundations` builds this
environment in full**, with the three ways to have a terminal on Ubuntu 24.04 (installed, which it
recommends; a virtual machine; a shell rented online), what each costs your computer, and what to do
when the setup fails. If you took that course, you already have everything below. If you did not, or
you deleted it since, this section is the same setup in brief.

## Building it

Three packages come from Ubuntu's archive. `python3-venv` is the one people leave out, because
Ubuntu ships Python without it:

```sh
sudo apt-get update
sudo apt-get install -y python3-venv curl unzip jq
```

Then the AWS command line, version 2.37.4, into `~/.local`, and moto 5.2.3 into a virtual
environment of its own in `~/aws/venv`. Nothing here needs `sudo`:

```sh
mkdir -p ~/aws ~/.local/bin && cd ~/aws
curl -sS -o awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.37.4.zip
unzip -q awscliv2.zip && ./aws/install -i ~/.local/aws-cli -b ~/.local/bin
rm -rf aws awscliv2.zip
python3 -m venv ~/aws/venv
~/aws/venv/bin/pip install -q 'moto[server]==5.2.3'
```

If `aws-foundations` already installed the command line, `./aws/install` refuses with a message
about a preexisting installation, and that is fine: the version is the same one. On a computer with
an Arm processor the file is `awscli-exe-linux-aarch64-2.37.4.zip`.

## Starting it, every time

**moto keeps everything in memory and forgets it when it stops**, so nothing from yesterday is still
there today, and no lesson assumes it is. Open a terminal for moto alone and start it there:

```sh
~/aws/venv/bin/moto_server -p 4567
```

It prints a warning, the address it listens on, and then one line for every request it answers:

```
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on http://127.0.0.1:4567
Press CTRL+C to quit
127.0.0.1 - - [16/Oct/2026 12:22:09] "GET / HTTP/1.1" 200 -
127.0.0.1 - - [16/Oct/2026 12:22:10] "POST / HTTP/1.1" 200 -
```

**The warning is about moto, not about you**: it is a development web server, and that is exactly
what it is for here. Leave that terminal open. In a **second** terminal, the one you work in, five lines point the command line at
it:

```sh
cd ~/aws && source venv/bin/activate
export PATH="$HOME/.local/bin:$PATH"
export AWS_ENDPOINT_URL=http://localhost:4567
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=sa-east-1
```

`AWS_ENDPOINT_URL` sends every request to moto instead of to AWS. The key pair is the word `test`
twice: moto accepts any credentials, and AWS refuses these, which is the point. The region is São
Paulo. The variables live in that terminal only, so a new terminal needs the five lines again.

Then check it answers:

```
ana@laptop:~/aws$ aws --version
aws-cli/2.37.4 Python/3.14.6 Linux/6.18.44-fc-v139 exe/x86_64.ubuntu.24
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:user/moto"
}
ana@laptop:~/aws$ du -sh ~/aws/venv ~/.local/aws-cli
301M	/home/ana/aws/venv
273M	/home/ana/.local/aws-cli
```

The first line is the command line's version. The second command asked "who am I?", and moto
answered with an account it invented, `123456789012`, which is the account every transcript in this
course shows. The other terminal printed a line for that request. The last command is the disk the
two installations take, some 575 MB, and deleting `~/aws` and `~/.local/aws-cli` removes all of it.

## When it does not answer

Three failures cover nearly every case.

**The endpoint variable is missing.** A new terminal where the five lines were not typed sends the
request to the real AWS, which refuses the `test` key:

```
ana@laptop:~/aws$ aws sts get-caller-identity

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the GetCallerIdentity operation: The security token included in the request is invalid.
```

The words *security token* are AWS's, and seeing them means the request left your computer. Type
the five lines and ask again.

**moto is not running.** The command line retries and then gives up on the address:

```
ana@laptop:~/aws$ aws sts get-caller-identity

aws: [ERROR]: Could not connect to the endpoint URL: "http://localhost:4567/"
```

**Port 4567 is taken**, by an earlier moto you forgot in another terminal or by another program.
A second moto then stops at once, and says why:

```
ana@laptop:~/aws$ timeout 10 moto_server -p 4567 2>&1 | tail -2
Address already in use
Port 4567 is in use by another program. Either identify and stop that program, or start the server with a different port.
```

Close the other terminal, or find the program with `ss -ltnp | grep 4567`.
