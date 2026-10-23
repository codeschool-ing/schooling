---
title: The door administrators use
version: 1
---

**SSH is the one service on `web` that is meant to let people in, which makes its settings the
ones that matter most.** The previous administrator allowed two things a server should not: root
logging in directly, and logging in with a password at all. A password can be guessed from anywhere
the port can be reached; a key cannot.

## What the server will actually do

The configuration of `sshd` is spread over several files, so reading one of them answers the wrong
question. `sshd -T` prints the settings the server would run with, after reading all of them, and
that is the answer that counts:

```
ana@web:~$ sudo sshd -T | grep -E '^(permitrootlogin|passwordauthentication|x11forwarding|maxauthtries) '
maxauthtries 6
permitrootlogin yes
passwordauthentication yes
x11forwarding yes
ana@web:~$ cat /etc/ssh/sshd_config.d/50-old.conf; grep -n Include /etc/ssh/sshd_config
PermitRootLogin yes
PasswordAuthentication yes
12:Include /etc/ssh/sshd_config.d/*.conf
```

Root may log in, passwords are accepted, X11 forwarding is on, and a client gets six attempts per
connection. The file that says so is `50-old.conf`, and line 12 of the main file reads every file in
`sshd_config.d` before anything else in it.

## The first value wins

Here `sshd` differs from most programs you will configure: **for most settings, the first value it
reads is the one it keeps.** The files in `sshd_config.d` are read in name order, so a file called
`10-hardening.conf` is read before `50-old.conf`, and its values win without touching the old file:

```
ana@web:~$ printf "PermitRootLogin no\nPasswordAuthentication no\nX11Forwarding no\nMaxAuthTries 3\n" | sudo tee /etc/ssh/sshd_config.d/10-hardening.conf
PermitRootLogin no
PasswordAuthentication no
X11Forwarding no
MaxAuthTries 3
ana@web:~$ sudo sshd -t && sudo systemctl reload ssh; echo "exit $?"
exit 0
ana@web:~$ sudo sshd -T | grep -E '^(permitrootlogin|passwordauthentication|x11forwarding|maxauthtries) '
maxauthtries 3
permitrootlogin no
passwordauthentication no
x11forwarding no
```

`sshd -t` checks the configuration and prints nothing if it is valid; only then is the server told
to reload, so a typo never takes SSH down. Reloading leaves sessions that are already open alone. `sshd -T` confirms all four values.

Each one closes something specific:

| setting | what it closes |
|---|---|
| `PermitRootLogin no` | the one account name every attacker knows; administrators log in as themselves and use `sudo`, which leaves a name in the log |
| `PasswordAuthentication no` | guessing: only somebody holding a private key can log in |
| `X11Forwarding no` | graphical programs tunnelled from the server, which a server with no screen never needs |
| `MaxAuthTries 3` | fewer attempts per connection, so guessing needs more connections and is easier to see |

## Proving it from the other side

A setting is a claim until a client has been refused. From `desk`, try the intern's account with a
password, and then your own with your key:

```
ana@desk:~$ ssh -o PreferredAuthentications=password -o BatchMode=yes estagio@web true; echo "exit $?"
estagio@web: Permission denied (publickey).
exit 255
ana@desk:~$ ssh web hostname
web
```

The refusal says what the server offers, `publickey`, and nothing else; the password was never asked
for. Your own login still works. **Always keep a session open while you change SSH on a remote
machine**, and test from a second one before closing the first.
A wrong setting that locks you out
of a server in another city is a drive, or a call to whoever has the console.

Lesson 15 goes further down this road: one machine allowed to reach the others, and keys that
expire within the hour.
