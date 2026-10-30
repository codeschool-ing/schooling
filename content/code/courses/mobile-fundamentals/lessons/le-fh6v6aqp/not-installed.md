---
title: When the app is not installed, and the link has to work anyway
version: 1
---

**A link is tapped by somebody whose phone may not have the app, and a good link works either way.**
That is the strongest argument for a verified link over a custom scheme.
`https://planner.example.com/course/sql` is an ordinary web address. With the planner installed and
verified, it opens the app on that course; without it, the browser opens the same address, and the
website answers with a page about that course. `planner://course/sql` has no web page behind it. On a phone without the planner, it has
nothing to open.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l11-decide\" aria-label=\"What happens when a link is tapped, as a decision path. First: is the link https? If not, it uses a custom scheme: if an installed app claims the scheme, that app opens, or a dialog if several do; if none does, nothing opens. If the link is https: if an installed app is verified for the domain, that app opens on the screen; if not, the browser opens the address and the website answers.\"><defs><marker id=\"l11-decide-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l11-decide-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"285\" y=\"12\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a link is tapped</text><rect x=\"285\" y=\"70\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"360.0\" y=\"85.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">is it an https</text><text x=\"360.0\" y=\"98.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">address?</text><path d=\"M360 44 L360 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-decide-ah-paper-dim)\"></path><rect x=\"70\" y=\"150\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"155.0\" y=\"165.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">does an installed app</text><text x=\"155.0\" y=\"178.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">claim the scheme?</text><path d=\"M285 92 L155 92 L155 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-decide-ah-paper-dim)\"></path><text x=\"220\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no · custom scheme</text><rect x=\"10\" y=\"236\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"251.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">that app opens, or a</text><text x=\"85.0\" y=\"264.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dialog if several do</text><rect x=\"180\" y=\"236\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"235.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nothing opens</text><path d=\"M115 194 L85 236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-decide-ah-paper-dim)\"></path><path d=\"M195 194 L235 236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-decide-ah-paper-dim)\"></path><text x=\"84\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">yes</text><text x=\"232\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no</text><rect x=\"470\" y=\"150\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"560.0\" y=\"165.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">is an installed app</text><text x=\"560.0\" y=\"178.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">verified for the domain?</text><path d=\"M435 92 L560 92 L560 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-decide-ah-paper-dim)\"></path><text x=\"498\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">yes</text><rect x=\"400\" y=\"236\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"475.0\" y=\"251.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the app opens, on</text><text x=\"475.0\" y=\"264.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the screen it names</text><rect x=\"560\" y=\"236\" width=\"156\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"638.0\" y=\"251.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the browser opens the</text><text x=\"638.0\" y=\"264.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">page, and the site answers</text><path d=\"M530 194 L475 236\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-decide-ah-phosphor)\"></path><path d=\"M600 194 L638 236\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-decide-ah-phosphor)\"></path><text x=\"486\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">yes</text><text x=\"636\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no</text></svg>", "caption": "The system follows this path before any of the app's code runs. Only a verified https link has an answer in every branch."}
```

**The path through the figure is decided by the system, in that order, before the planner runs.** Is
the link `https` on a domain an installed app has verified? Then that app opens, with no dialog.
Otherwise the browser opens the address. Apple's documentation on universal links says the same of
iOS: when the person has not installed the app, the system opens the URL in their default browser and
the website handles it. Android's documentation on App Links says users without the app "go to your
website instead", and names that as a reason to prefer them.

## The web page is part of the link

**So the website has to answer every path the app answers.** The `site.ts` of the previous section
serves a page for every `/course/...` address, and that is not decoration: it is what a person without
the app sees. A link that opens the app on a course and a 404 in the browser is a link that works for
half the people who receive it, and the half it fails is the half you were trying to reach. In the
transcript of that section, `/course/sql` came back with a `200` and an HTML page, while the same path
inside the app opened `courses > course:sql`.

**One more case breaks the tidy picture: the person is already in the browser, on your site.** Apple's
documentation says that a universal link tapped in Safari to a page on the same domain stays in
Safari, on the reasoning that the person meant to keep browsing; a link to that domain from a different
one opens the app. So the website should offer its own way into the app, a banner or a button, rather
than relying on its links to switch.

## Deferred deep links: surviving the install

**The link that matters most is the one tapped by somebody who has never installed the app.** They tap
a friend's link to a course, the browser opens the course's web page, and the page suggests the app.
They install it from the store, open it, and land on the planner's first screen, with the course they
came for nowhere in sight. The link was lost at the install, because a store install is not a link
being opened.

*Deferred* deep linking is the name for carrying the link across that gap: the app, on its first run,
finds out which link brought the person to the store, and opens on that screen. The platforms do not
make it simple. Google Play passes a *referrer* string from the store link to the newly installed app,
and Android's Play Install Referrer library reads it. On iOS there is no equivalent handed to every
app, and services that offer deferred links match the install to the earlier tap by other means. Each
of those means is a decision about the person's data, so lesson 13, on what the store makes you
declare and what is not worth collecting, is the place to weigh one.

**For the planner the decision is easy, and it is the honest one for most small apps.** A person who
installs the planner because of a link to one course loses one tap: they open Courses and choose it.
The parser and the stacks are ready for the day a referrer arrives, because a referrer is one more
string for `parse` to read or refuse, exactly like a link.

| situation | `planner://course/sql` | `https://planner.example.com/course/sql` |
|---|---|---|
| planner installed, link verified | opens the planner | opens the planner, no dialog |
| planner installed, file missing or wrong | opens the planner, or a dialog | opens the browser |
| planner not installed | nothing to open | the browser opens the course's page |
| tapped inside Safari, on the same site | not applicable | stays in Safari |
