---
title: The contract between a container and Cloud Run
version: 1
---

The first thing to unlearn about Cloud Run is that it runs servers. **It runs containers that
answer requests, and it starts and stops them as requests come and go.** You never see a machine,
never choose one, and are never told which one ran your code. What you get in exchange is a short
list of promises your container has to keep, and if it keeps them, Cloud Run takes care of the
rest: the address, the certificate, the load balancing, the number of copies, and the copies
nobody needs.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A client reaches Cloud Run's front end over HTTPS at a stable address. The front end, which Google runs, owns the certificate, the scaling and the routing, and forwards each request as plain HTTP to the port in PORT inside a container instance. The container, which you write, must listen on 0.0.0.0 on that port, keep no state, answer within the timeout and stop within ten seconds of SIGTERM.\"><defs><marker id=\"l8c-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"110\" width=\"110\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"71.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">a client</text><path d=\"M126 135 L176 135\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8c-ah)\"></path><text x=\"151\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HTTPS</text><rect x=\"176\" y=\"40\" width=\"210\" height=\"220\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"281\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">Google runs this</text><rect x=\"196\" y=\"80\" width=\"170\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"281.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">front end</text><text x=\"281.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a stable address</text><rect x=\"196\" y=\"136\" width=\"170\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"281.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">the certificate</text><rect x=\"196\" y=\"178\" width=\"170\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"281.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">how many instances</text><rect x=\"196\" y=\"220\" width=\"170\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"281.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">routing to revisions</text><path d=\"M410 30 L410 280\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"410\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">the contract</text><path d=\"M366 102 L450 102\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8c-ah)\"></path><text x=\"388\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HTTP</text><text x=\"388\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">$PORT</text><rect x=\"450\" y=\"40\" width=\"254\" height=\"220\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"577\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">you write this</text><rect x=\"470\" y=\"80\" width=\"214\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"577.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">your container</text><text x=\"577.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0.0.0:$PORT</text><text x=\"477\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">keeps no state between requests</text><text x=\"477\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">answers within the timeout</text><text x=\"477\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">logs one JSON line per entry</text><text x=\"477\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">stops within 10 s of SIGTERM</text></svg>", "caption": "The line between the two halves is the contract. Everything left of it is Google's; everything right of it is yours, and runs the same on a laptop."}
```

## What the container promises

Google calls it the **container runtime contract**, and five parts of it shape every program in
this lesson:

1. **Listen on the port in `PORT`**, on every interface, `0.0.0.0`. Cloud Run sets the variable,
   8080 unless you change it, and sends requests there. A server that listens on `127.0.0.1`
   answers nobody, because the requests arrive from outside the container's loopback.
2. **Start quickly, and say so by listening.** An instance is not sent requests until something is
   listening on the port; Cloud Run's default startup probe is exactly that check. A program that
   spends a minute loading before it opens the port is a minute of every cold start.
3. **Answer each request within its timeout**, five minutes unless configured, and at most sixty.
   A request is the unit of work: a service that answers at once and keeps working in the
   background is relying on CPU it may not get, which lesson 11 explains.
4. **Keep nothing that must survive.** The file system is writable, but it lives in the instance's
   memory and vanishes with the instance; the memory itself is gone the moment Cloud Run decides
   the instance is idle. State goes to a database, a bucket or a queue.
5. **Stop when told.** Before an instance is shut down it receives `SIGTERM`, and has ten seconds
   to finish before it is killed with `SIGKILL`. That is the time to finish a request in flight
   and flush a log, not to start anything new.

Two more are about the image rather than the program. It must be built for **`linux/amd64`**,
because that is what Cloud Run executes; an image built on an Arm laptop for Arm will not start.
And it must be in a registry Cloud Run can read, normally Artifact Registry in the same project.

## What Cloud Run promises back

In return, the platform sets a few things your program can read and rely on. `PORT` is one.
`K_SERVICE`, `K_REVISION` and `K_CONFIGURATION` name the service, the revision and the
configuration serving the request, which is how a log line says where it came from. Every request
arrives over **HTTPS at a stable address**, with the certificate managed for you, and reaches your
container as plain HTTP on `PORT`. And everything the program writes to standard output or
standard error goes to **Cloud Logging**, with one JSON object per line read as a structured entry.

**None of this needs Google to try.** A container that keeps the contract runs on your laptop
with `docker run` exactly as it will on Cloud Run, and the next two sections build one and run it.
What does need Google, and is taught from its documentation, is everything around the container:
the address, the scaling and the billing, which section 05 covers.

## The wrong picture, named

The picture most people bring is a small server that is always there, like a machine of lesson 1
with less to manage. It is wrong in three ways that each cost somebody a weekend:

- **instances are disposable**, so anything kept in memory between requests is a cache at best;
- **there may be none at all**, so the first request after a quiet hour waits for one to start;
- **there may be a hundred**, so anything that assumes one copy, a counter in memory or a file on
  local disk, is wrong the moment traffic arrives.

A program written for that picture works perfectly in the developer's single test and fails in
production in a way that looks random, because the bug depends on which instance a request
happened to reach.
