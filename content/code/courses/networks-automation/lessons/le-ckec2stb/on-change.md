---
title: Told when it changes
version: 1
---

Sampling suits a counter, which changes all the time. It wastes messages on a value that changes
twice a year, like whether a link is up, and it can still miss a change shorter than its
interval. **An ON_CHANGE subscription sends the current value once and then one message per
change**, whenever it happens.

```schooling-example
{
  "language": "python",
  "file": "watch.py",
  "parts": [
    {
      "code": "from datetime import datetime\nfrom pathlib import Path\n\nfrom pygnmi.client import gNMIclient, telemetryParser\n"
    },
    {
      "code": "SUB = {\"mode\": \"stream\", \"encoding\": \"json\",\n       \"subscription\": [{\"path\": \"/interfaces/interface[name=eth2]/state/oper-status\",\n                         \"mode\": \"on_change\"}]}\npassword = Path(\"~/.netops-password\").expanduser().read_text().strip()\n\nwith gNMIclient(target=(\"edge2.example.net\", 9339), username=\"netops\",\n                password=password, path_root=\"lab-ca.pem\") as gc:\n    stream = gc.subscribe(subscribe=SUB)\n    seen = 0\n    for response in stream:\n        msg = telemetryParser(response)\n        if \"update\" not in msg:\n            continue",
      "note": "**ON_CHANGE instead of SAMPLE.** The device sends the current value once, then a message only when the value changes, whatever the time between changes."
    },
    {
      "code": "        for u in msg[\"update\"][\"update\"]:\n            when = datetime.fromtimestamp(msg[\"update\"][\"timestamp\"] / 1e9).strftime(\"%H:%M:%S.%f\")[:-3]\n            print(f\"{when}  edge2 eth2 is {u['val']}\")\n        seen += 1\n        if seen == 3:\n            stream.cancel()\n            break",
      "note": "**The time printed is the device's**, converted from nanoseconds since 1970."
    }
  ]
}
```

The script runs in one terminal, watching `edge2`'s `eth2`, the link to branch 2's LAN. In
another, the link is disabled and enabled again with `gnmic set`, three seconds apart:

```
ana@ctl:~$ gnmic -a edge2.example.net:9339 set --update-path "/interfaces/interface[name=eth2]/config/enabled" --update-value false
{
  "source": "edge2.example.net:9339",
  "timestamp": 1790681209746217523,
  "time": "2026-09-29T08:26:49.746217523-03:00",
  "results": [
    {
      "operation": "UPDATE",
      "path": "interfaces/interface[name=eth2]/config/enabled"
    }
  ]
}
ana@ctl:~$ gnmic -a edge2.example.net:9339 set --update-path "/interfaces/interface[name=eth2]/config/enabled" --update-value true
{
  "source": "edge2.example.net:9339",
  "timestamp": 1790681212858854839,
  "time": "2026-09-29T08:26:52.858854839-03:00",
  "results": [
    {
      "operation": "UPDATE",
      "path": "interfaces/interface[name=eth2]/config/enabled"
    }
  ]
}
```

And what the first terminal printed meanwhile:

```
ana@ctl:~$ python watch.py
08:26:47.747  edge2 eth2 is UP
08:26:49.771  edge2 eth2 is DOWN
08:26:53.270  edge2 eth2 is UP
```

Three messages in about five seconds. The first is the value when the subscription started; the
second arrived when `enabled=false` took the interface down, and the third when it came back. The
times are `edge2`'s. **Nothing was sent in between**, and nothing would have been sent for a year
if nothing had changed.

That is the shape of an alerting system built on telemetry: an ON_CHANGE subscription to the
oper-status of every interface that matters, and a program that opens an incident on `DOWN`.
Lesson 7 builds the incident half, with webhooks and a service desk.

The lab's target notices a change by looking at the interface twice a second, which is why the
messages land a fraction after each `set`. A device does it from the event itself. Either way the
subscriber cannot tell, and does not need to.
