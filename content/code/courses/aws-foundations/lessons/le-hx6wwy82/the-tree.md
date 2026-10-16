---
title: The tree: a root, organisational units and accounts
version: 1
---

**An organisation is a tree of accounts, owned by the one account at its top.** The wrong picture
is a super-account, where the resources of every member pool together and whoever runs the
organisation sees them all. Nothing pools. Each member keeps every wall lesson 2 measured. What the
organisation adds is one bill for all of them, and rules that flow down its branches.

Four words name the parts:

- **The management account** created the organisation and pays its bill. There is one, it cannot
  be removed from the organisation it manages, and this lesson's last section says why it should run
  nothing. The API still calls it by its old name, `master`, in fields such as `MasterAccountId`.
- **Member accounts** are every other account in the tree. Each belongs to exactly one organisation
  at a time.
- **The root** is the top of the tree, one per organisation, with an id starting `r-`.
- **An organisational unit**, an OU, is a folder in the tree, with an id starting `ou-`. It holds
  accounts and other OUs, nested up to five levels below the root. Every account and every OU has
  exactly one parent.

**An OU holds no resources and has no bill of its own.** It exists so that a rule can be attached
to a branch once rather than to each account in it, which lesson 4 does. So the tree is
drawn by **what accounts have in common**, such as production or experiments, and not by the
company's departments. A rule follows the kind of work, not the team that does it.

## Building the shop's tree

Restart moto in the first terminal (Ctrl+C, then `moto_server -p 4567`) so this lesson starts from
an empty AWS. Then create the organisation:

```
ana@laptop:~/aws$ aws organizations create-organization --query "Organization.[Id,FeatureSet,MasterAccountId]" --output text
o-vpkre95at2	ALL	123456789012
ana@laptop:~/aws$ aws organizations list-roots --query "Roots[].[Id,Name]" --output text
r-ucqy	Root
```

The organisation has an id, `o-` and ten characters; `ALL` is its feature set, which the next
section explains; and its root exists already. Every id in this lesson is moto's invention and
yours will differ, so the commands below never type one: they look each id up by name. Two shell
functions do the looking, and they last until the terminal is closed. Type them into the second
terminal first:

```sh
ou() { aws organizations list-organizational-units-for-parent --parent-id "$1" --query "OrganizationalUnits[?Name=='$2'].Id" --output text; }
account() { aws organizations list-accounts --query "Accounts[?Name=='$1'].Id" --output text; }
```

`ou PARENT NAME` prints the id of the OU called NAME under PARENT, and `account NAME` the number of
the account called NAME. Now the OUs, three under the root and two under `Workloads`:

```
ana@laptop:~/aws$ root=$(aws organizations list-roots --query "Roots[0].Id" --output text)
ana@laptop:~/aws$ for name in Security Workloads Sandbox; do aws organizations create-organizational-unit --parent-id $root --name $name --query "OrganizationalUnit.[Id,Name]" --output text; done
ou-ucqy-vkatnym7	Security
ou-ucqy-x5zp8bqc	Workloads
ou-ucqy-as6q74bz	Sandbox
ana@laptop:~/aws$ workloads=$(ou $root Workloads)
ana@laptop:~/aws$ for name in Prod Staging; do aws organizations create-organizational-unit --parent-id $workloads --name $name --query "OrganizationalUnit.[Id,Name]" --output text; done
ou-ucqy-w1hyddq5	Prod
ou-ucqy-hdvl0tp6	Staging
```

And the five accounts, with the e-mail convention from lesson 2:

```
ana@laptop:~/aws$ for a in shop-prod shop-staging security log-archive sandbox; do aws organizations create-account --email aws+$a@example.com --account-name $a --query "CreateAccountStatus.[AccountId,AccountName]" --output text; done
332178477898	shop-prod
073648902831	shop-staging
771971365420	security
006227652844	log-archive
652028714336	sandbox
ana@laptop:~/aws$ aws organizations list-children --parent-id $root --child-type ACCOUNT --query "Children[].Id" --output text
123456789012	332178477898	073648902831	771971365420	006227652844	652028714336
```

**A new account always starts under the root.** `create-account` takes no parent, so all six
accounts, management included, are children of the root until something moves them. Moving is
`move-account`, which names the account, the parent it is leaving and the parent it is going to:

```
ana@laptop:~/aws$ aws organizations move-account --account-id $(account shop-prod) --source-parent-id $root --destination-parent-id $(ou $workloads Prod)
ana@laptop:~/aws$ aws organizations move-account --account-id $(account shop-staging) --source-parent-id $root --destination-parent-id $(ou $workloads Staging)
ana@laptop:~/aws$ for a in security log-archive; do aws organizations move-account --account-id $(account $a) --source-parent-id $root --destination-parent-id $(ou $root Security); done
ana@laptop:~/aws$ aws organizations move-account --account-id $(account sandbox) --source-parent-id $root --destination-parent-id $(ou $root Sandbox)
```

None of the four printed anything, which is what success looks like for `move-account`. Asking the
tree shows where everything went:

```
ana@laptop:~/aws$ aws organizations list-children --parent-id $root --child-type ACCOUNT --query "Children[].Id" --output text
123456789012
ana@laptop:~/aws$ aws organizations list-accounts-for-parent --parent-id $(ou $root Security) --query "Accounts[].[Id,Name]" --output text
771971365420	security
006227652844	log-archive
ana@laptop:~/aws$ aws organizations list-parents --child-id $(account shop-prod) --query "Parents[].[Id,Type]" --output text
ou-ucqy-w1hyddq5	ORGANIZATIONAL_UNIT
ana@laptop:~/aws$ aws organizations list-parents --child-id $(ou $workloads Prod) --query "Parents[].[Id,Type]" --output text
ou-ucqy-x5zp8bqc	ORGANIZATIONAL_UNIT
```

