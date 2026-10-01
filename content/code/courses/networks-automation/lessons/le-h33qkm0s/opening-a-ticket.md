---
title: Opening, and closing, a ticket
version: 1
---

What the receiver does with an event is ordinary API work, the same as lesson 2's. The service desk
has a REST API with a token, and `desk.py` holds everything the receiver needs from it:

```schooling-example
{
  "language": "python",
  "file": "desk.py",
  "parts": [
    {
      "code": "from pathlib import Path\n\nimport requests\n\nDESK = \"https://tickets.example.net/api/tickets\"\nhttp = requests.Session()\nhttp.verify = \"lab-ca.pem\"\nhttp.headers[\"Authorization\"] = \"Token \" + Path(\"~/.desk-token\").expanduser().read_text().strip()\n\n\ndef request(method, url, **kwargs):\n    r = http.request(method, url, timeout=10, **kwargs)\n    r.raise_for_status()\n    return r.json()\n\n",
      "note": "**The service desk's API**, with the token from `~/.desk-token`. A ticketing system is one more REST API, and lesson 2's habits apply: a session, a timeout, `raise_for_status`."
    },
    {
      "code": "def handle(event):\n    title = f\"{event['device']} {event['interface']} is down\"\n    found = request(\"GET\", DESK, params={\"status\": \"open\", \"q\": title})[\"results\"]\n    if event[\"event\"] == \"interface.down\":\n        if found:\n            t = request(\"POST\", f\"{DESK}/{found[0]['number']}/comments\",\n                        json={\"body\": f\"down again at {event['time']}\"})\n            return f\"{t['number']}: commented, down again\"\n        t = request(\"POST\", DESK, json={\"title\": title, \"priority\": \"high\", \"requester\": \"edge-monitor\",\n                                        \"body\": f\"{event['description'] or 'no description'}, down at {event['time']}\"})\n        return f\"{t['number']}: opened\"\n    if found:\n        number = found[0][\"number\"]\n        request(\"POST\", f\"{DESK}/{number}/comments\", json={\"body\": f\"up at {event['time']}\"})\n        t = request(\"PATCH\", f\"{DESK}/{number}\", json={\"status\": \"resolved\"})\n        return f\"{t['number']}: resolved\"\n    return \"up, and no open ticket to resolve\"",
      "note": "**One open ticket per link, not one per event.** A link that flaps ten times in an hour is one incident, so the handler looks for an open ticket about the same device and interface before opening another."
    }
  ]
}
```

The rule it applies is the one that matters most in event-driven automation: **one incident, one
ticket.** A link that flaps ten times in an hour is not ten problems, and ten tickets are ten
notifications to a person who will stop reading them by the third. So a `down` event first looks
for an open ticket about the same device and interface, and adds a comment if it finds one; an `up`
event resolves the ticket it finds.

The link goes down, with the receiver listening:

```
ana@ctl:~$ python link.py edge1 eth2 down
edge1 eth2: down
```

```
ana@ctl:~$ python receiver.py 1
edge1-1790682864-3: interface.down edge1 eth2
   INC-1001: opened
```

And the service desk has a ticket, opened by the automation, with the interface's description in it:

```
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Authorization: Token $(cat .desk-token)" "https://tickets.example.net/api/tickets?status=open"
{
  "count": 1,
  "results": [
    {
      "number": "INC-1001",
      "title": "edge1 eth2 is down",
      "body": "branch LAN, down at 2026-09-29T08:55:00-03:00",
      "priority": "high",
      "requester": "edge-monitor",
      "status": "open",
      "opened": "2026-09-29T08:55:00-03:00",
      "comments": []
    }
  ]
}
```

When the link came back, in the previous section's demonstration, the same receiver commented and
resolved it:

```
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Authorization: Token $(cat .desk-token)" https://tickets.example.net/api/tickets/INC-1001
{
  "number": "INC-1001",
  "title": "edge1 eth2 is down",
  "body": "branch LAN, down at 2026-09-29T08:55:00-03:00",
  "priority": "high",
  "requester": "edge-monitor",
  "status": "resolved",
  "opened": "2026-09-29T08:55:00-03:00",
  "comments": [
    {
      "time": "2026-09-29T08:55:02-03:00",
      "body": "up at 2026-09-29T08:55:02-03:00"
    }
  ]
}
```

**The ticket is the record.** It holds when the link went down, when it came back, and who opened
it, `edge-monitor`, so a person reading it later can tell a ticket the automation opened from one a
colleague did. That is also the limit of what this receiver should decide on its own. Opening a
ticket and resolving it when the condition clears are safe to automate; **deciding the cause, or
changing the network in response, is a person's job** until the automation has earned the trust to
do it, which lesson 13's tests are part of.
