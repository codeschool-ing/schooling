---
title: Closing the hole
version: 1
---

Removing the key undoes what the intruder did. It does not stop the next one, because the way in is still
open: `gw` accepts passwords from the internet, and a password can be guessed. `sshd -T` prints the settings
the server would actually use, after every file has been read, which is the honest answer to "what does this
server allow?":

```
root@soc:~# sshd -T | grep -E '^(password|pubkey)authentication'
pubkeyauthentication yes
passwordauthentication yes
root@soc:~# echo 'PasswordAuthentication no' > /etc/ssh/sshd_config.d/50-keys-only.conf
root@soc:~# sshd -T | grep -E '^(password|pubkey)authentication'
pubkeyauthentication yes
passwordauthentication no
```

Before: `passwordauthentication yes`. One line in a file of its own under `sshd_config.d/`, and after:
`no`. Keys still work, so nobody who has one loses access. A drop-in file of its own, rather than an edit in
the middle of `sshd_config`, is easier to find, to review, and to put in the standard build, which is where
it has to end up.

Run the setting as a check, not a belief: `sshd -T` reads the configuration the way the server will at its
next start, so a typo shows up here, before the restart, and not as a server that refuses everybody.

**The order matters.** Every user has to have a key, recorded in the inventory, *before* passwords are
switched off, or the fix locks out the staff along with the intruder. On Thursday, that meant bruno got his
new key in person first, as lesson 13's decision log says, and the setting changed afterwards.

Closing the hole is the step that turns an incident into an improvement, and it is also the one most often
skipped: the key is gone, the server works, everybody is tired. Lesson 15 is where skipped steps like this
are found.