Only the management account is left under the root. `Security` holds the two accounts that watch
the others, and `list-parents` walks upwards one step at a time: `shop-prod` sits in `Prod`, and
`Prod` sits in `Workloads`. **Each step has one parent**, so the path from any account to the root
is a single line. That is what makes "the rules of every OU above it" a question with one answer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" data-fig=\"l03-tree\" aria-label=\"The shop's organisation as the transcripts built it. The root r-ucqy has four children: the management account 123456789012 and the organisational units Security, Workloads and Sandbox. Security holds the accounts security, 771971365420, and log-archive, 006227652844. Workloads holds two more units, Prod with the account shop-prod, 332178477898, and Staging with shop-staging, 073648902831. Sandbox holds the account sandbox, 652028714336. Accounts are drawn as boxes with a bright edge, organisational units as rounded boxes.\"><defs><marker id=\"l03-tree-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"300.0\" y=\"22.0\" width=\"120.0\" height=\"36.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"2\"></rect><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Root  r-ucqy</text><rect x=\"15.0\" y=\"100.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"75.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">management</text><text x=\"75.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">123456789012</text><path d=\"M360.0 60.0 L360.0 80.0 L75.0 80.0 L75.0 97.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><rect x=\"155.0\" y=\"104.0\" width=\"120.0\" height=\"32.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"215.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Security</text><path d=\"M360.0 60.0 L360.0 80.0 L215.0 80.0 L215.0 101.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><rect x=\"370.0\" y=\"104.0\" width=\"120.0\" height=\"32.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"430.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Workloads</text><path d=\"M360.0 60.0 L360.0 80.0 L430.0 80.0 L430.0 101.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><rect x=\"585.0\" y=\"104.0\" width=\"120.0\" height=\"32.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"645.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Sandbox</text><path d=\"M360.0 60.0 L360.0 80.0 L645.0 80.0 L645.0 101.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><rect x=\"150.0\" y=\"190.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"215.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">security</text><text x=\"215.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">771971365420</text><rect x=\"150.0\" y=\"270.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"215.0\" y=\"283.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">log-archive</text><text x=\"215.0\" y=\"299.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">006227652844</text><path d=\"M215.0 136.0 L215.0 160.0 L215.0 160.0 L215.0 187.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><path d=\"M190.0 136.0 L190.0 160.0 L140.0 160.0 L140.0 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M140.0 290.0 L147.0 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><rect x=\"305.0\" y=\"194.0\" width=\"120.0\" height=\"32.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"365.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Prod</text><rect x=\"435.0\" y=\"194.0\" width=\"120.0\" height=\"32.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"495.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Staging</text><path d=\"M430.0 136.0 L430.0 165.0 L365.0 165.0 L365.0 191.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><path d=\"M430.0 136.0 L430.0 165.0 L495.0 165.0 L495.0 191.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><rect x=\"305.0\" y=\"280.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"365.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-prod</text><text x=\"365.0\" y=\"309.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">332178477898</text><rect x=\"435.0\" y=\"280.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"495.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-staging</text><text x=\"495.0\" y=\"309.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">073648902831</text><path d=\"M365.0 226.0 L365.0 250.0 L365.0 250.0 L365.0 277.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><path d=\"M495.0 226.0 L495.0 250.0 L495.0 250.0 L495.0 277.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><rect x=\"585.0\" y=\"190.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"645.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sandbox</text><text x=\"645.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">652028714336</text><path d=\"M645.0 136.0 L645.0 160.0 L645.0 160.0 L645.0 187.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><rect x=\"170.0\" y=\"346.0\" width=\"28.0\" height=\"18.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"206.0\" y=\"355.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">an account</text><rect x=\"330.0\" y=\"346.0\" width=\"28.0\" height=\"18.0\" rx=\"8\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"366.0\" y=\"355.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">an organisational unit, which holds no resources</text></svg>", "caption": "One root, one parent for everything, and the accounts at the leaves."}
```

## What the organisation says about itself

```
ana@laptop:~/aws$ aws organizations describe-organization
{
    "Organization": {
        "Id": "o-vpkre95at2",
        "Arn": "arn:aws:organizations::123456789012:organization/o-vpkre95at2",
        "FeatureSet": "ALL",
        "MasterAccountArn": "arn:aws:organizations::123456789012:account/o-vpkre95at2/123456789012",
        "MasterAccountId": "123456789012",
        "MasterAccountEmail": "master@example.com",
        "AvailablePolicyTypes": [
            {
                "Type": "SERVICE_CONTROL_POLICY",
                "Status": "ENABLED"
            }
        ]
    }
}
ana@laptop:~/aws$ aws organizations list-roots --query "Roots[0].PolicyTypes"
[]
```

`AvailablePolicyTypes` says service control policies are on; the root's own list says that no
policy type is enabled on it. **That disagreement is moto's.** AWS's API reference for
`CreateOrganization` says an organisation created with all features has service control policies
enabled in the root straight away. moto leaves the root's list empty until somebody runs
`enable-policy-type`, which lesson 4 does first.

The management account's address, `master@example.com`, is moto's invention as well. In AWS it is
the e-mail address the management account was opened with, its root user's address. Lesson 2
said why that should be a shared mailbox and not a person.
