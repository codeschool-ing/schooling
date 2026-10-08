---
title: Auditing the keys
version: 1
---

The first row of the checklist, in the lab. Every SSH key is identified by its **fingerprint**, a hash of
the public key that `ssh-keygen -l` prints. The inventory is a text file with one approved fingerprint per
line, and it starts with the one key the lab has, ana's from lesson 1:

```
root@soc:~# ssh-keygen -lf /home/ana/.ssh/id_ed25519.pub | awk '{print $2, "ana, work laptop"}' > inventory.txt
root@soc:~# cat inventory.txt
SHA256:QJsKkPtqEBuAn+lfcyMGgnotN3pJ16nFW1AbcdPz8bo ana, work laptop
root@soc:~# bash keyaudit.sh inventory.txt
/home/ana/.ssh/authorized_keys  SHA256:QJsKkPtqEBuAn+lfcyMGgnotN3pJ16nFW1AbcdPz8bo  approved
```

`awk` keeps the second field, the fingerprint, and adds a note about whose key it is. The audit is a short
script; write it as `keyaudit.sh` in root's home folder:

```schooling-example
{"language": "bash", "file": "keyaudit.sh", "parts": [{"code": "#!/usr/bin/env bash\n# keyaudit.sh INVENTORY: every key that can log in to this machine, checked against the inventory\ninv=${1:?usage: keyaudit.sh INVENTORY}", "note": "The inventory is a plain text file: one approved fingerprint per line, with whose key it is and how that was confirmed."}, {"code": "for f in /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys; do\n  [ -f \"$f\" ] || continue", "note": "Every place a key can sit for a login: root's file and one per home folder. A user with no file is skipped."}, {"code": "  ssh-keygen -lf \"$f\" | while read -r bits fp comment; do\n    if grep -qF \"$fp\" \"$inv\"; then verdict=approved; else verdict=\"NOT IN INVENTORY\"; fi\n    printf '%s  %s  %s\\n' \"$f\" \"$fp\" \"$verdict\"\n  done", "note": "ssh-keygen -l prints one line per key: its size, its fingerprint, its comment. The fingerprint is looked up as a fixed string, never trusting the comment, which anybody adding a key can write."}, {"code": "done"}]}
```

Run against the inventory, it finds one key, and that key is approved. Now the case an audit exists for. ana
makes a second key, for a new laptop, and adds it to the same file without telling anybody:

```
ana@soc:~$ ssh-keygen -q -t ed25519 -N '' -C ana@new-laptop -f ~/.ssh/new_laptop
ana@soc:~$ cat ~/.ssh/new_laptop.pub >> ~/.ssh/authorized_keys
root@soc:~# bash keyaudit.sh inventory.txt
/home/ana/.ssh/authorized_keys  SHA256:QJsKkPtqEBuAn+lfcyMGgnotN3pJ16nFW1AbcdPz8bo  approved
/home/ana/.ssh/authorized_keys  SHA256:ykVlgi+dtYAE67tXLUi1uRZaHEI9eZpkN+bDeY+MZO8  NOT IN INVENTORY
```

The second line is the audit doing its job: **a key that can log in, and that nobody wrote down.** Notice what
the line does not say. It does not say the key is an intruder's. Here it is a colleague's new laptop; on
Thursday, in bruno's file, it was not. **An unknown key is a question for the account's owner, asked through
another channel**, in person or by phone, never by a message to the account that may be compromised.

Once the owner confirms it, the key goes into the inventory, with how it was confirmed, and the audit is clean
again:

```
root@soc:~# ssh-keygen -lf /home/ana/.ssh/new_laptop.pub | awk '{print $2, "ana, new laptop, confirmed in person"}' >> inventory.txt
root@soc:~# bash keyaudit.sh inventory.txt
/home/ana/.ssh/authorized_keys  SHA256:QJsKkPtqEBuAn+lfcyMGgnotN3pJ16nFW1AbcdPz8bo  approved
/home/ana/.ssh/authorized_keys  SHA256:ykVlgi+dtYAE67tXLUi1uRZaHEI9eZpkN+bDeY+MZO8  approved
```

The fingerprints in your run are different from these: every key pair is new. What matters is the pattern.
Run the audit on a schedule, not only during an incident, and **a key appearing between two runs is an
alert**, which is exactly what Thursday's key would have been, hours before anybody read lesson 4's alerts.
