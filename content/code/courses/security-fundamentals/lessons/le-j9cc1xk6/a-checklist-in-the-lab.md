---
title: A checklist in the lab
version: 1
---

The shop's server `www` has an SSH server installed, for remote administration, with the configuration
Ubuntu ships. The shop's checklist has four lines for it:

| setting | value wanted | why |
|---|---|---|
| `PermitRootLogin` | `no` | nobody logs in directly as root; administrators log in as themselves and use `sudo`, so every action has a name (lessons 1 and 6) |
| `PasswordAuthentication` | `no` | log in with a key, not a password that can be guessed or reused |
| `X11Forwarding` | `no` | a feature for running graphical programs remotely that a server does not need |
| `MaxAuthTries` | `4` | fewer guesses per connection |

### What the file says

The obvious way to check is to read the configuration file:

```
root@www:~# grep -n -i -E "^#?(permitrootlogin|passwordauthentication|x11forwarding|maxauthtries) " /etc/ssh/sshd_config
42:#PermitRootLogin prohibit-password
44:#MaxAuthTries 6
66:#PasswordAuthentication yes
99:X11Forwarding yes
```

Three of the four settings are **commented out**: the `#` at the start means the line is ignored, and
it only documents the default. It is easy to read `#PermitRootLogin prohibit-password` as "root login
is restricted", or to miss that a commented line means the default applies. The file also includes, near
its top, every file in `/etc/ssh/sshd_config.d/`, and anything there changes the picture again. **The
file is not the configuration.** The configuration is what the server would actually use.

### What the server would use

`sshd -T` asks the SSH server to read all of its configuration, apply every default and every included
file, and print the result, without starting. The checklist script asks it, and compares four values:

```schooling-example
{"language": "bash", "file": "check-ssh.sh", "parts": [{"code": "#!/bin/bash\n# Four lines of the shop's hardening checklist for the SSH server, checked\n# against the settings sshd would really use, not against what the file says.\neffective=$(sshd -T)", "note": "The settings sshd would really use, read once: every default applied and every included file read."}, {"code": "check() {\n  actual=$(awk -v key=\"$1\" '$1 == key { print $2 }' <<< \"$effective\")\n  if [ \"$actual\" = \"$2\" ]; then\n    echo \"PASS  $1 $actual\"\n  else\n    echo \"FAIL  $1 $actual, expected $2\"\n  fi\n}", "note": "One check: find the setting's line in that output, compare its value with the one wanted, and print PASS or FAIL with what was found."}, {"code": "check permitrootlogin no\ncheck passwordauthentication no\ncheck x11forwarding no\ncheck maxauthtries 4", "note": "The four lines of the checklist, each a setting and the value the shop wants."}]}
```

```
root@www:~# ./check-ssh.sh
FAIL  permitrootlogin without-password, expected no
FAIL  passwordauthentication yes, expected no
FAIL  x11forwarding yes, expected no
FAIL  maxauthtries 6, expected 4
```

All four fail. Root may log in with a key (`without-password` is another spelling of
`prohibit-password`), passwords are accepted, X11 forwarding is on and six attempts are allowed per
connection. None of it is visible as a problem in the file, and the server is exactly as the package
shipped it.

### The fix

The four settings go into a file of the shop's own in the included folder, rather than editing the
package's file, so that an update to the package does not undo them. `sshd -t` (lower-case `t`) checks
that the configuration is valid before anybody restarts the server:

```
root@www:~# printf "PermitRootLogin no\nPasswordAuthentication no\nX11Forwarding no\nMaxAuthTries 4\n" > /etc/ssh/sshd_config.d/50-shop.conf
root@www:~# cat /etc/ssh/sshd_config.d/50-shop.conf
PermitRootLogin no
PasswordAuthentication no
X11Forwarding no
MaxAuthTries 4
root@www:~# sshd -t; echo "exit $?"
exit 0
```

`exit 0` means the configuration parses. And the same checklist again:

```
root@www:~# ./check-ssh.sh
PASS  permitrootlogin no
PASS  passwordauthentication no
PASS  x11forwarding no
PASS  maxauthtries 4
```

All four pass, and the main file still says `X11Forwarding yes` on line 99. The included file is read
first, and for most settings **the first value sshd reads is the one it keeps**. That is exactly the kind
of rule that makes reading the file misleading and asking the program reliable.

This script is the start of the shop's secure configuration process, IG1's safeguard from two sections
back: run it every night, alert when a line turns to `FAIL`, and the server cannot drift away from the
checklist without somebody hearing about it.
