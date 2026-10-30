---
title: Walking packets through the rules
version: 1
---

**Whether a packet gets in is a question with one answer, and the answer can be worked out by hand**: take the
rules that match, sort them by priority with deny first at a tie, and read the first. Google does that for
every packet. Without a network to send packets across, the lab does it with a short program over the
planner's rules, written as data. Nothing in this section reaches a network; what the program applies is the
order of the previous two sections, and the rules are the planner's design.

Save the rules as `~/gcp/firewall/rules.json`. The two address ranges of the first rule are where Google's
load balancers send health checks from, and the range of the second is where Identity-Aware Proxy's SSH
connections come from: three real ranges Google publishes. The last rule takes SSH away from machines tagged
`frozen`, the planner's word for a machine kept for an investigation:

```json
[
  {"name": "allow-health-checks", "priority": 1000, "action": "allow", "ports": [8080],
   "source_ranges": ["35.191.0.0/16", "130.211.0.0/22"], "target_service_accounts": ["web"]},
  {"name": "allow-ssh-from-iap", "priority": 1000, "action": "allow", "ports": [22],
   "source_ranges": ["35.235.240.0/20"]},
  {"name": "allow-web-to-db", "priority": 1000, "action": "allow", "ports": [5432],
   "source_service_accounts": ["web"], "target_service_accounts": ["db"]},
  {"name": "deny-ssh-to-frozen", "priority": 900, "action": "deny", "ports": [22],
   "source_ranges": ["0.0.0.0/0"], "target_tags": ["frozen"]}
]
```

And the program, as `~/gcp/firewall/walk.py`:

```schooling-example
{"language": "python", "file": "walk.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Walks one incoming packet through a network's firewall rules, as Google does.\n\n    python3 walk.py FROM TO PORT\n\nFROM is an address, or sa:NAME for a machine of the network running as that\nservice account. TO is sa:NAME, optionally with ,tag:TAG after it. The rules\nare read from rules.json.\n\"\"\"\nimport ipaddress\nimport json\nimport sys\n\n", "note": "How it is called: where the packet comes from, where it goes, and the port. A source is either an address, for traffic from outside, or `sa:NAME`, for a machine in the network running as that account."}, {"code": "IMPLIED = {'name': 'implied deny ingress', 'priority': 65535, 'action': 'deny', 'ports': None,\n           'any_source': True}\n\n", "note": "The implied rule at 65535, written as a rule like any other so that it is sorted with them. It matches every source and every port, which is what makes it the floor."}, {"code": "def parse(spec):\n    sa, tags, ip = None, [], None\n    for part in spec.split(','):\n        kind, _, value = part.partition(':')\n        if kind == 'sa':\n            sa = value\n        elif kind == 'tag':\n            tags.append(value)\n        else:\n            ip = ipaddress.ip_address(part)\n    return sa, tags, ip\n\n", "note": "Turn `sa:web,tag:frozen` into its parts: the service account, the tags, and the address if one was given."}, {"code": "def matches(rule, src, dst, port):\n    src_sa, _, src_ip = src\n    dst_sa, dst_tags, _ = dst\n    if rule['ports'] is not None and port not in rule['ports']:\n        return False\n    if 'target_tags' in rule and not set(rule['target_tags']) & set(dst_tags):\n        return False\n    if 'target_service_accounts' in rule and dst_sa not in rule['target_service_accounts']:\n        return False\n    by_range = src_ip is not None and any(src_ip in ipaddress.ip_network(r) for r in rule.get('source_ranges', []))\n    by_account = src_sa is not None and src_sa in rule.get('source_service_accounts', [])\n    return rule.get('any_source', False) or by_range or by_account\n\n", "note": "Whether one rule matches one packet: the port is one of its ports, the target is one of its targets, and the source is in one of its ranges or runs as one of its accounts."}, {"code": "src, dst, port = parse(sys.argv[1]), parse(sys.argv[2]), int(sys.argv[3])\nrules = json.load(open('rules.json')) + [IMPLIED]\nrules.sort(key=lambda r: (r['priority'], r['action'] != 'deny'))\nfor rule in rules:\n    if matches(rule, src, dst, port):\n        print(f\"{sys.argv[1]} -> {sys.argv[2]}:{port}  {rule['action'].upper()} by {rule['name']} ({rule['priority']})\")\n        break\n", "note": "Google's order: lowest priority number first, and at the same number deny before allow. The first rule that matches decides, and nothing after it is read."}]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l16-order\" aria-label=\"One packet, SSH from 35.235.240.7 to a web machine tagged frozen, checked against the planner's rules in the order Google reads them. The rules are listed from the lowest priority number down: deny-ssh-to-frozen at 900, then allow-health-checks, allow-ssh-from-iap and allow-web-to-db at 1000, then the implied deny ingress at 65535. The packet matches the first rule, at 900, and is denied; the rules below it are never read, including allow-ssh-from-iap, which would also have matched.\"><defs><marker id=\"l16-order-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20.0\" y=\"110.0\" width=\"190.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"115.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one packet</text><text x=\"115.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">35.235.240.7 → :22</text><text x=\"115.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">web, tag frozen</text><rect x=\"280.0\" y=\"30.0\" width=\"420.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"320.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">900</text><text x=\"360.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">deny-ssh-to-frozen</text><text x=\"540.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">deny</text><text x=\"690.0\" y=\"48.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">matches: decides</text><rect x=\"280.0\" y=\"76.0\" width=\"420.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"320.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1000</text><text x=\"360.0\" y=\"94.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">allow-health-checks</text><text x=\"540.0\" y=\"94.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">allow</text><text x=\"690.0\" y=\"94.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">not read</text><rect x=\"280.0\" y=\"122.0\" width=\"420.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"320.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1000</text><text x=\"360.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">allow-ssh-from-iap</text><text x=\"540.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">allow</text><text x=\"690.0\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">would match; not read</text><rect x=\"280.0\" y=\"168.0\" width=\"420.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"320.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1000</text><text x=\"360.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">allow-web-to-db</text><text x=\"540.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">allow</text><text x=\"690.0\" y=\"186.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">not read</text><rect x=\"280.0\" y=\"214.0\" width=\"420.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"320.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">65535</text><text x=\"360.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">implied deny ingress</text><text x=\"540.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">deny</text><text x=\"690.0\" y=\"232.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">not read</text><path d=\"M212.0 130.0 L276.0 50.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l16-order-af-ah-amber)\"></path><text x=\"360.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lowest number first; at a tie, deny first; the first match decides</text></svg>", "caption": "The first rule that matches decides, and nothing below it is read."}
```

