---
title: Describe, validate, apply, verify
version: 1
---

The scripts so far mix two things: **what the network should be**, a network in a prefix list, and
**how to get it there**, SSH and commands. Separating them is the step from a script to network
automation, and every lesson from here on keeps them apart.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The cycle every change in this course follows. Describe: intent.yaml on ctl says what the network should be. Validate: checks run on ctl, and a value that fails them stops there. Apply: the change is sent to the routers. Verify: each router is read back and compared with the description. A difference found by verifying goes back to describe.\"><defs><marker id=\"cy-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"140\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Describe</text><text x=\"90.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what it should be</text><text x=\"90.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">intent.yaml</text><rect x=\"200\" y=\"70\" width=\"140\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Validate</text><text x=\"270.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">checks on ctl</text><text x=\"270.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">before any router</text><rect x=\"380\" y=\"70\" width=\"140\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Apply</text><text x=\"450.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">send the change</text><text x=\"450.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Netmiko, NETCONF, API</text><rect x=\"560\" y=\"70\" width=\"140\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Verify</text><text x=\"630.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">read it back</text><text x=\"630.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">compare with intent</text><path d=\"M162 110 L198 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cy-ah)\"></path><path d=\"M342 110 L378 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cy-ah)\"></path><path d=\"M522 110 L558 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cy-ah)\"></path><path d=\"M630 152 L630 200 L90 200 L90 154\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#cy-ah)\"></path><text x=\"470\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a difference goes back to the description</text><path d=\"M270 152 L270 250\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cy-ah)\"></path><rect x=\"170\" y=\"252\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"270.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">refused</text><text x=\"380\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no router ever sees it</text><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">one change, four steps</text></svg>", "caption": "Describe, validate, apply, verify. Lessons 10 to 14 each make one of the four steps stronger."}
```

**Describe** means writing the intended state down as data. Here it is a YAML file on `ctl`:

```yaml
management_network: 192.0.2.0/24
routers:
  - core1
  - edge1
  - edge2
```

**Validate** means checking that description before anything touches a device, **apply** sends
it, and **verify** reads each device back and compares:

```schooling-example
{
  "language": "python",
  "file": "apply.py",
  "parts": [
    {
      "code": "import ipaddress\nimport sys\n\nimport yaml\nfrom netmiko import ConnectHandler\n\nintent = yaml.safe_load(open(\"intent.yaml\"))\n",
      "note": "**Describe.** What the network should be is a file, not a sequence of commands. `yaml.safe_load` turns it into a dictionary."
    },
    {
      "code": "try:\n    net = ipaddress.ip_network(intent[\"management_network\"])\nexcept ValueError as e:\n    sys.exit(f\"refused: {e}\")\nif not net.subnet_of(ipaddress.ip_network(\"192.0.2.0/24\")):\n    sys.exit(f\"refused: {net} is not inside the management range 192.0.2.0/24\")\n",
      "note": "**Validate, before anything is sent.** The value has to be a network, and one of the lab's management range. Lesson 13 builds real checks; what matters here is where they sit: a bad value stops on ctl, and no router ever sees it."
    },
    {
      "code": "want = f\"ip prefix-list MGMT seq 10 permit {net}\"\nfor name in intent[\"routers\"]:\n    router = ConnectHandler(device_type=\"cisco_ios\", host=name, username=\"netops\",\n                            use_keys=True, key_file=\"/home/ana/.ssh/id_ed25519\")\n    if want not in router.send_command(\"show running-config\").splitlines():\n        router.send_config_set([want])\n        router.save_config()\n    ok = want in router.send_command(\"show running-config\").splitlines()\n    router.disconnect()\n    print(f\"{name}: {'verified' if ok else 'NOT as intended'}\")",
      "note": "**Apply, then verify.** The last step reads each router back rather than trusting that sending succeeded."
    }
  ]
}
```

```
ana@ctl:~$ python apply.py
core1: verified
edge1: verified
edge2: verified
```

Now the description is edited with the mistake from the first section, and the script is run
again:

```
ana@ctl:~$ sed -i 's#192.0.2.0/24#192.0.12.0/24#' intent.yaml
ana@ctl:~$ python apply.py; echo "exit status $?"
refused: 192.0.12.0/24 is not inside the management range 192.0.2.0/24
exit status 1
```

**The typo never reached a router.** It was refused on `ctl`, with a sentence saying why, and the
script ended with a non-zero exit status, which is how a program tells the next program in a
pipeline that it failed. Lesson 14 relies on exactly that: a pipeline that stops at the first
failure.

The check is deliberately small, and it caught a typo only because this one happened to leave the
management range. A typo that stayed inside it, `192.0.2.0/25` for instance, would have passed.
**Validation catches what somebody thought to check**, which is why lesson 13 treats it as a
subject of its own.

The rest of the course fills in each box:

| step | where the course builds it |
|---|---|
| describe | YANG models in lesson 5, templates in lesson 10, NetBox as the source of truth in lesson 12 |
| validate | lesson 13, and the pipeline of lesson 14 |
| apply | APIs in lessons 2 to 4, Python libraries in lesson 8, Ansible in lesson 9 |
| verify | backups and diffs in lesson 11, state checks in lesson 13 |
