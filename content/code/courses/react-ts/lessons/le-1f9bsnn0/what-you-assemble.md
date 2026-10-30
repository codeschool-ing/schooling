---
title: What you assemble yourself, and in which lesson
version: 1
---

**A React app is React plus about six decisions**, and this course makes each of them once, in the
lesson where it matters, with the reason written down. The table is the whole list. Every package
in it is installed at an exact version in the lesson named beside it, and every version is the one
the transcripts were recorded with.

| the job | what this course uses | lesson |
|---|---|---|
| build, dev server, environment variables | Vite, created by `create-vite` | 1, and 20 for how it works |
| types | TypeScript, which the Vite template already includes | 2 onwards, and 19 in depth |
| state shared across the app | React's own context, then Zustand, with Redux Toolkit and Jotai compared | 9 |
| forms | plain React first, then React Hook Form and Zod | 10 |
| data from a server | TanStack Query, still called React Query by many | 11 |
| addresses and screens | React Router | 17 |
| server rendering | Next.js | 15, 16 and 18 |
| tests | Vitest and React Testing Library | 22 |
| style and mistakes in the code | Oxlint from the template, then ESLint, Prettier and Biome | 23 |

Three things about this list are worth knowing before you start.

**It changes.** For most of a decade, the way most people started a React project was a tool
called Create React App, and the React team deprecated it in February 2025. A course that taught it would
be teaching a road that is closed. Vite is one of the build tools the React documentation names now
for a project built from scratch, and it is the one this course uses; lesson 20 shows enough of how it works that
the next change will not be a mystery.

**Each row is a market, not a law.** For global state there are at least four serious libraries
and lesson 9 compares three of them. For forms, React Hook Form is one of several, and lesson 10
writes a form without any of them first. When the course picks one, it says why, and the reason is never "this is the standard".

**The versions are pinned.** A React library that releases a new major version can change its
interface, and a course recorded against one version and read against another is a course whose
examples fail for reasons that are not yours. The next two sections set up your computer and pin
everything this lesson installs, and every lesson after this one does the same for what it adds.

## What the course assumes

Two courses come before this one in the `frontend` track, and the course leans on them without
teaching them again:

- **`javascript`**, for the language: modules, arrow functions, destructuring, promises and
  `async`/`await`, `fetch`, and the event loop. Its lesson 1 also installed the Node.js this course
  uses, which the next section checks.
- **`git`**, because the project you create here is a folder you will want under version control
  from its first commit.

`html-css` is earlier in the track too, and React writes HTML: a component that renders a `<button>`
renders a real button, with everything that course said about labels and focus still true.

## Where this course sits

The track forks after `ai-dev`, and you took the React and TypeScript branch. Three other courses
sit beside this one, `angular`, `vue` and `svelte`, and a student takes one of the four. **They
build the same app**: the study planner this lesson introduces, with the same screens and the same
data. The courses after the fork, `front-quality`, `front-performance`, `front-delivery` and
`front-multiplatform`, name none of the four frameworks and use a plain TypeScript version of that
same planner, so what you build here carries over without a translation step.
