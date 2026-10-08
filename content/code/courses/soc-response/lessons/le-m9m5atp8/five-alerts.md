---
title: Five alerts, one at a time
version: 1
---

Lesson 4's first rule raised five alerts. Take them in the order they arrived, as a queue would deliver
them. The first came from `203.0.113.41` on Monday:

```
ana@soc:~/week$ bash context.sh 203.0.113.41
day         product   action      accounts  n
----------  --------  ----------  --------  -
2026-09-14  firewall  connection            2
2026-09-14  sshd      failure     helena    1
2026-09-14  sshd      success     helena    1
2026-09-15  firewall  connection            1
2026-09-15  sshd      success     helena    1
2026-09-16  firewall  connection            1
2026-09-16  sshd      success     helena    1
2026-09-17  firewall  connection            1
2026-09-17  sshd      success     helena    1
2026-09-18  firewall  connection            1
2026-09-18  sshd      success     helena    1
```

**What fired:** a failure then a success. **Is it real:** yes, both lines exist. **Is it expected:** this
address logs in as helena every weekday morning, once, with one typo on Monday. Close it as a **false
positive**, reason "known user, known address, one typo", and move on. The two alerts from
`203.0.113.23` on Tuesday and Wednesday read the same way for carla, as lesson 4 showed; both close with
the same reason. Three alerts, three minutes.

The fourth, from `203.0.113.66` on Thursday at 02:33:

```
ana@soc:~/week$ bash context.sh 203.0.113.66
day         product   action      accounts                                                                                                           n 
----------  --------  ----------  -----------------------------------------------------------------------------------------------------------------  --
2026-09-17  firewall  connection                                                                                                                     59
2026-09-17  sshd      failure     ana,bruno,carla,diego,helena,root,admin,test,oracle,ubuntu,user,backup,git,finance,hr,scanner,printer,support,dev  57
2026-09-17  sshd      success     bruno                                                                                                              2 
```

Nothing before Thursday. 57 failures over 19 accounts, most of them names that do not exist here, then
two successes as bruno. **Is it expected?** Bruno's own history answers:

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT datetime(timestamp, '-3 hours') AS local, host, method, src_ip FROM logs WHERE user = 'bruno' AND action = 'success'"
local                host   method     src_ip       
-------------------  -----  ---------  -------------
2026-09-14 08:33:31  gw     password   203.0.113.17 
2026-09-15 08:00:36  gw     password   203.0.113.17 
2026-09-16 08:28:51  gw     password   203.0.113.17 
2026-09-17 02:33:07  gw     password   203.0.113.66 
2026-09-17 02:35:40  files  password   198.51.100.22
2026-09-17 03:05:22  gw     publickey  203.0.113.66 
2026-09-17 08:35:03  gw     password   203.0.113.17 
2026-09-18 08:29:00  gw     password   203.0.113.17 
```

Every other day, bruno logs in once, around half past eight, with a password, from `203.0.113.17`. On
Thursday there are three logins he would not recognise: from a new address at 02:33, **onwards to the
file server from `gw` two minutes later**, and back at 03:05 with a key, a method he never uses. And at
08:35 he logged in as usual from home, so the person and the account were in two places that morning.

That is enough to escalate. One more look, at what crossed the firewall in that hour, belongs in the
escalation note:

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT datetime(timestamp, '-3 hours') AS local, product, src_ip, dst_ip, dst_port, bytes FROM logs WHERE timestamp BETWEEN '2026-09-17 05:30' AND '2026-09-17 06:30' AND product IN ('firewall', 'flow') ORDER BY timestamp"
local                product   src_ip         dst_ip         dst_port  bytes    
-------------------  --------  -------------  -------------  --------  ---------
2026-09-17 02:33:07  firewall  203.0.113.66   198.51.100.22  22                 
2026-09-17 02:35:40  firewall  198.51.100.22  192.168.20.10  22                 
2026-09-17 02:41:12  firewall  192.168.20.10  203.0.113.200  443                
2026-09-17 02:41:12  flow      192.168.20.10  203.0.113.200  443       612408119
2026-09-17 03:05:22  firewall  203.0.113.66   198.51.100.22  22                 
```

At 02:41, `files` opened a connection to `203.0.113.200` and sent **612,408,119 bytes**, about 612 MB, to an
address the backup never uses. The fifth alert, at 03:05, is the same visitor; it goes into the same
escalation rather than a second one. **Five alerts became three closures and one escalation**, and the
escalation is about something no rule was written for: the transfer.
