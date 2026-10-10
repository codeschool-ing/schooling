---
title: IX, disposability
version: 1
---

A platform stops processes all the time: to deploy a new release, to move work off a machine being
repaired, to scale down at night. **A disposable process starts fast and stops gracefully**, so that
none of that is an event anybody notices.

Stopping is a conversation with two messages. Docker, like Kubernetes and nearly every platform,
first sends **SIGTERM**, which means "finish up and exit". If the process is still there after a grace
period, ten seconds by default in Docker and thirty in Kubernetes, it sends **SIGKILL**, which cannot
be caught and ends the process wherever it was.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two timelines starting when Docker sends SIGTERM. In the first, the program has a handler: it finishes the request in progress and exits after about one second. In the second, the program has no handler and ignores the signal; Docker waits the full ten seconds and then sends SIGKILL, cutting off whatever was running.\"><defs><marker id=\"l4-sigterm-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M90 190 L690 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-sigterm-ah-wire)\"></path><text x=\"90\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0 s</text><text x=\"140\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1 s</text><text x=\"340\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5 s</text><text x=\"590\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10 s</text><text x=\"26\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">handler</text><rect x=\"90\" y=\"44\" width=\"50\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">exit</text><text x=\"26\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">ignored</text><rect x=\"90\" y=\"114\" width=\"500\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"340\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">waiting for a process that will not stop</text><rect x=\"592\" y=\"114\" width=\"90\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"637\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">SIGKILL</text></svg>", "caption": "With a handler, stopping takes as long as the work in progress. Without one, it takes Docker's whole grace period and ends with a kill."}
```

## The catalogue, which listens

The catalogue installs a handler for SIGTERM: stop taking new connections, let the requests in
progress finish, exit. Stop the three copies and time it:

```
ana@vm:~/lab/twelve$ time docker compose stop catalogue
 Container twelve-catalogue-2 Stopping 
 Container twelve-catalogue-1 Stopping 
 Container twelve-catalogue-3 Stopping 
 Container twelve-catalogue-3 Stopped 
 Container twelve-catalogue-2 Stopped 
 Container twelve-catalogue-1 Stopped 

real	0m0.855s
user	0m0.063s
sys	0m0.076s
ana@vm:~/lab/twelve$ docker compose logs catalogue | grep -E "SIGTERM|stopped"
catalogue-1  | 4ed40453cdac SIGTERM: finishing requests in progress, then exiting
catalogue-1  | 4ed40453cdac stopped
catalogue-2  | a3b89e5e7e5f SIGTERM: finishing requests in progress, then exiting
catalogue-2  | a3b89e5e7e5f stopped
catalogue-3  | 280702d81305 SIGTERM: finishing requests in progress, then exiting
catalogue-3  | 280702d81305 stopped
```

Under a second for three processes, and the log of each one says it saw the signal and stopped in
order.

## A program that does not listen

Here is the same thing with a Python process that has no handler, a one-line program that sleeps:

```
ana@vm:~/lab/twelve$ docker run -d --name sleeper python:3.12-slim python -c "import time; time.sleep(3600)"
696c76de8d517be8c237fd4bb78563e04a12c5d6551ce05d28515ad5eaacd98d
ana@vm:~/lab/twelve$ time docker stop sleeper
sleeper

real	0m10.209s
user	0m0.013s
sys	0m0.034s
ana@vm:~/lab/twelve$ docker inspect --format "{{.State.ExitCode}}" sleeper
137
```

**Ten seconds**, for a program that was doing nothing, and an exit code of 137, which lesson 1
explained: 128 plus signal 9, SIGKILL. The process was the container's first
process, PID 1, and the Linux kernel gives PID 1 special treatment: a signal it has no handler for is
not acted on at all, so SIGTERM was ignored and Docker waited out the grace period before killing it.
A web server that ignores SIGTERM in the same way loses every request in progress at the end of those
ten seconds, on every deploy.

There are three ways out, and any one is enough: handle SIGTERM in the program, as the catalogue
does; run the program under a small init process that forwards signals, which `docker run --init`
adds; or make sure the program the image starts is the one that handles signals, rather than a shell
script that started it and swallows them.

## Starting fast

The other half is start-up. A process that takes two minutes to start makes every deploy, every
recovery from a crash and every scale-up two minutes slower, and lesson 3's cold starts are the same
cost paid by a function. Load what is needed lazily, do not build caches at start-up that can be built
on first use, and **let the platform's health check, lesson 19, say when the process is ready**, rather
than the platform guessing.
