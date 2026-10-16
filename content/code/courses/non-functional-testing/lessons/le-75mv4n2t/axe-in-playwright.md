---
title: axe in a Playwright script
version: 1
---

**axe is a rules engine for accessibility**: a JavaScript library, written by Deque Systems and
published as open source, that runs inside a page and checks the document the browser built
against a list of rules. It is what most automated accessibility tools are made of. Lighthouse
runs it, so do several browser extensions, and so does the suite that checks every screen of the
platform this course is served on. Run on its own, from a script, it becomes a test like any
other: open the page, run the rules, fail if anything broke.

This lesson drives it with Playwright, the browser automation `web-automation` lesson 10 taught.
The booking page from lesson 12 is the subject, served by the box office as before.

## The project

`~/a11y` is the directory lesson 12 made for `contrast.py`. It becomes a Node project of its own,
with two packages: Playwright at the version lesson 10 installed, and the axe integration for it.

```sh
cd ~/a11y
npm init -y
npm install playwright@1.56.0 @axe-core/playwright@4.13.0
```

`npm init -y` writes a `package.json` and prints it. The install prints:

```
ana@nft:~/a11y$ npm install playwright@1.56.0 @axe-core/playwright@4.13.0

added 5 packages, and audited 6 packages in 3s

found 0 vulnerabilities
```

No browser is downloaded. Lesson 10 put Playwright's Chromium in `~/.cache/ms-playwright`, and
every project on the machine that uses the same Playwright version finds it there.

Before the audit, a look at what the engine knows. `nano rules.js`:

```javascript
// a11y/rules.js
// What the axe engine in this project knows: how many rules, and how many
// carry each tag that audit.js asks for, against the best-practice ones.
const axe = require("axe-core");

const rules = axe.getRules();
console.log(`axe ${axe.version}: ${rules.length} rules`);
for (const tag of ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa", "best-practice"]) {
  const tagged = rules.filter(r => r.tags.includes(tag)).map(r => r.ruleId);
  console.log(`  ${tag.padEnd(14)}${String(tagged.length).padStart(3)}` +
              (tagged.length < 3 ? `  (${tagged.join(", ")})` : ""));
}
```

```
ana@nft:~/a11y$ node rules.js
axe 4.13.0: 105 rules
  wcag2a         62
  wcag2aa         3
  wcag21a         1  (label-content-name-mismatch)
  wcag21aa        3
  wcag22aa        1  (target-size)
  best-practice  30
```

**Read the last two lines before trusting any result.** WCAG 2.2 added nine success criteria,
and the tag for its AA level holds one rule: `target-size`, for 2.5.8. Focus Not Obscured, Dragging
Movements and Accessible Authentication have none, because a program reading the document cannot
decide them. And thirty rules are tagged `best-practice`: checks Deque considers worth making that
no WCAG criterion requires. The script below leaves them out, so its verdict is about WCAG and
nothing else.

## The audit

`nano audit.js`, and the copy button takes the program without the notes:

