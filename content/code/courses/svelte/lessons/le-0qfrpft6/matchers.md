---
title: Matchers, for parameters with a shape
version: 1
---

**A parameter matches any text between two slashes, unless a matcher says otherwise.** `[id]` took
`piano` in the previous section, which was right, since a course called piano could exist. It also
takes `Linear%20algebra`, `1`, `..` and anything a person or a crawler might type. The page coped by
saying "No such course", but some addresses are not worth rendering a page for at all: a course id in
the planner is lower-case letters and hyphens, and anything else is not an id.

A matcher states that. In SvelteKit 3 the matchers of a project are declared together in
`src/params.js`. Save it:

```schooling-example
{"language": "javascript", "file": "src/params.js", "parts": [
 {"code": "// params.js: the shapes a route parameter may take.\nimport { defineParams } from '@sveltejs/kit/params';\n\nexport const params = defineParams({", "note": "`defineParams` declares named matchers. Each is a function from the text in the address to the value the page receives, or `undefined` if it does not match."},
 {"code": "\tslug: (param) => (/^[a-z][a-z-]*$/.test(param) ? param : undefined)\n});", "note": "A slug: lower-case letters, then letters or hyphens. The value passed on is the text itself."}
]}
```

and name the matcher in the folder, after an `=`:

```
ana@dev:~/planner$ mv 'src/routes/(planner)/courses/[id]' 'src/routes/(planner)/courses/[id=slug]'
```

The page's code does not change: the parameter is still called `id`. What changes is which addresses reach it:

```
ana@dev:~/planner$ look http://localhost:5173/courses/Algebra
at /courses/Algebra
- main:
  - heading "404" [level=1]
  - paragraph: Not Found
```

**A 404, before the page runs.** `Algebra` is not a slug, so the route does not match, SvelteKit tries
the other routes, finds none, and answers that nothing is at that address. `piano` still reaches the
page, because it has the shape of a course id; whether the course exists is a question about the data,
which a matcher cannot answer and should not try to.

## What changed in SvelteKit 3

Before version 3, each matcher was a file of its own in a `src/params/` folder, exporting a `match`
function that returned `true` or `false`. You will see that in older projects. The single
`defineParams` file is the replacement, and its functions return a value rather than a yes or no, so a
matcher can also convert: a matcher for numbers can hand the page a number instead of the string that
was in the address.
