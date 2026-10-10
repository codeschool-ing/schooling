---
title: Six questions, answered in reverse
version: 1
---

Typed key by key, `papaya` is six questions: `p`, `pa`, `pap`, `papa`, `papay` and `papaya`. They
leave a few milliseconds apart, because a robot types fast, and the server holds each one back for
a time that shrinks as the question grows. **So the answers come back in the opposite order to the
questions**, and the page draws each one as it lands. The last to land is the answer to `p`.

Reading that off the code is one thing; watching it is what makes it believable, and this program
prints it as it happens. It types a word into the search box and logs three kinds of line: a
question leaving, an answer arriving, and what the list holds each time it changes, with
`aria-busy` beside it. Save it as `race.mjs`:

```schooling-example
{"language": "javascript", "file": "race.mjs", "parts": [{"code": "// Types a word into the search page key by key and prints, as they happen,\n// each question asked, each answer, and what the page shows after it.\n// Run it with the shop started: node race.mjs [word] [ms between keys]\nimport { chromium } from '@playwright/test';\n\nconst word = process.argv[2] ?? 'papaya';\nconst delay = Number(process.argv[3] ?? 0);", "note": "The word and the pause between keys come from the command line. With neither, it types `papaya` with no pause at all, which is what Playwright does unless told otherwise."}, {"code": "const browser = await chromium.launch();\nconst page = await browser.newPage();\nawait page.goto('http://localhost:3000/search.html');", "note": "A browser nobody watches, already on the search page, so the page's own requests are over before the timing starts."}, {"code": "const start = Date.now();\nconst log = (text) => console.log(String(Date.now() - start).padStart(5) + ' ms  ' + text);\nconst query = (request) => new URL(request.url()).searchParams.get('q');\npage.on('request', (request) => {\n  if (request.url().includes('/api/search')) log(`asked    \"${query(request)}\"`);\n});\npage.on('response', (response) => {\n  if (response.url().includes('/api/search')) log(`answered \"${query(response.request())}\"`);\n});", "note": "Two listeners on the page's traffic. One prints a line when a question to `/api/search` leaves, the other when its answer arrives, each with the milliseconds since the start."}, {"code": "// Every time the list changes, the page calls shows() with what it holds.\nawait page.exposeFunction('shows', (text) => log(`  shows  ${text}`));\nawait page.evaluate(() => {\n  const results = document.querySelector('#results');\n  new MutationObserver(() => {\n    const names = [...results.children].map((li) => li.textContent);\n    window.shows(`${document.querySelector('#count').textContent}: ${names.join(', ')}`\n      + `  (aria-busy=${results.getAttribute('aria-busy')})`);\n  }).observe(results, { childList: true });\n});", "note": "This part runs inside the page. A `MutationObserver` is a browser feature that calls a function whenever part of the DOM changes; here, whenever the list's items change. `page.exposeFunction` makes `shows()` callable from inside the page, so the page can report back to this program."}, {"code": "await page.locator('#q').pressSequentially(word, { delay });\nawait page.locator('#results[aria-busy=\"false\"]').waitFor();\nawait browser.close();", "note": "`pressSequentially` types one key at a time, so the box fires one `input` event per key, as it does for a person. Then the program waits until the list carries `aria-busy=\"false\"`, which is the page saying no answer is outstanding."}]}
```

## A robot's speed

With the shop started, the word typed with no pause between keys, which is what Playwright does
unless told otherwise:

```
%%CAP race-0%%
```

Read it from the top. All six questions leave before the first answer comes back. The answer to
`papaya` is the first back, and the list shows *1 found: Papaya*, which is right. Three more answers
agree with it. Then the answer to `pa` lands and the list grows to two, and last of all the answer
to `p` lands and the list settles on **3 found: Papaya, Passion fruit, Pineapple**, in a box that
says `papaya`. Only then does `aria-busy` go back to `false`, because only then is no answer
outstanding.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Six questions leave within a few milliseconds of each other: p, pa, pap, papa, papay and papaya. The server waits 750, 600, 450, 300, 150 and 0 milliseconds before answering them, so the answer to papaya arrives first and the answer to p arrives last. Below, what the list shows: Papaya until 600 ms, then Papaya and Passion fruit, then from 750 ms three fruit, which is where it stays.\"><text x=\"20\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">asked</text><text x=\"150\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">milliseconds after the typing</text><text x=\"20\" y=\"55\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">\"p\"</text><rect x=\"150\" y=\"46\" width=\"465\" height=\"10\" rx=\"2\" fill=\"var(--scan)\"></rect><circle cx=\"615\" cy=\"51\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"625\" y=\"55\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">750 ms</text><text x=\"20\" y=\"81\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">\"pa\"</text><rect x=\"150\" y=\"72\" width=\"372\" height=\"10\" rx=\"2\" fill=\"var(--scan)\"></rect><circle cx=\"522\" cy=\"77\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"532\" y=\"81\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">600 ms</text><text x=\"20\" y=\"107\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">\"pap\"</text><rect x=\"150\" y=\"98\" width=\"279\" height=\"10\" rx=\"2\" fill=\"var(--scan)\"></rect><circle cx=\"429\" cy=\"103\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"439\" y=\"107\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">450 ms</text><text x=\"20\" y=\"133\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">\"papa\"</text><rect x=\"150\" y=\"124\" width=\"186\" height=\"10\" rx=\"2\" fill=\"var(--scan)\"></rect><circle cx=\"336\" cy=\"129\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"346\" y=\"133\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">300 ms</text><text x=\"20\" y=\"159\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">\"papay\"</text><rect x=\"150\" y=\"150\" width=\"93\" height=\"10\" rx=\"2\" fill=\"var(--scan)\"></rect><circle cx=\"243\" cy=\"155\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"253\" y=\"159\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">150 ms</text><text x=\"20\" y=\"185\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">\"papaya\"</text><circle cx=\"150\" cy=\"181\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"160\" y=\"185\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0 ms</text><path d=\"M150 206 L677 206\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M150 206 L150 211\" stroke=\"var(--wire)\"></path><text x=\"150\" y=\"224\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><path d=\"M274 206 L274 211\" stroke=\"var(--wire)\"></path><text x=\"274\" y=\"224\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">200</text><path d=\"M398 206 L398 211\" stroke=\"var(--wire)\"></path><text x=\"398\" y=\"224\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">400</text><path d=\"M522 206 L522 211\" stroke=\"var(--wire)\"></path><text x=\"522\" y=\"224\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">600</text><path d=\"M646 206 L646 211\" stroke=\"var(--wire)\"></path><text x=\"646\" y=\"224\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">800</text><text x=\"20\" y=\"265\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the list</text><rect x=\"150\" y=\"250\" width=\"372\" height=\"22\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><text x=\"336\" y=\"265\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Papaya</text><rect x=\"522\" y=\"250\" width=\"93\" height=\"22\" rx=\"3\" fill=\"var(--wire)\"></rect><text x=\"568\" y=\"265\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">+ Passion</text><rect x=\"615\" y=\"250\" width=\"62\" height=\"22\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"646\" y=\"265\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--ink)\">3 found</text><text x=\"150\" y=\"294\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the answer that arrives last is the one that stays</text></svg>", "caption": "Six questions, six answers in reverse order. The list is right for most of the time and wrong at the end."}
```

