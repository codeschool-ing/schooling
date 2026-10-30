---
title: The machine behind the terminal
version: 1
---

**Cloud Shell is a small Linux machine that Google starts for you when you open a terminal in the console**,
with gcloud, Terraform, kubectl, Docker and the common languages already installed, and with your own
credentials already in it. It costs nothing and needs nothing installed. It is the fastest way to run one
command against a real account, from any browser, and lesson 1 said why it is not this course's lab: it needs
a Google account, and this course was written so that nobody needs one.

What kind of machine it is decides most of what it is good for:

| it is | so |
|---|---|
| **a virtual machine in a project of Google's**, not of yours | it is not in your VPC network, and reaches your private addresses no better than the internet does |
| **started for you, and stopped when idle** | anything running in it stops with it; it is not a server |
| **signed in as you** | every command acts with your roles, which is the convenience and the risk |
| **reached from the browser** | nothing on it can be reached from the internet, except through the web preview of the third section |

**Nothing in this lesson ran in Cloud Shell**, for the reason above. What did run is gcloud's own side of it,
on the laptop, and Google's answer to it. The facts about the machine are Google's documentation, which was
not reachable from where this course was written on 30 October 2026, so the lesson gives no number that could
have changed since: the documentation's page on Cloud Shell limits is where the current hours and sizes are.

## gcloud's side

gcloud can reach Cloud Shell from a laptop, which is the only way to use it without a browser:

```
ana@laptop:~/gcp$ gcloud cloud-shell --help | sed -n "/^COMMANDS/,/^NOTES/p" | grep -E "^     [a-z]"
     get-mount-command
     scp
     ssh
```

`ssh` opens a session in it, `scp` copies files in and out, and `get-mount-command` prints the line that mounts
its home directory on the laptop over SSH. Ask for the SSH command it would run, without running it. This
request reaches Google, so the output is filtered to the lines that are not random:

```
ana@laptop:~/gcp$ gcloud cloud-shell ssh --dry-run 2>&1 | grep -E "^(Automatic|WARNING|ERROR|Your)"
Automatic authentication with GCP CLI tools in Cloud Shell is disabled. To enable, please rerun command with `--authorize-session` flag.
WARNING: The private SSH key file for gcloud does not exist.
WARNING: The public SSH key file for gcloud does not exist.
WARNING: You do not have an SSH key for gcloud.
WARNING: SSH keygen will be executed to generate a key.
Your identification has been saved in /home/ana/.ssh/google_compute_engine
Your public key has been saved in /home/ana/.ssh/google_compute_engine.pub
ERROR: (gcloud.cloud-shell.ssh) UNAUTHENTICATED: Request had invalid authentication credentials. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project. This command is authenticated with an access token from /home/ana/gcp/placeholder-token specified by the [auth/access_token_file] property.
```

Three things happened in order. gcloud said it would **not hand your credentials to the session** unless asked
with `--authorize-session`, which is the right default: a session that inherits your credentials is one more
place they are. It **made an SSH key** for itself, `~/.ssh/google_compute_engine`, which it reuses for every
machine it connects to from now on. And it asked the Cloud Shell API to start the machine, which refused the
placeholder token like every Google service in this course.
