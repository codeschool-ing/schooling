---
title: The door says who came through
version: 1
---

**A single door is only useful if it keeps a record.** Before this lesson the question "who logged in
to `web` as root last night" had no good answer: every machine had the same key, and the log would
say `ana` from wherever. Now every administrative connection comes from `jump`, carries a certificate
with an identity in it, and `web` was told to log in detail with `LogLevel VERBOSE`:

```
root@web:~# journalctl -u ssh -o cat | grep -E "^(Accepted|Failed|error)" | tail -4
Accepted publickey for ana from 192.168.60.40 port 51346 ssh2: ED25519-CERT SHA256:uNd8LFH2OUEz1CO+izl+KXX0/r30W6iqUjUjMA8jRkk ID ana@jatoba (serial 0) CA ED25519 SHA256:cGACsyfksD/bNohootB5cxsSQnXiWRHRd0ZyB8Jxg/k
Failed publickey for ana from 192.168.60.40 port 51360 ssh2: ED25519 SHA256:uNd8LFH2OUEz1CO+izl+KXX0/r30W6iqUjUjMA8jRkk
error: Certificate invalid: expired
Failed publickey for ana from 192.168.60.40 port 51360 ssh2: ED25519-CERT SHA256:uNd8LFH2OUEz1CO+izl+KXX0/r30W6iqUjUjMA8jRkk ID ana@jatoba-yesterday (serial 0) CA ED25519 SHA256:cGACsyfksD/bNohootB5cxsSQnXiWRHRd0ZyB8Jxg/k
```

Read the four lines from the top. The first is the successful login: from `192.168.60.40`, the
bastion, with a **certificate** whose identity is `ana@jatoba`, signed by a named authority. The
other three are the expired attempt: the plain key was offered first and failed, because
`AuthorizedKeysFile none` means no plain key can succeed; then the certificate, refused as
`expired`, with its identity `ana@jatoba-yesterday` still written down.

**That identity is the point.** The account on the server is `ana` either way. The certificate's
identity says which certificate was used, and the authority's own record says who asked for it and
when. In a firm with three administrators who all log in as `ana`, or as `root`, it is the field that
turns "somebody logged in" into a name.

## What else a door can record

The log above records who entered and when, not what they did. Recording the session itself, every
keystroke and every line of output, is a separate tool, and none of the ones below was run for this
course:

- **tlog**, from Red Hat, records terminal sessions to the journal and can play them back; it is the
  usual open-source choice on Linux bastions.
- **`script`**, the standard Unix command, can be run by `ForceCommand` on a server so that every
  session is written to a file; it is crude and easy to bypass by an administrator who knows it is
  there.
- **Commercial privileged-access products** (CyberArk, BeyondTrust, Teleport and others) sit in the
  bastion's place, issue short-lived credentials themselves, record video of graphical sessions, and
  require approval for some targets.

Recording keystrokes captures passwords typed at prompts and the contents of files somebody opened,
so a recording is itself sensitive data: it is kept on a machine the people being recorded cannot
alter, for as long as the firm's policy says, and read only when there is a reason. **Tell
administrators it happens**; a recorder people know about changes behaviour, which is half of its
value, and one they discover feels like a trap.
