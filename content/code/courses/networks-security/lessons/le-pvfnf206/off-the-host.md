---
title: Off the host, as it happens
version: 1
---

Everything so far is on `fw`, and a log on the machine it describes has a known weakness: whoever takes
the machine over can edit it. Lesson 16 promised the answer, which is to **ship every line elsewhere as
soon as it is written**, to a machine the source cannot reach back into.

Here the collector is `admin`, on the management network. `fw` runs **rsyslog** with this
configuration:

```schooling-example
{"language": "conf", "file": "rsyslog.conf", "parts": [{"code": "global(workDirectory=\"/var/log/lab/rsyslog\")\nmodule(load=\"imfile\")", "note": "The directory where rsyslog remembers how far into each file it has read, so a restart does not send everything again."}, {"code": "input(type=\"imfile\" file=\"/var/log/lab/drops.json\" tag=\"drops\" ruleset=\"ship\" reopenOnTruncate=\"on\")\ninput(type=\"imfile\" file=\"/var/log/lab/flows.json\" tag=\"flows\" ruleset=\"ship\" reopenOnTruncate=\"on\")", "note": "Follow both files and hand every new line to the ship rule set. The tag becomes the file name on the collector. reopenOnTruncate starts again from the top when a file is emptied, instead of waiting for it to grow past where it was."}, {"code": "ruleset(name=\"ship\") {\n  action(type=\"omfwd\" target=\"192.168.99.10\" port=\"514\" protocol=\"tcp\"\n         queue.type=\"LinkedList\" queue.filename=\"ship\" queue.saveOnShutdown=\"on\"\n         action.resumeRetryCount=\"-1\")\n}", "note": "Send each line over TCP to admin. The queue keeps lines on disk while the collector is unreachable, and the retry count of -1 means never give up."}]}
```

`admin` runs rsyslog too, listening on TCP port 514 and writing each machine's lines into a directory
of its own, and a host firewall decides who may talk to it:

```
root@admin:~# nft list ruleset
table inet host {
	chain input {
		type filter hook input priority filter; policy drop;
		ct state established,related accept
		iifname "lo" accept
		ip saddr 192.168.99.1 tcp dport 514 accept comment "logs from fw, and nothing else from it"
	}
}
root@admin:~# ls /var/log/lab/remote/fw/
drops.json
flows.json
root@admin:~# wc -l /var/log/lab/remote/fw/*.json
   4 /var/log/lab/remote/fw/drops.json
   7 /var/log/lab/remote/fw/flows.json
  11 total
```

The same lines are now in two places. Now suppose somebody with root on `fw` wants a clean slate, and
empties the drop log:

```
root@fw:~# : > /var/log/lab/drops.json; wc -l /var/log/lab/drops.json
0 /var/log/lab/drops.json
root@admin:~# wc -l /var/log/lab/remote/fw/drops.json
4 /var/log/lab/remote/fw/drops.json
```

The collector still holds all four. And recording carries on after the wipe: `remote` tries one more
port, and the line arrives at `admin` within seconds:

```
ana@remote:~$ probe 192.0.2.80:23
192.0.2.80:23          blocked
root@admin:~# tail -1 /var/log/lab/remote/fw/drops.json | jq -c '[.timestamp, .src_ip, .dest_port]'
["2026-09-28T18:55:35.444049-0300","203.0.113.50",23]
```

The last requirement is the one that makes the arrangement hold. `fw` may deliver lines, and nothing
else:

```
root@fw:~# nc -z -v -w1 admin 22; nc -z -v -w1 admin 514
nc: connect to admin (192.168.99.10) port 22 (tcp) timed out: Operation now in progress
Connection to admin (192.168.99.10) 514 port [tcp/shell] succeeded!
```

Port 22 times out, because `admin`'s rule set drops it. An intruder on `fw` can therefore **add** noise
to the collection, and cannot **change** what is already there. Three details make it sturdier in
production:

- **TLS on the way.** rsyslog can wrap port 514 in TLS and check both certificates, as lessons 12 and 20
  did for other services. The lab relies on the management network being a segment of its own.
- **A queue for when the collector is away.** `queue.saveOnShutdown` and `action.resumeRetryCount="-1"`
  hold lines on disk and retry for ever, so a restart on `admin` loses nothing.
- **An alarm on silence.** A source that stops sending is either switched off or switched off by
  somebody. A collector should notice when a source goes quiet for longer than it ever does, as a
  check of its own.
