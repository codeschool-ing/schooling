---
title: How a policy is inherited, merged or replaced
version: 1
---

**A policy written on a node applies to everything below it, and a node lower down may change that in
one of three ways.** Which way it chooses is written in its own policy, and the answer at any project
is called its **effective policy**: the result of walking from the organisation down to that project and
applying each node's choice in turn.

| a node's policy says | effect on what it inherits |
|---|---|
| nothing, no policy here | the parent's effective policy applies unchanged |
| `inherit_from_parent = true` with values of its own | **merge**: for a list constraint, the parent's values and this node's are combined |
| a policy of its own, not inheriting, which is the default | **replace**: this node's values are the whole answer, for it and everything below |
| `reset = true` | go back to the constraint's **default**, Google's own, as if no policy existed above |

## Merging lists

Merging is where the reasoning gets careful. Take `gcp.resourceLocations`, and the planner estate:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l04-merge\" aria-label=\"The effective value of gcp.resourceLocations in three places. The organisation allows in:southamerica-locations and in:us-locations. The folder non-production writes nothing, so its projects inherit both. The folder production writes its own policy without inheriting, allowing only in:southamerica-east1-locations, so its projects may use São Paulo alone. A dashed box shows the mistake: had production inherited, its value would have been added to the organisation's, and production could use the United States too.\"><rect x=\"220.0\" y=\"16.0\" width=\"280.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">organisation</text><text x=\"360.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">in:southamerica-locations</text><text x=\"360.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">in:us-locations</text><path d=\"M300.0 80.0 L140.0 116.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M420.0 80.0 L560.0 116.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"30.0\" y=\"116.0\" width=\"220.0\" height=\"96.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"140.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">non-production</text><text x=\"140.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no policy of its own</text><text x=\"140.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">effective:</text><text x=\"140.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">southamerica + us</text><rect x=\"450.0\" y=\"116.0\" width=\"240.0\" height=\"96.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"570.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">production</text><text x=\"570.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">inherit_from_parent = false</text><text x=\"570.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">in:southamerica-east1-locations</text><text x=\"570.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">effective: São Paulo only</text><rect x=\"450.0\" y=\"236.0\" width=\"240.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"570.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">had it inherited (true):</text><text x=\"570.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">its value is added to the parent's</text><text x=\"570.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">effective: southamerica + us</text><text x=\"250.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">for an allow list, inheriting widens</text><text x=\"250.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">for a deny list, it narrows</text></svg>", "caption": "Production replaces the organisation's list. Merging would have widened it."}
```

The organisation allows `in:southamerica-locations` and `in:us-locations`: the company runs in both.
The folder `production` writes its own policy **without inheriting**, allowing only
`southamerica-east1`, because the contracts with customers say their data stays in Brazil. So every
project in production may create resources in São Paulo and nowhere else, while the projects in
`non-production`, which write nothing, inherit both continents.

Had production written the same value **with** `inherit_from_parent = true`, the answer would have
been the opposite of the intention: its value would be added to the organisation's, and production
could create resources in the United States. **For an allow list, inheriting widens.** For a deny list
it narrows, because a merged deny keeps every value any level denied. That asymmetry is the whole of
what goes wrong with list policies, and it is why a folder that means to restrict usually replaces
rather than merges.

## Booleans, and the nearest answer

A boolean constraint has nothing to merge. The **nearest policy wins**: a project that sets
`compute.requireOsLogin` to off overrides an organisation that set it on. That is why the role to set
policies lives on the organisation and only there. If anybody who owned a project could write the
project's own policy, every guardrail would be one override away from gone.

## Trying a policy before enforcing it

A managed or custom constraint can carry a **dry run** policy beside the enforced one. A dry run
refuses nothing; it writes to the audit log every request it **would** have refused. A week of that log
is the honest answer to "what breaks if we turn this on?", and it is the order Google recommends:
dry run, read the violations, fix or exempt what deserves it, then enforce.

None of this ran in the lab: inheritance is evaluated by Google's Organization Policy service, which has
no emulator. The next section writes the figure's two policies down and has Terraform check them.
