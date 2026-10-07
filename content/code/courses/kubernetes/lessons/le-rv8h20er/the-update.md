---
title: An update that drops requests
version: 1
---

Version 1.1 of the shop is ready. **On one machine, replacing a running container means stopping it
first**, because the new one needs the same name and the same port, and the gap between the two is
something a customer can hit. This section measures that gap rather than asserting it.

The measurement is a small script that asks the shop 300 times, twenty milliseconds apart, and
writes down only the status code of each answer. It is `~/shop/probe.sh`, made runnable with
`chmod +x probe.sh`:

```sh
#!/bin/sh
# Ask the shop 300 times, 20 ms apart, and print each answer's status code.
# 000 means curl got no answer at all.
for i in $(seq 300); do
  curl -s -o /dev/null -m 1 -w '%{http_code}\n' localhost:8080
  sleep 0.02
done
```

Ana changes the image in `compose.yaml`, then starts the probe in the background and runs
`docker compose up -d` while it is still asking:

```
ana@laptop:~/shop$ sed -i "s/shop:1.0/shop:1.1/" compose.yaml
ana@laptop:~/shop$ ./probe.sh > codes.txt & docker compose up -d; wait
 Container shop-web-1 Recreate 
 Container shop-web-1 Recreated 
 Container shop-web-1 Starting 
 Container shop-web-1 Started 
ana@laptop:~/shop$ sort codes.txt | uniq -c
     12 000
    288 200
```

**Twelve of the 300 requests got no answer at all**, four in every hundred. The `000` is curl's
way of saying the connection was refused: for that moment nothing was listening on port 8080,
because Compose had stopped the 1.0 container (`Recreate`) and the 1.1 one was not yet serving.

```
ana@laptop:~/shop$ curl -s localhost:8080
shop 1.1 on cdb0f6d432ff
```

The new answer names a new hostname, `cdb0f6d432ff` instead of `7f1b64994482`: this is a different
container, not the old one updated in place. A container is never changed, only replaced, and the
replacement is where the gap comes from.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two timelines of an update. Above, what Compose did: the 1.0 container serves, is stopped, there is a gap where nothing listens and 12 of 300 requests got no answer, then 1.1 serves. Below, the order an orchestrator uses: 1.1 starts and becomes ready while 1.0 still serves, traffic moves, and only then 1.0 stops, so there is no gap.\"><defs><marker id=\"gap-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"gap-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">docker compose up -d</text><text x=\"20\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">stop, then start</text><rect x=\"180\" y=\"22\" width=\"220\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop 1.0</text><rect x=\"400\" y=\"22\" width=\"70\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"435.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">nothing listens</text><rect x=\"470\" y=\"22\" width=\"230\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop 1.1</text><text x=\"435\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">12 of 300 refused</text><text x=\"20\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a rolling update</text><text x=\"20\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">start, wait, then stop</text><rect x=\"180\" y=\"112\" width=\"290\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop 1.0</text><rect x=\"380\" y=\"152\" width=\"320\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop 1.1</text><path d=\"M430 185 L430 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"430\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">ready</text><text x=\"500\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">stopped</text><path d=\"M180 222 L700 222\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gap-ah-wire)\"></path></svg>", "caption": "The gap comes from the order: Compose stops the old container before the new one serves. Reversing the order needs two copies at once and something to move the traffic between them."}
```

## Why Compose cannot close the gap here

To update without a gap, the order has to be the other way round: **start the new copy, wait until
it answers, move the traffic to it, and only then stop the old one.** That needs three things this
setup does not have:

- two copies at once, which the previous section showed is impossible on one published port;
- something in front of the copies that decides which of them receives a request;
- a signal that the new copy is ready, rather than merely started, so traffic is not moved to a
  process that is still loading.

Each of those can be added by hand on one machine, and Docker's own Swarm mode provides them across
several; lesson 3 looks at where it fits. Kubernetes does all three as ordinary behaviour, and lesson 35 runs this same
probe against a rolling update to see what the number becomes.

Twelve failed requests sounds small, and on a quiet afternoon it is. It is twelve per update, every
update, and it is a number nobody sees unless somebody measures it.
