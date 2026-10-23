---
title: Accounts that should not log in
version: 1
---

**Every account that can log in is a way in, and a way in that is also a name and a password.** A
listener needs a bug to be dangerous. An account needs only its password, and passwords are guessed,
reused and written on notes. So the accounts on a server get the same treatment as its services:
list them, ask what each one is for, and remove or lock what has no answer.

## Who is root

Root is not a name, it is the user id 0. The kernel checks the number, never the name, so **any
account with id 0 is root**, whatever it is called:

```
ana@web:~$ awk -F: '$3 == 0 {print $1, $6}' /etc/passwd
root /root
suporte /root
```

`suporte` ("support") is root under another name, with root's home directory. Accounts like this
are made so somebody can log in as root without the root password, and then forgotten. It is also
one of the first things an intruder adds to a machine, which is why an audit asks this question
every time, and why the honest answer has to be one line.

## Who has a shell and a password

An account logs in interactively only if its shell is a real shell. Service accounts get
`/usr/sbin/nologin`, which prints a refusal and exits:

```
ana@web:~$ awk -F: '$7 !~ /(nologin|false|sync)$/ {print $1, $3, $7}' /etc/passwd
root 0 /bin/bash
ana 1000 /bin/bash
portal 999 /bin/bash
estagio 1001 /bin/bash
suporte 0 /bin/bash
ana@web:~$ sudo passwd -S -a | grep -v " L "
estagio P 2026-10-23 0 99999 7 -1
suporte P 2026-10-23 0 99999 7 -1
ana@web:~$ sudo grep -r NOPASSWD /etc/sudoers.d
/etc/sudoers.d/ana:ana ALL=(ALL) NOPASSWD:ALL
/etc/sudoers.d/estagio:estagio ALL=(ALL) NOPASSWD:ALL
```

Three findings, one per command. **`portal` has a shell**: it is the account the portal runs as, and
nobody ever needs to log in as it, but if somebody steals its password or finds a way to make the
portal run a command, a shell is what they get. **Two accounts have a usable password**: `passwd -S`
prints `P` for a password that works, `L` for a locked one and `NP` for none, and the `grep` hid the
locked ones. `estagio`, the intern's account, and `suporte` both have one. **And `estagio` may run
anything as root without typing a password**, through a file in `/etc/sudoers.d`. Yours appears
too: that line is the lab's convenience, and on a real server your `sudo` would ask for your
password.

## Removing the second root

The obvious command fails, and the reason is worth knowing:

```
ana@web:~$ sudo userdel suporte; echo "exit $?"
userdel: user suporte is currently used by process 1
exit 8
```

`userdel` refuses to delete an account that owns a running process, and process 1 runs as user id
0. To `userdel`, `suporte` and `root` are the same account, because the number is the same. **Do not
force it, and above all do not add `-r`**: `-r` deletes the account's home directory, and the home
directory of `suporte` is `/root`. What removes the name and nothing else is deleting its line from
the four files that hold accounts:

```
ana@web:~$ sudo sed -i "/^suporte:/d" /etc/passwd /etc/shadow /etc/group /etc/gshadow; getent passwd 0
root:x:0:0:root:/root:/bin/bash
ana@web:~$ sudo usermod -L -e 1 -s /usr/sbin/nologin estagio; sudo rm /etc/sudoers.d/estagio
ana@web:~$ sudo usermod -s /usr/sbin/nologin portal; sudo systemctl restart portal; systemctl is-active portal
active
ana@web:~$ sudo passwd -S estagio; sudo passwd -S portal; sudo chage -l estagio | head -4
estagio L 2026-10-23 0 99999 7 -1
portal L 2026-10-23 -1 -1 -1 -1
Last password change					: Oct 23, 2026
Password expires					: never
Password inactive					: never
Account expires						: Jan 02, 1970
```

`getent passwd 0` now finds only root. The intern's account is not deleted, because files and logs may still carry its name.
Three changes lock it instead: `usermod -L` locks the password, `-e 1` sets the account's expiry to day 1
of the Unix calendar, which `chage` prints as 2 January 1970, and `-s` takes the shell away. Each one alone would stop a login; all three
make the intent unmistakable to the next person who reads the account. `passwd -S` now
prints `L` for both accounts. The portal still starts, as `active` shows, because a service never needed a login shell.

## What the list does not show

Two things belong to the same question and are not in `/etc/passwd`. **SSH keys** let somebody in
without any password: each account's `~/.ssh/authorized_keys` is a list of who may log in as it, and
a key left behind by somebody who left the firm is an open account. And **group membership** grants
power quietly: `getent group sudo` lists everybody who may use `sudo`, whatever the files in
`/etc/sudoers.d` say. Both are one command each:

```
ana@web:~$ getent group sudo; sudo find / -xdev -name authorized_keys 2>/dev/null
sudo:x:27:ana
/home/ana/.ssh/authorized_keys
```

On `web` the only member of `sudo` is you, and the only key file is yours, the one `build` made.
On a machine you inherit, each line of each key file needs a name beside it.
