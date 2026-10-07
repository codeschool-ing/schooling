---
title: Configuration lives outside the code
version: 1
---

If the artifact is the same in every environment, the differences have to come from somewhere else,
and the usual answer is the one popularised by *The Twelve-Factor App*: **the program reads its
configuration from the environment it runs in**, as environment variables, and the code contains no
environment's settings. `shipquote` reads four:

| variable | what it decides | if absent |
|---|---|---|
| `SHIPQUOTE_PORT` | the port it listens on | 8080 |
| `SHIPQUOTE_ENV` | the name it reports on `/version` | `dev` |
| `SHIPQUOTE_CARRIER_URL` | the carrier it asks for prices | none: the shop's own table |
| `SHIPQUOTE_CARRIER_TOKEN` | the key it presents to the carrier | empty |

Step 10 of the project, tagged `v1.5.0`, added the two carrier variables. Here are the three
environments' configurations, with the token lines filtered out for now, since lesson 9 is about
them:

```
ana@laptop:~/shipquote$ grep -v TOKEN ~/envs/*/config.env
/home/ana/envs/dev/config.env:SHIPQUOTE_PORT=8100
/home/ana/envs/production/config.env:SHIPQUOTE_PORT=8300
/home/ana/envs/production/config.env:SHIPQUOTE_CARRIER_URL=http://127.0.0.1:9092
/home/ana/envs/staging/config.env:SHIPQUOTE_PORT=8200
/home/ana/envs/staging/config.env:SHIPQUOTE_CARRIER_URL=http://127.0.0.1:9091
```

Development has only a port, so it prices from the table. Staging and production each name a
carrier. The **same artifact** goes to all three, and each answers with its own identity:

```
ana@laptop:~/shipquote$ for env in dev staging production; do ops/deploy.sh $env dist/shipquote-1.5.0.tar.gz; done
smoke: http://127.0.0.1:8100 is up and running 1.5.0
smoke: http://127.0.0.1:8200 is up and running 1.5.0
smoke: http://127.0.0.1:8300 is up and running 1.5.0
ana@laptop:~/shipquote$ for port in 8100 8200 8300; do curl -s http://127.0.0.1:$port/version; echo; done
{"version": "1.5.0", "env": "dev", "carrier": "table"}
{"version": "1.5.0", "env": "staging", "carrier": "http://127.0.0.1:9091"}
{"version": "1.5.0", "env": "production", "carrier": "http://127.0.0.1:9092"}
```

Three smoke tests passed, one per environment, and the three `/version` answers say the same
version, three environment names and three different sources of prices.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"One artifact, shipquote-1.5.0.tar.gz, at the top, with lines to three environments. dev on port 8100 prices from the table and quotes R$ 21,90. staging on port 8200 asks the carrier on 9091 and quotes R$ 18,60. production on port 8300 asks the carrier on 9092 and quotes R$ 18,60.\"><rect x=\"250\" y=\"16\" width=\"220\" height=\"40\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">shipquote-1.5.0.tar.gz</text><path d=\"M360 56 L125 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><rect x=\"30\" y=\"96\" width=\"190\" height=\"96\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"125\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">dev</text><text x=\"44\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SHIPQUOTE_PORT=8100</text><text x=\"44\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">prices from: the table</text><text x=\"44\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">R$ 21,90</text><path d=\"M360 56 L355 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><rect x=\"260\" y=\"96\" width=\"190\" height=\"96\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">staging</text><text x=\"274\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SHIPQUOTE_PORT=8200</text><text x=\"274\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">prices from: carrier :9091</text><text x=\"274\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">R$ 18,60</text><path d=\"M360 56 L585 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><rect x=\"490\" y=\"96\" width=\"190\" height=\"96\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"585\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">production</text><text x=\"504\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SHIPQUOTE_PORT=8300</text><text x=\"504\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">prices from: carrier :9092</text><text x=\"504\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">R$ 18,60</text><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the same bytes in every box; only the configuration differs</text><text x=\"360\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the quote is for 1.2 kg to São Paulo with a R$ 50,00 basket</text></svg>", "caption": "Section 03's three deploys and section 04's three answers in one drawing. The difference between R$ 21,90 and R$ 18,60 is configuration, not code."}
```

## Where the values come from at run time

`restart.sh` reads `config.env` into the environment of the process it starts, so the values live
in the running process and nowhere in the release. On Linux that is visible from outside:

```
ana@laptop:~/shipquote$ tr '\0' '\n' < /proc/$(cat ~/envs/production/pid)/environ | grep ^SHIPQUOTE_ | grep -v TOKEN
SHIPQUOTE_CARRIER_URL=http://127.0.0.1:9092
SHIPQUOTE_ENV=production
SHIPQUOTE_PORT=8300
```

`/proc/<pid>/environ` holds the environment a process was started with. The production process sees
its port, its carrier and its name, which `restart.sh` sets from the directory. That file is
readable by the process's owner and by root, which matters for the tokens that were filtered out
above, and lesson 9 starts from it.

## What does not belong in configuration

Configuration is for **what differs between environments**. A business rule such as the
free-shipping threshold is the same everywhere and belongs in the code, behind tests, as it is in
`quote.py`. Making it a variable "for flexibility" would turn a tested rule into an untested value
that one environment can set differently from another, and section 07 shows what a difference like
that looks like when nobody can see it.
