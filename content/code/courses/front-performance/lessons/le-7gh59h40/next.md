---
title: Next.js
version: 1
---

**In Next.js a folder is an address and `page.tsx` inside it is the page.** `app/page.tsx` answers
`/`, `app/courses/[slug]/page.tsx` answers `/courses/` followed by anything, and the square brackets
make `slug` a parameter. Every component in `app/` is a **server component** unless its file says
otherwise: it runs on the server, can read a file or a database directly, and sends the browser its
HTML, not its code.

The data is read in one place. Save this as `lib/plan.ts`:

```typescript
// lib/plan.ts: the planner's data, read on the server.
import { readFile } from "node:fs/promises";
import { cacheLife } from "next/cache";

export interface Plan {
  courses: { slug: string; title: string }[];
  sessions: { id: number; course: string; date: string; minutes: number; done: boolean }[];
}

export async function getPlan(): Promise<Plan> {
  "use cache";
  cacheLife("hours");
  return JSON.parse(await readFile("courses.json", "utf8"));
}
```

**`"use cache"` is the line that decides how this app renders.** Next.js 16 projects are made with
*Cache Components* switched on (it is in the `next.config.ts` the maker wrote), and under it any data
a page reads is either cached, with a lifetime, or read on every request. This function is cached
for `"hours"`, one of the lifetimes Next.js names, so a page that only reads it can be rendered once,
at build time, and kept. Lesson 3 is about what happens when that lifetime runs out.

The page around every route replaces the maker's `app/layout.tsx`:

```tsx
// app/layout.tsx: the page around every route.
export const metadata = { title: "Study planner" };

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en">
      <body>
        <main>{children}</main>
      </body>
    </html>
  );
}
```

The home page, replacing `app/page.tsx`. It is an `async` function, because a server component may
wait for its data:

```tsx
// app/page.tsx: the address /.
import Link from "next/link";
import { getPlan } from "@/lib/plan";

export default async function Home() {
  const plan = await getPlan();
  return (
    <>
      <h1>Study planner</h1>
      <ul>
        {plan.courses.map((c) => (
          <li key={c.slug}>
            <Link href={`/courses/${c.slug}`}>{c.title}</Link> ·{" "}
            {plan.sessions.filter((s) => s.course === c.slug).length} sessions
          </li>
        ))}
      </ul>
    </>
  );
}
```

And a course, in a new file `app/courses/[slug]/page.tsx`. **`generateStaticParams` lists the
values of `slug` that exist**, so the build knows which course pages it can render ahead of time.
`params` arrives as a promise, and `notFound()` answers an unknown slug with a 404:

```tsx
// app/courses/[slug]/page.tsx: the address /courses/<slug>, one per course.
import Link from "next/link";
import { notFound } from "next/navigation";
import { getPlan } from "@/lib/plan";

export async function generateStaticParams() {
  const plan = await getPlan();
  return plan.courses.map((c) => ({ slug: c.slug }));
}

export default async function Course({ params }: PageProps<"/courses/[slug]">) {
  const { slug } = await params;
  const plan = await getPlan();
  const course = plan.courses.find((c) => c.slug === slug);
  if (!course) notFound();
  return (
    <>
      <p><Link href="/">All courses</Link></p>
      <h1>{course.title}</h1>
      <ul>
        {plan.sessions.filter((s) => s.course === slug).map((s) => (
          <li key={s.id}>{s.date} · {s.minutes} min{s.done ? " · done" : ""}</li>
        ))}
      </ul>
    </>
  );
}
```

`LayoutProps` and `PageProps` are types Next.js writes for you from the folders, so the parameter
is typed without a line of your own. `Link` is an `<a>` that Next.js also handles in the browser, as
`mount` did in lesson 1.

## The build says what it decided

`next build` ends with a table of every route and how it was rendered:

```
ana@dev:~/meta/next$ npm run build 2>&1 | sed -n '/^Route/,$p'
Route (app)                Revalidate  Expire
┌ ○ /                              1h      1d
├ ○ /_not-found
└   /courses/[slug]
  ├ ◐ /courses/[slug]
  ├ ○ /courses/html-css            1h      1d
  ├ ○ /courses/javascript          1h      1d
  └ ○ /courses/git                 1h      1d


○  (Static)             prerendered as static content
◐  (Partial Prerender)  prerendered as static HTML with dynamic server-streamed content
```

**`○` is a page rendered at build time into a file.** The home page and all three courses are. The
two columns on the right come from `cacheLife("hours")`: an hour after a copy was made, the next
request is still answered with it while Next.js makes a fresh one in the background, and after a
day with no requests the old copy is not served at all. The fourth line under `/courses/[slug]` is
the one for a slug the build did not list, and its `◐` says it was partly prerendered: Next.js
keeps a shell for it and renders the rest when somebody asks. Lesson 3 visits that line on purpose. Start the production server in the second terminal:

```sh
npx next start -p 3001
```
