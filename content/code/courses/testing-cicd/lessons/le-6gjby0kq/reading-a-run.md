---
title: Reading a real run
version: 2
---

`shipquote`'s workflow has never run on GitHub. The repository that publishes this course runs its
own on every pull request and every merge, and GitHub keeps a record of each run that anybody can
read through its public API, since the repository is public. This section reads one of them: the
run triggered by merging the previous course's pull request, on 6 October 2026.

`A` is just the API's address for this repository's Actions, to keep the commands short. Set it
with `A=https://api.github.com/repos/codeschool-ing/schooling/actions` and the commands below work
in your own terminal; curl and jq are the ones lesson 1 installed:

```
ana@laptop:~$ echo $A
https://api.github.com/repos/codeschool-ing/schooling/actions
ana@laptop:~$ curl -s $A/runs/37488673045 | jq -r "[.name, .event, .head_sha[:7], .conclusion, .run_started_at, .updated_at] | @tsv"
Continuous Integration	push	102e766	success	2026-10-06T15:34:36Z	2026-10-06T15:40:47Z
ana@laptop:~$ curl -s $A/runs/37488673045/jobs | jq -r ".jobs[] | [.name, .conclusion, .started_at, .completed_at] | @tsv"
Changes	success	2026-10-06T15:34:40Z	2026-10-06T15:34:49Z
Go	success	2026-10-06T15:34:52Z	2026-10-06T15:38:08Z
Browser	success	2026-10-06T15:34:52Z	2026-10-06T15:40:46Z
Infra	success	2026-10-06T15:34:52Z	2026-10-06T15:35:15Z
```

The run is the **Continuous Integration** workflow, started by a `push`, on commit `102e766`, and it
succeeded. It started at 15:34:36 UTC and was last updated at 15:40:47, a little over six minutes.

The jobs tell the shape. `Changes` ran first, alone, for nine seconds: it is the job that decides
which of the others the change can affect. The three others all started at 15:34:52, the moment
`Changes` finished, and ran **in parallel**: `Infra` finished in 23 seconds, `Go` in a little over
three minutes, and `Browser` in almost six. **The run took as long as its slowest job**, which is
lesson 5 section 10's remark about parallel cells, measured.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A timeline of run 37488673045 of this repository's CI, from 15:34:36 to 15:40:47 UTC. Changes runs alone first, for 9 seconds. Then Infra, Go and Browser all start at 15:34:52 and run in parallel: Infra takes 23 seconds, Go 3 minutes 16 seconds and Browser 5 minutes 54 seconds. The run ends when Browser does.\"><text x=\"128\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Changes</text><rect x=\"145.8\" y=\"40\" width=\"13.1\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><text x=\"166.92183288409703\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">9s</text><text x=\"128\" y=\"94\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Infra</text><rect x=\"163.3\" y=\"82\" width=\"33.5\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><text x=\"204.76549865229111\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">23s</text><text x=\"128\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Go</text><rect x=\"163.3\" y=\"124\" width=\"285.3\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><text x=\"456.57142857142856\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3m16s</text><text x=\"128\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Browser</text><rect x=\"163.3\" y=\"166\" width=\"515.3\" height=\"24\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"681.5\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5m54s</text><path d=\"M140.0 210 L140.0 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"140.0\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">+0 min</text><path d=\"M227.3 210 L227.3 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"227.33153638814017\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">+1 min</text><path d=\"M314.7 210 L314.7 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"314.66307277628033\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">+2 min</text><path d=\"M402.0 210 L402.0 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"401.99460916442047\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">+3 min</text><path d=\"M489.3 210 L489.3 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"489.32614555256066\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">+4 min</text><path d=\"M576.7 210 L576.7 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"576.6576819407009\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">+5 min</text><path d=\"M664.0 210 L664.0 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"663.9892183288409\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">+6 min</text><path d=\"M140 210 L680 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"140\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">minutes after the run started; the run ends when its slowest job does</text></svg>", "caption": "The same four jobs as the listing above, drawn against the clock. One short job decides, three run side by side, and the longest of the three is the length of the run."}
```

## Inside a job

Each job's steps carry their own start and end times. Here are the five slowest steps of the `Go`
job, in seconds:

```
ana@laptop:~$ curl -s $A/runs/37488673045/jobs | jq -r ".jobs[] | select(.name == \"Go\") | .steps[] | [.number, .name, ((.completed_at | fromdate) - (.started_at | fromdate))] | @tsv" | sort -t$'\t' -k3 -nr | head -5
19	The tests, with a database behind them	141
6	Nothing drops an error on the floor	12
4	Run actions/setup-go@b7ad1dad31e06c5925ef5d2fc7ad053ef454303e	9
2	Initialize containers	7
3	Run actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0	5
```

One step dominates: **141 seconds** for the Go test suite against a real PostgreSQL, the step named
*The tests, with a database behind them*. The next, a check that no error is silently dropped, took
12. Setting up Go, starting the database container and checking out the code take seconds each.
That is a typical profile, and it says where to look first if the job ever gets slow: not the
setup, which a cache would shorten, but the suite itself.

## Steps named after what they promise

Notice the step names. This repository does not name a step `Run tests` or `go test`; it names it
after the property it checks: *The tests, with a database behind them*, *Nothing drops an error on
the floor*. When a step goes red in a list of thirty, the name is the first thing anybody reads, and
a name that says what is now false saves opening the log. It is the same advice lesson 1 gave for
naming tests, one level up.

## What the record is for

The API returns the same data the web page draws: jobs, steps, timings, conclusions. Reading it from
a script is how teams answer questions the page cannot: which job got slower this month, how often
`main` is red, how long a pull request waits for its checks. In the `tech-lead` track, `delivery-metrics`
builds measures like those into the four numbers it teaches.