```schooling-example
{"language": "javascript", "file": "a11y/audit.js", "parts": [{"code": "// a11y/audit.js\n// Opens one page in Chromium, runs axe against WCAG 2.2 A and AA, and prints\n// every violation. Exits 1 when there is any, so a pipeline can stop on it.\nconst { chromium } = require(\"playwright\");\nconst { AxeBuilder } = require(\"@axe-core/playwright\");\n\nconst url = process.argv[2] || \"http://localhost:8000/book.html\";\nconst TAGS = [\"wcag2a\", \"wcag2aa\", \"wcag21a\", \"wcag21aa\", \"wcag22aa\"];", "note": "Playwright drives the browser and `@axe-core/playwright` puts the axe engine into the page it opened. The address comes from the command line, with `book.html` as the default. **The tags are the standard**: these five select every rule axe files under WCAG 2.0, 2.1 and 2.2 at levels A and AA, which is what \"WCAG 2.2 AA\" means as a list of rules. The same five tags are what this school's own suite asks for."}, {"code": "\n(async () => {\n  const browser = await chromium.launch();\n  const context = await browser.newContext();\n  const page = await context.newPage();\n  await page.goto(url);\n  await page.waitForLoadState(\"networkidle\");", "note": "A context made explicitly, because axe refuses a page that came from `browser.newPage()`. Waiting for `networkidle` matters here: the list of shows is filled by a `fetch` after the page loads, and an audit of a page that has not finished drawing is an audit of a different page."}, {"code": "\n  const result = await new AxeBuilder({ page }).withTags(TAGS).analyze();\n  for (const v of result.violations) {\n    console.log(`${v.id} (${v.impact}): ${v.help}`);\n    for (const node of v.nodes) {\n      console.log(`  at ${node.target.join(\" \")}`);\n      const reasons = node.failureSummary.split(\"\\n\").slice(1);\n      for (const reason of reasons) console.log(`    ${reason.trim()}`);\n    }", "note": "`analyze()` runs every selected rule and returns four lists: `violations`, `passes`, `incomplete` and `inapplicable`. Each violation carries its rule id, how bad axe thinks it is (`minor`, `moderate`, `serious`, `critical`), one line of help, and every element it failed on, with the reasons."}, {"code": "  }\n  const review = result.incomplete.map(v => v.id).join(\", \") || \"none\";\n  console.log(`${result.violations.length} violations; to review by hand: ${review}`);\n  await browser.close();\n  process.exit(result.violations.length ? 1 : 0);\n})();", "note": "`incomplete` is the list axe could not decide, and it is printed because it is work for a person, not a pass. **The exit code is the gate**: 1 when there is any violation, so a pipeline step that runs this file fails the build."}]}
```

With the box office running in its own terminal, audit the booking page:

```
ana@nft:~/a11y$ node audit.js; echo "exit $?"
color-contrast (serious): Elements must meet minimum color contrast ratio thresholds
  at .note
    Element has insufficient color contrast of 2.84 (foreground color: #999999, background color: #ffffff, font size: 12.0pt (16px), font weight: normal). Expected contrast ratio of 4.5:1
html-has-lang (serious): <html> element must have a lang attribute
  at html
    The <html> element does not have a lang attribute
image-alt (critical): Images must have alternative text
  at img
    Element does not have an alt attribute
    aria-label attribute does not exist or is empty
    aria-labelledby attribute does not exist, references elements that do not exist or references elements that are empty
    Element has no title attribute
    Element's default semantics were not overridden with role="none" or role="presentation"
label (critical): Form elements must have labels
  at #customer
    Element does not have an implicit (wrapped) <label>
    Element does not have an explicit <label>
    aria-label attribute does not exist or is empty
    aria-labelledby attribute does not exist, references elements that do not exist or references elements that are empty
    Element has no title attribute
    Element has no placeholder attribute
    Element's default semantics were not overridden with role="none" or role="presentation"
4 violations; to review by hand: none
exit 1
```

## Reading it

Four violations, each named by its rule, its impact and the elements it failed on.

- **`color-contrast`** found the note, and printed the measurement: 2.84 against the 4.5 that 1.4.3
  expects. It is the same pair of colours `contrast.py` put at 2.85 in lesson 12; the ratio is
  the two programs round the same ratio differently.
- **`html-has-lang`** is defect 1, `image-alt` defect 4, `label` defect 5.
- Under `image-alt` and `label` is a list of every way the element **could** have been given a
  name, each one missing. That list is the fix menu: any one of them clears the rule, and the
  first one, a real `alt` or a real `<label>`, is nearly always the right one.

The impact is axe's estimate of how badly the defect hurts a user, not a WCAG level: `image-alt`
is *critical* and `html-has-lang` *serious*, though both fail level A criteria.

**`exit 1`** is the line a pipeline reads. Nothing was left to review by hand on this page;
`incomplete` fills up on pages with text over images or gradients, where the background colour
cannot be worked out, and on content inside frames the script could not reach.

What is missing matters as much as what is there. Defects 3, 6, 7 and 8 were not reported: the
removed focus outline, the positive `tabindex`, the `<div>` that acts as a button and the error
shown only in red. Four found, four not. The section after next says why.
