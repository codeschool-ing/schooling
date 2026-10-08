---
title: A rule that names the application
version: 1
---

With the protocol known, a rule can ask about it. Two rules in Suricata's language, one per line:

```
root@fw:~# cat /etc/suricata/rules/local.rules
alert ssh $HOME_NET any -> $EXTERNAL_NET any (msg:"SSH leaving the LAN"; flow:to_server,established; ssh.proto; content:"2.0"; sid:1000001; rev:1;)
alert tls $HOME_NET any -> any !443 (msg:"TLS on a port other than 443"; flow:to_server,established; tls.sni; content:"."; sid:1000002; rev:1;)
root@fw:~# suricata -T -c /etc/suricata/suricata.yaml 2>&1 | tail -1
i: suricata: Configuration provided was successfully loaded. Exiting.
```

Read the first one piece by piece:

| part | says |
|---|---|
| `alert` | what to do on a match; lesson 14 turns this into `drop` |
| `ssh` | the application protocol, as Suricata recognised it, on any port |
| `$HOME_NET any -> $EXTERNAL_NET any` | from the company's networks, to anywhere outside |
| `flow:to_server,established` | on the client's side of a connection that completed its handshake |
| `ssh.proto; content:"2.0"` | the protocol version the client announced |
| `sid:1000001; rev:1` | the rule's number and revision; local rules take numbers from a million up |

The second rule looks for TLS going to any port **other than** 443. `suricata -T` checks that both
load before anything runs. Empty the logs of the first run with
`rm -f /var/log/suricata/*.json /var/log/suricata/*.log`, start Suricata with the same command as
before, and give it a few seconds. Then the SSH attempt and a normal page fetch again:

```
ana@laptop:~$ ssh -p 443 -o BatchMode=yes 203.0.113.50 true; echo "exit $?"
ana@203.0.113.50: Permission denied (publickey).
exit 255
ana@laptop:~$ curl -s -o /dev/null https://www.example.com/; echo "exit $?"
exit 0
```

```
root@fw:~# jq -c "select(.event_type==\"alert\") | [.src_ip, .dest_ip, .dest_port, .alert.signature_id, .alert.signature]" /var/log/suricata/eve.json
["192.168.10.20","203.0.113.50",443,1000001,"SSH leaving the LAN"]
root@fw:~# cat /var/log/suricata/fast.log
09/28/2026-15:17:47.539067  [**] [1:1000001:1] SSH leaving the LAN [**] [Classification: (null)] [Priority: 3] {TCP} 192.168.10.20:37562 -> 203.0.113.50:443
```

**One alert, for the SSH session, and none for the web page.** The second rule stayed silent because
the only TLS in this capture went to 443, which is what it is meant to do: most of the time a good
policy rule says nothing.

## What an application policy looks like in a product

Commercial NGFWs write the same idea in a table rather than a rule language. The row that replaces
"allow 443" reads roughly as "from the staff zone, to the internet, application web-browsing,
allow", followed by "from the staff zone, to the internet, application SSH, deny". The mechanism
underneath is what this section ran: identify the protocol from the payload, then match the rule.

**An application rule does not replace the port rule; it narrows it.** The firewall still decides
which ports may open at all, and anything that fails there never reaches the slower inspection.
