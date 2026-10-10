---
title: Three things that vary, at three speeds
version: 1
---

**Every repository layout is an answer to one question: when something changes, how many files
change with it?** Three things vary in what a GitOps repository describes, and they change at
different speeds, for different reasons, by different people.

- **The application**: its code, built into an image. It changes many times a day, by the
  developers who write it. In `fleet` it appears only as a reference: `localhost:5001/bulletin:1.0`.
- **The environment**: staging, production, a test environment for one feature. It changes when an
  environment is added or retired, rarely, by whoever runs the platform.
- **The configuration**: what one application needs in one environment. Two replicas in staging,
  three in production; a message here, a different one there; a database address per environment.
  It changes when somebody tunes or promotes, on every release.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 280\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"Three things that vary: the application, changed by developers many times a day; the configuration, changed on every release or tuning; and the environment, changed rarely, by the platform team. Each maps to one place in the repository.\"><rect x=\"0\" y=\"0\" width=\"680\" height=\"280\" fill=\"var(--ink)\"/><text x=\"30\" y=\"30\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper-dim)\">what varies</text><text x=\"250\" y=\"30\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper-dim)\">how often</text><text x=\"430\" y=\"30\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper-dim)\">where it lives in fleet</text><rect x=\"20\" y=\"50\" width=\"200\" height=\"55\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"120.0\" y=\"82.05\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">the application</text><rect x=\"240\" y=\"50\" width=\"170\" height=\"55\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"325.0\" y=\"82.05\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">many times a day</text><rect x=\"430\" y=\"50\" width=\"230\" height=\"55\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"545.0\" y=\"82.05\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">an image reference</text><line x1=\"410\" y1=\"77\" x2=\"418.0\" y2=\"77.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"426,77 418.0,72.5 418.0,81.5\" fill=\"var(--paper-dim)\"/><rect x=\"20\" y=\"125\" width=\"200\" height=\"55\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"120.0\" y=\"157.05\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">the configuration</text><rect x=\"240\" y=\"125\" width=\"170\" height=\"55\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"325.0\" y=\"157.05\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">every release</text><rect x=\"430\" y=\"125\" width=\"230\" height=\"55\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"545.0\" y=\"157.05\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">a file per app and environment</text><line x1=\"410\" y1=\"152\" x2=\"418.0\" y2=\"152.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"426,152 418.0,147.5 418.0,156.5\" fill=\"var(--paper-dim)\"/><rect x=\"20\" y=\"200\" width=\"200\" height=\"55\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"120.0\" y=\"232.05\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">the environment</text><rect x=\"240\" y=\"200\" width=\"170\" height=\"55\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"325.0\" y=\"232.05\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">rarely</text><rect x=\"430\" y=\"200\" width=\"230\" height=\"55\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"545.0\" y=\"232.05\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">a directory</text><line x1=\"410\" y1=\"227\" x2=\"418.0\" y2=\"227.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"426,227 418.0,222.5 418.0,231.5\" fill=\"var(--paper-dim)\"/></svg>", "caption": "What varies, how often, and where it belongs. A change of one kind should touch one place."}
```

A good layout puts each of those in one place, so that a change of one kind touches one file. A
new release changes an image reference in one environment's directory. A new environment is a new
directory. A new application is a new directory under `apps/`. **The layout fails when a single kind
of change has to be made in several places**, because sooner or later one of them is forgotten, and
the environments drift apart in ways nobody decided.

The rest of this lesson builds that layout for `fleet`, in four steps: the application's source
moves into a repository of its own, the files move into directories by application and environment,
production arrives, and a release is promoted from one to the other. Lesson 6 then removes the
duplication the directories leave behind.
