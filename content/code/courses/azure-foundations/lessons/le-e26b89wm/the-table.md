---
title: Which types move, read from Microsoft's own table
version: 1
---

**Not every resource can move, and the answer is per type, not per resource.** Microsoft keeps one
page listing every resource type with two answers: whether it can move to another resource group,
and whether it can move to another subscription. The two often differ, and the second is the one
that bites, because moving between subscriptions is what a reorganisation asks for.

That page is published as Markdown in Microsoft's public documentation repository on GitHub, so it
can be read by a program rather than by eye. Make the lesson's directory and save this as
`moves.py`:

```sh
mkdir -p ~/azure/moves && cd ~/azure/moves
```

```schooling-example
{"language": "python", "file": "moves.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"moves.py [TYPE...]: which Azure resource types can move, from Microsoft's own table.\"\"\"\nimport re\nimport sys\nimport urllib.request\n\nURL = ('https://raw.githubusercontent.com/MicrosoftDocs/azure-docs/main/articles/'\n       'azure-resource-manager/management/move-support-resources.md')\n\n\n", "note": "Microsoft publishes its documentation as Markdown in a public GitHub repository, and one page of it is **the table of every resource type and whether it can move**. `URL` is that page, read straight from the repository: no account, no key."}, {"code": "def verdict(cell):\n    cell = re.sub(r'\\[([^]]*)\\]\\([^)]*\\)', r'\\1', cell).replace('*', '').lower()\n    words = set(re.findall(r'[a-z]+', cell))\n    if 'yes' in words and 'no' in words:\n        return 'depends'\n    return 'yes' if 'yes' in words else 'no'\n\n\n", "note": "Each cell of the table says Yes or No, sometimes in bold, sometimes with a link or a condition after it. A cell that says both, such as *Yes for the Basic SKU, No for the Standard*, is reported as `depends`, which means: read the row."}, {"code": "def table():\n    text = urllib.request.urlopen(URL, timeout=60).read().decode('utf-8')\n    rows, namespace = {}, None\n    for line in text.splitlines():\n        if line.startswith('## '):\n            namespace = line[3:].strip()\n        elif line.startswith('> |') and namespace and '---' not in line:\n            cells = [c.strip() for c in line[3:].split('|')]\n            if len(cells) >= 3 and cells[0] != 'Resource type':\n                rows[f'{namespace}/{cells[0]}'.lower()] = (verdict(cells[1]), verdict(cells[2]))\n    return rows\n\n\n", "note": "Every `## ` heading is a provider namespace, and every table row under it a type. The first column is the move to another **resource group**, the second to another **subscription**. The key is lower-cased, because lesson 2 showed that Azure compares type names without regard to case."}, {"code": "rows = table()\nif len(sys.argv) == 1:\n    for i, scope in enumerate(('to another group', 'to another subscription')):\n        count = {v: sum(1 for r in rows.values() if r[i] == v) for v in ('yes', 'depends', 'no')}\n        print(f'{len(rows)} types, {scope}: ' + ', '.join(f'{v} {n}' for v, n in count.items()))\nfor name in sys.argv[1:]:\n    group, sub = rows.get(name.lower(), ('?', '?'))\n    print(f'{name:<44} group {group:<8} subscription {sub}')\n", "note": "With no arguments it counts; with type names it looks each one up. A type the table does not list answers `?`, which is a question to ask before the move, not a yes."}]}
```

Run it once with nothing, to count, and once with the types the shop's network and machines are
made of:

```
ana@laptop:~/azure/moves$ python3 moves.py
756 types, to another group: yes 201, depends 2, no 553
756 types, to another subscription: yes 186, depends 3, no 567
```

```
ana@laptop:~/azure/moves$ python3 moves.py Microsoft.Network/virtualNetworks Microsoft.Network/publicIPAddresses Microsoft.Network/loadBalancers Microsoft.Network/bastionHosts Microsoft.Network/natGateways Microsoft.Network/azureFirewalls Microsoft.Compute/virtualMachines Microsoft.KeyVault/vaults
Microsoft.Network/virtualNetworks            group yes      subscription yes
Microsoft.Network/publicIPAddresses          group yes      subscription yes
Microsoft.Network/loadBalancers              group yes      subscription depends
Microsoft.Network/bastionHosts               group yes      subscription no
Microsoft.Network/natGateways                group no       subscription no
Microsoft.Network/azureFirewalls             group no       subscription no
Microsoft.Compute/virtualMachines            group yes      subscription yes
Microsoft.KeyVault/vaults                    group yes      subscription yes
```

**The table was read on 30 October 2026**, and Microsoft edits it: a type that says No today may say
Yes next year. Run the program again before a real move rather than trusting the numbers here.

## What the numbers say

**Most of the 756 rows say No, and that is less alarming than it sounds.** Many rows are not things
anybody creates: operation records, diagnostic categories, types the portal uses internally. What
matters is the row for the type you own, and for the shop's resources the picture is mixed:

- **the virtual network, the machine, the key vault and the public IP address move anywhere** by
  the table. The network's subnets and the machine's extensions travel with them, as children;
- **the Bastion host moves between groups but not between subscriptions**;
- **the load balancer depends**: the table says the Basic one moves between subscriptions and the
  Standard one does not, which is a fact about a product version rather than about load balancing;
- **the NAT gateway and Azure Firewall do not move at all.** To have one in another group, you
  create a new one there and delete the old one.

**A Yes in the table is not the end of the question.** The public IP address says Yes for
subscriptions, and the networking guidance the row links to adds what the cell leaves out: a
resource associated with a **Standard** public IP address cannot be moved across subscriptions.
Every namespace with conditions has a page like that, linked from its section of the table, and it
is the second thing to read.

## When the answer is No

A type that cannot move is moved the honest way: **create it again where it belongs, switch the
things that use it over, and delete the old one.** For a firewall that is a maintenance window; for
a NAT gateway, a few minutes of changed outbound addresses. This is the strongest argument for the
habit lesson 26 builds, describing resources in a file: with the file, recreating something
elsewhere is a deployment, and without it, an archaeology project.
