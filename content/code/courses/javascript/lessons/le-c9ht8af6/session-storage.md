---
title: sessionStorage: one tab, one session
version: 1
---

**`sessionStorage` has exactly the same interface, and a shorter, narrower life**: it belongs to one
tab, survives a reload of that tab, and disappears when the tab is closed.

```html
<!doctype html>
<script>
  const before = sessionStorage.getItem("draft");
  console.log("draft found:", before);
  sessionStorage.setItem("draft", "half a review of Iracema");
  localStorage.setItem("seen", "yes");
</script>
```

```
ana@dev:~/js$ page draft.html --fresh --do reload --do newtab
draft found: null
-- reload
draft found: half a review of Iracema
-- newtab
draft found: null
```

The first load found no draft and saved one. **The reload found it**: same tab, same session. **The
new tab found nothing**, although it was the same page on the same site, because a new tab starts a
new session. `localStorage`, written in the same script, would have been visible in both.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"One origin, http://127.0.0.1:8080, with two tabs open. Both tabs share the origin&#x27;s single localStorage. Each tab has its own sessionStorage, which the other cannot see and which disappears when the tab is closed. Another origin has storage of its own that this one cannot reach.\"><rect x=\"16\" y=\"14\" width=\"500\" height=\"202\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">http://127.0.0.1:8080</text><rect x=\"40\" y=\"50\" width=\"210\" height=\"90\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tab 1</text><rect x=\"60\" y=\"82\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">sessionStorage</text><text x=\"145.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">this tab only</text><rect x=\"270\" y=\"50\" width=\"210\" height=\"90\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tab 2</text><rect x=\"290\" y=\"82\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">sessionStorage</text><text x=\"375.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">this tab only</text><rect x=\"40\" y=\"156\" width=\"440\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">localStorage</text><text x=\"260.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shared by every tab of the origin, kept between visits</text><rect x=\"540\" y=\"14\" width=\"164\" height=\"202\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"622\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">another origin</text><text x=\"622\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its own storage,</text><text x=\"622\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">out of reach</text></svg>", "caption": "localStorage belongs to the origin; sessionStorage belongs to one tab of it."}
```

## Which one

- **`sessionStorage`** for the state of one task in one tab: the step a multi-page form is on, a
  filter the user set on this tab only. Two tabs doing two different things then do not overwrite each
  other;
- **`localStorage`** for preferences that should follow the user to every tab and every visit.

Both belong to an **origin**: the scheme, the host and the port together. A page on
`http://127.0.0.1:8080` cannot read what a page on another origin stored, and a site cannot read
another site's storage at all. That boundary is the browser's, and nothing a page does can widen it.
