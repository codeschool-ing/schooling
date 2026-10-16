---
title: The same run, in a pipeline
version: 1
---

**A pipeline is a machine that runs your commands every time the code changes, and stops the change
when a command exits with anything but 0.** Everything in it is something you could type. The work is
in getting the order right: a fresh machine has no Newman, no boxoffice running and no `node_modules`,
so the pipeline has to build each of those before the run, and keep the report after it whatever
happened.

This one is for GitHub Actions, which runs a workflow file kept in the repository. Make the directory
with `mkdir -p .github/workflows`, then save it as `.github/workflows/api-tests.yml`:

```yaml
name: api tests

on: [push, pull_request]

jobs:
  newman:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1

      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        with:
          node-version: 22
          cache: npm

      - name: install Newman
        run: npm ci --no-audit --no-fund

      - name: start boxoffice
        run: node boxoffice.mjs > boxoffice.log 2>&1 &

      - name: wait for /health
        run: |
          for i in $(seq 30); do
            curl -sf localhost:8080/health > /dev/null && exit 0
            sleep 1
          done
          echo "boxoffice did not start"
          cat boxoffice.log
          exit 1

      - name: run the collection
        run: npm run test:api -- --reporters cli,junit --reporter-junit-export results/newman.xml

      - name: keep the report
        if: always()
        uses: actions/upload-artifact@cf430e030ddbb5b0abf93d22962f4752f3646cd9 # v7.0.2
        with:
          name: newman-report
          path: |
            results/newman.xml
            boxoffice.log
```

**This workflow was not run on GitHub for this course**: the machine the transcripts come from cannot
act as a GitHub runner. Its steps are run locally at the end of this section, which is the honest half
of the check. The other half is yours: push the repository to GitHub, and the run appears under the
repository's **Actions** tab.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 214\" role=\"img\" aria-label=\"The workflow runs on an empty machine in order: checkout of the repository, setup-node with Node 22, npm ci from the lock file, start boxoffice in the background, and wait for /health. Then it runs the collection with npm run test:api, whose exit code makes the job green on 0 or red on 1. Last, pass or fail, it keeps the report, a step marked if: always().\"><defs><marker id=\"f06pipeline-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"40\" width=\"104\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"66\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">checkout</text><text x=\"66\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the repository</text><line x1=\"118\" y1=\"63\" x2=\"136\" y2=\"63\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f06pipeline-ah)\"></line><rect x=\"136\" y=\"40\" width=\"104\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"188\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">setup-node</text><text x=\"188\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Node 22</text><line x1=\"240\" y1=\"63\" x2=\"258\" y2=\"63\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f06pipeline-ah)\"></line><rect x=\"258\" y=\"40\" width=\"104\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"310\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">npm ci</text><text x=\"310\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">from the lock</text><line x1=\"362\" y1=\"63\" x2=\"380\" y2=\"63\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f06pipeline-ah)\"></line><rect x=\"380\" y=\"40\" width=\"104\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"432\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">start</text><text x=\"432\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">boxoffice &amp;</text><line x1=\"484\" y1=\"63\" x2=\"502\" y2=\"63\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f06pipeline-ah)\"></line><rect x=\"502\" y=\"40\" width=\"104\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"554\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">wait</text><text x=\"554\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/health</text><text x=\"350\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">every run starts on an empty machine</text><line x1=\"570\" y1=\"86\" x2=\"570\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f06pipeline-ah)\"></line><rect x=\"470\" y=\"130\" width=\"200\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">run the collection</text><text x=\"570\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">npm run test:api</text><line x1=\"470\" y1=\"153\" x2=\"352\" y2=\"153\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f06pipeline-ah)\"></line><rect x=\"150\" y=\"130\" width=\"200\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"250\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">keep the report</text><text x=\"250\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">if: always()</text><text x=\"410\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pass or fail</text><text x=\"570\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its exit code is the job: 0 green, 1 red</text><text x=\"250\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">runs even after a failure</text></svg>", "caption": "Five steps build what a laptop already had, one step decides the result, and one keeps the evidence whatever the result was."}
```

## The steps, in order

- `on: [push, pull_request]` runs it on every push and every pull request. `runs-on: ubuntu-24.04`
  asks for a fresh Ubuntu machine, the same system as the course's transcripts.
- `checkout` copies the repository onto that machine. Nothing else is there until it does.
- `setup-node` installs Node 22, and `cache: npm` keeps npm's downloads between runs, keyed on
  `package-lock.json`, so the second run installs faster.
- `npm ci` installs exactly what `package-lock.json` lists, and fails if `package.json` and the lock
  disagree. That is why the lock is committed, and why `npm install`, which may update it, is the
  wrong command here. `--no-audit --no-fund` leaves out the two reports section 02 already read.
- `node boxoffice.mjs ... &` starts boxoffice in the background. The `&` matters: without it the step
  would wait for a server that never exits, and the job would hang until GitHub killed it.
- *wait for /health* asks once a second for up to thirty seconds. Starting a server and using it in
  the next line is a race the server sometimes loses; asking until it answers is not. If it never
  answers, the step prints boxoffice's log and fails, so the reason is in the log rather than in a
  wall of refused connections.
- *run the collection* is `npm run test:api` with the JUnit reporter added. Its exit code decides
  whether the job is green.
- *keep the report* uploads the JUnit file and boxoffice's log as an *artifact*, a file you can
  download from the run's page. `if: always()` runs it even after the step before failed, which is
  exactly when the report is wanted.

boxoffice starts with its built-in lab secret here, because `.env` is ignored by git and never reaches
the runner. A real service would take its secret from the repository's encrypted secrets, as lesson 3
said, and so would the client secret in the environment file, passed to Newman with
`--env-var clientSecret=...` instead of written in a committed file.

## Why each action is pinned to a commit

`actions/checkout@3d3c42e…` names one commit, and the comment says which release it was. Most examples
write `actions/checkout@v7`, which is a tag, and **a tag is a pointer its owner can move**. A moved tag
changes the code that runs in your pipeline, with your repository's permissions, without a line of
your repository changing. Tags of popular actions have been moved maliciously before, and a commit
hash cannot be. The comment exists because a hash says nothing to a person: when the time comes to
update, it tells you from which version.

## The same steps, on your machine

A pipeline that fails on its first push is debugged one push at a time. Run its steps locally first.
This script does what the workflow does, in the same order, and stops the server at the end.
Save it as `ci-local.sh`:

```sh
#!/usr/bin/env bash
# ci-local.sh: the pipeline's steps, in the same order, on your own machine.
set -u
npm ci --no-audit --no-fund

