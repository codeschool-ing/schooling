---
title: Quotas, and the thirty days after deletion
version: 1
---

Nothing in this section was run. Quotas are counted by Google and a project's life cycle is the
Resource Manager's, and the lab answers neither; what follows is from Google's documentation, with
the commands named so that you recognise them against a real account.

## Quotas

**A quota is a ceiling Google sets per project**, and it exists to protect both sides: Google from a
runaway customer, and the customer from a runaway bill. There are two kinds:

- **allocation quotas** count what exists: how many virtual CPUs in `southamerica-east1`, how many
  external addresses, how many networks. Creating one more than the quota allows is refused.
- **rate quotas** count requests over time: how many calls to an API per minute. Going over is refused
  with `429` and `RESOURCE_EXHAUSTED` until the minute turns.

Quotas are per project and, for most resources, per region, so a project may have room for 24 CPUs in
São Paulo and 8 in Santiago. A new project's quotas are deliberately small, and raising one is a
request, made in the console's *Quotas* page or with `gcloud beta quotas preferences create`; most
are granted in minutes, and large ones are reviewed. **Asking for a raise in the week of a launch is
the classic mistake**: the request is cheap and the review is not instant.

A quota is also the one ceiling a customer can **lower**. An API's rate quota can be set below the
default, which turns it into a cap: lesson 12 uses that to put a limit on what an API can cost.

## The life cycle

A project is created **`ACTIVE`**. Deleting it does not delete it: the project moves to
**`DELETE_REQUESTED`**, everything inside it stops serving, and billing for its resources stops. For
**thirty days** it can be restored with `gcloud projects undelete planner-reports`, by somebody who
holds the role to do so. After the thirty days Google deletes it for good, everything inside it with
it, and the id stays taken forever.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l03-life-cycle\" aria-label=\"The life cycle of a project, left to right. Created, the project is ACTIVE. A delete request moves it to DELETE_REQUESTED: its resources stop serving and stop being billed. For thirty days an undelete moves it back to ACTIVE, drawn as an arrow returning. After thirty days Google deletes it for good, and the id stays taken forever. Above the first arrow, two guards that refuse the delete request: a lien on the project, and deletion_policy PREVENT in Terraform.\"><defs><marker id=\"l03-life-cycle-af-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l03-life-cycle-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l03-life-cycle-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"110.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"110.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ACTIVE</text><text x=\"110.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">serving and billed</text><rect x=\"280.0\" y=\"110.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">DELETE_REQUESTED</text><text x=\"360.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">stopped, not billed</text><rect x=\"540.0\" y=\"110.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\"></rect><text x=\"620.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">deleted</text><text x=\"620.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the id stays taken</text><path d=\"M192.0 128.0 L276.0 128.0\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l03-life-cycle-af-ah-paper)\"></path><text x=\"234.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">delete</text><path d=\"M276.0 156.0 L192.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l03-life-cycle-af-ah-phosphor)\"></path><text x=\"234.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">undelete</text><path d=\"M442.0 140.0 L536.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l03-life-cycle-af-ah-paper-dim)\"></path><text x=\"489.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">after 30 days</text><rect x=\"120.0\" y=\"22.0\" width=\"230.0\" height=\"56.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"235.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">refuse the delete:</text><text x=\"235.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a lien on the project</text><text x=\"235.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">deletion_policy = &quot;PREVENT&quot;</text><path d=\"M235.0 78.0 L235.0 118.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"360.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">for thirty days the delete can be undone; after that, nothing can</text></svg>", "caption": "Deleting a project starts a thirty-day clock, and two guards can stop the clock starting."}
```

Two guards stop a deletion that should not happen:

- **A lien** is a mark on the project that refuses deletion while it is there. Google places some
  itself: a project that hosts a shared network, lesson 18, carries one, because deleting it would cut
  off every project that uses the network. People can place their own on a project that must never be
  deleted by accident.
- **Terraform's `deletion_policy`.** Since version 6 of the provider, a `google_project` carries
  `deletion_policy = "PREVENT"` unless the file says otherwise, which is why it appeared in lesson 2's
  plan without being written. A `terraform destroy` that reaches such a project fails before sending
  anything. Setting it to `"DELETE"` is a decision somebody makes in a diff that somebody else reads.

**Deleting a project is the surest way to stop paying for what is in it**, because nothing inside a
project survives it. It is also the surest way to lose what is in it, which is why the thirty days and
the two guards exist.
