---
title: The first message to management
version: 1
---

The first message to management goes out within the hour of declaring, before most of the answers exist. It has
one job: to let the managing partner act now, on what is known now. Military writing calls the shape **BLUF**,
*bottom line up front*, and it works because a busy reader may stop after the first sentence:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A message to management in five parts, top to bottom: the bottom line first, in one sentence; what is known, as facts with their times; what is not known yet; what the team is doing and what it needs decided; and when the next update comes.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"37\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">the bottom line</text><text x=\"400\" y=\"37\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one sentence, first</text><rect x=\"10\" y=\"62\" width=\"700\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">what we know</text><text x=\"400\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">facts, with times</text><rect x=\"10\" y=\"114\" width=\"700\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">what we do not know yet</text><text x=\"400\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">said plainly</text><rect x=\"10\" y=\"166\" width=\"700\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">what we are doing, what we need</text><text x=\"400\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">decisions asked for by name</text><rect x=\"10\" y=\"218\" width=\"700\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">next update</text><text x=\"400\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a time, not 'soon'</text></svg>", "caption": "The same five parts in every update, so the reader always knows where to look."}
```

For Thursday, at 09:30, it could read like this:

> **Subject: INC-2026-014, incident declared, 09:12**
>
> Somebody outside the company logged in to our remote access server last night with bruno's account, reached the
> file server, and about 612 MB left the company to an address we do not know, starting at 02:41.
>
> What we know: the login came from 203.0.113.66 at 02:33, after 57 guessed passwords against 19 accounts. The
> same account logged in again at 03:05 with a key that was added during the night. Bruno was at home and logged
> in normally at 08:35, so it was not him.
>
> What we do not know yet: which files the 612 MB were, and whether any of it is clients' personal data.
>
> What we are doing: containing it, from 09:30: cutting the file server's internet access except the backup, and
> locking bruno's account. **We need your decision on locking the account**, because it stops bruno working today.
> We have told the external lawyer and the DPO.
>
> Next update: 12:00, or earlier if anything changes.

Notice what is not in it. No jargon a non-specialist would trip on; "remote access server", not `gw`. No guess
presented as a fact: "about 612 MB" is measured, "which files" is said to be unknown. No blame: nothing about how
strong bruno's password was. And no reassurance that is not yet true: "there is no evidence of client data loss"
would be correct this morning and is the sentence most often regretted in incident reports, because absence of
evidence at 09:30 is not evidence of absence.
