---
title: File integrity: noticing that something changed
version: 1
---

An intruder who wants to stay has to change something: a configuration that opens a door, a key that
lets them back in, a program replaced with one that does more. **File integrity monitoring** records
what the files that matter looked like, and reports any difference. It is lesson 11's hash applied to a
whole server, on a schedule.

**AIDE** is the classic tool. Its configuration names what to record and which directories to watch;
on `www`, the proxy's configuration, the TLS keys and the SSH configuration:

```
root@www:~# cat /etc/aide/shop.conf
database_in=file:/var/lib/aide/aide.db
database_out=file:/var/lib/aide/aide.db.new
report_url=stdout
Watch = p+u+g+s+m+c+sha256
/etc/nginx Watch
/etc/ssl/private Watch
/etc/ssh Watch
```

`Watch` records permissions, owner, group, size, modification and change times, and a SHA-256 of the
contents. The first run builds the database of how things are now, which becomes the reference:

```
root@www:~# aide --config /etc/aide/shop.conf --init | grep -E "^Number|^AIDE"; mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
AIDE successfully initialized database.
Number of entries:	43
```

43 entries. Checked immediately, nothing differs, and AIDE exits with 0:

```
root@www:~# aide --config /etc/aide/shop.conf --check | grep -E "^AIDE|^Number|found"; echo "exit $?"
AIDE found NO differences between database and filesystem. Looks okay!!
Number of entries:	43
exit 0
```

Then somebody adds a location to the proxy's configuration, sending `/debug/` to a program on port
8081. AIDE, run again:

```
root@www:~# aide --config /etc/aide/shop.conf --check > aide.txt; echo "exit $?"; grep -E "^Summary|^ *Total|^ *Changed|^[fd] " aide.txt
exit 4
Summary:
  Total number of entries:	43
  Changed entries:		2
Changed entries:
d = ... mc        : /etc/nginx/sites-enabled
f > ... mc  H     : /etc/nginx/sites-enabled/shop
```

**Exit code 4**, which means *changed entries*, and two of them: the directory, whose modification and change
times moved, and the file itself, whose size, times and hash changed. The detail says by how much:

```
root@www:~# sed -n "/^File: /,/^$/p" aide.txt | grep -E "^File|Size|Mtime|SHA256"
File: /etc/nginx/sites-enabled/shop
 Size      : 602                              | 744
 Mtime     : 2026-09-28 18:06:09 -0300        | 2026-09-28 18:06:21 -0300
 SHA256    : quSh3YYoRucaiULCS+j/DH0mB8LL6A7d | gBTw4o9BdL4wu6Ygxf+qj8+Bn2nwcId1
```

602 bytes became 744, and the hashes have nothing in common. AIDE does not say whether the change was
a good one. That is a person's question, and it has a quick answer when changes are made through a
ticket: an AIDE report with no matching change request is the one to read first.

Two conditions make it worth running. **The reference database must live where an intruder cannot
rewrite it**, copied off the host or onto read-only media; a database the intruder can update reports
that nothing changed. And **the check must run on a schedule and send its report somewhere**; an
integrity check nobody reads is a file that changes every night.
