---
title: What a policy is for, and what it is not
version: 1
---

**Cross-site scripting**, XSS, is what happens when text somebody else chose ends up in a page as
code: a patient's name, a message, a search term written into the HTML without the escaping lesson 4
taught, and read by the browser as a script. Lesson 7 is about the three forms it takes. This lesson
is about what limits the damage on the day the escaping fails, because in a codebase with hundreds of
templates, one day it does.

That is the right way to think of **Content Security Policy**: a **second line**. The first line is
writing every value into the page safely, for its context, every time. A policy does not replace that
and cannot. What it does is make one missed escape far less likely to become a script running with
the patient's session.

### One header

A policy is a response header the server sends with each page, `Content-Security-Policy`, made of
**directives** separated by semicolons. Each directive names a kind of resource and the sources the
browser may load it from:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l08-policy\" aria-label=\"A Content Security Policy at work. The header script-src 'self' reaches the browser with the page. Three scripts try to run. A script loaded from the portal's own file, /static/portal.js, runs. A script written inside the page, whoever put it there, is refused. A script from another host is refused. Each refusal is reported to the portal's /csp-report.\"><defs><marker id=\"l08-policy-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-policy-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"680\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Content-Security-Policy: script-src 'self'</text><text x=\"360\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the browser checks each script against the policy</text><rect x=\"20\" y=\"84\" width=\"300\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"98.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">/static/portal.js</text><text x=\"170.0\" y=\"111.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the portal's own file</text><path d=\"M320 105 L460 105\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-phosphor)\"></path><rect x=\"460\" y=\"84\" width=\"240\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"580.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">runs</text><rect x=\"20\" y=\"138\" width=\"300\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"152.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;script&gt; inside the page</text><text x=\"170.0\" y=\"165.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">whoever put it there</text><path d=\"M320 159 L460 159\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-amber)\"></path><rect x=\"460\" y=\"138\" width=\"240\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"580.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">refused, reported</text><rect x=\"20\" y=\"192\" width=\"300\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"206.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a script from another host</text><text x=\"170.0\" y=\"219.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a host not in the policy</text><path d=\"M320 213 L460 213\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-amber)\"></path><rect x=\"460\" y=\"192\" width=\"240\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"580.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">refused, reported</text></svg>", "caption": "The policy cannot tell good inline script from bad, so it refuses all of it. That is the price, and the protection."}
```

The directives this lesson uses, and what each one says to the browser:

| directive | what it allows |
|---|---|
| `default-src 'self'` | anything not named below: only from the portal's own origin |
| `script-src 'self'` | scripts only from files on the portal's origin; **no inline script**, no `eval` |
| `object-src 'none'` | no plug-in content at all |
| `base-uri 'none'` | no `<base>` tag, which would change where every relative URL points |
| `frame-ancestors 'none'` | no other site may show the portal inside a frame |
| `form-action 'self'` | forms may post only to the portal |
| `report-uri /csp-report` | send a report of every violation to this address |

The line that does the work is `script-src 'self'`. An XSS flaw puts script **inside the page**, and
a page whose policy allows only scripts loaded from the portal's own files will not run it. That is
also why it costs something: **the portal's own inline scripts stop running too**, and so do inline
event handlers such as `onclick="…"`. Every one has to move into a file before the policy can be
enforced.

### What it does not do

- **It does not fix the flaw.** The text that should have been escaped is still in the page, and it
  can still damage the page's layout or mislead the reader. Fix the escape; the policy buys time.
- **It is only as strict as its weakest directive.** `'unsafe-inline'` in `script-src` turns the
  main protection off, and allowing a whole content delivery network allows every script anybody has
  published on it.
- **It is enforced by the browser.** A client that is not a browser ignores it. That is fine: the
  policy protects patients' browsers, which is where XSS runs.
