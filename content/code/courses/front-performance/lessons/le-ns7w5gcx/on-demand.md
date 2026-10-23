---
title: "On demand: when the data says so"
version: 1
---

**A timer regenerates a page because time passed. On-demand revalidation regenerates it because
somebody said the data changed**, and nothing at all happens between changes. The program that
changes the data, an editor's save button or a job that imports prices, calls an address on the site
that marks the affected copies as out of date.

In Next.js the copies are found by a **tag**. `cacheTag("plan")` inside `getPlan()` labels everything
rendered from the plan, and `revalidateTag("plan", …)` marks all of it at once, home page and course
pages together. That also fixes the problem of two pages that disagree. Replace `lib/plan.ts`:

```typescript
// lib/plan.ts: the planner's data, read on the server, cached and tagged.
import { readFile } from "node:fs/promises";
import { cacheLife, cacheTag } from "next/cache";

export interface Plan {
  courses: { slug: string; title: string }[];
  sessions: { id: number; course: string; date: string; minutes: number; done: boolean }[];
}

export async function getPlan(): Promise<Plan> {
  "use cache";
  cacheLife("hours");
  cacheTag("plan");
  return JSON.parse(await readFile("courses.json", "utf8"));
}
```

And the address that does the marking, a **route handler** in a new file,
`app/api/revalidate/route.ts`:

```typescript
// app/api/revalidate/route.ts: POST here after changing courses.json.
import { revalidateTag } from "next/cache";

export async function POST(request: Request) {
  const secret = process.env.REVALIDATE_SECRET;
  if (!secret || request.headers.get("x-revalidate-secret") !== secret) {
    return new Response("forbidden\n", { status: 403 });
  }
  revalidateTag("plan", { expire: 0 });
  return new Response("revalidated\n");
}
```

**The secret is not optional.** An address that throws away every cached page is an address anybody
on the internet can call in a loop, turning every request into a full render; the check refuses
whoever does not hold the secret, and a server started without one refuses everybody. `{ expire: 0 }`
asks for the old copies not to be served at all once marked.

Rebuild, and start the server with the secret in its environment, in the second terminal:

```sh
npm run build && REVALIDATE_SECRET=s3cret npx next start -p 3001
```

Then change the data, call the address without the secret and with it, and ask for the pages:

```
ana@dev:~/meta/next$ sed -i 's/"title": "Git"/"title": "Git and GitHub"/' courses.json
ana@dev:~/meta/next$ curl -s -X POST http://localhost:3001/api/revalidate
forbidden
ana@dev:~/meta/next$ curl -s -X POST -H 'x-revalidate-secret: s3cret' http://localhost:3001/api/revalidate
revalidated
ana@dev:~/meta/next$ curl -s http://localhost:3001/courses/git | grep -o '<h1>[^<]*</h1>'
<h1>Git</h1>
ana@dev:~/meta/next$ curl -s http://localhost:3001/courses/git | grep -o '<h1>[^<]*</h1>'
<h1>Git and GitHub</h1>
ana@dev:~/meta/next$ curl -s http://localhost:3001/ | grep -o '>Git[^<]*</a>'
>Git and GitHub</a>
```

The call without the secret was refused and changed nothing. After the call with it, the course page
and the home page both carry the new title, with no timer involved.

**Read the two requests for the course page again: the first still said *Git*.** The documentation
of `revalidateTag` says that with `{ expire: 0 }` the next request waits for a fresh render; on
Next.js 16.4.3, on this computer, the first request after the call got the old page and started the
render, and the second got the new one, exactly as with an age. That is the reason to check a
framework's promises with a request rather than trust them: a page that must be right on the very
next request, after a payment or a deletion, should not rely on this behaviour without a test that
fails when it is not there.

`s3cret` is a placeholder for this transcript. On a real site the secret is a long random value kept
in the host's settings and in the program that calls the address, never in the code, and
`front-delivery` lesson 2 is about where such values live. Put the title back afterwards.
