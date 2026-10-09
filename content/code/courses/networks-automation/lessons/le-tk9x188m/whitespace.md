---
title: Where the blank lines come from
version: 2
---

A router does not mind a blank line in its configuration; a diff does. Lesson 11 compares the
configuration a router is running with the one the template rendered, and every stray blank line
or indentation is a difference that means nothing and hides the one that does.

A smaller template shows where they come from. It writes an interface block per interface, and its
`{% if %}` is indented, as people tend to indent the logic they write:

```conf
{% for i in interfaces %}
interface {{ i.name }}
  {% if i.description %}
 description {{ i.description }}
  {% endif %}
 ip address {{ i.address }}
exit
{% endfor %}
```

Saved as `templates/iface.j2`, it is rendered for edge1 by `spacing.py`, which turns on Jinja2's
two whitespace options when it is given `--trim`:

```python
import sys

import yaml
from jinja2 import Environment, FileSystemLoader

data = yaml.safe_load(open("data/edge1.yaml"))
trim = "--trim" in sys.argv
env = Environment(loader=FileSystemLoader("templates"), trim_blocks=trim, lstrip_blocks=trim)
print(env.get_template("iface.j2").render(data), end="")
```

Rendered with Jinja2's defaults:

```
ana@ctl:~$ cd tpl && python spacing.py

interface eth1
  
 description uplink to core1
  
 ip address 198.51.100.2/30
exit

interface eth2
  
 description branch LAN
  
 ip address 203.0.113.1/26
exit
```

**Every tag left something behind.** The newline after `{% for %}` belongs to the loop's body, so
it is printed once per interface: the blank line above each `interface`. The two spaces before `{% if %}` and `{% endif %}` were copied, and so was the newline after each of
them, which is the line holding two spaces under `interface eth1`. Jinja2 removes the tag and keeps
everything around it, because that is what a template language for any kind of text has to do.

Two options change that for the whole environment. **`trim_blocks` drops the first newline after a
block tag, and `lstrip_blocks` drops the spaces and tabs before one** on its line:

```
ana@ctl:~$ cd tpl && python spacing.py --trim
interface eth1
 description uplink to core1
 ip address 198.51.100.2/30
exit
interface eth2
 description branch LAN
 ip address 203.0.113.1/26
exit
```

Now the tags vanish with their lines, and the output is the text between them. Turn on both
options for every configuration template; the alternative is `{%-` and `-%}` on each tag, which
trims by hand and is the first thing forgotten in the next edit.

That the `!` separator between interface blocks is missing here is the template's choice, not the
options': `iface.j2` never wrote one. The full template in the section after next does.
