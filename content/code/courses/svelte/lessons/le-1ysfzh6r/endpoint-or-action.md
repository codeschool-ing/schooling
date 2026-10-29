---
title: An endpoint or an action
version: 1
---

**For a form on one of the application's own pages, an action. For anything else, an endpoint.** That
is the rule the documentation gives, and the planner now has both, so the reasons can be seen side by
side:

| | form action | endpoint |
|---|---|---|
| who sends it | a `<form>` on a page of the application | any program: a script, another site's server, `fetch` in a component |
| works with JavaScript off | yes, it is a form | only if something other than JavaScript sends it |
| after it runs | the page renders again, or a redirect, and the load functions rerun | whatever `Response` it returns |
| an error | the nearest `+error.svelte`, inside the layouts | JSON, or a plain fallback page, never `+error.svelte` |
| layouts | it belongs to a page, and the page has layouts | none: `+layout` files have no effect on it |
| hooks | `handle` runs | `handle` runs |

**The error row is the one that surprises people.** An endpoint has no page, so an error in it cannot
show the error page. SvelteKit answers with the error as JSON to a request that does not ask for HTML,
and with a plain fallback page, `src/error.html` if the project has one, to a browser:

```
ana@dev:~/planner$ curl -s -w '\n' http://localhost:5173/courses/piano/sessions.csv
{"status":404,"message":"There is no course called “piano”."}
```

`{"status":404,"message":…}`: the `error(404, …)` in the CSV endpoint, written as data, with none of the
planner's header or links around it.

**Lesson 12 promised this** in "The error page": errors in endpoints "are answered as data rather than
as pages". They still pass through `handleError`, so an unexpected one is logged under its request's
id, as lesson 16 arranged.

One more difference is not in the table because it is about time rather than mechanism. SvelteKit 3's
experimental **remote functions**, which lesson 14 mentioned, let a component call a function on the
server as though it were local, and they cover much of what an application writes endpoints for today.
They are still experimental; endpoints are not, and an endpoint is what any program outside the
application, which knows nothing of SvelteKit, will always need.
