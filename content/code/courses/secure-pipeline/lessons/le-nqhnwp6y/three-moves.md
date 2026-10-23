---
title: Three moves, and when each is right
version: 1
---

Lesson 5 treated a dependency as a list of advisories: a scanner names a package and a version, and
the fix is the version the advisory says is fixed. That handles the finding in front of you. It
does not answer the question that decides most of a service's risk over a year: **what do we do with
this dependency from now on?** There are three moves, and each is right in a different situation.

| move | what it is | right when |
|---|---|---|
| **update** | take a newer version, deliberately, with its changelog read and the tests run | the project is healthy and the new version is what the maintainers support |
| **pin** | fix the exact version and the hash of every file, and change it only on purpose | always, as the base every other move starts from |
| **replace** | stop depending on it, for another package or for code of your own | the project has stopped fixing what matters to you |

**Pinning is not an alternative to updating; it is what makes an update a decision.** A service whose
dependencies float picks up whatever was published last night, in production, with nobody having
read a word of it. A service that pins updates when somebody chooses to, and the pipeline's checks
run on the change. The rest of this lesson does all three to linkbox: the pin with hashes, an update
of gunicorn across four major versions, and an argued replacement.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"sp-l15-moves\" aria-label=\"The three moves for a dependency. Pin is the base under every package: exact versions and hashes. On top of it, update when the project is healthy and the new version is supported, or replace when the project will not fix what matters to you.\"><defs><marker id=\"sp-l15-moves-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l15-moves-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"260\" y=\"20\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a dependency</text><text x=\"360.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its health read first</text><rect x=\"60\" y=\"100\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">update</text><text x=\"175.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a newer version, read and tested</text><rect x=\"430\" y=\"100\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">replace</text><text x=\"545.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">another package, or none</text><rect x=\"60\" y=\"170\" width=\"600\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pin</text><text x=\"360.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">exact versions and hashes, changed only on purpose</text><path d=\"M300 70 L300 85 L175 85 L175 98\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l15-moves-ah-phosphor)\"></path><path d=\"M420 70 L420 85 L545 85 L545 98\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l15-moves-ah-amber)\"></path><text x=\"170\" y=\"78\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">healthy, and fixing</text><text x=\"550\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">will not fix what matters</text></svg>", "caption": "Pinning is the floor every package stands on; updating and replacing are the two decisions made on top of it."}
```

### Reading a package's health

Before choosing a move, look at the package as a project rather than as a version number. Four
questions, each with a place to read the answer:

- **Is it maintained?** The release history: how recently, how regularly, and whether old majors
  still get fixes.
- **Who maintains it?** The repository's recent commits: one person or many, and whether the people
  who wrote it are still the ones merging.
- **What does it pull in?** Its own dependencies, which are yours too.
- **What is open against it?** Advisories with no fixed version, and the maintainers' answer to them.

How many other projects depend on it matters as well, because a package with many dependants is
watched by many eyes and is also a bigger prize. Services such as deps.dev and libraries.io answer
that question; neither could be reached from the recording machine, so it is named here and not shown.

### What linkbox actually depends on

`requirements.txt` from lesson 5 names eight packages, and two of them are what linkbox asked for.
`uv pip tree` shows who pulls in what, in the virtual environment built from those pins:

```
ana@vm:~/linkbox$ uv pip tree --package gunicorn --package flask
flask v3.1.3
├── blinker v1.9.0
├── click v8.1.7
├── itsdangerous v2.2.0
├── jinja2 v3.1.6
│   └── markupsafe v2.1.3
├── markupsafe v2.1.3
└── werkzeug v3.1.9
    └── markupsafe v2.1.3
gunicorn v22.0.0
└── packaging v26.3
```

Two trees. Flask brings six packages, and **gunicorn brings `packaging`**, which is the package lesson
13's bill of materials found in the image although no requirements file ever named it. It got there
because gunicorn 22 declares it as a dependency, and lesson 5's flat list of pins could not say so.

### gunicorn as a project

PyPI answers the first question for any package with a JSON document. The last twelve releases of
gunicorn, by the date their first file was uploaded:

```
ana@vm:~/linkbox$ curl -s https://pypi.org/pypi/gunicorn/json | jq -r ".releases | to_entries[] | select(.value | length > 0) | \"\(.value[0].upload_time[:10]) \(.key)\"" | sort | tail -n 12
2026-01-23 24.1.0
2026-01-24 24.1.1
2026-02-01 25.0.0
2026-02-02 25.0.1
2026-02-06 25.0.2
2026-02-07 25.0.3
2026-02-13 25.1.0
2026-03-24 25.2.0
2026-03-27 25.3.0
2026-05-05 26.0.0
2026-08-18 26.1.0
2026-08-24 26.2.0
ana@vm:~/linkbox$ for v in 22.0.0 26.2.0; do echo "$v: $(curl -s https://pypi.org/pypi/gunicorn/$v/json | jq -c "[.info.requires_dist[] | select(contains(\"extra\") | not)]")"; done
22.0.0: ["packaging","importlib-metadata; python_version < \"3.8\""]
26.2.0: []
```

Four major versions since the 22 that linkbox pins, the most recent in August, and regular minor
releases in between. That is a project moving, which is good news for its health and a cost for
whoever stays behind: **the further a pin falls behind, the larger the jump when an advisory forces
it.** The second command lists what each version requires outside its optional extras. gunicorn 22
requires `packaging` outright; gunicorn 26 requires nothing at all, and names `packaging` only under
extras linkbox does not install.

So an update of gunicorn would take one package out of the image as well as moving the server
forward four majors. That is a decision with a changelog to read, and a later section of this lesson
makes it. First the pins need to become something an update can be measured against.
