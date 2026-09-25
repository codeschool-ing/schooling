---
title: Creating, locking and removing an account
version: 1
---

The new person gets an account. **`useradd`** creates it; `-m` makes the home folder, `-s` sets the
shell and `-c` the full name:

```
ana@server:~$ sudo useradd -m -s /bin/bash -c "Carla Souza" carla
ana@server:~$ getent passwd carla
carla:x:1001:1001:Carla Souza:/home/carla:/bin/bash
ana@server:~$ sudo passwd -S carla
carla L 2026-09-25 0 99999 7 -1
ana@server:~$ ls -A /home/carla
ls: cannot open directory '/home/carla': Permission denied
ana@server:~$ sudo ls -A /home/carla
.bash_logout
.bashrc
.profile
```

- `getent` shows the new line, with the **next free ID, 1001**.
- **`passwd -S` says `L`**: the account exists, and it is **locked** because it has no password yet.
  Nobody can log in to it, which is the safe way for an account to be born.
- ana could not list carla's home, the `drwxr-x---` of lesson 9, and with `sudo` could: the new home
  was filled from **`/etc/skel`**, the files every new user starts with.

## A password, and the first login

```
ana@server:~$ sudo passwd carla
New password: 
Retype new password: 
passwd: password updated successfully
ana@server:~$ sudo passwd -S carla
carla P 2026-09-25 0 99999 7 -1
```

**The password was typed twice and never shown**, which is how every password prompt on Linux behaves:
not even asterisks, so somebody watching cannot count the characters. The status is now `P`, a usable
password.

**`su`** switches to another user, and asks for **that user's** password:

```
ana@server:~$ su - carla
Password: 
carla@server:~$ whoami
carla
carla@server:~$ exit
logout
```

A temporary password should not outlive the first login, so the account is set to demand a new one:

```
ana@server:~$ sudo passwd -e carla
passwd: password changed.
ana@server:~$ sudo chage -l carla | head -3
Last password change					: password must be changed
Password expires					: password must be changed
Password inactive					: password must be changed
```

## Leaving

```
ana@server:~$ sudo usermod -L carla
ana@server:~$ sudo passwd -S carla
carla L 1970-01-01 0 99999 7 -1
ana@server:~$ sudo usermod -U carla
```

When somebody leaves, **lock first**: `usermod -L` disables the password while keeping the account,
its files and its ownership intact, and `-U` undoes it. Lock on the last day, and delete later, once
their files have been handed on.

```
ana@server:~$ sudo userdel -r carla
userdel: carla mail spool (/var/mail/carla) not found
ana@server:~$ getent passwd carla || echo "no such user"
no such user
```

**`userdel -r`** removes the account and its home folder. The warning about a mail spool is harmless:
there was no mail. Files the person owned **elsewhere**, in a shared folder, are not removed; they
remain, owned by a number, 1001, with no name, until the next account created receives the same ID and,
with it, those files. That is one more reason to hand files on before deleting.
