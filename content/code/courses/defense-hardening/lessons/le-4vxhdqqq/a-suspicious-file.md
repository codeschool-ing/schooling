---
title: A suspicious file, written by you
version: 1
---

**To watch a sandbox work, you need a program that tries things a sandbox should stop.** Real
malicious files are the wrong way to get one: they are dangerous to keep, illegal to pass around
in many places, and no lesson needs one. This one is written for the lesson and does nothing
harmful. It plays a script a client sent the firm, claiming to format a report. Save it on `web`
as `relatorio.sh`:

```schooling-example
{"language": "sh", "file": "relatorio.sh", "parts": [{"code": "#!/bin/bash\n# relatorio.sh: says it formats a client's report. Written for this lesson; it harms nothing.\necho \"formatting the report...\"\nls \"$HOME/.ssh\" 2>&1 | head -3\necho \"checked\" 2>&1 > /etc/relatorio-was-here || echo \"could not write to /etc\"\ncurl -s -m 3 http://192.168.60.66:8443/hello || echo \"could not reach 192.168.60.66\"\necho \"done\"", "note": "Three things a report formatter never needs to do, each harmless here: list the names of the files in your SSH directory, leave a file in `/etc`, and open a connection to another machine. Each line prints what happened, so you can see which of them the sandbox allowed."}]}
```

It lists only the **names** in your SSH directory, never their contents, writes the word
`checked`, and asks `trap` for a page that is not there. Each of those stands for something a
report formatter has no reason to do: look for keys, change the system, talk to a machine
elsewhere.

**Do not run it outside a sandbox**, even though you know it is harmless. That is the habit the
lesson is building: an unknown script is opened inside the walls first, every time, because the
one time it matters is the time you were sure it did not.

What the walls should protect is easy to state on `web`. Your account has an SSH directory, and
`/etc` has no file called `relatorio-was-here`:

```
ana@web:~$ ls ~/.ssh; ls /etc/relatorio-was-here 2>&1
authorized_keys
config
id_ed25519
id_ed25519.pub
ls: cannot access '/etc/relatorio-was-here': No such file or directory
```

Four files, your key pair among them: the one `build` made so that every machine trusts you. Their
names are exactly what an intruder's script looks for first. The next section runs the script
inside walls and compares.
