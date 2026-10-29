---
title: Choosing, page by page
version: 1
---

**There is no best mode, only a best mode for a page**, decided by two questions: is the page the same
for every reader, and how soon must a change reach it?

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three timelines of one visit, left to right. Client-side rendering: the HTML arrives empty, the script is downloaded and runs, the data is fetched, and only then is the page drawn and usable. Server-side rendering: the server renders the page for the request, the HTML arrives drawn and is readable at once, then the script downloads and hydrates it, and only after that does it answer a click. Static generation: the page was rendered once at build time; the request is answered with the file, readable at once, and hydrated when the script has run.\"><text x=\"40\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">CSR</text><rect x=\"80\" y=\"40\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">empty HTML</text><rect x=\"194\" y=\"40\" width=\"90\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"239.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">script</text><rect x=\"288\" y=\"40\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"328.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">data</text><rect x=\"372\" y=\"40\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"447.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">drawn, usable</text><text x=\"40\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">SSR</text><rect x=\"80\" y=\"110\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">server renders</text><rect x=\"204\" y=\"110\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"279.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">drawn, readable</text><rect x=\"358\" y=\"110\" width=\"160\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"438.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">hydrated, usable</text><text x=\"40\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">SSG</text><rect x=\"80\" y=\"180\" width=\"70\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">file</text><rect x=\"154\" y=\"180\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"229.0\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">drawn, readable</text><rect x=\"308\" y=\"180\" width=\"160\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"388.0\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">hydrated, usable</text><line x1=\"80\" y1=\"228\" x2=\"690\" y2=\"228\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"690.0,228.0 682.6,231.1 682.6,224.9\" fill=\"var(--wire)\"></polygon><text x=\"385\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">time since the click on the link</text></svg>", "caption": "The server's modes put words on the screen sooner; the page answers a click only after hydration in all of them."}
```

| mode | the HTML is made | first words on screen | a change reaches the page | needs a server |
| --- | --- | --- | --- | --- |
| CSR, the Vite planner | in the browser, every visit | after the script and the data | at once | only for the data |
| SSR, Nuxt's default | on the server, every request | with the HTML | at once | yes |
| SSG, `nuxt generate` | once, at build time | with the HTML | at the next deploy | no |
| SWR or ISR | on the server, then kept | with the HTML | within the window, `60` s here | yes, or the host's |
| client-only | in the browser, after hydration | after the script | at once | no |

Every mode except CSR sends HTML that is already drawn, and every one of those hydrates, so the
mismatches of this lesson apply to all of them, SSG included. What the browser knows and the server
does not has to be drawn after hydration, whatever the mode.

## The planner's choices

- **The week, `/`: SSR**, with the reader's day client-only. It changes with every tick, and it is the
  page a student opens every day, so it is worth arriving drawn.
- **A course, `/courses/:id`: SSR.** The `swr` of the route rules section is the wrong trade for a page
  its reader edits; the rule comes out of `nuxt.config.ts` the day this planner is deployed.
- **`/about`: prerendered.** The same for everybody until the next deploy.
- **The API: no cache.** A list of sessions somebody has just changed is not a thing to keep.

A course catalogue, the kind of site where these modes were invented, decides the other way round. Its
pages are the same for every reader, they are read thousands of times between two edits, and they must
be found by search engines. So they are generated or kept with `swr`, and only the parts that belong to
one reader, a basket or a name, are drawn in the browser.

`front-performance` lesson 2 measures these modes, in Nuxt and in three other frameworks, and is the
place to take the numbers further. The next lesson goes back to the line both SSR and SSG depend on,
`useFetch`, and what happens to data that is fetched on one side and used on the other.
