---
title: Watching what a host listens on
version: 1
---

The configuration change in the previous section pointed at a program on port 8081. The file check saw
the configuration; a check of **what the host is listening on** sees the program itself. It is one of
the cheapest host checks there is, and the logic is the same as AIDE's: record a baseline, compare.

`www`'s listening sockets, saved as the baseline:

```
root@www:~# ss -Hltn | awk "{print \$4}" | sort > listening.baseline; cat listening.baseline
192.0.2.80:443
192.0.2.80:80
```

The shop on 80 and 443 and nothing else. Later, the same list compared against it:

```
root@www:~# ss -Hltn | awk "{print \$4}" | sort | diff listening.baseline -; ss -Hltnp "sport = :8081" | awk "{print \$4, \$6}"
0a1
> 0.0.0.0:8081
0.0.0.0:8081 users:(("socat",pid=23908,fd=5))
```

**A new listener, on every address, port 8081**, and the process holding it: `socat`, which has no
business on a production proxy. On `0.0.0.0` it answers on every interface the machine has, so the
firewall of lesson 4 is now all that stands between it and the DMZ. The network sensor saw nothing,
because nobody has connected to it yet; the host check saw it without anybody connecting.

Useful host checks share that shape, and a HIDS agent runs many of them on a schedule:

| check | baseline | a finding looks like |
|---|---|---|
| listening ports | the services the host is meant to run | a port nobody documented |
| files | hashes of configuration and binaries | a changed file with no change request |
| users and keys | accounts and `authorized_keys` entries | a new account, or a key nobody issued |
| processes | what normally runs | a shell spawned by the web server |
| authentication log | the usual logins | a login at 3 a.m. from a new address |

Each is small; together they describe a machine closely enough that most intrusions have to show up in
at least one. And because an intruder with root can edit what the host reports, **every finding is
shipped off the host as it happens**, to a place the host cannot reach back into. Lesson 23 is about that
place.
