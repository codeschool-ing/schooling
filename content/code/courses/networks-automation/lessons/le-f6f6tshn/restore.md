---
title: Putting a configuration back
version: 1
---

Restoring is getting a file out of the history and pushing it as a whole configuration. The file
comes from `git show HEAD~1:edge1.conf`, as in section 06, where `HEAD~1` is the commit before the
last one, the night before the change:

```schooling-example
{
  "language": "python",
  "file": "restore.py",
  "parts": [
    {
      "code": "import sys\n\nfrom napalm import get_network_driver\n\nhost, filename = sys.argv[1], sys.argv[2]\ndriver = get_network_driver(\"frr\")\nwith driver(host, \"netops\", None, optional_args={\"key_file\": \"/home/ana/.ssh/id_ed25519\"}) as dev:"
    },
    {
      "code": "    dev.load_replace_candidate(filename=filename)\n    print(dev.compare_config() or \"nothing to restore\")\n    if \"--commit\" in sys.argv:\n        dev.commit_config()\n        print(\"restored\")\n    else:\n        dev.discard_config()",
      "note": "**A backup is restored the way a template is pushed**: as a whole configuration that replaces the running one, after a look at the diff."
    }
  ]
}
```

```
ana@ctl:~$ cd net && git -C backups show HEAD~1:edge1.conf > edge1-before.conf && python restore.py edge1 edge1-before.conf
interface eth2
- description guest wifi
+no ip route 192.0.2.128/25 198.51.100.1
interface eth2
+ description branch LAN
```

The dry run shows the restore as NAPALM will do it: the description put back, the route removed.
**A restore is a change like any other**, and it is looked at before it is committed. With
`--commit`, then a backup and the comparison:

```
ana@ctl:~$ cd net && python restore.py edge1 edge1-before.conf --commit
interface eth2
- description guest wifi
+no ip route 192.0.2.128/25 198.51.100.1
interface eth2
+ description branch LAN
restored
ana@ctl:~$ cd net && python backup.py && git -C backups log --oneline
committed: edge1.conf
dbe7812 backup: edge1
3c44ac7 backup: edge1
4ad37d6 backup: core1, edge1, edge2
ana@ctl:~$ cd net && python compare.py edge1
edge1, missing from the router:
(nothing)
edge1, on the router and not intended:
(nothing)
```

The history now has three commits for edge1, and the last one puts it back where the first left
it. **Nothing was rewritten**: the drift is still in the history, between the commit that found it
and the commit that undid it, which is what an audit needs.

A restore is only as good as the backup it reads, and the backup is only proven by restoring it.
Pushing a backup back to a router in the lab, as here, is the test; a backup nobody has ever
restored is a set of files that probably work.