node boxoffice.mjs > boxoffice.log 2>&1 &
server=$!

for i in $(seq 30); do
  curl -sf localhost:8080/health > /dev/null && break
  sleep 1
done
if ! curl -sf localhost:8080/health > /dev/null; then
  echo "boxoffice did not start"
  cat boxoffice.log
  kill $server
  exit 1
fi

npm run test:api -- --reporters cli,junit --reporter-junit-export results/newman.xml
status=$?
kill $server
exit $status
```

Stop boxoffice in its own terminal first, with Ctrl-C, because the script starts its own on the same
port. Then:

```
ana@laptop:~/boxoffice$ bash ci-local.sh; echo "exit code $?"
npm warn deprecated har-validator@5.1.5: this library is no longer supported
npm warn deprecated uuid@3.4.0: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
npm warn deprecated uuid@8.3.2: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
npm warn deprecated @faker-js/faker@5.5.3: Please update to a newer version.

added 148 packages in 3s

> boxoffice@1.0.0 test:api
> newman run postman/boxoffice.postman_collection.json -e postman/lab.postman_environment.json --disable-unicode --reporters cli,junit --reporter-junit-export results/newman.xml

newman

boxoffice

Folder shows
Sub-folder List shows
  POST http://localhost:8080/oauth/token [200 OK, 479B, 26ms]
  GET http://localhost:8080/v1/shows [200 OK, 569B, 3ms]
  Pass  status is 200
  Pass  the body is JSON
  Pass  every show has a whole number of seats left

Sub-folder One show
  GET http://localhost:8080/v1/shows/sh-103 [200 OK, 312B, 2ms]
  Pass  status is 200
  Pass  it is the show asked for
  Pass  it carries an etag

Sub-folder HEAD one show
  HEAD http://localhost:8080/v1/shows/sh-103 [405 Method Not Allowed, 171B, 4ms]
  1. HEAD answers like GET

Folder auth
Sub-folder Get token
  POST http://localhost:8080/oauth/token [200 OK, 479B, 4ms]
  Pass  status is 200
  Pass  a bearer token comes back
  Pass  nobody may keep a copy of it

Folder orders
Sub-folder Create order
  POST http://localhost:8080/v1/orders [201 Created, 316B, 4ms]
  Pass  status is 201
  Pass  the order is for the show and the seat asked for
  Pass  location says where it lives

Sub-folder Read order
  GET http://localhost:8080/v1/orders/ord-1001 [200 OK, 280B, 4ms]
  Pass  status is 200
  Pass  it is the order just created

Sub-folder Cancel order
  DELETE http://localhost:8080/v1/orders/ord-1001 [204 No Content, 111B, 2ms]
  Pass  status is 204

Sub-folder Read cancelled order
  GET http://localhost:8080/v1/orders/ord-1001 [200 OK, 280B, 6ms]
  Pass  the order now says cancelled

Folder seat rules
Sub-folder Order seats
  POST http://localhost:8080/v1/orders [201 Created, 316B, 3ms]
  Pass  seats 1 answers 201

---------------------------------------------------------------
|                         |        executed |          failed |
--------------------------+-----------------+------------------
|              iterations |               1 |               0 |
--------------------------+-----------------+------------------
|                requests |              10 |               0 |
--------------------------+-----------------+------------------
|            test-scripts |               9 |               0 |
--------------------------+-----------------+------------------
|      prerequest-scripts |              11 |               0 |
--------------------------+-----------------+------------------
|              assertions |              18 |               1 |
---------------------------------------------------------------
| total run duration: 267ms                                   |
---------------------------------------------------------------
| total data received: 1.55kB (approx)                        |
---------------------------------------------------------------
| average response time: 5ms [min: 2ms, max: 26ms, s.d.: 6ms] |
---------------------------------------------------------------

  #  failure         detail                                                
                                                                           
 1.  AssertionError  HEAD answers like GET                                 
                     expected response to have status code 200 but got 405 
                     at assertion:0 in test-script                         
                     inside "shows / HEAD one show"                        
exit code 1
```

`npm ci` removed `node_modules` and installed it again from the lock, which is the clean start a
runner has. boxoffice started, answered `/health`, and the run is the run of section 03, with one
failure and exit code 1, which is what the pipeline will report until boxoffice answers `HEAD`.
**A red pipeline here is the correct result**: it is the defect report of lesson 1, run on every push.

What the project should now hold, as git sees it:

```
ana@laptop:~/boxoffice$ git status --short
?? .github/
?? .gitignore
?? boxoffice.mjs
?? ci-local.sh
?? openapi.yaml
?? package-lock.json
?? package.json
?? postman/
```

`node_modules/` and `results/` are absent, as `.gitignore` says. Everything listed is what a fresh
checkout needs to run the pipeline, and nothing more.
