---
title: Edit the candidate, then commit
version: 1
---

A change in NETCONF happens in two steps, and the space between them is the point. **`edit-config`
writes to the candidate**; running, the configuration in force, does not move until **`commit`**
copies the candidate into it.

```schooling-example
{
  "language": "python",
  "file": "candidate.py",
  "parts": [
    {
      "code": "from nc import connect, describe, interface_config\n\nwith connect() as m:"
    },
    {
      "code": "    m.edit_config(target=\"candidate\", config=interface_config(\n        \"<interface><name>eth2</name><description>to pc1</description><enabled>true</enabled></interface>\"))\n    print(describe(m, \"candidate\", \"eth2\"))\n    print(describe(m, \"running\", \"eth2\"))",
      "note": "**The edit goes to the candidate**, a working copy. Running, the configuration in force, does not move."
    },
    {
      "code": "    m.commit()\n    print(\"-- after commit\")\n    print(describe(m, \"running\", \"eth2\"))",
      "note": "**`commit` copies the candidate to running, as one operation.**"
    }
  ]
}
```

```
ana@ctl:~$ python candidate.py
candidate eth2: description='to pc1' enabled=true
running   eth2: description='(none)' enabled=false
-- after commit
running   eth2: description='to pc1' enabled=true
```

Between the edit and the commit, the two datastores disagreed: the candidate had the description
and `enabled=true`, running had neither. Anything reading running in that moment, a monitoring
system or another script, saw the old configuration. **Nothing was half applied**, because
nothing was applied at all until `commit`.

`edit-config` **merges** by default: the XML sent is laid over the existing tree, so the
interface's `type` and its other leaves stayed as they were. The protocol has other operations
for when merging is wrong, set with an `operation` attribute on an element: `replace` makes that
element exactly what was sent, `delete` removes it and fails if it is absent, `remove` removes
it and does not fail, and `create` fails if it already exists.

The candidate is shared. **On `nc1` there is one candidate for every session**, so an edit left
there by one script is still there when the next script commits. The next two sections are about
what that costs, and how to prevent it.
