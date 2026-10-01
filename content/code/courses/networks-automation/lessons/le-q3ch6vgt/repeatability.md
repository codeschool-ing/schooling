---
title: The same result, every time
version: 1
---

`mgmt.py` sends its line whether or not the router needs it. That is harmless here, and it is a
habit that stops being harmless when the command has side effects: some changes reset a session,
restart a process or add a duplicate line. A script worth running twice **asks first and changes
only what differs**.

```schooling-example
{
  "language": "python",
  "file": "mgmt_check.py",
  "parts": [
    {
      "code": "from netmiko import ConnectHandler\n\nROUTERS = [\"core1\", \"edge1\", \"edge2\"]\nWANT = \"ip prefix-list MGMT seq 10 permit 192.0.2.0/24\"\n\nfor name in ROUTERS:\n    router = ConnectHandler(device_type=\"cisco_ios\", host=name, username=\"netops\",\n                            use_keys=True, key_file=\"/home/ana/.ssh/id_ed25519\")\n    running = router.send_command(\"show running-config\")",
      "note": "**Ask before changing.** The script reads the running configuration and compares it with the line it wants."
    },
    {
      "code": "    if WANT in running.splitlines():\n        print(f\"{name}: already as intended\")\n    else:\n        router.send_config_set([WANT])\n        router.save_config()\n        print(f\"{name}: changed\")\n    router.disconnect()",
      "note": "**Change only what differs.** A router already in the wanted state is left alone and says so, which is what makes a second run safe."
    }
  ]
}
```

The three routers are already right, so the first run changes nothing:

```
ana@ctl:~$ python mgmt_check.py
core1: already as intended
edge1: already as intended
edge2: already as intended
```

Then somebody logs into `edge2` and removes the list by hand, the kind of change nobody writes down:

```
ana@ctl:~$ ssh netops@edge2

Hello, this is FRRouting (version 8.4.4).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

edge2# configure terminal
edge2(config)# no ip prefix-list MGMT
edge2(config)# end
edge2# write memory
Note: this version of vtysh never writes vtysh.conf
Building Configuration...
Integrated configuration saved to /etc/frr/frr.conf
[OK]
edge2# exit
Connection to edge2 closed.
```

The same script, run twice more:

```
ana@ctl:~$ python mgmt_check.py
core1: already as intended
edge1: already as intended
edge2: changed
ana@ctl:~$ python mgmt_check.py
core1: already as intended
edge1: already as intended
edge2: already as intended
```

The first run found the one router that had drifted and put it back. **The second run found
nothing to do**, and that is the property that matters: running the script again is safe, so it
can run after every change, every night, or whenever anyone doubts the state of the network.

That property has a name, **idempotence**: applying the operation twice leaves the network exactly
as applying it once. Ansible, in lesson 9, is built around it, and its output says `changed` or
`ok` for the same reason this script says `changed` or `already as intended`.

**Repeatable is also how a script becomes evidence.** "It said `already as intended` on every
router at 03:00" is a statement about the network that a person can check. "I think I did all of
them" is not.
