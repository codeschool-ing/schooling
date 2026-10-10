---
title: The split, a write model and a read model
version: 1
---

**CQRS, command-query responsibility segregation, takes Meyer's rule from methods up to models:
commands go to one model, built to enforce the rules, and queries go to another, built to answer the
screens.** Greg Young gave it the name around 2010, from work he and Udi Dahan had been describing
for a few years. The write model is small and holds only what the rules check. The read model is
shaped like the screen that reads it, often one table per screen, and it is kept up to date from the
changes the write model makes.

The picture most people arrive with is three things at once: two databases, a message bus between
them, and event sourcing underneath. None of them is required. CQRS is the decision to have two
models; where they live and how the second is kept current are separate decisions, and the smallest
version of all of this runs in one Python process on one SQLite file.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l08-split\" aria-label=\"The CQRS split for the library. On the left, the desk. Along the top, the command side: the desk sends a command such as LendCopy to handle, which calls the write model, Lending, which holds only who has each copy and who is waiting, and enforces the rules. When a command succeeds, Lending publishes an event such as CopyLent. A projector on the right receives the event and updates the read model along the bottom, an availability table with one row per title, its author, the copies on the shelf and the number waiting. The query side: the desk asks the read model with a SELECT and gets rows back, without going near the write model.\"><defs><marker id=\"l08-split-dp-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-split-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l08-split-dp-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"360.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">command side: rules, one model</text><text x=\"360.0\" y=\"304.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">query side: shaped for screens, as many as needed</text><path d=\"M150.0 162.0 L580.0 162.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><rect x=\"20.0\" y=\"139.0\" width=\"110.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the desk</text><rect x=\"215.0\" y=\"63.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">handle()</text><rect x=\"400.0\" y=\"50.0\" width=\"150.0\" height=\"96.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"475.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Lending</text><path d=\"M400.0 72.5 L550.0 72.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"408.0\" y=\"83.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">holder</text><text x=\"408.0\" y=\"98.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">waiting</text><path d=\"M400.0 109.5 L550.0 109.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"408.0\" y=\"120.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lend()</text><text x=\"408.0\" y=\"135.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">give_back()</text><rect x=\"590.0\" y=\"145.0\" width=\"100.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">projector</text><rect x=\"380.0\" y=\"206.0\" width=\"190.0\" height=\"74.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"475.0\" y=\"217.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">«table»</text><text x=\"475.0\" y=\"231.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">availability</text><path d=\"M380.0 243.0 L570.0 243.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"388.0\" y=\"254.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">title, author</text><text x=\"388.0\" y=\"268.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">on_shelf, waiting</text><path d=\"M75.0 139.0 L75.0 80.0 L213.0 80.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-split-dp-ah-phosphor)\"></path><text x=\"140.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">LendCopy</text><path d=\"M325.0 80.0 L398.0 80.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-split-dp-ah-phosphor)\"></path><text x=\"362.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lend</text><path d=\"M550.0 80.0 L640.0 80.0 L640.0 143.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-split-dp-ah-amber)\"></path><text x=\"596.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">CopyLent</text><path d=\"M640.0 179.0 L640.0 240.0 L572.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-split-dp-ah-amber)\"></path><text x=\"668.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">UPDATE</text><path d=\"M75.0 185.0 L75.0 236.0 L378.0 236.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-split-dp-ah-phosphor)\"></path><text x=\"220.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">SELECT</text><path d=\"M378.0 260.0 L95.0 260.0 L95.0 187.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l08-split-dp-ah-paper-dim)\"></path><text x=\"220.0\" y=\"271.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rows</text></svg>", "caption": "Commands go through the rules and change the write model; an event carries the change to the read model, which answers every query."}
```

## The two shapes, side by side

The strained class of the first section already contained both models, mixed. Pulled apart, this is
what each side holds for the same moment, Caio holding the only *Vidas Secas* and Bia waiting:

```python
# what the rules need: the write model
holder = {"C1": ("bia", date(2026, 3, 16)), "C3": ("caio", date(2026, 3, 16))}
waiting = {"T2": ["bia"]}

# what the availability screen needs: one row of the read model
{"title": "Vidas Secas", "author": "Graciliano Ramos", "on_shelf": 0, "waiting": 1}
```

The write side keys everything by copy, because a loan changes one copy. It has no names and no
authors, because no rule reads them. The read side keys by title, carries the author, and stores
the counts already counted, because that is what the screen draws. **Neither shape is wrong; each is
wrong for the other's job**, and the strain of the first section was the cost of forcing one shape
to do both.

## What each side promises

| | the write side | the read side |
|---|---|---|
| receives | commands: `LendCopy`, `ReturnCopy`, `Reserve` | queries: "what is on the shelf?" |
| returns | nothing, or a refusal | rows, already shaped for one screen |
| holds | exactly what the rules check | whatever a screen shows, duplicated freely |
| how many | one per consistency boundary | as many as there are screens that need different shapes |
| if it is lost | the library's state is lost | rebuilt from the write side, at some cost |

The last row is the one that changes how you treat the read side. **A read model is derived data**:
everything in it can be recomputed from the write model or from the events it published. That is
why duplicating the author's name into every row is acceptable here when it would be a
normalisation error in the write model. If a read model turns out wrong, you fix the projector and
rebuild it, and lesson 9 shows that rebuild done by replaying every event.

## Three levels of separation

CQRS comes in degrees, and most systems that benefit from it need only the first or second.

1. **Separate code, one store.** Commands and queries go through different classes, and the read
   side runs its own queries against the same tables, shaped as views or as SQL written for the
   screen. Nothing is duplicated, and the gain is that neither side's code is bent by the other's.
2. **Separate tables, one transaction.** The read model has tables of its own, updated in the same
   transaction as the write. The screen reads a table built for it, and it is never stale.
3. **Separate stores, updated later.** The read model lives in another database, a search index or
   a cache, and a projector updates it after the write has committed. Reads scale on their own,
   and they can be stale, which is the subject of the section on projections.

The rest of the lesson builds level 2 in memory and then shows what changes at level 3.
`architecture` lesson 13 looks at the same split from the system's side, with the stores, the
messages between them and the operational cost; this lesson stays in the code.
