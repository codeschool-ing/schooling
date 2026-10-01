---
title: What launching an instance asks for
version: 1
---

A console's launch page makes starting an instance look like a form with a big button at the
bottom. **Underneath, it is one request to the provider's API**, and every field on the page is a
field of that request. The quickest way to see all of them is to ask the command-line tool for the
shape of the request without sending it.

The AWS CLI does that locally. It was run here with an empty environment and a fresh home
directory, so it had no credentials, no configuration and no account to talk to:

```
ana@laptop:~/cloud$ aws --version
aws-cli/2.37.4 Python/3.14.6 Linux/6.18.44-fc-v37 exe/x86_64.ubuntu.24
ana@laptop:~/cloud$ aws ec2 run-instances --generate-cli-skeleton | jq "keys | length"
44
ana@laptop:~/cloud$ aws ec2 run-instances --generate-cli-skeleton | jq "{ImageId, InstanceType, SubnetId, SecurityGroupIds, KeyName, UserData}"
{
  "ImageId": "",
  "InstanceType": "a1.medium",
  "SubnetId": "",
  "SecurityGroupIds": [
    ""
  ],
  "KeyName": "",
  "UserData": ""
}
ana@laptop:~/cloud$ aws ec2 describe-instances --region sa-east-1

aws: [ERROR]: An error occurred (NoCredentials): Unable to locate credentials. You can configure credentials by running "aws login".
```

Four commands, and only the last one tried to reach AWS. `--generate-cli-skeleton` prints the
request as JSON with every field empty; the CLI builds it from the API description it ships with,
so it answers on a laptop with no network. The request has 44 fields, and the second `jq` keeps six
of them. `"a1.medium"` in `InstanceType` is only the placeholder the skeleton writes, not a
recommendation. The last command is refused before anything is sent, because a request to AWS has
to be signed with credentials and there were none. **This course stops at that line on purpose**:
nothing in it needs an account, and nothing in it shows what an account would answer.

## The six answers every launch needs

Most of the 44 fields have defaults. These are the ones you decide, or the default decides for you.

**An image**, `ImageId`: the disk the instance boots from. An operating system and whatever was
installed on it before, and the subject of the next section.

**A type**, `InstanceType`: the processor and memory, chosen the way the last section said.

**A place in a network**, `SubnetId`: which network the instance joins and which range its private
address comes from. On AWS a subnet sits in one availability zone, so this field also decides which zone
the instance runs in. Lesson 6 builds the networks and lesson 9 explains the zones.

**A firewall**, `SecurityGroupIds`: the rules saying which traffic may reach the instance, by
protocol, port and source. An instance whose rules allow SSH from `0.0.0.0/0` is open to the whole
internet, and lesson 6 is where you learn to write them narrower.

**A way in**, `KeyName`: the public half of an SSH key pair, which the provider places on the
instance at first boot so that you can log in with the private half, as the `networks` course did
with SSH. Some providers also offer a shell through an agent on the instance and no open port at
all, which needs the instance to carry an identity; that is lesson 7's subject.

**Instructions for the first boot**, `UserData`: a script or a configuration file the instance reads
the first time it starts. It is how a machine installs its own software without anybody logging in,
and two sections from here are about it.

A seventh is always there even when nobody writes it: **a disk**, in `BlockDeviceMappings`. The
image says how large the root disk is and what kind; the request may change both. What happens to
that disk when the instance goes away is the section on disks.

## Writing the answers down once

Filled in by hand, those fields are a form that somebody completes slightly differently each time.
Providers let you save the answers under a name. On AWS that is a **launch template**: an image, a
type, the security groups, the key, the user data and the disks, versioned, so that every instance
started from it is started the same way. Nothing in this lesson needs one until autoscaling does,
because a group of identical machines has to be told what one of them looks like. Keeping the
template itself in a file under version control, rather than in a console, is where the `iac`
course begins.
