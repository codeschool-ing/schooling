---
title: What the first paint waits for
version: 1
---

**A browser does not paint as soon as the HTML arrives.** It reads the HTML, finds what the page
needs, and paints once it has the things it must not paint without. The chain from the first byte to
the first paint is called the **critical rendering path**, and everything on it is a request the
person waits through before they see anything at all.

| on the path | why it holds the paint |
|---|---|
| **the HTML** | nothing exists before it |
| **stylesheets in the head** | a page painted without its CSS would be drawn twice, the second time differently, so the browser waits for every stylesheet first |
| **scripts in the head without `defer`, `async` or `type="module"`** | the browser stops reading the HTML until such a script has been downloaded and run, because it may write into the page |
| **a font, for the text that uses it** | depending on `font-display`, the text is not drawn until the font arrives, or is drawn twice |

**Off the path**: images, scripts with `defer`, `async` or `type="module"`, which is what Vite writes,
and anything a script fetches later. They can still decide the LCP, as the planner's notice did in
lesson 5, but the first paint does not wait for them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Requests along time, as a page loads. The HTML comes first. The stylesheet is requested once the HTML names it, and the first paint waits for it. The font is requested only after the stylesheet has arrived, and the text that uses it waits for the font. The module script and the picture are requested alongside the stylesheet, and the first paint does not wait for either.\"><text x=\"158\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the HTML</text><rect x=\"170\" y=\"30\" width=\"150\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"158\" y=\"72\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">stylesheet</text><rect x=\"320\" y=\"62\" width=\"150\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"158\" y=\"104\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">font</text><rect x=\"470\" y=\"94\" width=\"150\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"158\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">module script</text><rect x=\"320\" y=\"126\" width=\"194.99999999999997\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"158\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">picture</text><rect x=\"320\" y=\"158\" width=\"240.0\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><line x1=\"470\" y1=\"22\" x2=\"470\" y2=\"196\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></line><text x=\"470\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">first paint</text><line x1=\"620\" y1=\"22\" x2=\"620\" y2=\"196\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"620\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">text in its font</text><rect x=\"170\" y=\"228\" width=\"12\" height=\"12\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"188\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">on the critical path</text><rect x=\"370\" y=\"228\" width=\"12\" height=\"12\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"388\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">off it</text></svg>", "caption": "Each step on the path is a round trip the person waits through with nothing to see."}
```

## What this lesson does about it

The planner is about to get the two things most pages are made of: a picture and a typeface. Each
starts the way a real project starts, with the file a designer hands over, and each is measured, made
smaller, and measured again:

- **the picture** is the largest thing on a page, so it is usually the LCP. Its size, its format, its
  dimensions and its priority are four separate fixes, and Lighthouse finds all four.
- **the font** is on the critical path for text. What happens while it loads is a choice, and both
  choices have a cost a person can see.
- **the stylesheet** is on the path for everything. The last fix takes it off.
