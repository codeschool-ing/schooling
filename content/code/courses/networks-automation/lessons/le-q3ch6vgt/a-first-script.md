---
title: A first script
version: 1
---

The same change, written once in Python and run against the three routers. It uses **Netmiko**,
the library lesson 8 takes apart properly: it opens an SSH session, recognises the router's
prompt, and sends commands the way a person would.

```schooling-example
{
  "language": "python",
  "file": "mgmt.py",
  "parts": [
    {
      "code": "from netmiko import ConnectHandler\n\nROUTERS = [\"core1\", \"edge1\", \"edge2\"]\nLINE = \"ip prefix-list MGMT seq 10 permit 192.0.2.0/24\"\n",
      "note": "**The list of routers is data.** Three names today, and the loop below does not care whether there are three or three hundred."
    },
    {
      "code": "for name in ROUTERS:\n    router = ConnectHandler(device_type=\"cisco_ios\", host=name, username=\"netops\",\n                            use_keys=True, key_file=\"/home/ana/.ssh/id_ed25519\")",
      "note": "**One login per router**, with ana's SSH key rather than a password typed into the file. `cisco_ios` is the driver whose prompts match FRR's CLI; lesson 8 says why that is the choice here."
    },
    {
      "code": "    router.send_config_set([LINE])\n    router.save_config()\n    router.disconnect()\n    print(f\"{name}: MGMT set\")",
      "note": "**The same two lines on every router**, sent in configuration mode, then saved. Nothing here can be mistyped on one router and not on the others."
    }
  ]
}
```

**The script does exactly what the three sessions did**: log in, enter configuration mode, send
the line, save. The difference is that the line exists in one place, `LINE`, and the list of
routers in another, `ROUTERS`. Neither is typed at a prompt.

Running it, on `ctl`:

```
ana@ctl:~$ time python mgmt.py
core1: MGMT set
edge1: MGMT set
edge2: MGMT set

real	0m3.539s
user	0m0.238s
sys	0m0.137s
```

And the question from the first section, asked again:

```
ana@ctl:~$ for r in core1 edge1 edge2; do echo "== $r"; ssh netops@$r "show running-config" | grep MGMT; done
== core1
ip prefix-list MGMT seq 10 permit 192.0.2.0/24
== edge1
ip prefix-list MGMT seq 10 permit 192.0.2.0/24
== edge2
ip prefix-list MGMT seq 10 permit 192.0.2.0/24
```

All three agree. `edge1` holds the right network now, and it holds only one entry, because **an
entry in an FRR prefix list is identified by its sequence number**: the script's `seq 10`
replaced the mistyped `seq 10` rather than being added beside it. That is a property of this
router's CLI, and it is worth checking on every platform before trusting a script to overwrite
anything. A different line with a different sequence number would have left the typo in place.

`send_config_set` enters and leaves configuration mode on its own, and `save_config` is
`write memory` for this driver. **The saving is part of the script**, so the mistake from the
first section, forgetting to save, cannot happen to one router and not the others.
