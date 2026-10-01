---
title: Checking a file before trusting it
version: 1
---

A file with a syntax error fails loudly and at once. **The dangerous files are the ones that parse
and mean something other than what their author intended.** The YAML surprises were one kind. A
duplicate key is another, in an inventory where somebody copied `edge1` to make `edge2` and forgot
to rename it:

```yaml
routers:
  core1:
    address: 192.0.2.11
    site: core
  edge1:
    address: 192.0.2.12
    site: branch-1
  edge1:
    address: 192.0.2.13
    site: branch-2
```

```
ana@ctl:~$ python -c 'import yaml; print(yaml.safe_load(open("inventory.yaml")))'
{'routers': {'core1': {'address': '192.0.2.11', 'site': 'core'}, 'edge1': {'address': '192.0.2.13', 'site': 'branch-2'}}}
ana@ctl:~$ yamllint inventory.yaml; echo "exit status $?"
inventory.yaml
  1:1       warning  missing document start "---"  (document-start)
  8:3       error    duplication of key "edge1" in mapping  (key-duplicates)

exit status 1
```

PyYAML read it without a word, and **the second `edge1` replaced the first**: the result has an
`edge1` at `edge2`'s address and no `edge2` at all. A script looping over it would configure the
wrong router with the right name. `yamllint` refuses the file, with the line and the rule, and it
also warns about the missing `---` that starts a YAML document, which is a style rule and can be
turned off. **Running a linter on every YAML file before a script reads it** catches this whole
class of mistake, and lesson 14 makes it the first step of the pipeline.

The other two formats have their own checkers. A trailing comma, legal in Python and illegal in
JSON:

```
ana@ctl:~$ printf '{"name": "eth1", "mtu": 1500,}\n' > bad.json; python -m json.tool bad.json; echo "exit status $?"
Expecting property name enclosed in double quotes: line 1 column 30 (char 29)
exit status 1
```

And an XML element closed in the wrong order:

```
ana@ctl:~$ printf '<interface><name>eth1</interface>\n' > bad.xml; xmllint --noout bad.xml; echo "exit status $?"
bad.xml:1: parser error : Opening and ending tag mismatch: name line 1 and interface
<interface><name>eth1</interface>
                                 ^
bad.xml:2: parser error : Premature end of data in tag interface line 1

^
exit status 1
```

Each tool gives the line, the column and a non-zero exit status, which is all a pipeline needs.
**Well-formed is the first check, valid is the second**: `json.tool` and `xmllint --noout` say the
syntax is right, and a model, through `yanglint` as in lesson 5, says the content is.