## A person's speed

The same word, with 200 milliseconds between keys, which is an ordinary typing pace:

```
%%CAP race-200%%
```

Now each answer arrives before the next one, because each question left 200 ms after its
neighbour and is held back only 150 ms less. On the way the list passes through three fruit and
two, while the box still says `papa`, and it ends on *1 found: Papaya*. **Nothing in the
page changed; only the speed of the typing did.** One more detail is in that run: `aria-busy` went
back to `false` once in the middle, when every question asked so far had its answer and the last
key had not been pressed yet.

Work it out for any pace: a key every *k* milliseconds puts the answer to the *n*-th question at
*k*×(*n*−1) + 900 − 150×*n*, which grows with *n* when *k* is above 150 and shrinks when *k* is
below it. **Slower than 150 ms a key, the defect never shows; faster, it always does.** A person
testing by hand types at a person's speed and sees the right answer. Paste the word, or type it
the way a robot does, and the other answer appears.

## What a test is up against

Three facts come out of these two runs, and each of the next two sections leans on one of them.

- **For most of the time the page is right.** At a robot's speed the list shows *Papaya* from the
  first answer until the answer to `pa` replaces it: by the server's rule, from about 0 ms to
  600 ms of the 750 the race lasts. A test that looks during that window sees a correct page.
- **The wrong state is the final one.** Whatever looks after the last answer sees three fruit, and
  keeps seeing them for as long as the page stays open.
- **The page says when it is done.** `aria-busy` is `true` from the first key until the last
  answer and `false` after it. It is the one signal on the page that separates *the list is right
  for now* from *the list is finished*.