## Seven packets

A health check from a load balancer reaching a web machine on 8080, and the same port from an address on the
internet:

```
ana@laptop:~/gcp/firewall$ python3 walk.py 35.191.4.20 sa:web 8080
35.191.4.20 -> sa:web:8080  ALLOW by allow-health-checks (1000)
ana@laptop:~/gcp/firewall$ python3 walk.py 203.0.113.9 sa:web 8080
203.0.113.9 -> sa:web:8080  DENY by implied deny ingress (65535)
```

The second is refused by nothing the planner wrote: **the implied rule refuses what no rule allows**, which is
why the planner's list has no rule saying *deny everything else*.

SSH through Identity-Aware Proxy to a web machine, and to one that has been tagged `frozen`:

```
ana@laptop:~/gcp/firewall$ python3 walk.py 35.235.240.7 sa:web 22
35.235.240.7 -> sa:web:22  ALLOW by allow-ssh-from-iap (1000)
ana@laptop:~/gcp/firewall$ python3 walk.py 35.235.240.7 sa:web,tag:frozen 22
35.235.240.7 -> sa:web,tag:frozen:22  DENY by deny-ssh-to-frozen (900)
```

The second packet matched both `allow-ssh-from-iap` at 1000 and `deny-ssh-to-frozen` at 900; **900 is read
first**, and the allow is never reached. Move the deny to the same priority as the allow and walk it again:

```
ana@laptop:~/gcp/firewall$ sed -i 's/"priority": 900/"priority": 1000/' rules.json
ana@laptop:~/gcp/firewall$ python3 walk.py 35.235.240.7 sa:web,tag:frozen 22
35.235.240.7 -> sa:web,tag:frozen:22  DENY by deny-ssh-to-frozen (1000)
```

Still denied, now at 1000: at a tie, deny wins. The planner keeps its denies at 900 anyway, because a rule
whose effect depends on a tie-break is a rule somebody will misread.

Last, the database, from a web machine and from the reports job:

```
ana@laptop:~/gcp/firewall$ python3 walk.py sa:web sa:db 5432
sa:web -> sa:db:5432  ALLOW by allow-web-to-db (1000)
ana@laptop:~/gcp/firewall$ python3 walk.py sa:reports sa:db 5432
sa:reports -> sa:db:5432  DENY by implied deny ingress (65535)
```

The reports job runs as `reports@`, lesson 5's account, and no rule lets it reach the database: it is refused
by the implied rule like the stranger on the internet. If it should read the database, the fix is a rule
naming `reports` as a source, written and reviewed like the others, and not a wider range on the existing
one.

**What the program does not do** is everything Google does around this: firewall policies above the network,
egress rules, protocols other than TCP, and the traffic that is always allowed. It walks the one list the
planner wrote, in the one order Google reads it.
