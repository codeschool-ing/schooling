---
title: What continuous integration is for
version: 1
---

**Continuous integration is a machine that runs the project's checks on every push, on a clean copy of
the repository, and says pass or fail where everybody can see it.** The name describes the habit it
makes possible: merging small changes into the main branch often, because each one has been checked
before it lands, instead of merging a month of work at once and finding out what broke.

The common picture is that CI is "running the tests on a server". The tests are part of it, and they
are not the reason it exists. The reason is the two words **clean** and **every**: a machine with none
of your local state, which nobody can skip, on every change. Your own computer is neither. It has files
you never committed, a `node_modules` from three weeks ago and environment variables you forgot setting,
and you run the checks when you remember.

## What the planner's pipeline does

Four steps, each one a command you can already run, in the order that fails fastest:

1. **Install exactly what the lockfile says**, with `npm ci`. The next section is about why not
   `npm install`.
2. **Check the types**, with `tsc`. A type error is the cheapest failure to find, so it comes first.
3. **Run the tests**, with Vitest, which the planner gets two sections from now.
4. **Build**, with `vite build`, which proves that what was checked can be turned into the folder a host
   serves.

Each step stops the pipeline when it fails, so a red result names the first thing that went wrong and
nothing after it is wasted.

## Where it sits

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A branch is pushed and a pull request opened. CI runs four steps on a clean machine: npm ci, tsc, the tests and the build. Red stops the merge; green lets it through to main, and the host then builds main and publishes it at the real address.\"><rect x=\"20\" y=\"70\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pull request</text><text x=\"80\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">from a branch</text><line x1=\"140\" y1=\"100\" x2=\"168\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"168.0,100.0 160.6,103.1 160.6,96.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"170\" y=\"30\" width=\"250\" height=\"140\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"295\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">CI, on a clean machine</text><rect x=\"190\" y=\"65\" width=\"18\" height=\"18\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"199\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">1</text><text x=\"220\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">npm ci</text><rect x=\"190\" y=\"89\" width=\"18\" height=\"18\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"199\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">2</text><text x=\"220\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">npx tsc</text><rect x=\"190\" y=\"113\" width=\"18\" height=\"18\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"199\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">3</text><text x=\"220\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">npm test</text><rect x=\"190\" y=\"137\" width=\"18\" height=\"18\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"199\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">4</text><text x=\"220\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">npx vite build</text><line x1=\"420\" y1=\"70\" x2=\"470\" y2=\"50\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"470.0,50.0 464.3,55.6 462.0,49.8\" fill=\"var(--amber)\"></polygon><text x=\"478\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">red: no merge</text><line x1=\"420\" y1=\"130\" x2=\"470\" y2=\"150\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"470.0,150.0 462.0,150.2 464.3,144.4\" fill=\"var(--phosphor)\"></polygon><rect x=\"472\" y=\"130\" width=\"90\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"517\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main</text><line x1=\"562\" y1=\"150\" x2=\"590\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"590.0,150.0 582.6,153.1 582.6,146.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"592\" y=\"125\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"647\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">host builds</text><text x=\"647\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">and publishes</text><text x=\"470\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">green: merge allowed</text></svg>", "caption": "The checks run before the merge, on every pull request, so a failure is a comment on a branch rather than a broken main."}
```

**The checks run on the pull request, before the merge**, which is the point: a failure there is a
comment on a branch, cheap and private to the person who made it. The same failure after the merge is
a broken main branch that everybody pulls. The host's build from lesson 1 runs after the checks, or
beside them, and only the main branch reaches the real address.

## What this lesson can run, and what it cannot

The pipeline's four steps all run on your computer, and the sections that follow run each of them,
including on a clean copy of the repository. GitHub Actions itself, the service that runs them on every
push, needs a repository on GitHub and was **not run for this course**; the workflow file is shown, each
line explained, and marked as such.
