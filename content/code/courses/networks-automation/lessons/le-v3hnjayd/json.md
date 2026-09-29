---
title: JSON and Python
version: 1
---

JSON has six kinds of value, and Python's `json` module maps each to one Python type:

```schooling-example
{
  "language": "python",
  "file": "types.py",
  "parts": [
    {
      "code": "import json\n"
    },
    {
      "code": "text = '{\"name\": \"eth1\", \"mtu\": 1500, \"enabled\": true, \"speed\": null, \"load\": 0.25, \"addresses\": [\"198.51.100.2/30\"]}'\ndata = json.loads(text)\nfor key, value in data.items():\n    print(f\"{key:10} {type(value).__name__:6} {value!r}\")\n",
      "note": "**What `json.loads` turns each JSON value into.** An object becomes a `dict`, an array a `list`, `true` becomes `True` and `null` becomes `None`. A number with a dot becomes a `float`."
    },
    {
      "code": "print(json.dumps(data, sort_keys=True, indent=2))",
      "note": "**And back.** `sort_keys` and `indent` do not change the data, only its layout, which is what makes two files comparable line by line."
    }
  ]
}
```

```
ana@ctl:~$ python types.py
name       str    'eth1'
mtu        int    1500
enabled    bool   True
speed      NoneType None
load       float  0.25
addresses  list   ['198.51.100.2/30']
{
  "addresses": [
    "198.51.100.2/30"
  ],
  "enabled": true,
  "load": 0.25,
  "mtu": 1500,
  "name": "eth1",
  "speed": null
}
```

The mapping is simple and it has three edges worth knowing.

- **A number with a decimal point becomes a `float`**, and a float cannot hold every decimal
  exactly. A counter or a bandwidth that arrives as `0.1` is not quite 0.1 once parsed, which does
  not matter for display and matters for equality tests.
- **JSON has no integers of limited size, and many parsers do.** JavaScript loses precision above
  2 to the power 53, so RFC 7951 writes YANG's 64-bit types, `counter64` among them, **as strings**
  in JSON: `"in-octets": "123456789012"`. A script that reads RESTCONF counters has to convert them
  with `int()` itself. Python's `json` has no such limit, which is why the gNMI target of lesson 4
  could send integers and `pygnmi` read them as they were.
- **Keys are always strings**, and **key order carries no meaning**. `sort_keys=True` writes them
  alphabetically, which is what makes two JSON files comparable with a line-by-line diff.

`json.dumps` with `indent` is the other half: data back to text. **What a program writes should be
stable**: the same data written twice should give the same bytes. Sorted keys and a fixed indent
give that, and a backup or a rendered configuration that changes its layout on every run makes
every diff noise.
