---
title: From a rendered file to the router
version: 1
---

A change now starts in the data. edge2's LAN gets a better description, and everything is rendered
again:

```
ana@ctl:~$ cd tpl && sed -i 's/description: branch LAN/description: branch 2 LAN, floor 1/' data/edge2.yaml && python render.py
data/core1.yaml -> configs/core1.conf, 34 lines
data/edge1.yaml -> configs/edge1.conf, 34 lines
data/edge2.yaml -> configs/edge2.conf, 34 lines
```

Pushing the files is lesson 8's NAPALM, with one difference: the rendered file is the whole
configuration, so it goes in with `load_replace_candidate` rather than as a merge.

```schooling-example
{
  "language": "python",
  "file": "push.py",
  "parts": [
    {
      "code": "import sys\n\nfrom napalm import get_network_driver\n\ndriver = get_network_driver(\"frr\")\nfor host in (\"core1\", \"edge1\", \"edge2\"):\n    with driver(host, \"netops\", None, optional_args={\"key_file\": \"/home/ana/.ssh/id_ed25519\"}) as dev:"
    },
    {
      "code": "        dev.load_replace_candidate(filename=f\"configs/{host}.conf\")\n        diff = dev.compare_config()\n        if not diff:\n            print(f\"{host}: matches\")\n            dev.discard_config()\n            continue\n        print(f\"{host}:\\n{diff}\")\n        if \"--commit\" in sys.argv:\n            dev.commit_config()\n            print(f\"{host}: committed\")\n        else:\n            dev.discard_config()",
      "note": "**The rendered file is the whole configuration**, so it goes in as a replacement: whatever the router has that the file does not is removed."
    }
  ]
}
```

A run without `--commit` shows what each router would receive:

```
ana@ctl:~$ cd tpl && python push.py
core1: matches
edge1: matches
edge2:
interface eth2
- description branch LAN
interface eth2
+ description branch 2 LAN, floor 1
```

**Three files were rendered and one router has something to do.** The diff is NAPALM's
comparison with what edge2 is running, so it holds exactly the line that changed in the data. With
`--commit`, and once more afterwards:

```
ana@ctl:~$ cd tpl && python push.py --commit
core1: matches
edge1: matches
edge2:
interface eth2
- description branch LAN
interface eth2
+ description branch 2 LAN, floor 1
edge2: committed
ana@ctl:~$ cd tpl && python push.py
core1: matches
edge1: matches
edge2: matches
```

The second run is the check that matters: every router matches its file.

Replacing has a consequence that merging does not. Somebody adds a static route to edge1 by hand,
and the next run notices:

```
ana@ctl:~$ ssh netops@edge1

Hello, this is FRRouting (version 8.4.4).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

edge1# configure terminal
edge1(config)# ip route 192.0.2.128/25 198.51.100.1
edge1(config)# end
edge1# exit
Connection to edge1 closed.
ana@ctl:~$ cd tpl && python push.py
core1: matches
edge1:
+no ip route 192.0.2.128/25 198.51.100.1
edge2: matches
```

**The route is not in the data, so pushing removes it.** That is the point of a whole-configuration
template, and it is also why it should not be turned on for a network one afternoon: every hand-made
line that nobody wrote into the data is removed by the first `--commit`. The safe order is the one
this lesson followed. First render, compare and make the data match the network, with nothing
pushed; only then let the data decide.
