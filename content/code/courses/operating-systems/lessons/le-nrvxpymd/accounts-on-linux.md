---
title: Where Linux keeps its accounts
version: 1
---

Every account on a Linux machine is a line in **`/etc/passwd`**, seven fields separated by colons.
`getent` prints the lines for the accounts you name:

```
ana@server:~$ getent passwd root ana www-data nobody
root:x:0:0:root:/root:/bin/bash
ana:x:1000:1000::/home/ana:/bin/bash
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
ana@server:~$ awk -F: '$3 < 1000' /etc/passwd | wc -l
22
ana@server:~$ awk -F: '$3 >= 1000 && $3 < 65534' /etc/passwd
ana:x:1000:1000::/home/ana:/bin/bash
```

Taking `ana`'s line apart: *name*, `x` (the password is kept elsewhere), *user ID* 1000, *group
ID* 1000, a comment for the person's full name (empty for ana), *home folder*, and the *shell*
that starts when she logs in.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 140\" role=\"img\" aria-label=\"The user ID numbers on Ubuntu, from left to right. 0 is root, the administrator. 1 to 999 are system accounts, for services rather than people; www-data, the web server&#x27;s, is 33. 1000 and up are people: ana is 1000, the next person 1001. 65534 is nobody, an account that owns nothing on purpose.\"><defs><marker id=\"ui-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"90\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"65.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><text x=\"65.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">root</text><text x=\"65.0\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the administrator</text><rect x=\"114\" y=\"20\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"214.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1 to 999</text><text x=\"214.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">system accounts</text><text x=\"214.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">services, no person: www-data is 33</text><rect x=\"318\" y=\"20\" width=\"240\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"438.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1000 and up</text><text x=\"438.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">people</text><text x=\"438.0\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ana is 1000, the next person 1001</text><rect x=\"562\" y=\"20\" width=\"138\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"631.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">65534</text><text x=\"631.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">nobody</text><text x=\"631.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">owns nothing on purpose</text></svg>", "caption": "The system decides by the number, not the name. An account called admin with ID 1005 is an ordinary user; any account with ID 0 is root, whatever it is called."}
```

The server has **22 accounts below 1000 and one person**, ana. Most accounts on a Linux machine are not
people: `www-data` is the account a web server runs as, so a flaw in the web server gets only what
`www-data` may touch. Their shell is **`/usr/sbin/nologin`**, which refuses any attempt to log in as them.

## Groups

```
ana@server:~$ groups
ana sudo
ana@server:~$ getent group sudo
sudo:x:27:ana
```

**`/etc/group`** is the same idea for groups: the name, an `x`, the group ID, and the members. **Being
in the group `sudo` is what makes ana an administrator on Ubuntu**. Nothing about her account is special
otherwise. Other distributions call that group `wheel`.

## The password is not in passwd

`/etc/passwd` has to be readable by everybody, because every `ls -l` turns user IDs into names. So the
password hashes live in **`/etc/shadow`**, readable only by root. `passwd -S` reports on them without
showing them, which section 02 uses.
