---
title: A model for the data
version: 1
---

The first check is the cheapest: is the data even the right shape? Lesson 10's `StrictUndefined`
caught a missing key, but only at render time, only the first one, and only a missing key. A
**model** says what every router's data has to look like, as types:

```schooling-example
{
  "language": "python",
  "file": "model.py",
  "parts": [
    {
      "code": "from ipaddress import IPv4Address, IPv4Interface\nfrom typing import Literal\n\nfrom pydantic import BaseModel, ConfigDict\n\n"
    },
    {
      "code": "class Interface(BaseModel):\n    model_config = ConfigDict(extra=\"forbid\")\n    name: str\n    description: str = \"\"\n    address: IPv4Interface\n    ospf: Literal[\"point-to-point\", \"passive\"] | None = None\n\n\nclass Router(BaseModel):\n    model_config = ConfigDict(extra=\"forbid\")\n    hostname: str\n    loopback: IPv4Address\n    interfaces: list[Interface]",
      "note": "**The shape of a router's data, written as types.** An address has to parse as an address, `ospf` has to be one of two words, and `extra=\"forbid\"` refuses a key the model does not name, which is how a typo such as `adress` gets caught."
    }
  ]
}
```

`pydantic` reads a dictionary into the model and refuses anything that does not fit. A small script
runs it on every file:

```schooling-example
{
  "language": "python",
  "file": "validate.py",
  "parts": [
    {
      "code": "import pathlib\nimport sys\n\nimport yaml\nfrom pydantic import ValidationError\n\nfrom model import Router\n\nfailed = False\nfor path in sorted(pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else \"data\").glob(\"*.yaml\")):\n    try:\n        Router.model_validate(yaml.safe_load(path.read_text()))\n        print(f\"{path}: ok\")"
    },
    {
      "code": "    except ValidationError as e:\n        failed = True\n        print(f\"{path}: {e.error_count()} error(s)\")\n        for err in e.errors():\n            print(\"   \", \".\".join(str(p) for p in err[\"loc\"]), \"-\", err[\"msg\"])\nsys.exit(1 if failed else 0)",
      "note": "**Every problem in the file, not only the first.** pydantic collects them all, each with the path to the value and what was wrong with it."
    }
  ]
}
```

```
ana@ctl:~$ cd net && python validate.py
data/core1.yaml: ok
data/edge1.yaml: ok
data/edge2.yaml: ok
```

A new router's file with three mistakes in it, put in a directory of its own:

```
ana@ctl:~$ cd net && mkdir -p new && cp edge3.yaml new/ && python validate.py new; echo "exit status $?"
new/edge3.yaml: 4 error(s)
    interfaces.0.address - Field required
    interfaces.0.adress - Extra inputs are not permitted
    interfaces.1.address - Input is not a valid IPv4 interface
    interfaces.1.ospf - Input should be 'point-to-point' or 'passive'
exit status 1
```

**Four errors, each with the path to the value**: `interfaces.0.adress` is the misspelt key, which
also leaves `address` missing; `interfaces.1.address` has `300` where an octet should be; and
`interfaces.1.ospf` says which two words it would have accepted. The template never ran, and the
exit status is 1.

That is three kinds of mistake caught by one declaration, and none of them needed a router. They
would have reached one by three different routes: a `KeyError`, a configuration FRR refuses, and an
interface with no OSPF and no error at all.

Below the model there is YAML itself. `yamllint` checks the syntax and the layout of the files:

```
ana@ctl:~$ cd net && yamllint -d relaxed data/
```

**It printed nothing, which is its way of passing**; the exit status, 0, is what a pipeline reads.
