---
title: One timeline
version: 1
---

The sensor saw `remote` too. Its `eve.json` has been copied into the collection, and the three sources
now describe the same stranger from three sides: the firewall's refusals, the firewall's flows and the
sensor's alert. Read separately, each is a list. **Put in one order by time, they tell what happened.**

That is the core of what a **SIEM** does, and the lab's version is small enough to read whole:

```schooling-example
{"language": "python", "file": "correlate.py", "parts": [{"code": "import json, sys\nfrom datetime import datetime\n\nLOGS = \"/var/log/lab/remote\"\nwho = sys.argv[1]\nevents = []", "note": "The one argument is the address to follow, and every record that mentions it goes into one list."}, {"code": "def lines(path):\n    with open(path) as f:\n        return [json.loads(l) for l in f if l.strip()]", "note": "Every file in the collection is one JSON object per line, so one reader serves all three."}, {"code": "for r in lines(f\"{LOGS}/fw/flows.json\"):\n    if who in (r[\"src_ip\"], r[\"dest_ip\"]):\n        t = datetime.fromtimestamp(r[\"flow.start.sec\"]).astimezone()\n        size = r[\"orig.raw.pktlen\"] + r[\"reply.raw.pktlen\"]\n        events.append((t, \"flow \", f'{r[\"src_ip\"]} -> {r[\"dest_ip\"]}:{r[\"orig.l4.dport\"]}  {size} bytes'))", "note": "Flows carry their start in seconds since 1970. The size is both directions added together."}, {"code": "for r in lines(f\"{LOGS}/fw/drops.json\"):\n    if who in (r[\"src_ip\"], r[\"dest_ip\"]):\n        t = datetime.fromisoformat(r[\"timestamp\"])\n        events.append((t, \"drop \", f'{r[\"src_ip\"]} -> {r[\"dest_ip\"]}:{r[\"dest_port\"]}  {r[\"oob.prefix\"]}'))", "note": "Drops carry a written timestamp, and the prefix says which rule refused the packet."}, {"code": "for r in lines(f\"{LOGS}/sensor/eve.json\"):\n    if r.get(\"event_type\") == \"alert\" and who in (r[\"src_ip\"], r[\"dest_ip\"]):\n        t = datetime.fromisoformat(r[\"timestamp\"])\n        events.append((t, \"alert\", f'{r[\"src_ip\"]} -> {r[\"dest_ip\"]}:{r[\"dest_port\"]}  {r[\"alert\"][\"signature\"]}'))", "note": "From the sensor, alerts only. Its HTTP, flow and statistics records are in the same file and are skipped."}, {"code": "for t, kind, what in sorted(events):\n    print(t.strftime(\"%H:%M:%S\"), kind, what)", "note": "Sorting by time is the whole join. It only means something because every source's clock agrees."}]}
```

```
root@admin:~# python3 correlate.py 203.0.113.50
18:52:31 flow  203.0.113.50 -> 192.0.2.80:80  835 bytes
18:52:32 flow  203.0.113.50 -> 192.0.2.80:80  1136 bytes
18:52:32 alert 203.0.113.50 -> 192.0.2.80:80  secrets file requested from outside
18:52:32 drop  203.0.113.50 -> 192.0.2.80:22  forward-drop
18:52:33 drop  203.0.113.50 -> 192.0.2.53:22  forward-drop
18:52:34 drop  203.0.113.50 -> 192.168.20.30:5432  forward-drop
18:55:35 drop  203.0.113.50 -> 192.0.2.80:23  forward-drop
18:55:39 drop  203.0.113.50 -> 192.0.2.80:80  intel-drop
18:55:40 drop  203.0.113.50 -> 192.0.2.80:80  intel-drop
18:55:41 drop  203.0.113.50 -> 192.0.2.80:80  intel-drop
```

Read top to bottom. At 18:52:31 `remote` loaded the front page. One second later it asked for `/.env`,
a file that commonly holds passwords and keys, and the sensor raised its alert on that request. Over
the next two seconds it tried SSH on the shop, then SSH on the name server, then the database, which is
not on the DMZ at all. The flows say the two web requests were answered, 835 and 1136 bytes in total; the
drops say every other door stayed shut. At 18:55:35 it came back for port 23. After the feed was
loaded, the intel rule refused its next request to the shop, three packets one second apart.

That is the answer an alert alone could not give: **did anything else succeed?** Here, no. The one
alert was a 404, and the only conversations that completed were two page loads. The work that remains
is to confirm `/.env` does not exist on the server, which the 404 already suggests, and to decide
whether the address belongs on the block list, which the feed has already decided.

A real SIEM adds what this script leaves out: parsing dozens of formats, keeping indexes so a month is
searched in seconds, rules that raise one incident from many records, and the host events of lesson 16
beside the network's. The join is the same, by address and by time, and it only works if the clocks
agree. Every machine in the lab takes its time from the same host; on a real network, **NTP on every
device is a precondition of correlation**, not a nicety.
