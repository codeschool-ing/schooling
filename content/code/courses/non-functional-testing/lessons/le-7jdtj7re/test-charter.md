---
title: A charter for the session a tool cannot run
version: 1
---

The tree says what the browser offers the screen reader. **Whether the reader turns that into
something a person can use is the part only a person can test**, and it is also the part most
teams skip, because a screen reader session has no obvious shape and no obvious end. A charter
gives it both. The format comes from exploratory testing, where Elisabeth Hendrickson's
*Explore It!* popularised it: one sentence of mission, a time box, and notes.

The tree already knows what is on the page, so a script can write the first draft. In `~/a11y`,
`nano charter.js`:

```schooling-example
{"language": "javascript", "file": "a11y/charter.js", "parts": [{"code": "// a11y/charter.js\n// Writes charter.md: a short charter for one manual session with a screen\n// reader, listing every control the accessibility tree says the page has.\nconst fs = require(\"fs\");\nconst { chromium } = require(\"playwright\");\n\nconst url = process.argv[2] || \"http://localhost:8000/book4.html\";\nconst reader = process.argv[3] || \"NVDA and Firefox\";\nconst ROLES = /^(link|heading|img|combobox|spinbutton|textbox|button|alert|status)\\b/;\n", "note": "Two arguments: the address your own computer's browser will open, and the reader and browser the session uses. The roles in `ROLES` are the ones a person should hear on this page; options, paragraphs and plain text are left out, so the list stays short enough to work through."}, {"code": "(async () => {\n  const browser = await chromium.launch();\n  const page = await browser.newPage();\n  await page.goto(url);\n  await page.waitForLoadState(\"networkidle\");\n  const tree = await page.locator(\"body\").ariaSnapshot();\n  await browser.close();\n\n  const controls = tree.split(\"\\n\").map(line => line.trim().replace(/^- /, \"\").replace(/:$/, \"\"))\n                       .filter(line => ROLES.test(line));", "note": "The tree is taken exactly as `tree.js` takes it, and each line that starts with one of those roles becomes an item to listen for: the role, and the name in quotes, as the browser will hand them to the reader."}, {"code": "  const charter = [\n    `# Charter: booking a seat with ${reader}`,\n    \"\",\n    `Explore ${url}`,\n    `with ${reader}, the keyboard only, and the screen out of sight,`,\n    \"to discover whether somebody who cannot see the page can book a seat.\",\n    \"\",\n    \"Before: python3 seed.py, then BOXOFFICE_HOST=0.0.0.0 python3 app.py.\",\n    \"Time box: 30 minutes. Write down what was heard, not what was expected.\",\n    \"\",\n    \"## What the tree says is there: is each one announced like this?\",\n    ...controls.map(control => `- [ ] ${control}`),\n    \"\",\n    \"## Tasks\",\n    \"- [ ] Book a free seat. Is the booking number announced, without moving the focus?\",\n    \"- [ ] Press Book with the name empty. Is the error announced, and is the focus on the name?\",\n    \"- [ ] Book a seat that is taken. Is \\\"seat taken\\\" announced?\",\n    \"- [ ] Move by headings, then by form fields. Is anything missing or out of order?\",\n    \"\",\n    \"## Notes\",\n    \"\",\n  ];\n  fs.writeFileSync(\"charter.md\", charter.join(\"\\n\"));\n  console.log(`charter.md: ${controls.length} things to listen for, 4 tasks`);\n})();", "note": "The charter itself, in the shape exploratory testers use: **explore** a target, **with** resources, **to discover** information. Then a time box, the items, four tasks that are the page's purpose, and an empty section for notes. The instruction that matters most is the second line under the mission: write down what was heard, because a tester who knows what the page should say hears it whether it was said or not."}]}
```

```
ana@nft:~/a11y$ node charter.js
charter.md: 12 things to listen for, 4 tasks
ana@nft:~/a11y$ cat charter.md
# Charter: booking a seat with NVDA and Firefox

Explore http://localhost:8000/book4.html
with NVDA and Firefox, the keyboard only, and the screen out of sight,
to discover whether somebody who cannot see the page can book a seat.

Before: python3 seed.py, then BOXOFFICE_HOST=0.0.0.0 python3 app.py.
Time box: 30 minutes. Write down what was heard, not what was expected.

## What the tree says is there: is each one announced like this?
- [ ] link "Skip to the booking form"
- [ ] img "boxoffice"
- [ ] link "What's on"
- [ ] link "Prices"
- [ ] link "Access"
- [ ] heading "Book a seat" [level=1]
- [ ] combobox "Show"
- [ ] spinbutton "Seat": "1"
- [ ] textbox "Your name"
- [ ] alert
- [ ] button "Book"
- [ ] status

## Tasks
- [ ] Book a free seat. Is the booking number announced, without moving the focus?
- [ ] Press Book with the name empty. Is the error announced, and is the focus on the name?
- [ ] Book a seat that is taken. Is "seat taken" announced?
- [ ] Move by headings, then by form fields. Is anything missing or out of order?

## Notes
```

Twelve things to listen for, and four tasks. When you run it for real, give it the address your
own browser opens and the pair you will test with, for example
`node charter.js http://` followed by the VM's address and `:8000/book4.html "VoiceOver and Safari"`,
so that the charter names what was actually tested.

## Running the session

On your own computer, with the box office answering on `0.0.0.0` as the section on the screen
readers set up:

1. Start the reader, open the page, and look away from the screen.
2. **Work through the list in the reader's own way**, not only with Tab: by headings, by form
   fields, by reading from the top. Tick an item when it is announced with that role and that
   name; write down exactly what you heard when it is not.
3. **Do the four tasks.** The second is the one `book.html` fails and `book4.html` was written to
   pass: an empty name has to produce speech, and the focus has to end up on the field.
4. Stop at the time box, and file what you wrote.

The same charter, run against `book.html`, is the most persuasive defect report this third of the
course can produce: an unnamed image, an unnamed field, a Book that is not a button, and an error
that makes no sound. Every one of those items was in the tree before anybody started a screen
reader, which is why reading the tree first makes the session short.

## Testing properly, not just passing the tool

The four lessons of this third add up to a plan with three layers, each catching what the one
before cannot:

| layer | how often | catches | lesson |
|---|---|---|---|
| automated audit, axe as a gate | every commit | missing names, contrast, missing `lang`: what is decidable from the document | 13 |
| scripted checks: the tab walk, the tree before and after an action | every commit | the tab order, a control that cannot be reached, an error that never reaches the tree | 14, 15 |
| a manual session with the keyboard and a screen reader, from a charter | when a page changes, and before a release | whether the names make sense, whether the speech is usable, whether the task can be finished | 14, 15 |

**The requirement lesson 12 wrote said "checked with an automated audit and by hand"**, and this
table is what the second half of that sentence means in practice. A page that passes only the
first layer has passed a tool. A page that passes all three is one a tester can call accessible,
with the version, the level and the readers named beside the claim.
