---
title: Asking the network
version: 1
---

The online tests read their expectations from the same data and compare them with what the routers
report:

```schooling-example
{
  "language": "python",
  "file": "test_network.py",
  "parts": [
    {
      "code": "import ipaddress\nimport json\nimport pathlib\nimport subprocess\n\nimport pytest\nimport yaml\n\nROUTERS = {p.stem: yaml.safe_load(p.read_text()) for p in sorted(pathlib.Path(\"data\").glob(\"*.yaml\"))}\n\n\ndef show(router, command):\n    out = subprocess.run([\"ssh\", f\"netops@{router}\", command + \" json\"], capture_output=True, text=True,\n                         check=True, timeout=15).stdout\n    return json.loads(out)\n\n"
    },
    {
      "code": "@pytest.mark.parametrize(\"name\", ROUTERS)\ndef test_ospf_neighbours_are_full(name):\n    expected = sum(i.get(\"ospf\") == \"point-to-point\" for i in ROUTERS[name][\"interfaces\"])\n    neighbours = [n for ns in show(name, \"show ip ospf neighbor\")[\"neighbors\"].values() for n in ns]\n    assert [n[\"converged\"] for n in neighbours] == [\"Full\"] * expected\n\n",
      "note": "**What the network should be doing, read from the data**: one OSPF neighbour per point-to-point interface, and every neighbour `Full`."
    },
    {
      "code": "LANS = [str(ipaddress.ip_interface(i[\"address\"]).network)\n        for r in ROUTERS.values() for i in r[\"interfaces\"] if i.get(\"ospf\") == \"passive\"]\n\n\n@pytest.mark.parametrize(\"name\", ROUTERS)\ndef test_every_branch_lan_is_routed(name):\n    routes = show(name, \"show ip route\")\n    assert [lan for lan in LANS if lan not in routes] == []",
      "note": "**Every router reaches every branch LAN.** The prefixes come from the data too, so a branch added tomorrow is tested without editing this file."
    }
  ]
}
```

```
ana@ctl:~$ cd net && pytest -v test_network.py
======================================= test session starts ========================================
platform linux -- Python 3.12.3, pytest-9.1.1, pluggy-1.6.0 -- /opt/netauto/bin/python3.12
cachedir: .pytest_cache
rootdir: /home/ana/net
collecting ... collected 6 items

test_network.py::test_ospf_neighbours_are_full[core1] PASSED                                 [ 16%]
test_network.py::test_ospf_neighbours_are_full[edge1] PASSED                                 [ 33%]
test_network.py::test_ospf_neighbours_are_full[edge2] PASSED                                 [ 50%]
test_network.py::test_every_branch_lan_is_routed[core1] PASSED                               [ 66%]
test_network.py::test_every_branch_lan_is_routed[edge1] PASSED                               [ 83%]
test_network.py::test_every_branch_lan_is_routed[edge2] PASSED                               [100%]

======================================== 6 passed in 1.31s =========================================
```

**What the network should be doing is derived from the data**, not written into the test: core1 has
two point-to-point interfaces, so it should have two `Full` neighbours, and every passive interface
is a LAN every router should have a route to. A branch added to the data is tested the day it is
added, by the same three lines.

These tests are slower, over a second, because each one opens an SSH session, and they are the
only ones that can find what files cannot: a cable that is unplugged, a process that did not start,
a neighbour that disagrees about a timer. Before a change, they are a **pre-check**: the network is
healthy now, so a failure afterwards is the change's. After a change, they are the **post-check**,
and the next section is what it looks like when one fails.
