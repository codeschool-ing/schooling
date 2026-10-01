---
title: Testing the configurations without a router
version: 1
---

A model checks each file on its own. Some mistakes are only visible across files, or only in the
rendered configuration, and those need tests. `pytest` finds every function named `test_*` in
files named `test_*.py`, runs it, and counts a test as failed when it raises:

```schooling-example
{
  "language": "python",
  "file": "test_configs.py",
  "parts": [
    {
      "code": "import ipaddress\nimport pathlib\nfrom collections import Counter\n\nimport pytest\nimport yaml\n\nfrom model import Router\nfrom render import template\n"
    },
    {
      "code": "ROUTERS = {p.stem: yaml.safe_load(p.read_text()) for p in sorted(pathlib.Path(\"data\").glob(\"*.yaml\"))}\n\n",
      "note": "**The data is loaded once, and every test reads it.** A test is a function whose name starts with `test_`; pytest finds it, runs it, and reports each one."
    },
    {
      "code": "@pytest.mark.parametrize(\"name\", ROUTERS)\ndef test_data_matches_the_model(name):\n    Router.model_validate(ROUTERS[name])\n\n\ndef test_no_address_is_used_twice():\n    addresses = Counter(i[\"address\"].split(\"/\")[0] for r in ROUTERS.values() for i in r[\"interfaces\"])\n    addresses.update(r[\"loopback\"] for r in ROUTERS.values())\n    assert [a for a, n in addresses.items() if n > 1] == []\n\n\n@pytest.mark.parametrize(\"name\", ROUTERS)\ndef test_every_ospf_interface_gets_a_network_line(name):\n    config = template.render(ROUTERS[name])\n    for i in ROUTERS[name][\"interfaces\"]:\n        if i.get(\"ospf\"):\n            network = ipaddress.ip_interface(i[\"address\"]).network\n            assert f\" network {network} area 0\" in config.splitlines()",
      "note": "**One test per router**, from one function: `parametrize` runs it once for each name, and a failure says which router."
    }
  ]
}
```

`render.py` is lesson 10's, with its loop moved under `if __name__ == "__main__":` so that the
tests can import the template without rendering every file as a side effect.

```
ana@ctl:~$ cd net && pytest -v test_configs.py
======================================= test session starts ========================================
platform linux -- Python 3.12.3, pytest-9.1.1, pluggy-1.6.0 -- /opt/netauto/bin/python3.12
cachedir: .pytest_cache
rootdir: /home/ana/net
collecting ... collected 7 items

test_configs.py::test_data_matches_the_model[core1] PASSED                                   [ 14%]
test_configs.py::test_data_matches_the_model[edge1] PASSED                                   [ 28%]
test_configs.py::test_data_matches_the_model[edge2] PASSED                                   [ 42%]
test_configs.py::test_no_address_is_used_twice PASSED                                        [ 57%]
test_configs.py::test_every_ospf_interface_gets_a_network_line[core1] PASSED                 [ 71%]
test_configs.py::test_every_ospf_interface_gets_a_network_line[edge1] PASSED                 [ 85%]
test_configs.py::test_every_ospf_interface_gets_a_network_line[edge2] PASSED                 [100%]

======================================== 7 passed in 0.10s =========================================
```

**Seven tests from three functions**: the model on each router, the addresses across all of them,
and the rendered configuration of each. `-v` prints one line per test, named with its parameter,
so a failure says not only what failed but on which router. The whole run took a tenth of a
second; nothing was asked of the network.

The second test is the kind no model can express. Each router's data is valid on its own and yet
two of them could claim the same address, and only a test that reads all of them at once sees it.
The third tests the template and the data together: a template edit that dropped the `network`
loop would pass the model and fail here.
