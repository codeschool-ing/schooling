---
title: Paramiko, SSH and nothing more
version: 1
---

Lesson 1's script used Netmiko without explaining it, and lessons 2 to 4 used APIs. **Most network
equipment in service today is still configured through its CLI over SSH**, so the Python libraries
that drive a CLI are where most automation starts. There are four, and each sits on the one below:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"The four libraries as layers. Paramiko is SSH: a connection and a command. Netmiko sits on it and knows each device&#x27;s prompts, paging and configuration mode. NAPALM sits on a driver, here Netmiko, and gives the same getters and configuration methods on every platform. Nornir sits above all of them: it holds the inventory and runs a task on many hosts at once.\"><defs><marker id=\"ly-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"440\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Nornir</text><text x=\"260.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">inventory, tasks, many hosts at once</text><rect x=\"40\" y=\"95\" width=\"440\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">NAPALM</text><text x=\"260.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the same methods on every platform</text><rect x=\"40\" y=\"170\" width=\"440\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Netmiko</text><text x=\"260.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">prompts, paging, configuration mode</text><rect x=\"40\" y=\"245\" width=\"440\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"267.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Paramiko</text><text x=\"260.0\" y=\"283.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">an SSH connection and a command</text><rect x=\"520\" y=\"95\" width=\"180\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"610.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the device</text><text x=\"610.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">core1, edge1, edge2</text><path d=\"M482 275 L516 275\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><text x=\"610\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what each layer adds</text></svg>", "caption": "Each library uses the one below it. A script picks the highest layer that does what it needs."}
```

At the bottom is **Paramiko**, an implementation of SSH in pure Python. It opens a connection,
authenticates, checks the host key and runs a command, and it knows nothing about what is on the
other end:

```schooling-example
{
  "language": "python",
  "file": "para.py",
  "parts": [
    {
      "code": "import paramiko\n\nclient = paramiko.SSHClient()",
      "note": "**Paramiko is SSH in Python, and nothing more.** It knows how to open a connection, check the host key and run a command; it knows nothing about routers."
    },
    {
      "code": "client.load_system_host_keys(\"/home/ana/.ssh/known_hosts\")\nclient.set_missing_host_key_policy(paramiko.RejectPolicy())\nclient.connect(\"edge1\", username=\"netops\", key_filename=\"/home/ana/.ssh/id_ed25519\")\n",
      "note": "**Refuse a host whose key is not in `known_hosts`.** Paramiko's `AutoAddPolicy` accepts any key the first time, which is exactly what an attacker in the middle needs."
    },
    {
      "code": "stdin, stdout, stderr = client.exec_command(\"show ip ospf neighbor\")\nprint(stdout.read().decode())\nprint(\"exit status\", stdout.channel.recv_exit_status())\nclient.close()",
      "note": "**One command, one channel.** The router's login shell is its CLI, so the command runs there, and what comes back is bytes."
    }
  ]
}
```

```
ana@ctl:~$ python para.py

Neighbor ID     Pri State           Up Time         Dead Time Address         Interface                        RXmtL RqstL DBsmL
203.0.113.251     1 Full/-          10.906s           39.092s 198.51.100.1    eth1:198.51.100.2                    0     0     0


exit status 0
```

The router's login shell is its CLI, so `exec_command` ran `show ip ospf neighbor` there and the
output came back as bytes, blank lines included, with an exit status. **That is all Paramiko
offers**, and for one command on one kind of device it is enough.

It stops being enough quickly. Most devices do not accept a command as an argument the way FRR's
login shell does; they need an interactive session in which the script waits for a prompt, sends a
line, and waits again. Paging has to be turned off, or a long output stops at `--More--`.
Configuration mode has to be entered and left. **Each vendor does all of that differently**, and
writing it for each one is what the next layer is for.

The one thing to keep from this section is the host-key policy. `RejectPolicy` refuses a device
whose key is not in `known_hosts`; the `AutoAddPolicy` that many examples on the internet use
accepts any key it has not seen, which **turns off the protection SSH exists to provide**, the same
mistake as lesson 2's `verify=False`.
