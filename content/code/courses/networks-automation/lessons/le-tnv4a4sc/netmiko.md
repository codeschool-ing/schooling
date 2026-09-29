---
title: Netmiko, which knows the device
version: 1
---

**Netmiko is Paramiko plus knowledge of each device's CLI**: its prompt, how to turn paging off, how
to enter configuration mode, how to save. That knowledge lives in drivers, selected by
`device_type`, and there are drivers for more than a hundred platforms.

```schooling-example
{
  "language": "python",
  "file": "nm.py",
  "parts": [
    {
      "code": "from netmiko import ConnectHandler\n"
    },
    {
      "code": "edge1 = ConnectHandler(device_type=\"cisco_ios\", host=\"edge1\", username=\"netops\",\n                       use_keys=True, key_file=\"/home/ana/.ssh/id_ed25519\")\nprint(repr(edge1.find_prompt()))",
      "note": "**Netmiko adds what Paramiko lacks: the device.** `device_type` picks a driver that knows the prompt, how to turn paging off, how to enter configuration mode and how to save."
    },
    {
      "code": "print(edge1.send_command(\"show ip route ospf\"))\nedge1.disconnect()",
      "note": "**`send_command` sends one line and waits for the prompt to come back**, so the output is complete however long it is."
    }
  ]
}
```

```
ana@ctl:~$ python nm.py
'edge1#'
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   192.0.2.0/24 [110/20] via 198.51.100.1, eth1, weight 1, 00:00:01
O   198.51.100.0/30 [110/10] is directly connected, eth1, weight 1, 00:00:22
O>* 198.51.100.4/30 [110/20] via 198.51.100.1, eth1, weight 1, 00:00:02
O   203.0.113.0/26 [110/10] is directly connected, eth2, weight 1, 00:00:22
O>* 203.0.113.64/26 [110/30] via 198.51.100.1, eth1, weight 1, 00:00:02
O>* 203.0.113.251/32 [110/20] via 198.51.100.1, eth1, weight 1, 00:00:01
O>* 203.0.113.253/32 [110/20] via 198.51.100.1, eth1, weight 1, 00:00:01
```

`find_prompt` returned `edge1#`, and `send_command` waited for that prompt to come back after the
command, so it returns the whole output however long it is. Netmiko also turned off paging when it
logged in, which is why nothing stopped at a screenful.

**The lab uses the `cisco_ios` driver**, and that is a choice worth being honest about. Netmiko has
no FRR driver. FRR's CLI is modelled on Cisco's, with the same prompts, `configure terminal`, `end`
and `write memory`, so the Cisco driver drives it correctly for everything this course does; the
one command it sends when it logs in, `terminal width 511`, is one FRR does not have, and FRR's
refusal of it is ignored. On a real Cisco router the driver would be the same, and on Junos, EOS or
RouterOS the name would change and the rest of the script would not.

The output above is the problem the next section solves. It is a screen, designed for a person:
codes explained at the top, columns aligned with spaces, a time that changes every second. **A
script that cuts fields out of it by position breaks the day a software upgrade adds a column.**
