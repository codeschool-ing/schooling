---
title: root, `su`, `sudo`, and why the second one won
version: 1
---

Everything in this lesson so far has one exception, and it is total.

**root is uid 0, and the kernel does not check permissions for uid 0.** Not "root is in every
group", not "root's bits are always set" — the check is skipped. A file that is `-rw-------` and
owned by somebody else, root reads. A directory that is `700`, root enters. `chmod`, `chown`, a
mode with no bits at all: none of it applies.

```
ana@vm:~$ head -1 /etc/shadow
head: cannot open '/etc/shadow' for reading: Permission denied
ana@vm:~$ sudo head -1 /etc/shadow
root:*:20501:0:99999:7:::
```

Same file, same command, same second. The only thing that changed is who was asking.

## The two ways to become root, and why one of them is gone

**`su` — switch user.** It asks for **root's password** and gives you a root shell for as long as
you keep it open.

```
ana@vm:~$ su -
Password:
su: Authentication failure
```

That failure is not a mistake in the transcript. **On Ubuntu and most modern Debian installations
the root account has no password at all**, deliberately, so `su` cannot succeed by any input. The
distribution has decided you will use `sudo`.

**`sudo` — do this as somebody else.** It asks for **your own password**, checks a file to see
whether you are allowed, and runs **one command**:

```
ana@vm:~$ whoami
ana
ana@vm:~$ sudo whoami
[sudo] password for ana:
root
ana@vm:~$ sudo id
uid=0(root) gid=0(root) groups=0(root)
```

Look at the third line. `sudo whoami` printed `root` and then you were back at `ana@vm:~$` — the
elevation lasted exactly one command.

## Why `sudo` won, in four reasons

**Nobody has to know root's password.** Ten administrators, ten personal passwords, and no shared
secret that has to be changed when one of them leaves.

**It is logged, with a name on it.** `/var/log/auth.log` records who ran what, as themselves. A
shared root login records "root", which is nobody.

**It can be narrowed.** A person can be allowed to restart one service and nothing else, which is
impossible with a root password.

**And it is one command at a time.** That is the part people underrate. A root shell is an evening
where every typo is permanent; `sudo` is five extra characters that make you decide, each time,
that this particular command should run as root.

## Who is allowed: the group, then the file

```
ana@vm:~$ id -nG
ana sudo team
```

On Debian and Ubuntu, membership of the group `sudo` is what grants it. On Red Hat and its family
the group is called `wheel`. That is the whole mechanism for most machines, and adding somebody is
`usermod -aG sudo bruno` — with the `-a`, as section 61 insisted.

Somebody not in it gets this:

```
carla@vm:~$ id -nG
carla
carla@vm:~$ sudo whoami
[sudo] password for carla:
carla is not in the sudoers file.
```

She typed the correct password. **`sudo` authenticated her and then refused her**, which is the
right order: it confirms you are who you say before it tells you what you may not do.

Older versions added *"This incident will be reported."* — and it meant it, by mail to root. It is
a famous line and most current builds have dropped it.

## The rules live in `/etc/sudoers`

```
root    ALL=(ALL:ALL) ALL
%sudo   ALL=(ALL:ALL) ALL
```

Read a line as **who = (as whom) what**. `%` marks a group. So the second line says *anybody in the
group `sudo`, on any host, may run any command as any user*.

They can be much narrower, and this is what narrowing looks like:

```
bruno  ALL=(root) NOPASSWD: /usr/bin/systemctl restart nginx
```

Bruno may restart nginx as root, without a password, and may do nothing else. That is the shape of
a well-run machine, and it is why `sudo` is worth the trouble.

`sudo -l` asks what you are allowed:

```
ana@vm:~$ sudo -l
[sudo] password for ana:
Matching Defaults entries for ana on vm:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin,
    use_pty

User ana may run the following commands on vm:
    (ALL : ALL) ALL
```

**Edit it with `visudo`, never with an editor directly.** `visudo` checks the syntax before it
saves, and a syntax error in `/etc/sudoers` locks everybody out of `sudo` on a machine where root
has no password — which is a rescue-disk afternoon. Machine-specific rules go in a file under
`/etc/sudoers.d/`, edited with `visudo -f`.

## Running as somebody who is not root

```
ana@vm:~$ sudo -u bruno whoami
bruno
ana@vm:~$ sudo -u bruno id -nG
bruno team
```

`-u` picks the target account, and root is only the default. This is how you test what a service
account can actually do — run the command as `www-data` and watch it fail the same way the service
does, instead of running it as root and watching it work.

## The password is remembered for a few minutes

```
ana@vm:~$ sudo id -u
0
ana@vm:~$ sudo id -u
0
```

The second one did not ask. `sudo` records a timestamp per terminal and skips the prompt for about
fifteen minutes. `sudo -k` forgets it immediately, which is worth doing before you walk away from a
machine somebody else can touch.

## The rule to leave with

**Use `sudo` for the command that needs it, and nothing more.**

`sudo apt install nginx` is right. Becoming root and *then* deciding what to do is how a `rm -rf`
in the wrong directory becomes unrecoverable rather than annoying. Section 65 is the practical half
— including the one `sudo` that does not do what you expect.
