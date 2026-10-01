---
title: Replace, compare, commit, roll back
version: 1
---

NAPALM's configuration methods bring lesson 3's candidate to devices that have none. **The change is
loaded, compared, and then committed or discarded**, and the driver does whatever the platform needs
to make that true.

A **replace** takes a whole configuration and makes the device match it. The file here is `edge1`'s
running configuration with two edits: a longer description on `eth2` and a new static route.

```
ana@ctl:~$ ssh netops@edge1 "show running-config" > edge1.conf
ana@ctl:~$ sed -i 's/description branch LAN/description branch 1 LAN, floor 2/' edge1.conf
ana@ctl:~$ sed -i 's/^router ospf/ip route 192.0.2.128\/25 198.51.100.1\n!\nrouter ospf/' edge1.conf
```

```schooling-example
{
  "language": "python",
  "file": "candidate.py",
  "parts": [
    {
      "code": "import sys\n\nfrom napalm import get_network_driver\n\ndriver = get_network_driver(\"frr\")\nwith driver(\"edge1\", \"netops\", None, optional_args={\"key_file\": \"/home/ana/.ssh/id_ed25519\"}) as dev:"
    },
    {
      "code": "    dev.load_replace_candidate(filename=\"edge1.conf\")\n    diff = dev.compare_config()",
      "note": "**Replace, not merge.** The file is the whole configuration edge1 should have; NAPALM works out what to remove and what to add to get there."
    },
    {
      "code": "    if not diff:\n        print(\"edge1 already matches edge1.conf\")\n        dev.discard_config()\n        sys.exit()\n    print(diff)\n    if \"--commit\" in sys.argv:\n        dev.commit_config()\n        print(\"committed\")\n    else:\n        dev.discard_config()\n        print(\"discarded (run with --commit to apply)\")",
      "note": "**Look before committing.** An empty diff means the router already matches the file, and there is nothing to do."
    }
  ]
}
```

Run without `--commit`, it only shows what would change:

```
ana@ctl:~$ python candidate.py
interface eth2
- description branch LAN
interface eth2
+ description branch 1 LAN, floor 2
+ip route 192.0.2.128/25 198.51.100.1
discarded (run with --commit to apply)
```

The diff reads like a Git diff. Under `interface eth2`, the old description goes and the new one
comes, and the static route is added at the top level. **Nothing touched the router**, and the script
discarded the candidate. With `--commit`, and then once more:

```
ana@ctl:~$ python candidate.py --commit
interface eth2
- description branch LAN
interface eth2
+ description branch 1 LAN, floor 2
+ip route 192.0.2.128/25 198.51.100.1
committed
ana@ctl:~$ python candidate.py
edge1 already matches edge1.conf
```

The second run found nothing to do, because the router now matches the file. **That is what makes
replace the strongest operation**: the file is the whole truth, and anything on the router that is
not in it is removed. That is also its danger, because a line missing from the file by mistake is a
line removed from the router, which is why the diff comes first.

A **merge** adds lines to what is there, and `rollback` undoes the last commit:

```schooling-example
{
  "language": "python",
  "file": "rollback.py",
  "parts": [
    {
      "code": "from napalm import get_network_driver\n\nROUTE = \"ip route 198.51.100.128/25 198.51.100.1\"\n\ndriver = get_network_driver(\"frr\")\nwith driver(\"edge1\", \"netops\", None, optional_args={\"key_file\": \"/home/ana/.ssh/id_ed25519\"}) as dev:\n    dev.load_merge_candidate(config=ROUTE + \"\\n\")\n    print(dev.compare_config())\n    dev.commit_config()\n    print(\"after commit:  \", ROUTE in dev.get_config()[\"running\"])"
    },
    {
      "code": "    dev.rollback()\n    print(\"after rollback:\", ROUTE in dev.get_config()[\"running\"])",
      "note": "**`rollback` puts back the configuration the last commit replaced.** The driver kept it at commit time, so undoing does not depend on anybody having taken a backup."
    }
  ]
}
```

```
ana@ctl:~$ python rollback.py
+ip route 198.51.100.128/25 198.51.100.1
after commit:   True
after rollback: False
```

The route was there after the commit and gone after the rollback. The driver kept the configuration
it replaced, at commit time, and put it back. **Rollback is only as good as the device's or the
driver's memory**: it undoes the last commit, not an arbitrary one from last week, which is what the
backups of lesson 11 are for.
