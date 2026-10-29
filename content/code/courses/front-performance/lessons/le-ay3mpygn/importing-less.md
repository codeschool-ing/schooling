---
title: Importing less
version: 1
---

**A bundler ships what is imported, and drops what nothing imports.** That is called **tree shaking**:
Vite follows every `import` from the entry, and code no import reaches is left out of the build. It only
works on code the bundler can see is unused, so it works best on libraries written as ES modules whose
parts are imported by name.

`chart.js/auto` defeats it on purpose. It imports every controller, element, scale and plugin Chart.js
has and registers them all, so that `new Chart(...)` works for any kind of chart without a second line;
the convenience is exactly the code a bar chart does not need. Chart.js also offers its pieces one by one.
A bar chart needs four: the bar controller, the bar element, a category scale for the weeks and a linear
scale for the minutes. In `src/chart.ts`, replace the import of `chart.js/auto` with:

```typescript
// Only the pieces a bar chart uses: the rest of Chart.js is never imported, so never shipped.
import { BarController, BarElement, CategoryScale, Chart, LinearScale } from "chart.js";
Chart.register(BarController, BarElement, CategoryScale, LinearScale);
```

The register call is the reason this is safe: Chart.js finds its pieces through a registry rather than
through imports, so a piece left out is not a broken import but a chart type that is not there, and
asking for one says so with an error that names it.

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 9 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                  0.69 kB │ gzip: 0.35 kB
dist/assets/index-gserWk4t.css   0.76 kB │ gzip: 0.41 kB
dist/assets/index-yh2nfJj3.js   18.08 kB │ gzip: 6.95 kB

✓ built in 192ms
```

**Seventy kilobytes gone**, a third of the file. Build, restart, and ask again:

```
ana@dev:~/planner$ node tools/unused.ts http://localhost:3000/stats
/assets/index-DG0BwuX_.js      147.5 KB, ran  75.5 KB (51%)
```

**The stats page now runs about half of its script**, against less than half before. The course page
still downloads all of it, because a chart the course page never draws is still imported by the one
file every page loads. Importing less shrank the library; it did not move it off the pages that do not
use it. The next section does.

## Reading a library's size before installing it

Most libraries say in their documentation how to import only part of them, and the ones that do not are
worth a look before they are installed. A build is the measurement that settles it: install, import the
way you will use it, build, and read the number Vite prints. The habit that costs the most is importing
a whole utility library for one function.
