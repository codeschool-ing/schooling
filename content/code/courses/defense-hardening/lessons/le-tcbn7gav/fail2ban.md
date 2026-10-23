---
title: fail2ban, from log line to ban
version: 1
---

**fail2ban reads logs, counts failures per address, and bans an address that fails too often.**
It is the most common HIPS on Linux servers, and Ubuntu installs it with a jail for SSH already
switched on. Look at what is there before changing anything:

```
ana@web:~$ sudo fail2ban-client status sshd
Status for the jail: sshd
|- Filter
|  |- Currently failed:	0
|  |- Total failed:	0
|  `- Journal matches:	_SYSTEMD_UNIT=sshd.service + _COMM=sshd
`- Actions
   |- Currently banned:	0
   |- Total banned:	0
   `- Banned IP list:	
ana@web:~$ sudo fail2ban-client get sshd maxretry; sudo fail2ban-client get sshd actions
5
The jail sshd has the following actions:
nftables
```

The jail exists and has counted nothing yet. It would ban after five failures, and its action is
`nftables`, which is what Ubuntu 24.04 sets and what the system filters with.
**That choice matters more than it looks.** A ban is only real if the action takes effect, and an
action written for a firewall the machine does not use fails with an error in a log nobody reads,
while `fail2ban-client status` goes on listing the address as banned. A HIPS whose action does not
take effect is a HIDS that believes it is a HIPS, so this section checks the ban from
the other side.

Five is generous. A person who logs in with a key fails rarely, and a guesser gets two more tries
than it needs; three is enough. Save this as `jail.local` on `web`:

```schooling-example
{"language": "ini", "file": "jail.local", "parts": [{"code": "[sshd]\nenabled = true\nmaxretry = 3\nfindtime = 10m\nbantime = 10m", "note": "The jail for SSH: three failures within ten minutes from one address, and that address is refused for ten minutes. Each number is a trade, which the section on tuning weighs. Everything not written here, the log to read and the action that bans, is left as Ubuntu set it."}]}
```

`jail.local` is read after the package's own `jail.conf` and overrides it, so the package's file
stays untouched for the next update. Copy it in and restart fail2ban:

```
ana@web:~$ sudo cp jail.local /etc/fail2ban/ && sudo systemctl restart fail2ban && sleep 2 && sudo fail2ban-client get sshd maxretry
3
```

## A client that keeps failing

From `desk`, ask `web` four times for an account that does not exist. This is your own
workstation, failing against your own server, which is all fail2ban needs to see:

```
ana@desk:~$ for i in 1 2 3 4; do ssh -o BatchMode=yes visitor@web true; done
visitor@web: Permission denied (publickey,password).
visitor@web: Permission denied (publickey,password).
visitor@web: Permission denied (publickey,password).
visitor@web: Permission denied (publickey,password).
```

Four refusals, each one a line in `web`'s journal saying an invalid user tried to log in from
`192.168.60.20`. fail2ban reads them as they arrive:

```
ana@web:~$ sleep 2; sudo fail2ban-client status sshd | tail -3
   |- Currently banned:	1
   |- Total banned:	1
   `- Banned IP list:	192.168.60.20
ana@web:~$ sudo nft list table inet f2b-table
table inet f2b-table {
	set addr-set-sshd {
		type ipv4_addr
		elements = { 192.168.60.20 }
	}

	chain f2b-chain {
		type filter hook input priority filter - 1; policy accept;
		tcp dport 22 ip saddr @addr-set-sshd reject with icmp port-unreachable
	}
}
ana@desk:~$ nc -zv -w3 web 22 2>&1; curl -s -m3 http://web/
nc: connect to web (192.168.60.10) port 22 (tcp) failed: Connection refused
Jatobá Contabilidade: client portal
```

`desk` is banned. The table fail2ban made for it lives in `nftables` beside everything else, with a
set of banned addresses and a rule that rejects them on port 22. From `desk`, SSH is now refused,
and the portal on port 80 still answers: `multiport` bans the ports of the jail and nothing else,
so a client that mistyped a password does not lose the web site too.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l11-ban\" aria-label=\"How fail2ban turns log lines into a ban. sshd writes a line for each failed login to the journal. fail2ban's filter for sshd matches the line and pulls out the address. The jail counts failures per address within findtime. At maxretry the action adds the address to a set in nftables, and a rule there rejects it on port 22 for bantime.\"><defs><marker id=\"l11-ban-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"60.0\" width=\"120.0\" height=\"56.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sshd</text><text x=\"80.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">logs each failure</text><path d=\"M140.0 88.0 L160.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-ban-dh-ah-paper-dim)\"></path><rect x=\"160.0\" y=\"60.0\" width=\"120.0\" height=\"56.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"220.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">filter</text><text x=\"220.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">finds the address</text><path d=\"M280.0 88.0 L300.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-ban-dh-ah-paper-dim)\"></path><rect x=\"300.0\" y=\"60.0\" width=\"120.0\" height=\"56.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">jail</text><text x=\"360.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">counts per address</text><path d=\"M420.0 88.0 L440.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-ban-dh-ah-paper-dim)\"></path><rect x=\"440.0\" y=\"60.0\" width=\"120.0\" height=\"56.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">action</text><text x=\"500.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">adds it to a set</text><path d=\"M560.0 88.0 L580.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-ban-dh-ah-paper-dim)\"></path><rect x=\"580.0\" y=\"60.0\" width=\"120.0\" height=\"56.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">nftables</text><text x=\"640.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">rejects port 22</text><text x=\"300.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">maxretry = 3, findtime = 10m</text><text x=\"580.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bantime = 10m</text><text x=\"360.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">from a log line to a refused connection</text></svg>", "caption": "The last box is the one that has to be checked: a ban is real only if the firewall refuses."}
```

fail2ban's own log says what it saw and what it did, one line per failure and one per ban:

```
ana@web:~$ sudo grep -E "Found|Ban" /var/log/fail2ban.log | cut -d" " -f2,6-
09:30:21,329       [125]: INFO    [sshd] Found 192.168.60.20 - 2026-10-23 09:30:21
09:30:21,330       [125]: INFO    [sshd] Found 192.168.60.20 - 2026-10-23 09:30:21
09:30:21,330       [125]: INFO    [sshd] Found 192.168.60.20 - 2026-10-23 09:30:21
09:30:21,432      [125]: NOTICE  [sshd] Ban 192.168.60.20
```

## Lifting a ban

A ban ends by itself after `bantime`. When it was a colleague who forgot their key, it ends sooner
by hand:

```
ana@web:~$ sudo fail2ban-client set sshd unbanip 192.168.60.20
1
ana@desk:~$ ssh web hostname
web
```

The ban is lifted and `desk` logs in again. **A person lifting a ban is an event worth a line in the
change log**, because the next ban on the same address is a question about whether the first one
should have been lifted.
