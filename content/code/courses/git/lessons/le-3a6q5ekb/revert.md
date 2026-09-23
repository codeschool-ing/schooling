---
title: Revert: undo a commit by adding one
version: 1
---

The flour arrived, and rye bread should go back on the menu. The commit that took it off is in the
history, and by now it is also in Bruno's copy, and in the shared one. **`git revert` makes a new
commit that does the opposite of an old one:**

```
ana@vm:~/site$ git revert --no-edit HEAD~1
[main c28977c] Revert "Take rye bread off until the flour arrives"
 Date: Mon Sep 21 10:30:00 2026 -0300
 1 file changed, 1 insertion(+)
ana@vm:~/site$ git log --oneline -3
c28977c Revert "Take rye bread off until the flour arrives"
6555c9b Link the menu from the home page
eadf998 Take rye bread off until the flour arrives
ana@vm:~/site$ cat menu.html
<h1>Menu</h1>
<p>French bread, 0.90</p>
<p>Rye bread, 1.35</p>
<p>Cheese roll, 2.50</p>
```

The log shows what happened and what did not. The old commit, `eadf998`, is still there. A new one,
`c28977c`, sits on top, with a message Git wrote: `Revert "Take rye bread off until the flour
arrives"`. Its change is the old change turned inside out, one line added back, and the menu has rye
bread again. `--no-edit` accepted that message as it is; without it, Git opens the editor so you can
add *why* you are reverting, which is usually worth doing.

## Why add instead of remove

It seems roundabout: the commit was a mistake, so why not delete it? Because **other people's
copies already contain it.** Lesson 1 showed that every commit's id covers its parent's; remove a
commit from the middle of a history and every commit after it gets a new id. Your copy and Bruno's
would then disagree about what the history *is*, and the next time you shared work, Git would see
two unrelated sets of commits with the same messages. Lesson 7 shows what that looks like from the
other side.

A revert has none of that. It is an ordinary new commit on top, and everybody who fetches it gets a
history that still agrees with theirs. **Revert is the only undo that is safe on a commit that has
been shared**, and on most teams the main branch is shared by definition.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two versions of the same history of three commits, A, B and C. In the first, revert adds a fourth commit that undoes C, and main moves forward to it; C stays in the history. In the second, reset moves main back to B, and C is left on no branch, drawn faintly, remembered only by the reflog.\"><defs><marker id=\"ud-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">revert — a new commit undoes C</text><path d=\"M169 80 L93 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ud-ah)\"></path><path d=\"M269 80 L193 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ud-ah)\"></path><path d=\"M369 80 L293 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ud-ah)\"></path><circle cx=\"80\" cy=\"80\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"80\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">A</text><circle cx=\"180\" cy=\"80\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"180\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">B</text><circle cx=\"280\" cy=\"80\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"280\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">C</text><circle cx=\"380\" cy=\"80\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"380\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">revert C</text><rect x=\"357.0\" y=\"40\" width=\"46\" height=\"20\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"380\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main</text><path d=\"M380 60 L380 68\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"440\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the history grows; C stays, and so does its undoing</text><path d=\"M20 140 L700 140\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20\" y=\"170\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">reset — the branch moves back past C</text><path d=\"M169 230 L93 230\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ud-ah)\"></path><circle cx=\"80\" cy=\"230\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"80\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">A</text><circle cx=\"180\" cy=\"230\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"180\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">B</text><rect x=\"157.0\" y=\"190\" width=\"46\" height=\"20\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main</text><path d=\"M180 210 L180 218\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"280\" cy=\"230\" r=\"10\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><circle cx=\"280\" cy=\"230\" r=\"10\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></circle><text x=\"280\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">C</text><path d=\"M269 230 L193 230\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ud-ah)\" stroke-dasharray=\"3 3\"></path><text x=\"320\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">C is on no branch; only the reflog still names it</text></svg>", "caption": "Revert adds to the history, so it is safe on commits other people have. Reset removes from the branch, so it is only safe on commits nobody else has."}
```

## What revert does not do

It does not hide anything. Both commits stay in the log forever, which is a feature: six months from
now somebody reading `git log -- menu.html` sees rye removed, and rye restored, with the reason for
each.

It also works on any commit, not only the last one. Here it reverted `HEAD~1` and left the link on
the home page, which came after it, alone. If a later commit had changed the same lines, Git could
not work out the opposite on its own and would stop and ask you, which is a conflict; lesson 6
teaches what to do with one.
