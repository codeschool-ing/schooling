---
title: What an access key is, and where keys leak
version: 1
---

**An access key is a password for the API that has no second factor, no expiry and no idea where it
is being used from.** Whoever holds the two strings is the IAM user, from any computer on the
internet, until somebody deletes the key. Lessons 10 and 11 replaced it for machines and for people.
This lesson is about the cases where nothing replaced it, and what to do on the day one escapes.

The common wrong picture is that a key is safe because it is long. **The key is never guessed; it
is copied.** Its length protects it against an attacker who tries strings, and nobody does that.
The attacker who matters finds a key that was written down somewhere, and from then on the length
is irrelevant.

## Two strings, and what they do

A key is a pair. The **access key id**, `AKIA` and sixteen more characters for a long-term key, is
not secret. It names the key, and it appears in every request and in every line of CloudTrail. The
**secret access key**, forty characters, is never sent anywhere. The client uses it to sign each
request, as lesson 26 shows byte by byte, and AWS checks the signature with its own copy.

What the pair does not have is the list that makes the rest of this course comfortable:

| | an access key | a role session (lessons 9 to 11) |
|---|---|---|
| expires | never, until deleted | in minutes or hours |
| second factor | none; the key alone is enough | inherited from whoever started the session |
| tied to a place | no; it works from any network | to whoever was allowed to assume the role |
| shows in CloudTrail as | the IAM user | the role, with a session name |

**Two keys per user is the limit**, and the next section measures moto enforcing it. The second
slot exists for exactly one reason: to rotate without stopping the program that uses the first.

## Where keys leak

Keys rarely leak through AWS. **They leak through everything else a person touches.** Four places
account for most of the cases AWS and GitHub publish:

- **a repository.** A key pasted into a configuration file, a test, a notebook or a `.env` that was
  committed once and removed later. Deleting the line does not delete the commit, and a public
  repository is read by scanners within minutes of a push;
- **an image.** A container image built with `COPY . .` from a directory that held `~/.aws` or a
  `.env`, then pushed to a registry. Every layer is a tar file anybody who can pull it can unpack;
- **a log.** A program that prints its environment when it fails, a CI job that runs with `set -x`,
  an error report that attaches the request it was making. The key ends up wherever logs go, which
  is usually somewhere with weaker access than the account;
- **a laptop.** `~/.aws/credentials` is a plain text file. A stolen laptop, a synchronised home
  directory, a backup on a shared drive: each one is a copy of the key.

The four have the same shape. **A key is a string, and strings get copied** by tools that were
never told it was secret.

## The alternatives, which come first

So the rule is that a key is the **last resort**: the answer once every other answer has been ruled
out. For each kind of program, the course already has one:

| who calls AWS | instead of a key | where |
|---|---|---|
| a person at a keyboard | IAM Identity Center and `aws sso login` | lesson 11 |
| a program on EC2 | an instance profile | lesson 10 |
| a container on ECS or a pod on EKS | a task role, Pod Identity or IRSA | lesson 10 |
| a CI pipeline (GitHub Actions, GitLab) | the pipeline's OIDC token, traded for a role | lesson 10 |
| a program in another AWS account | a role it assumes across accounts | lesson 9 |
| a server in the office, outside AWS | IAM Roles Anywhere, with a certificate | named here |

The last row is the one that tempts people towards a key, and it has an answer too. **IAM Roles
Anywhere** lets a machine outside AWS assume a role by presenting an X.509 certificate from a
certificate authority the account trusts. The credentials it receives expire like any other role
session. It needs a certificate authority and the discipline to run one, which is why some
organisations still fall back to a key there. This course names it and does not run it: moto 5.2.3
answers every `rolesanywhere` call with an internal error.

What is left after the table is short. **A program outside AWS, on a machine the organisation cannot
give a certificate to, calling AWS on a schedule**: a supplier's system that uploads a file every
night, an old appliance with a field for an access key and nothing else. The shop has one of those,
the office's accounting system. The next section gives it a key and rotates it.
