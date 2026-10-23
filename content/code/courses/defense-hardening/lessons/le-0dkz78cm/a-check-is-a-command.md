---
title: A check is a command
version: 1
---

**Every control in every guide comes down to a question a machine can answer with yes or no.**
"Is root allowed to log in over SSH?" is `sshd -T` and a `grep`. "Is there more than one account
with user id 0?" is one line of `awk`. A guide's audit section is a list of such commands, and an
organisation's **baseline** is the same thing for its own machines: the controls it has decided
on, each with the command that proves it.

So write the portal's. Seven controls, the ones lesson 1 applied by hand, each a function that
succeeds when the machine is right. On `web`, in your home, create `check.sh`:

```schooling-example
{"language": "sh", "file": "check.sh", "parts": [{"code": "#!/bin/bash\n# check.sh: the portal's baseline, one line per control. Exit status: how many failed.\nfail=0\ncheck() {  # check ID 'what it means' COMMAND...: PASS if the command succeeds\n  local id=$1 what=$2; shift 2\n  if \"$@\" >/dev/null 2>&1; then echo \"PASS $id $what\"; else echo \"FAIL $id $what\"; fail=$((fail + 1)); fi\n}", "note": "`check` runs a command, throws its output away and keeps only the verdict. A control is a question with a yes or no answer, and the exit status of a command is exactly that. The count of failures becomes the script's own exit status, so another program can ask \"is this machine within the baseline?\" without reading a word."}, {"code": "only_root_uid0()   { [ \"$(awk -F: '$3 == 0' /etc/passwd | wc -l)\" -eq 1 ]; }\nno_telnet()        { ! ss -Htln | grep -q ':23 '; }\nno_ftp()           { ! dpkg -s vsftpd; }", "note": "Each control is a small function that succeeds when the machine is right. Notice what each one asks: not \"is there a line in a file\" but the state that line was meant to produce. Telnet is checked by asking what listens on port 23, so a telnet server started some other way fails it too."}, {"code": "no_root_login()    { sshd -T | grep -qx 'permitrootlogin no'; }\nno_passwords_ssh() { sshd -T | grep -qx 'passwordauthentication no'; }\nintern_locked()    { passwd -S estagio | grep -q ' L '; }\nno_version()       { ! curl -s -D - -o /dev/null http://localhost/ | grep -qi '^server: nginx/'; }", "note": "The SSH controls ask `sshd -T`, the settings the server would really run with, for the reason lesson 1 found: with several files, reading one of them answers the wrong question. The last one asks nginx itself what it says about itself."}, {"code": "check JAT-01 'only root has user id 0' only_root_uid0\ncheck JAT-02 'nothing listens for telnet' no_telnet\ncheck JAT-03 'no FTP server is installed' no_ftp\ncheck JAT-04 'root may not log in over SSH' no_root_login\ncheck JAT-05 'SSH refuses passwords' no_passwords_ssh\ncheck JAT-06 \"the intern's password is locked\" intern_locked\ncheck JAT-07 'nginx hides its version' no_version\nexit $fail", "note": "Every control has an id, `JAT-01` to `JAT-07`, written down rather than worked out from its position, so a report from March and one from June can be compared line by line even after a control is added in the middle."}]}
```

It must run as root, because `sshd -T` and `passwd -S` read files only root may read. On the
portal as it was handed over:

```
ana@web:~$ sudo bash check.sh; echo "failed: $?"
FAIL JAT-01 only root has user id 0
FAIL JAT-02 nothing listens for telnet
FAIL JAT-03 no FTP server is installed
FAIL JAT-04 root may not log in over SSH
FAIL JAT-05 SSH refuses passwords
FAIL JAT-06 the intern's password is locked
FAIL JAT-07 nginx hides its version
failed: 7
```

Seven controls, seven failures, and an exit status of 7. That number is the point of the last
line of the script. A person reads the list; a program reads the number, and **a check another
program can read is a check that can run every night** without anybody looking at it until it
says something.

## What makes a check worth having

A check that passes on a machine that is wrong is worse than no check, because it is believed.
Three habits keep them honest, and `check.sh` follows all three.

**Ask about the effect, not the file.** `no_telnet` does not look for a line in `/etc/inetd.conf`;
it asks what listens on port 23. A telnet server started any other way, by another super-server,
by hand or by a package nobody remembers, fails it all the same.

**Ask the program that decides.** The SSH checks read `sshd -T`, not `sshd_config`, because lesson
1 showed that the effective value can come from a file you did not open. The section after next
puts a file like that on `web` and watches this check catch it.

**Give every control an id that never changes.** `JAT-04` means "root may not log in over SSH"
for as long as the baseline exists. A report that numbered its lines by position would renumber
every control after a new one, and two months of results would stop being comparable.

What `check.sh` does not have is the guide's breadth: seven controls against Lynis's 259 tests.
That is deliberate. The seven are the ones this firm decided on, and each one is a promise
somebody can be asked about. The guide is where the next ones come from.
