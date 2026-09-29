---
title: A commit that undoes itself
version: 1
---

Some changes cut the branch you are sitting on: a new filter on the management interface, a
route that moves the management traffic, a wrong address on the uplink. The change is committed,
the session drops, and nobody can reach the device to undo it. **A confirmed commit is the
answer**: it applies the change and starts a clock, and if no second commit confirms it before
the clock runs out, the device goes back to the configuration it had before, on its own.

The lab's version of cutting the branch is disabling `eth1`, the interface described as the
uplink, with a timeout of ten seconds, and then not confirming:

```schooling-example
{
  "language": "python",
  "file": "confirmed.py",
  "parts": [
    {
      "code": "import time\n\nfrom nc import connect, describe, interface_config\n\nwith connect() as m:\n    m.edit_config(target=\"candidate\", config=interface_config(\n        \"<interface><name>eth1</name><enabled>false</enabled></interface>\"))"
    },
    {
      "code": "    m.commit(confirmed=True, timeout=\"10\")\n    print(\"t=0 \", describe(m, \"running\", \"eth1\"))\n    time.sleep(5)\n    print(\"t=5 \", describe(m, \"running\", \"eth1\"))",
      "note": "**A confirmed commit applies the change and starts a clock.** If nothing confirms it within `timeout` seconds, the device puts the previous configuration back by itself."
    },
    {
      "code": "    time.sleep(8)\n    print(\"t=13\", describe(m, \"running\", \"eth1\"))",
      "note": "**Nobody confirms.** This is what happens when the change cut the path to the device: the script that should confirm can no longer reach it."
    },
    {
      "code": "    print(\"    \", describe(m, \"candidate\", \"eth1\"))\n    m.discard_changes()",
      "note": "**Running went back; the candidate did not.** It still holds the change that was rolled back, and the next plain `commit` from anyone would apply it again. Discard it."
    }
  ]
}
```

```
ana@ctl:~$ python confirmed.py
t=0  running   eth1: description='uplink to core1' enabled=false
t=5  running   eth1: description='uplink to core1' enabled=false
t=13 running   eth1: description='uplink to core1' enabled=true
     candidate eth1: description='uplink to core1' enabled=false
```

`enabled=false` was in force at 0 and at 5 seconds. **At 13 seconds it was `true` again**, and
nobody had sent anything: `nc1` rolled the change back when the ten seconds ran out. On a real
device that is what gets a network engineer home: the change that locked everyone out lasts ten
seconds, or ten minutes, and not until somebody drives to the site.

The last line is a finding about this device, and it is worth checking on every other one:
**running went back and the candidate did not.** The rolled-back `enabled=false` was still in the
candidate, waiting for the next commit, whoever sent it. The script discards it before leaving.

When the change is good, the confirmation is simply a second `commit` without `confirmed`, after
whatever check decides the device is still healthy:

```schooling-example
{
  "language": "python",
  "file": "confirmed_ok.py",
  "parts": [
    {
      "code": "from nc import connect, describe, interface_config\n\nwith connect() as m:\n    m.edit_config(target=\"candidate\", config=interface_config(\n        \"<interface><name>eth1</name><description>uplink to core1, port 7</description></interface>\"))\n    m.commit(confirmed=True, timeout=\"60\")"
    },
    {
      "code": "    print(describe(m, \"running\", \"eth1\"))",
      "note": "**The check that decides whether to keep it.** Here it is only \"can I still read the device\"; lesson 13 makes it a real test."
    },
    {
      "code": "    m.commit()\n    print(\"confirmed\")",
      "note": "**A plain `commit` confirms it**, and the clock stops."
    }
  ]
}
```

```
ana@ctl:~$ python confirmed_ok.py
running   eth1: description='uplink to core1, port 7' enabled=true
confirmed
```

**The check between the two commits is the whole design.** Here it only reads the device back;
if the change had broken the path, that read would fail, the script would never reach the
second `commit`, and the device would roll back by itself. Lesson 13 replaces the read with real
tests.
