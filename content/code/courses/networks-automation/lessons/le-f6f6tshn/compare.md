---
title: Comparing with what should be running
version: 1
---

The history compares the network with itself. **The other comparison is with the intent**: lesson
10's data and template, rendered, against the backup. A plain `diff` first:

```
ana@ctl:~$ cd net && python render.py > /dev/null && diff configs/edge1.conf backups/edge1.conf
0a1,2
> 
> !
6a9,10
> ip route 192.0.2.128/25 198.51.100.1
> !
14c18
<  description branch LAN
---
>  description guest wifi
```

Two of the differences are real, the route and the description. **The first two lines are not**:
the blank line and `!` are what FRR prints before the configuration starts, which the backup kept on
purpose. A plain diff of text has no way of knowing which lines mean something, and on other
platforms the noise is worse: a timestamp of the last change, a line whose position moves, a
section printed in a different order after an upgrade.

A comparison that understands the configuration's structure does better. `netutils`, a library
of network utilities, has one that reads a configuration as sections, `interface eth2` with its
lines underneath, and asks which lines of one are absent from the other:

```schooling-example
{
  "language": "python",
  "file": "compare.py",
  "parts": [
    {
      "code": "import pathlib\nimport sys\n\nfrom netutils.config.compliance import diff_network_config\n\nhost = sys.argv[1]\nintended = pathlib.Path(f\"configs/{host}.conf\").read_text()\nactual = pathlib.Path(f\"backups/{host}.conf\").read_text()"
    },
    {
      "code": "missing = diff_network_config(intended, actual, \"cisco_ios\")\nextra = diff_network_config(actual, intended, \"cisco_ios\")\nprint(f\"{host}, missing from the router:\\n{missing or '(nothing)'}\")\nprint(f\"{host}, on the router and not intended:\\n{extra or '(nothing)'}\")",
      "note": "**Two questions, each a diff by sections.** What the intended configuration has and the router lacks, and what the router has that nobody intended. A line is shown under the section it belongs to, wherever it sits in the file."
    }
  ]
}
```

```
ana@ctl:~$ cd net && python compare.py edge1
edge1, missing from the router:
interface eth2
 description branch LAN
edge1, on the router and not intended:
ip route 192.0.2.128/25 198.51.100.1
interface eth2
 description guest wifi
```

**Each line is shown under the section it belongs to**, wherever it sits in the file, and the
blank line and `!` are gone because they are not configuration. The two directions answer two
different questions: what the data asks for and the router lacks, and what the router has that
nobody wrote down. The first is usually a change that failed; the second is the drift.

The parser named is `cisco_ios`, because FRR's configuration has the same shape, sections opened by
a line and indented beneath it. `netutils` has parsers for about thirty platforms, and the right
one has to be named; a parser for the wrong shape gives a confident and wrong answer.
