---
title: A sampled stream
version: 1
---

`Subscribe` with `--stream-mode sample` asks the device to send a value every interval,
**without being asked again**. `timeout 5` stops `gnmic` after five seconds, because a stream
does not end on its own:

```
ana@ctl:~$ timeout 5 gnmic -a edge1.example.net:9339 subscribe --path "/interfaces/interface[name=eth1]/state/counters/in-octets" --stream-mode sample --sample-interval 2s
{
  "source": "edge1.example.net:9339",
  "subscription-name": "default-1790681185",
  "timestamp": 1790681185638940350,
  "time": "2026-09-29T08:26:25.63894035-03:00",
  "updates": [
    {
      "Path": "interfaces/interface[name=eth1]/state/counters/in-octets",
      "values": {
        "interfaces/interface/state/counters/in-octets": 1858
      }
    }
  ]
}
{
  "sync-response": true
}
{
  "source": "edge1.example.net:9339",
  "subscription-name": "default-1790681185",
  "timestamp": 1790681187663415268,
  "time": "2026-09-29T08:26:27.663415268-03:00",
  "updates": [
    {
      "Path": "interfaces/interface[name=eth1]/state/counters/in-octets",
      "values": {
        "interfaces/interface/state/counters/in-octets": 1858
      }
    }
  ]
}
{
  "source": "edge1.example.net:9339",
  "subscription-name": "default-1790681185",
  "timestamp": 1790681189664768514,
  "time": "2026-09-29T08:26:29.664768514-03:00",
  "updates": [
    {
      "Path": "interfaces/interface[name=eth1]/state/counters/in-octets",
      "values": {
        "interfaces/interface/state/counters/in-octets": 1858
      }
    }
  ]
}

received signal 'terminated'. terminating...
```

The first message is the value when the subscription started, and then comes
**`sync-response`**. That marker means "you now have everything that existed when you
subscribed; what follows is new". A collector that loads a table of current state waits for it
before drawing anything. After it, one message every two seconds, each with the device's timestamp.

The counter did not move in those five seconds: nothing was crossing `eth1` except the odd OSPF
packet. **A counter is the number of bytes since the interface came up, not a rate.** To get a
rate, subtract two samples and divide by the time between them, using the device's timestamps
rather than the time the message arrived, which includes the network's delay.

```schooling-example
{
  "language": "python",
  "file": "rate.py",
  "parts": [
    {
      "code": "from pathlib import Path\n\nfrom pygnmi.client import gNMIclient, telemetryParser\n\nPATH = \"/interfaces/interface[name=eth1]/state/counters\"\nSUB = {\"mode\": \"stream\", \"encoding\": \"json\",\n       \"subscription\": [{\"path\": PATH, \"mode\": \"sample\", \"sample_interval\": 2_000_000_000}]}\npassword = Path(\"~/.netops-password\").expanduser().read_text().strip()\n\nwith gNMIclient(target=(\"edge1.example.net\", 9339), username=\"netops\",\n                password=password, path_root=\"lab-ca.pem\") as gc:\n    stream = gc.subscribe(subscribe=SUB)\n    last = None",
      "note": "**The same subscription as `gnmic` made, from Python.** `sample_interval` is in nanoseconds, as every time in gNMI is: two seconds is 2,000,000,000."
    },
    {
      "code": "    for n, response in enumerate(stream):\n        msg = telemetryParser(response)\n        if \"update\" not in msg:\n            continue\n        values = {u[\"path\"].rsplit(\"/\", 1)[1]: u[\"val\"] for u in msg[\"update\"][\"update\"]}\n        now = (msg[\"update\"][\"timestamp\"], values[\"in-octets\"], values[\"out-octets\"])\n        if last:\n            seconds = (now[0] - last[0]) / 1e9\n            rx = (now[1] - last[1]) * 8 / seconds / 1000\n            tx = (now[2] - last[2]) * 8 / seconds / 1000\n            print(f\"{seconds:5.2f} s   in {rx:7.1f} kbit/s   out {tx:7.1f} kbit/s\")\n        last = now",
      "note": "**Each sample is a counter, and a counter only ever grows.** What a person wants is a rate: the difference between two samples divided by the time between them, taken from the device's own timestamps rather than from when the message arrived."
    },
    {
      "code": "        if n == 6:\n            stream.cancel()\n            break",
      "note": "**A stream does not end by itself**, so the script cancels it after six messages."
    }
  ]
}
```

To give the counter something to count, `pc1` pings `pc2` in a second terminal, 20 packets a
second of 1,228 bytes each. Every packet crosses `edge1`'s `eth1` on the way out and its answer
crosses it on the way back:

```
ana@ctl:~$ python rate.py
 2.02 s   in   176.8 kbit/s   out   176.8 kbit/s
 2.00 s   in   179.2 kbit/s   out   179.2 kbit/s
 2.00 s   in   174.0 kbit/s   out   174.0 kbit/s
 2.00 s   in   178.8 kbit/s   out   178.8 kbit/s
 2.00 s   in   173.9 kbit/s   out   173.9 kbit/s
```

```
ana@pc1:~$ ping -q -i 0.05 -s 1200 -c 300 203.0.113.74
PING 203.0.113.74 (203.0.113.74) 1200(1228) bytes of data.

--- 203.0.113.74 ping statistics ---
300 packets transmitted, 300 received, 0% packet loss, time 16892ms
rtt min/avg/max/mdev = 0.033/0.067/6.536/0.374 ms
```

About 175 kbit/s each way, and the same both ways because every echo has its reply. The
intervals are two seconds within a few hundredths, **as measured by `edge1`'s clock**.

The number can be checked. Twenty packets a second of 1,228 bytes, plus 14 bytes of Ethernet
header that the interface counts too, would be about 199 kbit/s. The ping's summary explains the
difference: 300 packets took 16.9 seconds, not 15, because `ping` waits its interval after each
packet rather than keeping a strict clock. At the rate it really sent, 17.8 packets a second, the
same sum gives 177 kbit/s, **which is what the counters measured**.
