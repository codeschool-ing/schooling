---
title: The `sudo` that does not work, and four that do
version: 2
---

This section exists because of one line. Everybody types it, it fails, and every answer to it
online is a fix without an explanation.

```
ana@vm:~$ sudo echo x > /root/marker.txt
bash: /root/marker.txt: Permission denied
```

`sudo` is right there. The command is `echo`, which cannot fail. And it says permission denied.

## Read who is speaking

**`bash:`** — not `sudo:`, not `echo:`. Lesson 1 section 17 built this habit and here is where it
pays.

The shell reads the whole line **before anything runs**. It sees a redirect, `> /root/marker.txt`,
and the redirect is the shell's own work — it opens that file, then starts the command with its
output already pointing there. So the order is:

1. **bash** — still `ana` — tries to create `/root/marker.txt`. Refused.
2. `sudo` is never reached. `echo` is never reached.

**`sudo` elevates the command. It cannot elevate the shell that is preparing the line**, because
that shell is your login shell and it started long before you typed `sudo`.

## The fixes, and what each one costs

```
ana@vm:~$ sudo sh -c 'echo x > /root/marker.txt'
ana@vm:~$ sudo ls -l /root/marker.txt
-rw-r--r-- 1 root root 2 Sep 14 22:46 /root/marker.txt
```

**`sudo sh -c '...'`** — start a *new shell* as root and give it the whole line, redirect included.
The quotes matter: without them the redirect is again the outer shell's.

**`... | sudo tee file`** — the one to prefer for writing a file:

```
echo 'net.ipv4.ip_forward=1' | sudo tee /etc/sysctl.d/99-forward.conf
echo 'a line' | sudo tee -a /var/log/notes.log        # -a appends
```

`tee` reads its input and writes it to a file *and* to the screen. Here it is `tee` that opens the
file, and `tee` is running under `sudo`. It also shows you what it wrote, which is a free check.

**`sudo -i`** for a session, when you genuinely have ten things to do:

```
ana@vm:~$ sudo -i
[sudo] password for ana:
root@vm:~# whoami
root
root@vm:~# pwd
/root
root@vm:~# echo $HOME
/root
root@vm:~# exit
logout
ana@vm:~$ whoami
ana
```

Note the prompt changed to `#`, and `pwd` is `/root`, and `$HOME` moved. Lesson 1 section 06 told
you to watch that last character before pressing enter on anything destructive; this is the moment
it matters.

**`sudo -i` against `sudo -s` against `sudo su -`.** The first is a full login shell as root: root's
environment, root's home, root's `.bashrc`. `sudo -s` keeps *your* environment with root's
privileges, which is occasionally what you want and more often a surprise. `sudo su -` works and is
two tools doing one tool's job.

## `sudo !!` is the one you will use daily

```
apt install nginx
sudo !!
```

`!!` is the previous command, expanded by the shell before it runs, so the second line becomes
`sudo apt install nginx`. It is the muscle memory for *I forgot the sudo*, and it saves retyping a
long line.

**Look at what it expands to before you press enter** when the previous command was long — because
`!!` will happily re-run something you did not mean, as root.

## The environment is not yours any more

```
Defaults    env_reset
Defaults    secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
```

Those two lines are in `/etc/sudoers` on nearly every machine, and they explain two confusions.

**`env_reset`** throws away your environment variables. So `sudo` does not see your `$http_proxy`,
your `$JAVA_HOME`, or the variable you exported a moment ago. `sudo -E` keeps them, and is refused
on machines where the rules forbid it.

**`secure_path`** replaces your `$PATH` with a fixed one. That is why a program you installed in
`~/bin` is `command not found` under `sudo` while it works without. Give the full path, or put the
program somewhere on the secure path.

Both are security measures rather than annoyances: a `$PATH` you control plus a root command is a
way to have root run your program instead of the real one.

## Four habits

**`sudo -l` when you arrive somewhere.** It tells you what you may do before you find out by being
refused.

**Never `sudo` something you have not read.** `curl https://… | sudo bash` is the most successful
attack delivery mechanism on Linux, and it is in installation instructions everywhere. Download it,
read it, then run it.

**Prefer a narrow rule to a broad one.** If a deploy needs to restart one service, write that rule
in `/etc/sudoers.d/` — with `visudo -f` — rather than putting the account in the `sudo` group.

**And `sudo -k` before you walk away.** The fifteen-minute cache is a convenience for you and an
open door for whoever sits down next.
