---
title: The error page
version: 1
---

**When SvelteKit cannot render a page, it renders the nearest `+error.svelte` instead**, inside the
layouts above it. The 404 of the previous section was SvelteKit's own, plain page. A `+error.svelte`
at the root of `src/routes` replaces it for every address, and keeps the planner's header around it so
that a student who mistyped an address has somewhere to go. Save it as `src/routes/+error.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/+error.svelte", "parts": [
 {"code": "<script>\n\timport { page } from '$app/state';\n</script>\n\n<svelte:head>\n\t<title>{page.status} · Study planner</title>\n</svelte:head>", "note": "`page.status` is the HTTP status, and `page.error` the error that was raised, with a `message`."},
 {"code": "<h1>{page.status === 404 ? 'Nothing at this address' : 'Something went wrong'}</h1>\n<p>{page.error?.message}</p>\n<p><a href=\"/\">Back to the planner</a></p>", "note": "The page says what happened in words and offers a way back. The status code is for the browser and the logs."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/courses/Algebra
at /courses/Algebra
title: 404 · Study planner
- main:
  - heading "Nothing at this address" [level=1]
  - paragraph: Not Found
  - paragraph:
    - link "Back to the planner":
      - /url: /
```

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:5173/courses/Algebra
404
```

The page is friendlier and **the status is still 404**. That matters more than it looks: a crawler, a
link checker or a monitoring tool reads the status, not the words, and a "not found" page answered with
200 tells all of them that the address exists.

## Where an error page applies

SvelteKit looks for `+error.svelte` starting in the folder of the route that failed and walking up, so
a section of the application can have its own error page, nearer the failure than the root's. An error
page is rendered inside the layouts **above** its own folder, which is why this one has the header: the
root layout wraps it.

Two failures never reach an `+error.svelte`. If the root layout itself fails, there is no layout left to
render the error page in, and SvelteKit falls back to a static page, `src/error.html`, which you can
write to replace its default. And errors in server endpoints, which are lesson 17, are answered as data
rather than as pages. Lesson 13 raises errors on purpose, with `error(404, …)`, from the functions that
load a page's data, and this file is what shows them.
