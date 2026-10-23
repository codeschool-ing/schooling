---
title: Who touched it
version: 1
---

**A honeypot's alert is one line, and that line is already the answer to the first question: which
machine.** Touch the bait from `desk`, the way a program on a compromised workstation looking around
the network would. It is your own machine and your own honeypot, and one connection is enough:

```
ana@desk:~$ nc -zv -w2 trap 445 2>&1
Connection to trap (192.168.60.66) 445 port [tcp/microsoft-ds] succeeded!
```

To `desk`, nothing happened: the port was open and the connection closed. On `trap`, the system log
and the JSON file both have it:

```
ana@trap:~$ sudo journalctl -t bait -o short-iso --no-pager
2026-10-23T10:13:47-03:00 trap bait[88]: touched: 192.168.60.20 on port 445
ana@trap:~$ cat /var/log/bait.jsonl
{"time": "2026-10-23T10:13:47-0300", "from": "192.168.60.20", "port": 445}
```

`192.168.60.20` is `desk`, on port 445, at that second. **There is nothing to tune, no threshold and
no false positive to argue about**, because nobody's work connects to `trap`. In a real firm that
line would go to the same place every other alert goes, and the response would start from `desk`,
the machine that touched it: what is running there, who is logged in, what else it connected to.
Lesson 8's telemetry is what answers those.

## A scan looks like this

Somebody exploring a network rarely tries one port. They scan, and a scan touches every listener at
once:

```
ana@desk:~$ nmap -Pn -p 1-3400 trap | grep -E "^[0-9]+/tcp"
22/tcp   open  ssh
23/tcp   open  telnet
445/tcp  open  microsoft-ds
1433/tcp open  ms-sql-s
3389/tcp open  ms-wbt-server
ana@trap:~$ sudo journalctl -t bait -o cat --no-pager | sort | uniq -c
      1 touched: 192.168.60.20 on port 1433
      1 touched: 192.168.60.20 on port 23
      1 touched: 192.168.60.20 on port 3389
      2 touched: 192.168.60.20 on port 445
```

The scan found SSH and the four bait ports, and `trap` logged a touch on each of the four, one per
port, beside the earlier touch on 445 that makes that line's count two. A machine that connects to four unrelated services on a machine nobody uses within a second
is not making a mistake.

**Mistakes happen, and they are the one false positive a honeypot has.** An administrator who scans
the network for an inventory, as lesson 18 does, touches the honeypot too. The answer is not to tune
the honeypot but to know about the scan: authorised scans are written down beforehand, from known
machines, and an alert from one of those at that time is closed with a note. An alert from anywhere
else is not.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l13-touch\" aria-label=\"One touch and its record. desk connects to trap on port 445. bait.py accepts and closes the connection at once, and writes the time, the address 192.168.60.20 and the port to its JSON file and as a warning to the system log. From there the line goes to wherever the firm's alerts are read, and the response starts from the machine that touched the bait.\"><defs><marker id=\"l13-touch-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-touch-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"70.0\" width=\"120.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><rect x=\"220.0\" y=\"70.0\" width=\"160.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"300.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">trap</text><text x=\"300.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bait.py on 445</text><path d=\"M140.0 95.0 L220.0 95.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-touch-dh-ah-paper-dim)\"></path><text x=\"180.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">connects</text><rect x=\"450.0\" y=\"40.0\" width=\"250.0\" height=\"40.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">touched: 192.168.60.20 on port 445</text><rect x=\"450.0\" y=\"110.0\" width=\"250.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a person, within minutes</text><path d=\"M380.0 90.0 L450.0 62.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-touch-dh-ah-paper-dim)\"></path><path d=\"M575.0 80.0 L575.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-touch-dh-ah-paper-dim)\"></path><path d=\"M575.0 150.0 L575.0 185.0 L80.0 185.0 L80.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-touch-dh-ah-amber)\"></path><text x=\"330.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the response starts from desk</text></svg>", "caption": "Nobody's work connects to trap, so the one line is already the finding."}
```
