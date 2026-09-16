---
title: `ssh`, because every machine is somewhere else
version: 1
---

This is one section in a lesson whose title does not mention it, and it is here because **every
Linux machine you will ever administer is one you reach over ssh.** The course has no better place
for it, and doing without it until then would be dishonest about what the job looks like.

Keys, the fingerprint prompt, and where things live. Tunnels, config files and hardening are
somebody else's lesson.

```
ssh user@host
ssh -p 2222 ana@localhost       # a port that is not 22
```

That is it. A shell on another machine, and everything from lessons 1 to 4 works there exactly as
it does here.

## The question it asks the first time

```
ana@vm:~$ ssh -p 2222 ana@localhost
The authenticity of host '[localhost]:2222 ([127.0.0.1]:2222)' can't be established.
ED25519 key fingerprint is SHA256:iokzK3UORZNPSUcTadj2ARlnsRdwOFmIQ2oOVirnSy8.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '[localhost]:2222' (ED25519) to the list of known hosts.
ana@localhost's password:
```

Everybody types `yes` without reading it. Here is what it is actually asking.

**The server has a key of its own**, made when ssh was installed. That fingerprint is a hash of its
public half. Your ssh has never seen this machine before, so it cannot tell whether it is talking
to the machine you meant or to somebody sitting in between pretending to be it.

Typing `yes` means *I accept this key as this machine's identity*, and it is written to
`~/.ssh/known_hosts`. **From then on, ssh checks it every time**, silently, and complains loudly if
it ever changes:

```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```

That banner means one of three things, and they are in descending order of likelihood: the machine
was rebuilt and has a new key; you are reaching a different machine behind the same name; or
somebody is intercepting you. **It is not a thing to clear away without knowing which.** The fix
when it is innocent is `ssh-keygen -R hostname`, which removes the stored key so the question is
asked again.

The honest way to answer the first prompt is to compare the fingerprint against one you were given
out of band — printed by `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` on the server by
somebody who was already there. Nearly nobody does this. It is still what the prompt is for.

## Keys instead of passwords

A password goes over the wire on every connection and can be guessed. A key does neither. Make one:

```
ana@vm:~$ ssh-keygen -t ed25519 -C "ana@vm" -f ~/.ssh/id_ed25519 -N ""
Generating public/private ed25519 key pair.
Created directory '/home/ana/.ssh'.
Your identification has been saved in /home/ana/.ssh/id_ed25519
Your public key has been saved in /home/ana/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:754NYP2waKcTxYlX8j8/HBVtWL19iPG45a/enwVhrJY ana@vm
```

**Two files, and the difference between them is the whole idea:**

```
ana@vm:~$ ls -l ~/.ssh
total 8
-rw------- 1 ana ana 399 Sep 14 23:23 id_ed25519
-rw-r--r-- 1 ana ana  88 Sep 14 23:23 id_ed25519.pub
```

`id_ed25519` is the **private** key, mode `600`, and it never leaves this machine. `id_ed25519.pub`
is the **public** half, mode `644`, and it is meant to be copied anywhere:

```
ana@vm:~$ cat ~/.ssh/id_ed25519.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKHhDDaH171LJb/mce2OhMnKDYo5PArO8BPrVDTHdhd ana@vm
```

Publishing that line costs you nothing. Publishing the other file costs you everything. Lesson 4
section 13 said `.ssh` is the most sensitive directory you own, and this is why — **ssh checks the
permissions and refuses a key that anybody else could read.**

`-t ed25519` is the algorithm to use; it is short, fast and current. `-N ""` means no passphrase,
which is right for this demonstration and wrong for a laptop — a passphrase is what protects the
private key if the machine is stolen, and `ssh-agent` is what stops you typing it forty times a
day.

## Putting the public half on the other machine

```
ana@vm:~$ ssh-copy-id -p 2222 bruno@localhost
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/ana/.ssh/id_ed25519.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
bruno@localhost's password:

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh -p 2222 'bruno@localhost'"
and check to make sure that only the key(s) you wanted were added.
```

That was the last time a password was typed. Watch:

```
ana@vm:~$ ssh -p 2222 bruno@localhost
Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 6.18.44-fc-v33 x86_64)
...
bruno@vm:~$ whoami
bruno
bruno@vm:~$ ls -l ~/.ssh
total 8
-rw------- 1 bruno bruno 88 Sep 14 23:23 authorized_keys
-rw------- 1 bruno bruno 42 Sep 14 22:27 config
bruno@vm:~$ cat ~/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKHhDDaH171LJb/mce2OhMnKDYo5PArO8BPrVDTHdhd ana@vm
```

No prompt at all. **`ssh-copy-id` appended one line to `~/.ssh/authorized_keys` on the other side**
— the public half, unchanged, the same string printed above. That file is the list of keys allowed
to log in as `bruno`, one per line, and you can edit it by hand; `ssh-copy-id` is a convenience
that gets the permissions right.

Note what this means for section 03's warning. **`passwd -l bruno` would not have stopped that
login.** Keys never consult `/etc/shadow`. When somebody leaves, the account is locked *and*
`authorized_keys` is emptied, and forgetting the second is a real way people keep access for years.

## The four files in `~/.ssh`

| | |
|---|---|
| `id_ed25519` | your private key. `600`, never copied |
| `id_ed25519.pub` | your public key. Safe to paste anywhere |
| `authorized_keys` | public keys allowed to log in **as you, on this machine** |
| `known_hosts` | server keys **you** have accepted |

The two halves of the confusion are worth saying plainly: `authorized_keys` is about people coming
in; `known_hosts` is about machines you have gone out to. They live in the same directory and
answer opposite questions.

## Running one command without a shell

```
ssh ana@host 'uptime'
ssh ana@host 'systemctl is-active nginx'
```

ssh will run a command and hand you its output. This is how you ask fifty machines the same
question from a loop, and it is the single most useful thing ssh does after giving you a shell.

**That command runs in a non-interactive, non-login shell**, which is section 05's third row — so
your aliases are absent and your `PATH` may not be what you expect. Give full paths, and the
surprise never happens.

## Three things worth knowing now

**`scp` and `rsync` go over the same connection.** `scp file host:/path` copies one thing;
`rsync -av dir/ host:/path/` copies a tree and only the parts that changed. Both use ssh
underneath, so a key that works for a shell works for them.

**Password authentication is usually switched off on servers.** Once keys work, `PasswordAuthentication no`
in the server's configuration removes an entire category of attack. Do it *after* checking your key
works, from a session you have not closed.

**And the host you cannot reach is usually a firewall.** `ssh: connect to host … port 22:
Connection refused` means something answered and said no; `Connection timed out` means nothing
answered at all. The two point in different directions, and lesson 11 comes back to the difference.
