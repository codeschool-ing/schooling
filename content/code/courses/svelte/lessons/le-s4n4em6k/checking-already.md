---
title: The checking that happens already
version: 1
---

**The Svelte compiler checks every component it compiles, in JavaScript or TypeScript, and some of what
it checks is the page's accessibility.** A `<div>` with a click handler and no keyboard equivalent, an
image with no `alt`, a label pointing at nothing: the compiler knows the markup well enough to notice,
and it warns while it compiles. Nobody has to opt in.

The tool that collects those warnings, and type errors too, is **`svelte-check`**. It runs the Svelte
compiler over every component and TypeScript's checker over every file, and prints what both found.
Install it, and TypeScript, which it uses; the dev server can stay stopped for this lesson until the
end:

```
ana@dev:~/planner$ npm install --save-dev svelte-check@4.7.7 typescript@6.0.3

removed 1 package, changed 7 packages, and audited 57 packages in 1s

13 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

and give it a script, as projects created with TypeScript have:

```
ana@dev:~/planner$ npm pkg set scripts.check='svelte-kit sync && svelte-check'
```

`svelte-kit sync` writes the types SvelteKit generates for each route, which the checker reads; the
`prepare` script runs it after every install, and `check` runs it first so that the types are never
older than the routes.

## A warning, on purpose

Make the About page's heading clickable, the wrong way. Replace `src/routes/(info)/about/+page.svelte`
for a moment:

```schooling-example
{"language": "html", "file": "src/routes/(info)/about/+page.svelte", "parts": [
 {"code": "<svelte:head>\n\t<title>About · Study planner</title>\n</svelte:head>"},
 {"code": "<h1 onclick={() => history.back()}>About the planner</h1>\n<p>\n\tThe study planner lists your courses, the sessions you plan for each, and the minutes in your week.\n\tIt keeps everything on this computer, in one small file, and asks nobody for anything.\n</p>\n<p><a href=\"/\">Back to the planner</a></p>", "note": "A trial. A heading that does something when clicked, and nothing for a keyboard."}
]}
```

```
ana@dev:~/planner$ npm run check 2>&1 | grep -A3 'about/+page.svelte'
/home/ana/planner/src/routes/(info)/about/+page.svelte:4:1
Warn: Visible, non-interactive element `<h1>` with a click event must be accompanied by a keyboard event handler. Consider whether an interactive element such as `<button type="button">` or `<a>` might be more appropriate
https://svelte.dev/e/a11y_click_events_have_key_events (svelte)
</svelte:head>
--
/home/ana/planner/src/routes/(info)/about/+page.svelte:4:1
Warn: Non-interactive element `<h1>` should not be assigned mouse or keyboard event listeners
https://svelte.dev/e/a11y_no_noninteractive_element_interactions (svelte)
</svelte:head>
```

**Two warnings from the compiler, about accessibility**: a heading is not something a keyboard can
reach or press, and a click with no key event leaves keyboard users out. The fix is a `<button>` or a
link, which have both for free. Put the file back as lesson 12 wrote it:

```schooling-example
{"language": "html", "file": "src/routes/(info)/about/+page.svelte", "parts": [
 {"code": "<svelte:head>\n\t<title>About · Study planner</title>\n</svelte:head>\n<h1>About the planner</h1>\n<p>\n\tThe study planner lists your courses, the sessions you plan for each, and the minutes in your week.\n\tIt keeps everything on this computer, in one small file, and asks nobody for anything.\n</p>\n<p><a href=\"/\">Back to the planner</a></p>", "note": "As lesson 12 wrote it."}
]}
```

## And the types, in JavaScript

Run it over the whole project:

```
ana@dev:~/planner$ npm run check 2>&1 | tail -8
/home/ana/planner/src/routes/(planner)/courses/[id=slug]/sessions.csv/+server.js:24:15
Error: Parameter 'value' implicitly has an 'any' type. 
// formula, and in quotes if it holds a comma, a quote or a line break.
function cell(value) {
	let text = String(value);

====================================
svelte-check found 66 errors and 0 warnings in 13 files
```

**Errors in a project with no TypeScript in it.** `jsconfig.json`, which `sv` wrote in lesson 1, asks for
strict checking, and TypeScript checks JavaScript too when asked. Most of the errors are of one kind:

```
ana@dev:~/planner$ npm run check -- --output machine 2>&1 | grep -c 'implicitly has an'
56
```

`Parameter 's' implicitly has an 'any' type`: the checker cannot tell what a parameter is, so it cannot
check anything done with it, and strict mode says so rather than staying quiet. **Each of those is a
place where a typo would go unnoticed.** `s.minuts` instead of `s.minutes` would be `undefined`, the
total would be `NaN`, and nothing would complain until a student saw it. The rest of this lesson tells
the checker what each value is, by converting the planner to TypeScript, until the count is zero.
