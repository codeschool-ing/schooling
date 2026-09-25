---
title: A method, whichever system it is
version: 1
---

The tools change between systems; the order of the questions does not.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 160\" role=\"img\" aria-label=\"A diagnosis as six steps in a loop. What exactly happens? Since when, and what changed? What do the logs say? Test one explanation. Fix the smallest thing. Confirm, and write it down. If the test fails, go back to the logs with the next explanation.\"><defs><marker id=\"lp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"210\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">what exactly happens?</text><rect x=\"250\" y=\"20\" width=\"210\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"355\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">since when, and what changed?</text><rect x=\"480\" y=\"20\" width=\"210\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"585\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">what do the logs say?</text><rect x=\"480\" y=\"84\" width=\"210\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"585\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">test one explanation</text><rect x=\"250\" y=\"84\" width=\"210\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"355\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fix the smallest thing</text><rect x=\"20\" y=\"84\" width=\"210\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">confirm, and write it down</text><path d=\"M232 38 L248 38\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><path d=\"M462 38 L478 38\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><path d=\"M585 58 L585 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><path d=\"M478 102 L462 102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><path d=\"M248 102 L232 102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><text x=\"700\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">wrong? back to the logs</text></svg>", "caption": "The second question solves more problems than any tool: most failures start the day something changed, an update, a new program, a moved cable."}
```

1. **What exactly happens?** The error text, word for word, or a screenshot, lesson 7's habit. "It does
   not work" is not a symptom.
2. **Since when, and what changed?** An update, a new program, a moved cable, a password change. Lesson
   11's `history.log`, lesson 16's update history and Reliability Monitor answer it with dates.
3. **What do the logs say?** Around the time it started, filtered to the program involved.
4. **Test one explanation.** Change one thing, and see whether the symptom changes. Two changes at once
   leave you not knowing which one worked.
5. **Fix the smallest thing** that removes the cause, and prefer the fix that can be undone, lesson 15's
   rule.
6. **Confirm, and write it down.** Check the output, as section 03 did with the report file, and record
   what happened, what fixed it, and how you knew. The next person with this problem may be you, in a
   year.

This course ends here, with the three systems installed, understood and kept running. The *tech-support*
course takes the method further, with the person at the other end of the ticket; *virtualization*
runs all three systems side by side on one machine.
