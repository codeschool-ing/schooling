---
title: A role is a list of actions
version: 1
---

**In Azure, nobody is given access to a resource directly. They are given a role, at a scope.** The
role says what may be done, the scope says where, and the pairing of the two with a principal is a
**role assignment**. This lesson takes the three pieces one at a time: the role here, the rule that
reads it in the next section, and the assignment in the one after.

A common first picture is a list of people on each resource, the way a shared folder has one. That
list does not exist. Ask Azure who may change `vnet-shop-prod` and it answers by collecting every
assignment on the network, on its resource group, on its subscription and on every management group
above it, and reading the roles they name. Lesson 2's boxes are where the answer comes from.

## What a role definition holds

**A role definition is a named list of operations.** Every operation in Azure has a name built like
a resource id, starting with the provider namespace: `Microsoft.Network/virtualNetworks/write` is
creating or changing a network, `Microsoft.Compute/virtualMachines/start/action` is starting a
machine, `Microsoft.Storage/storageAccounts/listKeys/action` is reading a storage account's keys.
A definition holds four lists of them, and a fifth list of places:

| field | what it holds |
|---|---|
| `actions` | the management operations the role allows: create, read, change and delete resources |
| `notActions` | operations taken out of `actions`, usually because `actions` used a wildcard |
| `dataActions` | operations on the data inside a resource: reading a blob, reading a secret's value |
| `notDataActions` | the same subtraction, for data |
| `assignableScopes` | where the role may be assigned: `/` for everywhere, or a list of subscriptions and groups |

**Management and data are separate on purpose.** Changing a storage account and reading the files
inside it are different powers, held by different people: the platform team runs the account, and
the application reads the files. Lesson 25 calls the two halves the control plane and the data plane.

## The built-in roles

Microsoft ships several hundred roles, and four of them carry most of the weight. Their ids are the
same GUIDs in every tenant on the planet, which is why a template can name one by id:

| role | what it allows | id |
|---|---|---|
| **Owner** | everything, including giving access to others | `8e3af657-a8ff-443c-a75c-2fe8c4bcb635` |
| **Contributor** | everything except giving access | `b24988ac-6180-42a0-ab88-20f7382dd24c` |
| **Reader** | looking, and changing nothing | `acdd72a7-3385-48ef-bd42-f606fba81ae7` |
| **User Access Administrator** | giving access, and nothing else | `18d7d88d-d35e-4fb5-a5c3-7773c20a72d9` |

Beside them sits **Role Based Access Control Administrator**, `f58310d9-a9f6-439a-9e8d-f62e7b41a168`,
which gives access through assignments and can be limited by conditions to certain roles; and the
specific roles, such as Network Contributor or Storage Blob Data Reader, which are where least
privilege actually lives.

## Reading a definition yourself

The list of roles is a question for Resource Manager, and the lab gets its usual answer:

```
ana@laptop:~/azure$ az role definition list --name Contributor
ERROR: Please run 'az login' to setup account.
```

The definitions are public, though. **Microsoft publishes every built-in role's JSON in its
documentation**, and the documentation's source is a public repository on GitHub. Make the
lesson's directory, and save this program as `roledef.py`:

```sh
mkdir -p ~/azure/rbac && cd ~/azure/rbac
```

```schooling-example
{"language": "python", "file": "roledef.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"roledef.py PAGE ROLE: a built-in role's definition, from the source of Microsoft's documentation.\"\"\"\nimport json\nimport re\nimport sys\nimport urllib.request\n\nBASE = ('https://raw.githubusercontent.com/MicrosoftDocs/azure-docs/main/'\n        'articles/role-based-access-control/built-in-roles/')\n\n", "note": "Microsoft writes its documentation in Markdown, in a public repository on GitHub, and the pages on built-in roles carry each role's definition as a JSON block. `BASE` is the folder those pages live in. Reading it needs no account."}, {"code": "page, role = sys.argv[1], sys.argv[2]\nwith urllib.request.urlopen(BASE + page + '.md', timeout=60) as reply:\n    text = reply.read().decode()\n", "note": "The roles are spread over pages by subject: `general` holds Reader, `privileged` holds Owner and Contributor, `storage` the storage roles."}, {"code": "section = text.split('\\n## ' + role + '\\n', 1)[1].split('\\n## ', 1)[0]\nblock = re.search(r'```json\\n(.*?)\\n```', section, re.S).group(1)\nprint(json.dumps(json.loads(block), indent=2))\n", "note": "Each role has a heading of its own, `## Contributor`, and the first JSON block under it is the definition. The program cuts out that block and prints it, which also checks that it is valid JSON. **If Microsoft rearranges the pages, this breaks loudly** rather than printing the wrong role."}]}
```

Fetch four definitions and keep them as files, then read what Contributor takes away:

```
ana@laptop:~/azure/rbac$ python3 roledef.py privileged Contributor > contributor.json
ana@laptop:~/azure/rbac$ python3 roledef.py privileged Owner > owner.json
ana@laptop:~/azure/rbac$ python3 roledef.py general Reader > reader.json
ana@laptop:~/azure/rbac$ python3 roledef.py storage 'Storage Blob Data Reader' > blob-reader.json
ana@laptop:~/azure/rbac$ jq .permissions contributor.json
[
  {
    "actions": [
      "*"
    ],
    "notActions": [
      "Microsoft.Authorization/*/Delete",
      "Microsoft.Authorization/*/Write",
      "Microsoft.Authorization/elevateAccess/Action",
      "Microsoft.Blueprint/blueprintAssignments/write",
      "Microsoft.Blueprint/blueprintAssignments/delete",
      "Microsoft.Compute/galleries/share/action",
      "Microsoft.Purview/consents/write",
      "Microsoft.Purview/consents/delete",
      "Microsoft.Resources/deploymentStacks/manageDenySetting/action",
      "Microsoft.Subscription/cancel/action",
      "Microsoft.Subscription/enable/action"
    ],
    "dataActions": [],
    "notDataActions": []
  }
]
ana@laptop:~/azure/rbac$ jq -c .permissions owner.json reader.json
[{"actions":["*"],"notActions":[],"dataActions":[],"notDataActions":[]}]
[{"actions":["*/read"],"notActions":[],"dataActions":[],"notDataActions":[]}]
ana@laptop:~/azure/rbac$ jq -c .permissions blob-reader.json
[{"actions":["Microsoft.Storage/storageAccounts/blobServices/containers/read","Microsoft.Storage/storageAccounts/blobServices/generateUserDelegationKey/action"],"notActions":[],"dataActions":["Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read"],"notDataActions":[]}]
```

Contributor's `actions` is a single `*`: every management operation in Azure. Then `notActions`
takes eleven back, and **the first two are the point of the role**: nothing under
`Microsoft.Authorization` may be written or deleted, and `Microsoft.Authorization` is where role
assignments live. A Contributor can build anything and cannot give anybody access to it, themselves
included. Owner is `*` with nothing removed, and Reader is `*/read`: every operation whose name ends
in `read`, in every provider.

**Read the last line of the Storage Blob Data Reader**: its `actions` let it see that containers
exist, and its `dataActions` let it read the blobs inside. Contributor's `dataActions` is empty.
The next section asks what that means for the people who hold it.
