---
title: Building the lab, step by step
version: 1
---

These steps are for **Ubuntu 24.04**, in the virtual machine the previous section recommends or
installed directly. On another Debian or Ubuntu release they are the same; on macOS and on other
Linux families the package commands differ, and the end of this section says how.

**The whole installation is one script.** Save it in your home directory as `setup-iac.sh`:

```sh
#!/bin/sh
# ~/setup-iac.sh: the tools lessons 1 to 13 use, on Ubuntu 24.04.
set -e
sudo apt-get update -qq
sudo apt-get install -qq -y curl git gnupg jq lsb-release python3-venv tree unzip >/dev/null

# Terraform, from HashiCorp's own package repository, checked against its key
curl -fsSL https://apt.releases.hashicorp.com/gpg |
  sudo gpg --dearmor --yes -o /usr/share/keyrings/hashicorp.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" |
  sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
sudo apt-get update -qq
sudo apt-get install -qq -y terraform=1.16.4-1 >/dev/null

# moto and the AWS CLI, in a Python environment of their own
python3 -m venv ~/iac-venv
~/iac-venv/bin/pip install -q "moto[server]==5.2.3" "awscli==1.46.1"

terraform version
~/iac-venv/bin/aws --version
```

Three things in it are choices rather than necessities. **The versions are pinned** to the ones
every transcript in this course was recorded with, so what you see matches what the page says;
leave out `=1.16.4-1` and the two `==` and you get the newest, which works too and prints slightly
different lines. **moto and the AWS CLI go into a virtual environment**, `~/iac-venv`, because
Ubuntu 24.04 refuses to let `pip` install into the system's own Python, and it is right to.
And **`jq`, `tree` and `git`** are not Terraform's: the lessons use them to read JSON, to show a
directory and to keep each configuration's history.

Run it. It asks for your password once, for `sudo`, and takes a few minutes:

```
ana@laptop:~$ sh setup-iac.sh
Terraform v1.16.4
on linux_amd64
aws-cli/1.46.1 Python/3.12.3 Linux/6.18.44-fc-v77 botocore/1.43.62
```

The second file is shorter, and you will use it in every terminal you open for this course. Save it
as `iac-env.sh`:

```sh
# ~/iac-env.sh: read it into each terminal with ". ~/iac-env.sh"
. ~/iac-venv/bin/activate
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=sa-east-1
mkdir -p ~/.terraform.d/plugin-cache
export TF_PLUGIN_CACHE_DIR=~/.terraform.d/plugin-cache
```

It is read with `.`, not run with `sh`, because a script that is *run* sets its variables in a
shell of its own and they die with it. The first line puts `aws` and `moto_server` on your `PATH`;
the next three set the variables the next section explains. The last two are about disk: the AWS
provider is a program of **789 MB**, and without a cache `terraform init` downloads a copy of it into
every directory you initialise. With one, it is downloaded once and each directory links to it.
Your prompt gains `(iac-venv)` in front when the first line runs; the transcripts in this course
leave it out.

**moto gets a terminal of its own.** Open a second one, and start it there:

```
ana@laptop:~$ . ~/iac-env.sh
ana@laptop:~$ moto_server -p 4566
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on http://127.0.0.1:4566
Press CTRL+C to quit
```

Leave it running. Every request it answers prints a line in that terminal, which is a useful thing
to glance at when a command seems to do nothing. Back in the first terminal, the check that the
whole chain works:

```
ana@laptop:~$ . ~/iac-env.sh
ana@laptop:~$ env | grep ^AWS_ | sort
AWS_ACCESS_KEY_ID=test
AWS_DEFAULT_REGION=sa-east-1
AWS_ENDPOINT_URL=http://localhost:4566
AWS_SECRET_ACCESS_KEY=test
ana@laptop:~$ aws sts get-caller-identity
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:user/moto"
}
ana@laptop:~$ aws ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock,IsDefault]" --output text
vpc-4052a1bd303dbea6e	172.31.0.0/16	True
```

`env` shows the four variables the file set. `get-caller-identity` asks AWS who you are, and moto
answers with its placeholder account. The VPC is the **default VPC** that every AWS region comes with, and moto creates one too; it is the only
thing in an emulated account that you did not make. If you see those three answers, the lab is ready
for lesson 2.

**On other systems.** On **macOS**, install Terraform with Homebrew,
`brew install hashicorp/tap/terraform`, and run the `python3 -m venv` and `pip` lines of the script
as they are; `iac-env.sh` works unchanged. On **Windows**, install WSL 2 with Ubuntu 24.04 and
follow this section inside it, word for word. On **Fedora** and its relatives, HashiCorp publishes a
`dnf` repository, and its downloads page gives the two lines for it.
