---
title: Ten components rendered, ten text nodes changed
version: 1
---

**Rendering every component did not rebuild the page.** The commit step changes the page only where
the new tree differs from the old one, and this section counts how little that is. Another temporary
file, `src/watch.ts`, asks the browser to report every change made under `#root`:

```typescript
// For lesson 3 only: after each change React makes to the page, say how many
// nodes it touched and what they now read.
const root = document.getElementById('root')!
new MutationObserver((records) => {
  const touched = records.map((r) => `${r.type} "${r.target.textContent}"`)
  console.log(`DOM: ${records.length} change(s)`, touched.join(', '))
}).observe(root, { subtree: true, childList: true, characterData: true, attributes: true })
```

A `MutationObserver` is the browser's own way of watching a part of the page; React knows nothing
about it. Imported at the top of `main.tsx`, it reports each commit as one console line:

```
ana@dev:~/planner$ sed -i '1i import "./watch"' src/main.tsx
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'click button Next week'
render App
render WeekNav
render WeekSummary
render CourseList
render CourseCard
render Card
render CourseCard
render Card
render CourseCard
render Card
DOM: 1 change(s) childList "Study plannerPrevious weekNext weekWeek of 19 Oct 202680 of 195 minutes doneStatistics2 sessions · 90 minSpanish2 sessions · 60 minOrganic chemistry1 session · 45 min"
-- click button Next week
render App
render WeekNav
render WeekSummary
render CourseList
render CourseCard
render Card
render CourseCard
render Card
render CourseCard
render Card
DOM: 10 change(s) characterData "26 Oct 2026", characterData "0", characterData "0", characterData "0", characterData "0", characterData "0", characterData "0", characterData "0", characterData "sessions", characterData "0"
```

On load, **one change**: React inserted the whole tree into `#root` at once, the text of it all in one
node. After "Next week", ten changes, every one of them `characterData`, which is the browser's word
for the text inside an existing text node. "19 Oct 2026" became "26 Oct 2026", eight numbers became
`0`, and the word "session" under Organic chemistry became "sessions", because one session had become
zero. **No element was created or removed, and no attribute moved.** The headings, the buttons and
the articles are the same DOM nodes they were before the click.

Going back the other way changes the same ten nodes back:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'click button Next week' --do 'click button Previous week'
render App
render WeekNav
render WeekSummary
render CourseList
render CourseCard
render Card
render CourseCard
render Card
render CourseCard
render Card
DOM: 1 change(s) childList "Study plannerPrevious weekNext weekWeek of 19 Oct 202680 of 195 minutes doneStatistics2 sessions · 90 minSpanish2 sessions · 60 minOrganic chemistry1 session · 45 min"
-- click button Next week
render App
render WeekNav
render WeekSummary
render CourseList
render CourseCard
render Card
render CourseCard
render Card
render CourseCard
render Card
DOM: 10 change(s) characterData "26 Oct 2026", characterData "0", characterData "0", characterData "0", characterData "0", characterData "0", characterData "0", characterData "0", characterData "sessions", characterData "0"
-- click button Previous week
render App
render WeekNav
render WeekSummary
render CourseList
render CourseCard
render Card
render CourseCard
render Card
render CourseCard
render Card
DOM: 10 change(s) characterData "19 Oct 2026", characterData "80", characterData "195", characterData "2", characterData "90", characterData "2", characterData "60", characterData "1", characterData "session", characterData "45"
```

```schooling-figure
{"svg": "<svg data-fig=\"diff\" viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two columns of the same tree, before and after the click. Most nodes are drawn the same in both and are labelled kept. Only the text nodes differ: 19 Oct 2026 becomes 26 Oct 2026, 80 and 195 become 0, and the course lines change their numbers. Arrows mark the ten text changes; no element is added or removed.\"><text x=\"170\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">last tree</text><text x=\"550\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">new tree</text><rect x=\"40\" y=\"38\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;h1&gt; Study planner</text><rect x=\"420\" y=\"38\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;h1&gt; Study planner</text><text x=\"360\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">kept</text><rect x=\"40\" y=\"63\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;button&gt; Previous week</text><rect x=\"420\" y=\"63\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;button&gt; Previous week</text><text x=\"360\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">kept</text><rect x=\"40\" y=\"88\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;p&gt; Week of 19 Oct 2026</text><rect x=\"420\" y=\"88\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">&lt;p&gt; Week of 26 Oct 2026</text><line x1=\"302\" y1=\"98\" x2=\"418\" y2=\"98\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,98.0 410.5,101.2 410.5,94.8\" fill=\"var(--amber)\"></polygon><rect x=\"40\" y=\"113\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;p&gt; 80 of 195 minutes done</text><rect x=\"420\" y=\"113\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">&lt;p&gt; 0 of 0 minutes done</text><line x1=\"302\" y1=\"123\" x2=\"418\" y2=\"123\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,123.0 410.5,126.2 410.5,119.8\" fill=\"var(--amber)\"></polygon><rect x=\"40\" y=\"138\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;h2&gt; Statistics</text><rect x=\"420\" y=\"138\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;h2&gt; Statistics</text><text x=\"360\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">kept</text><rect x=\"40\" y=\"163\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;p&gt; 2 sessions · 90 min</text><rect x=\"420\" y=\"163\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">&lt;p&gt; 0 sessions · 0 min</text><line x1=\"302\" y1=\"173\" x2=\"418\" y2=\"173\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,173.0 410.5,176.2 410.5,169.8\" fill=\"var(--amber)\"></polygon><rect x=\"40\" y=\"188\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;h2&gt; Organic chemistry</text><rect x=\"420\" y=\"188\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;h2&gt; Organic chemistry</text><text x=\"360\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">kept</text><rect x=\"40\" y=\"213\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;p&gt; 1 session · 45 min</text><rect x=\"420\" y=\"213\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">&lt;p&gt; 0 sessions · 0 min</text><line x1=\"302\" y1=\"223\" x2=\"418\" y2=\"223\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,223.0 410.5,226.2 410.5,219.8\" fill=\"var(--amber)\"></polygon><text x=\"360\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">only text changed: 10 characterData records</text></svg>", "caption": "The commit compares two trees and writes only the difference."}
```

Two things to take from it. **Re-rendering is cheap compared with what it looks like**, because the
expensive part, changing the page, is limited to the difference. And the nodes that did not change
keep everything the browser associates with them: a button that had focus still has it after the
click, and text a user selected stays selected. That second point is why React works hard to keep a
node rather than recreate it, and the next section shows how it decides which node is which.
