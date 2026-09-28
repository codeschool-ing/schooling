---
title: Credentials on a machine
version: 1
---

A program that calls a cloud API needs credentials, exactly like a person. The obvious way to give
it some is the wrong one: create an access key, paste it into the code or a configuration file, and
ship it. **An access key written into anything that gets copied is a key given to whoever receives a
copy.**

- A repository keeps its history. A key committed and deleted in the next commit is still in the
  first one, for everybody who clones it.
- A container image keeps every file of every layer it was built from, so a key copied in and deleted
  in a later step is still inside the image.
- A configuration file on a server is in its backups and its disk snapshots, and in lesson 4's
  images built from that server.

And a key in a public repository is found by people who search public repositories for exactly that
shape of string. The leak does not have to be noticed by anybody on your side for it to be used.

## The machine gets a role instead

The provider already knows which machine is which, so it can hand credentials to the machine
directly. You attach a role to the virtual machine, and a program on it asks for credentials at an
address that only answers from inside that machine: the **instance metadata service**, at
`169.254.169.254`. That is a link-local address, one that is never routed off the network it is
on. The answer is a set of temporary credentials for the role, and the provider
replaces them before they expire. Nothing is written into the code or the image, nothing needs
rotating, and a copy of the disk contains no key.

AWS's current version of the metadata service asks for a session token first, fetched with a `PUT`
request, before it will answer. The point is a specific attack: a web application tricked into
fetching a URL on an attacker's behalf can be made to fetch the metadata address, and a plain `GET`
was enough to hand over the role's credentials. A request that needs a `PUT` and a token first is
much harder to trick an application into making.

A function works the same way through its execution role, which lesson 8 uses, and a container
running on a managed service has an equivalent endpoint of its own.

## How a program finds its credentials

The CLI and the SDKs do not look in one place: they search a chain of sources in a fixed order and
use the first that answers. You can watch the search on a laptop with the AWS CLI and no credentials
at all. Nothing here reaches an AWS account; the environment and the home directory are empty on
purpose, as the lesson's `captures.sh` sets up.

```
ana@laptop:~/cloud$ aws --version
aws-cli/2.37.4 Python/3.14.6 Linux/6.18.44-fc-v37 exe/x86_64.ubuntu.24
ana@laptop:~/cloud$ aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : <not set>                : None             : None
access_key : <not set>                : None             : None
secret_key : <not set>                : None             : None
region     : <not set>                : None             : None
ana@laptop:~/cloud$ aws sts get-caller-identity

aws: [ERROR]: An error occurred (NoCredentials): Unable to locate credentials. You can configure credentials by running "aws login".
```

`aws configure list` reports, for each setting, the value found and the source it came from. Every
row says `<not set>` and `None`, because there is no source. The call that follows,
`sts get-caller-identity`, is the one that asks "who am I?", and the CLI refuses it itself:
`NoCredentials` means it found nothing to sign the request with, so **it never sent the request**.

The `--debug` output shows the search:

```
ana@laptop:~/cloud$ aws sts get-caller-identity --debug 2>&1 | grep -o 'Looking for credentials via: .*'
Looking for credentials via: env
Looking for credentials via: assume-role
Looking for credentials via: assume-role-with-web-identity
Looking for credentials via: sso
Looking for credentials via: shared-credentials-file
Looking for credentials via: login
Looking for credentials via: custom-process
Looking for credentials via: config-file
Looking for credentials via: ec2-credentials-file
Looking for credentials via: boto-config
Looking for credentials via: container-role
Looking for credentials via: iam-role
```

Twelve sources, and the order is the lesson. **The environment comes first**: variables such as
`AWS_ACCESS_KEY_ID` beat everything below them. Then the configuration and credentials files in
`~/.aws`, including the ways a profile there can point at a role, a sign-in in the browser
(`sso`, `login`) or a program that fetches credentials (`custom-process`). The last two are the
machine's own: `container-role` for a container's endpoint and `iam-role` for the instance metadata
service. The consequence is a trap worth remembering: on a virtual machine with a perfectly scoped
role, one forgotten `AWS_ACCESS_KEY_ID` in the environment wins, and every call quietly runs as
whoever that key belongs to.

This is what a long-lived key looks like when somebody does put one in a file. The pair is the example
AWS prints in its own documentation and belongs to nobody:

```
ana@laptop:~/cloud$ cat ~/.aws/credentials
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
ana@laptop:~/cloud$ aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : <not set>                : None             : None
access_key : ****************MPLE     : shared-credentials-file : 
secret_key : ****************EKEY     : shared-credentials-file : 
region     : <not set>                : None             : None
```

The same command now names `shared-credentials-file` as the source, and masks all but the last four
characters. The id begins with `AKIA`, the prefix of a long-lived key; the temporary credentials a
role hands out begin with `ASIA`. Anyone who reads that file, or a backup of it, has the key until
somebody deactivates it.
