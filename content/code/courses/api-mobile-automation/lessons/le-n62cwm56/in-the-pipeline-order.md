---
title: Starting services in order, in a pipeline
version: 1
---

**On your machine you start the services by hand, in terminals, and you can see when each is ready.
A pipeline has no eyes.** It runs commands one after another as fast as it can. A script that starts
boxoffice and runs the tests on the next line sends its first request before Node has finished
loading boxoffice. The test fails with a refused connection that has nothing to do with the code.
The fix is the same at every scale, from two Node programs to a dozen containers: start each service
after what it needs, and wait until it answers before going on.

The race is easy to show. Stop boxoffice and the stub with Ctrl-C in their terminals. This line
starts boxoffice in the background with `&` and asks for `/health` straight away. `$!` is the process
just started, so `kill $!` stops it again:

```
ana@laptop:~/boxoffice$ node boxoffice.mjs > /dev/null & curl -s localhost:8080/health; echo "curl: $?"; kill $!
curl: 7
```

Exit code 7, *failed to connect*: curl was faster than Node.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 280\" role=\"img\" aria-label=\"Two timelines. Without waiting, the first test request arrives while boxoffice is still loading, before it is listening, and is refused. With wait_for, curl asks every tenth of a second while boxoffice loads and gets no answer; the first answer comes once boxoffice is listening, and only then do the tests run.\"><defs><marker id=\"f12startup-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">without waiting</text><line x1=\"20\" y1=\"70\" x2=\"680\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"60\" y=\"48\" width=\"180\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">boxoffice loading</text><rect x=\"250\" y=\"48\" width=\"110\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"305\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">listening</text><line x1=\"90\" y1=\"110\" x2=\"90\" y2=\"82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f12startup-ah)\"></line><text x=\"90\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">first test request: refused</text><text x=\"20\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">with wait_for</text><line x1=\"20\" y1=\"210\" x2=\"680\" y2=\"210\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"60\" y=\"188\" width=\"180\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">boxoffice loading</text><rect x=\"250\" y=\"188\" width=\"110\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"305\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">listening</text><line x1=\"90\" y1=\"240\" x2=\"90\" y2=\"222\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"130\" y1=\"240\" x2=\"130\" y2=\"222\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"170\" y1=\"240\" x2=\"170\" y2=\"222\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"210\" y1=\"240\" x2=\"210\" y2=\"222\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"150\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">curl every 0.1 s: no answer yet</text><line x1=\"275\" y1=\"240\" x2=\"275\" y2=\"222\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f12startup-ah)\"></line><rect x=\"400\" y=\"188\" width=\"150\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"475\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the tests run</text><line x1=\"362\" y1=\"203\" x2=\"398\" y2=\"203\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f12startup-ah)\"></line><text x=\"275\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the first answer starts the tests</text><text x=\"680\" y=\"232\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">time</text></svg>", "caption": "A script that waits for an answer starts the tests at the first moment they can pass; one that does not wait races the server and loses."}
```

## The script

It starts the stub and waits until the stub answers. It starts boxoffice pointed at the stub and
waits until `/health` answers. Then it runs every test, and stops both servers whatever happened. In
`~/boxoffice`, save it as `run-integration.sh`:

```sh
#!/usr/bin/env bash
# run-integration.sh: start what the tests need, in order, wait until each
# answers, run every test, and stop it all whatever happened.
set -uo pipefail
cd "$(dirname "$0")"

# wait_for URL NAME: until URL answers, for at most five seconds.
wait_for() {
  for _ in $(seq 50); do
    curl -s -o /dev/null "$1" && return 0
    sleep 0.1
  done
  echo "$2 did not answer at $1; its log:" >&2
  cat "$3" >&2
  return 1
}

# A server left running from earlier would answer every health check below
# while the one this script starts dies on a port in use.
for port in 8080 8090; do
  if curl -s -o /dev/null "http://localhost:$port/"; then
    echo "something already answers on port $port; stop it first" >&2
    exit 1
  fi
done

node payments-stub.mjs > stub.log 2>&1 &
STUB=$!
trap 'kill $STUB ${API:-} 2>/dev/null' EXIT
wait_for http://localhost:8090/__requests 'the payments stub' stub.log || exit 1

PAYMENTS_URL=http://localhost:8090 node boxoffice.mjs > boxoffice.log 2>&1 &
API=$!
wait_for http://localhost:8080/health boxoffice boxoffice.log || exit 1

status=0
node --test --test-reporter=tap --test-reporter-destination=test-results.tap 'tests/*.test.mjs' || status=$?
grep -E '^not ok|^# (tests|pass|fail|todo)' test-results.tap
exit $status
```

The parts, in the order they run:

| part | what it does | the failure it prevents |
|---|---|---|
| `wait_for` | asks a URL every tenth of a second, for five seconds at most, and prints the server's log if it never answers | a fixed `sleep` that is too short on a slow runner and wasted on a fast one |
| the port check | refuses to start when something already answers on 8080 or 8090 | a health check answered by an old server, while the new one died on a port in use |
| `trap … EXIT` | kills both servers when the script ends, by success, failure or Ctrl-C | servers left running in the background, holding the ports for the next run |
| `'tests/*.test.mjs'` | names the test files instead of letting Node search | Node's default search also takes any `.js` under a directory called `test`, and lesson 8's `karate/src/test/java/karate-config.js` is one |
| `status` | keeps the exit code of `node --test` and ends the script with it | a pipeline that goes green because the last command, `grep`, succeeded |

**The port check is the one people leave out.** Without it, a boxoffice left running in a terminal
answers `/health`. The script's own boxoffice exits on `EADDRINUSE` into a log nobody reads, and the
tests run against a server with an unknown history. Start boxoffice and the stub again in their
terminals, the way a pair left over from the afternoon would be, and run the script:

```
ana@laptop:~/boxoffice$ bash run-integration.sh
something already answers on port 8080; stop it first
ana@laptop:~/boxoffice$ echo $?
1
```

That is the right refusal. Stop both with Ctrl-C in their terminals and run it again:

```
ana@laptop:~/boxoffice$ bash run-integration.sh
not ok 9 - HEAD answers like GET, without a body # TODO boxoffice answers HEAD with 405, lesson 1
# tests 9
# pass 8
# fail 0
# todo 1
ana@laptop:~/boxoffice$ echo $?
0
```

Every test file in `tests/` ran: the ones that use the shared servers and the ones that start their
own. The HEAD test is the one `not ok`, marked `# TODO`, and the exit code is 0. The full report is
in `test-results.tap`. A pipeline keeps that file as an artefact, beside the two servers' logs.
After the script, nothing is listening any more:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/health; echo "curl: $?"
curl: 7
ana@laptop:~/boxoffice$ ls *.log *.tap
boxoffice.log  shows.tap  slow.tap  stub.log  test-results.tap
```

## In a real pipeline

A CI job runs exactly this. It checks out the code and sets up Node 22 as lesson 6's workflow did.
Then comes one step, `bash run-integration.sh`, and an upload of `test-results.tap` and the logs. The
upload runs even when the step fails, because that is when the files are needed. The script was not
run on a CI service for this course. It was run here, as shown, and a runner executes the same
commands.

When the services are containers, the same ideas carry other names. Docker Compose's `depends_on`
with `condition: service_healthy` waits for a health check rather than for a process to exist; that
is `wait_for`. In GitHub Actions, a job's `services:` block starts databases and stubs beside the
job, with health checks of their own. Neither changes the rule: **start in order of need, wait for an
answer, never for a number of seconds.**
