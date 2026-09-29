---
title: YAML, and the values that are not what they seem
version: 1
---

YAML is the format people write, because it is readable with almost no punctuation: indentation
is structure, `-` starts a list item, `key: value` is a mapping. **The price is that YAML guesses
the type of every unquoted value**, and in the version of YAML that PyYAML reads, 1.1, it guesses
more than anybody expects. Six values a person meant as text:

```yaml
country: NO
enable_ntp: on
file_mode: 0755
version: 1.10
port_range: 22:22
vlan_name: 010
```

```schooling-example
{
  "language": "python",
  "file": "surprises.py",
  "parts": [
    {
      "code": "import yaml\n"
    },
    {
      "code": "for key, value in yaml.safe_load(open(\"surprises.yaml\")).items():\n    print(f\"{key:11} {type(value).__name__:5} {value!r}\")",
      "note": "**Six values a person meant as text.** PyYAML reads YAML 1.1, and in YAML 1.1 each of them looks like something else."
    }
  ]
}
```

```
ana@ctl:~$ python surprises.py
country     bool  False
enable_ntp  bool  True
file_mode   int   493
version     float 1.1
port_range  int   1342
vlan_name   int   8
```

Each is a real mistake with a real cost in a network inventory:

| wrote | meant | got | why |
|---|---|---|---|
| `NO` | the country code of Norway | `False` | `yes`, `no`, `on`, `off` are booleans in YAML 1.1 |
| `on` | the text "on" | `True` | the same rule |
| `0755` | a file mode, as text | `493` | a leading zero makes it octal |
| `1.10` | a software version | `1.1` | it is a float, and the trailing zero means nothing to a float |
| `22:22` | a port range | `1342` | numbers with colons are base 60, for times like `1:30:00` |
| `010` | a VLAN name | `8` | octal again |

**The fix is quoting.** A quoted value is always a string, and nothing about it is guessed:

```
ana@ctl:~$ sed -E 's/: (.*)$/: "\1"/' surprises.yaml > quoted.yaml; cat quoted.yaml
country: "NO"
enable_ntp: "on"
file_mode: "0755"
version: "1.10"
port_range: "22:22"
vlan_name: "010"
ana@ctl:~$ python -c 'import yaml; print(yaml.safe_load(open("quoted.yaml")))'
{'country': 'NO', 'enable_ntp': 'on', 'file_mode': '0755', 'version': '1.10', 'port_range': '22:22', 'vlan_name': '010'}
```

The rule that avoids all six: **quote every value that is not a number or a boolean you meant as
one**, and treat versions, codes, modes and anything with leading zeros as text. YAML 1.2 dropped
most of these guesses, but PyYAML and much of the tooling around Ansible still read 1.1.

**And always `safe_load`, never `load`.** Full YAML can describe Python objects, including a call
to a function, and `yaml.load` with `yaml.UnsafeLoader` will construct them. `safe_load` refuses:

```
ana@ctl:~$ python -c 'import yaml; yaml.safe_load("!!python/object/apply:os.system [echo hello]")' 2>&1 | grep Error
    raise ConstructorError(None, None,
yaml.constructor.ConstructorError: could not determine a constructor for the tag 'tag:yaml.org,2002:python/object/apply:os.system'
```

That tag asks for `os.system("echo hello")` to be run while the file is read. `safe_load` would not
build it; on a file from somebody else's repository, that refusal is the difference between reading
data and running their code.
