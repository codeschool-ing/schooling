---
title: The whole configuration from a template
version: 1
---

The project on `ctl` is a directory of data and a directory of templates:

```
ana@ctl:~$ cd tpl && find data templates -type f | sort
data/core1.yaml
data/edge1.yaml
data/edge2.yaml
templates/frr.j2
templates/iface.j2
```

Each data file is what makes one router different. edge1's:

```yaml
hostname: edge1
loopback: 203.0.113.252
interfaces:
  - name: eth1
    description: uplink to core1
    address: 198.51.100.2/30
    ospf: point-to-point
  - name: eth2
    description: branch LAN
    address: 203.0.113.1/26
    ospf: passive
```

The template is FRR's running configuration with holes in it. Two parts are worth reading closely.
The `{% if %}` inside the interface loop turns one value, `ospf`, into the right command for each
kind of link; and the `router ospf` block loops over the same interfaces a second time, so a
network statement is written for every interface that has OSPF, and an interface added to the data
appears in both places at once:

```conf
frr version 8.4.4
frr defaults traditional
hostname {{ hostname }}
log file /var/log/frr/frr.log informational
service integrated-vtysh-config
!
{% for i in interfaces %}
interface {{ i.name }}
{% if i.description %}
 description {{ i.description }}
{% endif %}
 ip address {{ i.address }}
{% if i.ospf == "point-to-point" %}
 ip ospf network point-to-point
{% elif i.ospf == "passive" %}
 ip ospf passive
{% endif %}
exit
!
{% endfor %}
interface lo
 ip address {{ loopback }}/32
exit
!
router ospf
 ospf router-id {{ loopback }}
 redistribute connected
{% for i in interfaces if i.ospf %}
 network {{ i.address | network }} area 0
{% endfor %}
exit
!
line vty
 exec-timeout 30 0
exit
!
end
```

`network` is not one of Jinja2's filters. It is a function in the script that renders, which turns
`198.51.100.2/30` into `198.51.100.0/30` with Python's `ipaddress` module. **A calculation belongs in
Python and a filter is how a template calls it**: the alternative is a `network` value in every
data file, written by hand next to the address it is derived from, and wrong the first time
somebody renumbers a link.

```schooling-example
{
  "language": "python",
  "file": "render.py",
  "parts": [
    {
      "code": "import ipaddress\nimport pathlib\n\nimport yaml\nfrom jinja2 import Environment, FileSystemLoader, StrictUndefined\n\n"
    },
    {
      "code": "def network(address):\n    return str(ipaddress.ip_interface(address).network)\n\n\nenv = Environment(\n    loader=FileSystemLoader(\"templates\"),",
      "note": "**A filter is a Python function.** `198.51.100.2/30 | network` calls it with the address and prints what it returns, the network the address sits in."
    },
    {
      "code": "    trim_blocks=True,\n    lstrip_blocks=True,",
      "note": "**Block tags leave no blank lines.** `trim_blocks` drops the newline after a `{% %}` tag and `lstrip_blocks` the spaces before it."
    },
    {
      "code": "    undefined=StrictUndefined,",
      "note": "**A missing value is an error, not an empty string.** Jinja2's default prints nothing for a name it does not know, and the configuration comes out with a hole in it."
    },
    {
      "code": "    keep_trailing_newline=True,\n)\nenv.filters[\"network\"] = network\ntemplate = env.get_template(\"frr.j2\")\n\nout = pathlib.Path(\"configs\")\nout.mkdir(exist_ok=True)",
      "note": "**The last newline is kept.** Jinja2 drops one trailing newline from a template by default, and the rendered file would then differ from the router's by one byte."
    },
    {
      "code": "for path in sorted(pathlib.Path(\"data\").glob(\"*.yaml\")):\n    data = yaml.safe_load(path.read_text())\n    text = template.render(data)\n    (out / f\"{data['hostname']}.conf\").write_text(text)\n    print(f\"{path} -> configs/{data['hostname']}.conf, {len(text.splitlines())} lines\")",
      "note": "**One template, one file of data per router.** The loop is the whole program: read the host's YAML, render, write."
    }
  ]
}
```

```
ana@ctl:~$ cd tpl && python render.py
data/core1.yaml -> configs/core1.conf, 34 lines
data/edge1.yaml -> configs/edge1.conf, 34 lines
data/edge2.yaml -> configs/edge2.conf, 34 lines
```

The first check of a template that describes an existing network is whether it reproduces it. The
first comparison did not quite:

```
ana@ctl:~$ cd tpl && ssh netops@core1 "show running-config" | tail -n +5 | diff - configs/core1.conf
34c34
< end
---
> end
\ No newline at end of file
```

**One byte.** Jinja2 removes a single trailing newline from the template unless it is told to keep
it, so the rendered file ended in `end` and the router's in `end` and a newline. That is what
`keep_trailing_newline=True` in the script above is for. With it:

```
ana@ctl:~$ cd tpl && python render.py
data/core1.yaml -> configs/core1.conf, 34 lines
data/edge1.yaml -> configs/edge1.conf, 34 lines
data/edge2.yaml -> configs/edge2.conf, 34 lines
ana@ctl:~$ cd tpl && for h in core1 edge1 edge2; do ssh netops@$h "show running-config" | tail -n +5 | diff -q - configs/$h.conf > /dev/null && echo "$h: same"; done
core1: same
edge1: same
edge2: same
```

Three routers, three rendered files, no difference. From here on the data and the template are the
description of the network, and the routers are what they render.
