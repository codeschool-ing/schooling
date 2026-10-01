---
title: The test that would have caught it
version: 1
---

The bad change reached the network because no offline test looked at **both ends of a link**. Each
router's data was valid; the error was in the pair. That test can be written, and it needs no
router:

```schooling-example
{
  "language": "python",
  "file": "test_links.py",
  "parts": [
    {
      "code": "import ipaddress\nimport pathlib\nfrom collections import defaultdict\n\nimport yaml\n\nROUTERS = {p.stem: yaml.safe_load(p.read_text()) for p in sorted(pathlib.Path(\"data\").glob(\"*.yaml\"))}\n\n"
    },
    {
      "code": "def test_both_ends_of_a_link_agree():\n    ends = defaultdict(list)\n    for name, router in ROUTERS.items():\n        for i in router[\"interfaces\"]:\n            net = ipaddress.ip_interface(i[\"address\"]).network\n            if net.prefixlen == 30:\n                ends[str(net)].append(f\"{name} {i['name']} ospf={i.get('ospf')}\")\n    for net, sides in ends.items():\n        assert len(sides) == 2, f\"{net} has {len(sides)} end(s): {sides}\"\n        assert sides[0].split(\"ospf=\")[1] == sides[1].split(\"ospf=\")[1], f\"{net}: {sides}\"",
      "note": "**The test that would have caught it.** A point-to-point link is a /30 with a router at each end, and OSPF only forms an adjacency if both ends run it the same way. Neither router's data is wrong on its own; the error is in the pair."
    }
  ]
}
```

With the same bad change made again, and the offline tests run with the new file:

```
ana@ctl:~$ cd net && sed -i 's/ospf: point-to-point/ospf: passive/' data/edge2.yaml && pytest -q test_configs.py test_links.py
.......F                                                                                     [100%]
============================================= FAILURES =============================================
__________________________________ test_both_ends_of_a_link_agree __________________________________

    def test_both_ends_of_a_link_agree():
        ends = defaultdict(list)
        for name, router in ROUTERS.items():
            for i in router["interfaces"]:
                net = ipaddress.ip_interface(i["address"]).network
                if net.prefixlen == 30:
                    ends[str(net)].append(f"{name} {i['name']} ospf={i.get('ospf')}")
        for net, sides in ends.items():
            assert len(sides) == 2, f"{net} has {len(sides)} end(s): {sides}"
>           assert sides[0].split("ospf=")[1] == sides[1].split("ospf=")[1], f"{net}: {sides}"
E           AssertionError: 198.51.100.4/30: ['core1 eth2 ospf=point-to-point', 'edge2 eth1 ospf=passive']
E           assert 'point-to-point' == 'passive'
E             
E             - passive
E             + point-to-point

test_links.py:19: AssertionError
===================================== short test summary info ======================================
FAILED test_links.py::test_both_ends_of_a_link_agree - AssertionError: 198.51.100.4/30: ['core1 e...
1 failed, 7 passed in 0.11s
```

**Caught with nothing rendered and nothing pushed, with the link, both interfaces and both values in the message.** Reverted:

```
ana@ctl:~$ cd net && git checkout data/edge2.yaml && pytest -q test_configs.py test_links.py
Updated 1 path from the index
........                                                                                     [100%]
8 passed in 0.09s
```

That is the habit this lesson is about. A failure found by an online test is a question: **could a
file have shown it?** When the answer is yes, write the offline test that would have caught it,
and the next time the same mistake costs a second of CI instead of an outage. When the answer is
no, a cable or a crashed process, the online test is the right place, and it has done its job.

Tests also have limits worth naming. They check what somebody thought to check; the network has
other ways to fail. Tools that analyse whole configurations offline, such as Batfish, which models
the network's control plane from the configuration files and answers questions like "can this LAN
reach that one", go much further than hand-written tests, at the cost of running a service of
their own.
