---
title: The five whys
version: 1
---

**The five whys is the simplest root cause method there is: state the problem, ask why it happened, then ask why
about the answer, and keep going until the answer is something the team can change.** It comes from Toyota, where
Taiichi Ohno taught it as part of the same production system that gave Kanban its cards; five is a rule of thumb
for how deep the first useful cause usually sits, not a quota.

## The Sunday 9:30 session

Cine Aurora ran it in the retrospective after lesson 4's defect, starting from the problem statement in the
previous section.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 330\" role=\"img\" data-fig=\"l18-whys\" aria-label=\"The five whys as a chain going down. The problem: the 9:30 session was charged the evening price. Why one: 9:30 was compared with 17:00 as text. Why two: Rafael assumed a two-digit hour. Why three: every example had two digits. Why four: nobody asked Célia how she types times. Why five: planning never asks where an input comes from. The action: planning asks where each input comes from.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"150.0\" y=\"8.0\" width=\"320.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"23.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">9:30 session charged the evening price</text><text x=\"140.0\" y=\"66.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">why 1</text><rect x=\"150.0\" y=\"52.0\" width=\"320.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;9:30&quot; compared with &quot;17:00&quot; as text</text><path d=\"M310.0 39.0 L310.0 51.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"140.0\" y=\"112.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">why 2</text><rect x=\"150.0\" y=\"98.0\" width=\"320.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">assumed a two-digit hour</text><path d=\"M310.0 85.0 L310.0 97.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"140.0\" y=\"158.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">why 3</text><rect x=\"150.0\" y=\"144.0\" width=\"320.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">every example had two digits</text><path d=\"M310.0 131.0 L310.0 143.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"140.0\" y=\"204.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">why 4</text><rect x=\"150.0\" y=\"190.0\" width=\"320.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nobody asked Célia how she types times</text><path d=\"M310.0 177.0 L310.0 189.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"140.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">why 5</text><rect x=\"150.0\" y=\"236.0\" width=\"320.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">planning never asks where an input comes from</text><path d=\"M310.0 223.0 L310.0 235.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"110.0\" y=\"292.0\" width=\"400.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"307.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">action: planning asks where each input comes from</text><path d=\"M310.0 277.0 L310.0 291.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path></svg>", "caption": "Each answer becomes the next question. The chain stops at a cause the team can change, and that would prevent more than this one defect."}
```

1. **Why was the order charged the evening price?** Because `price()` compared the session time `9:30` with
   `17:00` as text, and as text `9:30` comes after `17:00`.
2. **Why did it compare the times as text?** Because Rafael wrote it assuming every time had two digits for the
   hour, and with two digits a text comparison happens to work.
3. **Why did he assume two digits?** Because every example he had seen did: the sessions were at 15:00, 17:00 and
   20:00, and nobody had mentioned how times were typed.
4. **Why had nobody mentioned it?** Because Célia types the schedule, and nobody who builds the system had ever
   asked her how.
5. **Why had nobody asked her?** Because planning never asked where each input comes from. The team discussed what
   the program does with a time, never who writes the time and how.

The fifth answer is a gap in the process, and a gap the team can close. Lesson 12 recorded the action that came out
of this retrospective: **for every new input, planning asks where it comes from**, and the person who produces it is
asked how. It is a sentence on a checklist. It would have prevented the defect, and it will prevent defects in inputs
nobody has thought of yet, which no fix to `price()` could do.

## When to stop

Stop when the answer is a cause the team can act on, and acting on it would prevent this defect *and others like it*.
The first answer, the text comparison, is a cause, and fixing it fixes this defect. It does not prevent the next
assumption about the next input, and that is why the analysis did not stop there.

Two signs that it went too far: the answer is outside the team's reach (*because the cinema decided to open on
Sunday mornings*), or the answer is a person (*because Rafael is careless*). The first can't be acted on; the
second is the blame the last section warned about, and it is almost always a sign that one more *why* was skipped:
*why was it reasonable for a careful person to do that?*

## Where the method is weak

The five whys is popular because it is quick, and it is weak in the ways quick things are.

- **It follows one chain.** Most defects have several causes at once, and the chain follows whichever answer was
  given first. Ask the second *why* differently, *why did the review not catch it?*, and a different chain grows
  from the same defect: Tomás reviewed alone, a day later, without the examples.
- **It only finds what the room knows.** If nobody in the retrospective knew that Célia types the schedule, the
  chain would have stopped at *Rafael assumed two digits*, and the action would have been *be more careful*.
- **Different people get different answers.** Two groups running it on the same defect often end at different
  root causes, both plausible.

None of this makes it useless. It makes it a good first tool, and a reason to reach for the next one, the Ishikawa
diagram, when a defect looks like it has more than one cause.
