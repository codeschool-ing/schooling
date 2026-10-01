---
title: A missing value is an error
version: 1
---

Data files are typed by people, and people misspell keys. Here one interface's `address` is
written `adress`, and the same template renders it with Jinja2's defaults:

```schooling-example
{
  "language": "python",
  "file": "missing.py",
  "parts": [
    {
      "code": "import sys\n\nimport yaml\nfrom jinja2 import Environment, FileSystemLoader, StrictUndefined, Undefined\n\ndata = yaml.safe_load(open(\"data/edge1.yaml\"))"
    },
    {
      "code": "data[\"interfaces\"][1][\"adress\"] = data[\"interfaces\"][1].pop(\"address\")\n\nstrict = \"--strict\" in sys.argv\nenv = Environment(loader=FileSystemLoader(\"templates\"), trim_blocks=True, lstrip_blocks=True,\n                  undefined=StrictUndefined if strict else Undefined)\nprint(env.get_template(\"iface.j2\").render(data), end=\"\")",
      "note": "**A typo in the data**: one interface's key is spelt `adress`, so `i.address` names nothing."
    }
  ]
}
```

```
ana@ctl:~$ cd tpl && python missing.py
interface eth1
 description uplink to core1
 ip address 198.51.100.2/30
exit
interface eth2
 description branch LAN
 ip address 
exit
```

**No error, no warning, and a configuration with `ip address` and nothing after it.** That is
Jinja2's default on purpose: a name it cannot find renders as an empty string, which suits a web
page with an optional field. For a router it is the worst outcome available, because the file looks
complete. Sent to FRR, that line is refused as `% Command incomplete`; sent to some other platform, an incomplete command can
mean something else entirely.

`StrictUndefined` makes a missing name an exception instead:

```
ana@ctl:~$ cd tpl && python missing.py --strict 2>&1 | tail -4
  File "templates/iface.j2", line 6, in top-level template code
    ip address {{ i.address }}
   ^^^^^^^^^^^^^^^^^^^^^^^^^
jinja2.exceptions.UndefinedError: 'dict object' has no attribute 'address'
```

The traceback names the template, the line, the expression and the key that was not there, which
is all the information needed to fix the data. **Nothing is rendered, so nothing can be sent.**

Where a value really is optional, the template has to say so, which is the point: `{% if
i.description %}` in the next section's template is a decision that an interface may have no
description, written where a reader can see it. Without `StrictUndefined`, every value is
optional, and nobody decided that.
