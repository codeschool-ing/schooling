---
title: Shipping logs off the machine
version: 1
---

A log kept only on the machine that wrote it shares that machine's fate. **A failed disk, a reinstall, an
administrator's mistake or a compromised account on that machine all reach the log too.** The answer is to
send each line to a second machine as it is written, run by different people, so that one machine's bad
day is not also the end of its record.

In the lab, `soc` is that second machine. Its rsyslog gets a second input, a TCP listener on the address
`gw` can reach, and a rule that files each sender's lines under its own name. Put this in
`/etc/rsyslog.d/10-remote.conf`:

```conf
module(load="imtcp")
template(name="perhost" type="string" string="/var/log/remote/%HOSTNAME%.log")
ruleset(name="remote") {
  action(type="omfile" dynaFile="perhost"
         fileCreateMode="0640" fileOwner="syslog" fileGroup="adm")
}
input(type="imtcp" address="192.168.99.10" port="514" ruleset="remote")
```

The file's mode, owner and group are spelled out because this kind of action does not inherit the old
`$FileCreateMode` from `rsyslog.conf`: without them the copies come out readable by every user on `soc`.
Create the folder, restart rsyslog with `systemctl restart rsyslog` (the recording machine had no systemd
and restarted it by hand), and check it listens:

```
root@soc:~# mkdir -p /var/log/remote && chown syslog:adm /var/log/remote && chmod 750 /var/log/remote
root@soc:~# ss -ltn src 192.168.99.10
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      25     192.168.99.10:514       0.0.0.0:*          
```

On `gw`, a second rsyslog follows its SSH log and forwards every new line. Save this as
`/etc/soclab/gw-rsyslog.conf`:

```schooling-example
{"language": "conf", "file": "gw-rsyslog.conf", "parts": [{"code": "global(localHostname=\"gw\" workDirectory=\"/var/spool/rsyslog-gw\")", "note": "Who this rsyslog says it is, and where it keeps its queue. Without `localHostname` it would take the name of your computer, because the namespace shares it."}, {"code": "module(load=\"imfile\")\ninput(type=\"imfile\" file=\"/var/log/soclab/gw-auth.log\" tag=\"gw-auth:\")", "note": "`imfile` follows a text file the way `tail -f` does, and turns each new line into a message tagged `gw-auth:`."}, {"code": "action(type=\"omfwd\" target=\"192.168.99.10\" port=\"514\" protocol=\"tcp\"\n       template=\"RSYSLOG_SyslogProtocol23Format\"", "note": "Send every message to soc over TCP, in the RFC 5424 format, which carries the time zone with the time."}, {"code": "       queue.type=\"LinkedList\" queue.filename=\"to-soc\" queue.saveOnShutdown=\"on\"\n       action.resumeRetryCount=\"-1\")", "note": "A queue in memory and on disk, saved if rsyslog stops, retried until it succeeds: if soc is down, lines wait on gw instead of being lost."}]}
```

Start it inside `gw`, cause one failed login from `outside`, and look on `soc`:

```
root@soc:~# mkdir -p /var/spool/rsyslog-gw
root@soc:~# ip netns exec gw rsyslogd -f /etc/soclab/gw-rsyslog.conf -i /run/rsyslogd-gw.pid
root@soc:~# ip netns exec outside ssh -o BatchMode=yes -o StrictHostKeyChecking=no admin@198.51.100.22 true
admin@198.51.100.22: Permission denied (publickey,password).
root@soc:~# cat /var/log/remote/gw.log
2026-10-07T04:51:42.824635-03:00 gw gw-auth 2026-10-07T04:51:39-0300 gw sshd: Server listening on 198.51.100.22 port 22.
2026-10-07T04:51:43.986525-03:00 gw gw-auth 2026-10-07T04:51:43-0300 gw sshd: Invalid user admin from 203.0.113.66 port 32906
2026-10-07T04:51:43.991050-03:00 gw gw-auth 2026-10-07T04:51:43-0300 gw sshd: Connection closed by invalid user admin 203.0.113.66 port 32906 [preauth]
```

Each line now carries **two time stamps**: the first is when rsyslog on `gw` read the line, with
microseconds and the zone, and the second is the one `ts` had already written. Here they are within a
second of each other; on a day the collector was down and the queue held the lines, they would be minutes
apart, and that gap is how an analyst sees that the collector was down.

Two cautions. Syslog over plain TCP travels **in clear text**, so on a real network the same `omfwd` action
takes TLS settings, and the collector accepts only the senders it knows. And **forwarding is one road among
several**: Windows machines use Windows Event Forwarding or an agent, and cloud services push their logs
through an API. Lesson 4 receives all of them in one place.
