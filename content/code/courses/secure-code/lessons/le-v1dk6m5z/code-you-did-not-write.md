---
title: Code you did not write
version: 1
---

Lesson 1 installed two packages and pip installed twelve. That ratio is normal, and it is the
reason this lesson exists: **most of the code inside a Python application was written by people
outside the team**, and it runs with exactly the same rights as the code the team wrote. A flaw
in a library the portal imports is a flaw in the portal.

This lesson's folder holds no application, only the list of what one depends on. Make it as
before:

```
(.venv) ana@vm:~/sc$ mkdir deps
(.venv) ana@vm:~/sc$ cd deps
(.venv) ana@vm:~/sc/deps$ git init -b main
Initialized empty Git repository in /home/ana/sc/deps/.git/
```

`pip show` tells you what a package pulls in. The `Requires` line is Flask's own list:

```
(.venv) ana@vm:~/sc/deps$ pip show flask
Name: Flask
Version: 3.1.3
Summary: A simple framework for building complex web applications.
Home-page: 
Author: 
Author-email: 
License-Expression: BSD-3-Clause
Location: /home/ana/sc/.venv/lib/python3.13/site-packages
Requires: blinker, click, itsdangerous, jinja2, markupsafe, werkzeug
Required-by: 
```

Six packages, each with its own maintainers, release schedule and history of advisories. Jinja2,
the template engine lesson 4 relied on for escaping, requires MarkupSafe in its turn. These are
**transitive dependencies**: nobody at Vereda chose them by name, and every one of them is code
that runs when a patient opens a page.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l17-tree\" aria-label=\"What one line in a requirements file brings with it. The line flask==3.1.3 installs Flask, and Flask requires six more packages: blinker, click, itsdangerous, Jinja2, MarkupSafe and Werkzeug. Jinja2 in turn requires MarkupSafe. pip-audit, installed to check the others, brought 24 packages of its own. Every box is code that runs inside the application.\"><defs><marker id=\"l17-tree-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">what you wrote</text><rect x=\"30\" y=\"120\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">flask==3.1.3</text><text x=\"110\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">one line</text><text x=\"470\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">what came with it</text><rect x=\"250\" y=\"120\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"305.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Flask</text><rect x=\"430\" y=\"40\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">blinker</text><path d=\"M360 142 L395 142 L395 55 L430 55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-tree-ah-paper-dim)\"></path><rect x=\"430\" y=\"78\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">click</text><path d=\"M360 142 L395 142 L395 93 L430 93\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-tree-ah-paper-dim)\"></path><rect x=\"430\" y=\"116\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"131.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">itsdangerous</text><path d=\"M360 142 L395 142 L395 131 L430 131\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-tree-ah-paper-dim)\"></path><rect x=\"430\" y=\"154\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Jinja2</text><path d=\"M360 142 L395 142 L395 169 L430 169\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-tree-ah-paper-dim)\"></path><rect x=\"430\" y=\"192\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">MarkupSafe</text><path d=\"M360 142 L395 142 L395 207 L430 207\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-tree-ah-paper-dim)\"></path><rect x=\"430\" y=\"230\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Werkzeug</text><path d=\"M360 142 L395 142 L395 245 L430 245\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-tree-ah-paper-dim)\"></path><path d=\"M570 169 L620 169 L620 207 L570 207\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l17-tree-ah-paper-dim)\"></path><path d=\"M190 142 L250 142\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-tree-ah-paper-dim)\"></path><text x=\"470\" y=\"285\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">pip-audit itself brought 24 more</text></svg>", "caption": "One line written, seven packages installed. A dependency's dependencies run with the same rights as your own code."}
```

### Three questions about each one

A dependency is a decision, even when it arrives without anybody deciding. The three questions
worth asking are short:

| question | why it matters |
|---|---|
| **is a known flaw published for the version we run?** | the commonest and cheapest problem to find, and the next section is about it |
| **is it still maintained?** | a library nobody maintains receives no fixes, so an advisory against it has no fixed version to move to |
| **do we need it at all?** | the safest dependency is one the application does not have; a function copied from a package of ten lines is often better owned than imported |

The first question has a tool. The other two are judgement, asked when a dependency is added and
again when it causes trouble, and they belong in the code review lesson 18 describes.
