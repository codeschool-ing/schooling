---
title: Actions minus not-actions, and roles added together
version: 1
---

**Microsoft states the rule for reading a role in two lines**: what the role's actions allow, minus
what its not-actions remove, gives the operations it permits; and the same subtraction, done
separately, gives the data operations. A wildcard in `actions` is expanded first, and a wildcard
in `notActions` takes away everything it matches.

The wrong picture to drop is a not-action as a ban. **`notActions` is not a deny.** It only removes
something from the role it sits in. If a second role, assigned to the same person, allows the same
operation, the person may do it. That is the second half of the rule, and Microsoft's documentation
names it plainly: Azure RBAC is **additive**, and a person's effective permissions are the sum of
all their role assignments.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l09-additive\" aria-label=\"Two role assignments held by the same person, added together. Contributor allows every operation except those under Microsoft.Authorization, which its notActions remove. User Access Administrator allows Microsoft.Authorization operations. The person's effective permissions are the union: everything, including writing role assignments. The notActions of Contributor removed the operation from Contributor only, not from the person.\"><rect x=\"30.0\" y=\"30.0\" width=\"200.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Contributor</text><text x=\"46.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">allows</text><text x=\"130.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">*</text><text x=\"46.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">removes</text><text x=\"130.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Microsoft.Authorization/*/Write</text><text x=\"255.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--paper-dim)\">+</text><rect x=\"280.0\" y=\"30.0\" width=\"200.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">User Access Administrator</text><text x=\"296.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">allows</text><text x=\"380.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Microsoft.Authorization/*</text><text x=\"296.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">removes</text><text x=\"380.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">nothing</text><text x=\"505.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--paper-dim)\">=</text><rect x=\"530.0\" y=\"30.0\" width=\"160.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">effective</text><text x=\"610.0\" y=\"91.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">every operation,</text><text x=\"610.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">role assignments</text><text x=\"610.0\" y=\"118.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">included</text><text x=\"360.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">notActions takes away from its own role, not from the person</text><text x=\"360.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">only a deny assignment takes away from everything</text></svg>", "caption": "Roles are added together. A not-action narrows its own role and nothing else."}
```

## The rule, as a program

The lab cannot ask Resource Manager whether an operation would be allowed. It can apply the
documented rule to the definitions the previous section downloaded, and that makes the rule
something you can test rather than recite. Save this as `can.py` in `~/azure/rbac`:

```schooling-example
{"language": "python", "file": "can.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"can.py [--data] ACTION ROLE.json...: which of these roles grant ACTION?\n\nThe course's model of the rule Microsoft documents, not Azure's own evaluator.\"\"\"\nimport fnmatch\nimport json\nimport sys\n\n\n", "note": "**This is the course's model, not Azure.** It follows the rule Microsoft's documentation states, on the definitions you just downloaded, so that the rule can be tried on your own computer. Resource Manager's real evaluation also weighs deny assignments and conditions, which the next section names."}, {"code": "def matches(pattern, action):\n    return fnmatch.fnmatchcase(action.lower(), pattern.lower())\n\n\n", "note": "A `*` in a permission matches anything, slashes included, so `*/read` is every read in every provider. The model compares without regard to case, as Azure compares ids."}, {"code": "def grants(role, action, data):\n    allow, remove = ('dataActions', 'notDataActions') if data else ('actions', 'notActions')\n    for p in role['permissions']:\n        if any(matches(a, action) for a in p[allow]) and not any(matches(n, action) for n in p[remove]):\n            return True\n    return False\n\n\n", "note": "The documented rule: **what the actions allow, minus what the not-actions remove**. Management and data are two separate lists, and `--data` chooses which one is asked."}, {"code": "args = sys.argv[1:]\ndata = args[0] == '--data'\naction, files = (args[1], args[2:]) if data else (args[0], args[1:])\nfor path in files:\n    with open(path) as f:\n        role = json.load(f)\n    print('yes' if grants(role, action, data) else 'no ', role['roleName'])\n", "note": "One line per role file given: `yes` or `no`, and the role's name."}]}
```

Ask it four questions, each against the roles that make the answer interesting:

```
ana@laptop:~/azure/rbac$ python3 can.py Microsoft.Network/virtualNetworks/write contributor.json reader.json owner.json
yes Contributor
no  Reader
yes Owner
ana@laptop:~/azure/rbac$ python3 can.py Microsoft.Authorization/roleAssignments/write contributor.json owner.json
no  Contributor
yes Owner
ana@laptop:~/azure/rbac$ python3 can.py --data Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read owner.json contributor.json blob-reader.json
no  Owner
no  Contributor
yes Storage Blob Data Reader
ana@laptop:~/azure/rbac$ python3 can.py Microsoft.Storage/storageAccounts/listKeys/action contributor.json reader.json
yes Contributor
no  Reader
```

The first two answers are the roles' reputations, now read from their definitions: Contributor may
change the network and Reader may not; Contributor may not create a role assignment and Owner may.

**The third answer surprises people.** Neither Owner nor Contributor may read a blob through the
data plane, because both have an empty `dataActions`; only the Storage Blob Data Reader may. Being
Owner of a subscription does not, by that route, show you a single file in it.

**The fourth answer is why that is not the whole story.** Contributor may run `listKeys` on a storage
account, and a storage account's key opens every blob in it, with no role involved at all. So an
Owner or a Contributor who wants the data can fetch the key and read it. The separation between
management and data holds only where the shared keys are switched off, and the `azure-data` course
returns to that switch.

## What the program does not know

The program is honest about one definition at a time, and Resource Manager weighs more than that.
Microsoft's documentation lists the order in which a request is judged:

1. **Every deny assignment that covers the resource is checked first.** If one denies the operation
   to this principal, the request is refused and nothing else is read.
2. **The role assignments that apply are gathered**: the principal's own and those of every group
   it belongs to, at the resource and at every scope above it.
3. **The operation is looked for in those roles**, with the subtraction above.
4. **Conditions are evaluated** where an assignment carries one, such as a storage role limited to
   blobs with a given tag.

`can.py` does step 3 for the roles you hand it, and nothing else. It does not know which assignments
a principal has, which groups they are in, whether a deny assignment covers the resource, or whether
a condition would hold. Those are facts about one tenant on one day, and they live in Resource
Manager.

**Deny assignments are rare, and you cannot write one.** They are created by Azure on your behalf: a
deployment stack with deny settings, which the `azure-operations` course builds in its lesson 5, places one over the resources it manages
so that nobody deletes them by hand, and a managed application places one over its own resource
group. A deny assignment beats every allow, an Owner's included, which is the property that makes it
useful and the reason it is not handed out.
