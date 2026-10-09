---
title: A playbook that asks first
version: 1
---

Here is a playbook for lesson 4's best alert, *login accepted from an address that tried many accounts*.
It is a short Python program, because the logic of a playbook is the same whether it runs in a product's
visual editor or in a file. Save it in root's home folder as `playbook.py`; it needs the lab up, because
its one action is on `fw`.

```schooling-example
{"language": "python", "file": "playbook.py", "parts": [{"code": "# playbook.py DB ADDRESS [--approve NAME]\n# For the alert \"login accepted from an address that tried many accounts\":\n# gather the facts, propose what to do, and act only when a named person approves.\nimport ipaddress, json, sqlite3, subprocess, sys, datetime as dt\n\nNEVER_BLOCK = {\"203.0.113.11\", \"203.0.113.17\", \"203.0.113.23\", \"203.0.113.31\",\n               \"203.0.113.41\",                  # staff, working from home\n               \"203.0.113.150\"}                 # the backup provider\nOURS = [ipaddress.ip_network(n) for n in (\"198.51.100.0/24\", \"192.168.20.0/24\", \"192.168.99.0/24\")]\ndb_path, address = sys.argv[1], sys.argv[2]\napprover = sys.argv[sys.argv.index(\"--approve\") + 1] if \"--approve\" in sys.argv else None", "note": "Two lists a person maintains: addresses a machine may never block, and the company's own networks. The approver's name is an argument, so that every action carries one."}, {"code": "# 1. enrich: what else did this address do this week?\ndb = sqlite3.connect(db_path)\nfailures, accounts = db.execute(\n    \"SELECT count(*), count(DISTINCT user) FROM logs WHERE src_ip = ? AND action = 'failure'\",\n    (address,)).fetchone()\nlogins = db.execute(\n    \"SELECT timestamp, host, user, method FROM logs WHERE src_ip = ? AND action = 'success'\",\n    (address,)).fetchall()\nprint(f\"{address}: {failures} failed logins over {accounts} accounts, {len(logins)} accepted\")\nfor when, host, user, method in logins:", "note": "Enrichment: the questions an analyst asks first, answered from the SIEM before anybody opens it. How much did this address try, and what did it get into?"}, {"code": "\n# 2. guard: some addresses are never blocked by a machine, whatever the alert says\nreasons = []\nif address in NEVER_BLOCK:\n    reasons.append(\"on the never-block list\")\nif any(ipaddress.ip_address(address) in net for net in OURS):", "note": "The guard runs before any decision. Blocking a partner, a provider or your own network is the classic way automation causes the outage it was meant to prevent."}, {"code": "\n# 3. propose\nactions = [] if reasons else [f\"block {address} at fw\"]\nfor user, host in sorted({(user, host) for _, host, user, _ in logins}):\n    actions.append(f\"disable {user} on {host} and reset the password (a person does this)\")\nticket = {\"opened\": dt.datetime.now(dt.timezone.utc).isoformat(timespec=\"seconds\"),\n          \"alert\": \"login accepted after many accounts tried\", \"address\": address,\n          \"failures\": failures, \"accounts_tried\": accounts,\n          \"accepted\": [list(row) for row in logins], \"not_automated\": reasons,\n          \"proposed\": actions, \"approved_by\": approver}\nfor a in actions:\n    print(\"  proposed:\", a)\nfor r in reasons:\n    print(f\"  refused to block: {address} is {r}\")", "note": "The proposal. Blocking an address is reversible and narrow, so the machine may do it. Disabling an account touches a person's work, so the playbook only says it and a person does it."}, {"code": "# 4. act, only what was approved and only what a machine may do\nif approver and not reasons:\n    subprocess.run([\"ip\", \"netns\", \"exec\", \"fw\", \"nft\", \"insert\", \"rule\", \"ip\", \"fw\", \"forward\",\n                    \"ip\", \"saddr\", address, \"drop\", \"comment\", f'\"playbook, approved by {approver}\"'],\n                   check=True)\n    print(f\"  done: {address} blocked at fw, approved by {approver}\")", "note": "The only action, taken only with a named approver and no guard objecting. The rule's comment says who approved it, so the firewall itself records the decision."}, {"code": "with open(f\"ticket-{address}.json\", \"w\") as f:\n    json.dump(ticket, f, indent=2)\nprint(f\"  ticket written: ticket-{address}.json\")", "note": "Every run leaves a ticket, whether it acted or not: what was known, what was proposed, who approved."}]}
```

Run it on the address from Thursday night, without approving anything:

```
root@soc:~# python3 playbook.py /home/ana/week/siem.db 203.0.113.66
203.0.113.66: 57 failed logins over 19 accounts, 2 accepted
  accepted 2026-09-17 05:33:07 UTC on gw: bruno by password
  accepted 2026-09-17 06:05:22 UTC on gw: bruno by publickey
  proposed: block 203.0.113.66 at fw
  proposed: disable bruno on gw and reset the password (a person does this)
  ticket written: ticket-203.0.113.66.json
```

In under a second it has done what took a section of lesson 4 by hand: **57 failures across 19 accounts,
then two successful logins as bruno**, the second one with a key. It proposes two things, and says which of
them is a person's job. And it wrote the ticket:

```
root@soc:~# cat ticket-203.0.113.66.json
{
  "opened": "2026-10-07T08:06:52+00:00",
  "alert": "login accepted after many accounts tried",
  "address": "203.0.113.66",
  "failures": 57,
  "accounts_tried": 19,
  "accepted": [
    [
      "2026-09-17 05:33:07",
      "gw",
      "bruno",
      "password"
    ],
    [
      "2026-09-17 06:05:22",
      "gw",
      "bruno",
      "publickey"
    ]
  ],
  "not_automated": [],
  "proposed": [
    "block 203.0.113.66 at fw",
    "disable bruno on gw and reset the password (a person does this)"
  ],
  "approved_by": null
}
```

`"approved_by": null`: nothing was done, and the ticket says so. Now ana reads the proposal, agrees, and
approves by name:

```
root@soc:~# python3 playbook.py /home/ana/week/siem.db 203.0.113.66 --approve ana
203.0.113.66: 57 failed logins over 19 accounts, 2 accepted
  accepted 2026-09-17 05:33:07 UTC on gw: bruno by password
  accepted 2026-09-17 06:05:22 UTC on gw: bruno by publickey
  proposed: block 203.0.113.66 at fw
  proposed: disable bruno on gw and reset the password (a person does this)
  done: 203.0.113.66 blocked at fw, approved by ana
  ticket written: ticket-203.0.113.66.json
root@soc:~# ip netns exec fw nft list chain ip fw forward
table ip fw {
	chain forward {
		type filter hook forward priority filter; policy accept;
		ip saddr 203.0.113.66 drop comment "playbook, approved by ana"
		ct state new log prefix "fw-new " group 1
	}
}
root@soc:~# ip netns exec outside runuser -u ana -- ssh -o BatchMode=yes -o ConnectTimeout=3 ana@198.51.100.22 true
ssh: connect to host 198.51.100.22 port 22: Connection timed out
```

The rule sits first in `fw`'s chain, with ana's name in its comment, and a connection from the blocked
address now times out. The firewall itself is now a record of the decision; anybody who lists its rules
learns who added this one and why.

Notice what the playbook did **not** do. It did not touch bruno's account. That remains a proposal in the
ticket, for a person who can find out whether bruno, rather than somebody using his password, also logged
in from home that morning, before deciding whether to stop his work.
