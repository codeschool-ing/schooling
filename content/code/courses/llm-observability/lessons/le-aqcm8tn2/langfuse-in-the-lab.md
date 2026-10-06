---
title: Langfuse in the lab
version: 1
---

The lab runs Langfuse 3.225.11 from its official images, with the compose file in
`lab/langfuse/docker-compose.yml`, started by `sudo bash lab.sh langfuse`. It creates an organisation,
a project called `support-assistant`, the project's two API keys and one user as it starts, from
`LANGFUSE_INIT_*` settings, so that no sign-up screen has to be clicked. The keys are the lab's, and
they are in ana's environment as `LANGFUSE_PUBLIC_KEY` and `LANGFUSE_SECRET_KEY`.

```
ana@lab:~/obs$ curl -s $LANGFUSE_HOST/api/public/health; echo
{"status":"OK","version":"3.225.11"}
```

## Six containers

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Langfuse's six containers. The assistant sends spans over OTLP to the web server. The web server writes each incoming batch to object storage (MinIO) and puts a job on a queue (Redis). The worker takes the job, reads the batch and writes traces and observations into ClickHouse. PostgreSQL holds users, projects, keys, model prices and prompts. The web server reads from ClickHouse and PostgreSQL to answer the screens and the API.\"><rect x=\"150\" y=\"14\" width=\"556\" height=\"256\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><rect x=\"12\" y=\"112\" width=\"116\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"70\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">assistant.py</text><text x=\"70\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\"></text><rect x=\"172\" y=\"112\" width=\"140\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"242\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">web</text><text x=\"242\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">screens, API, OTLP</text><rect x=\"360\" y=\"30\" width=\"150\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"435\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">MinIO</text><text x=\"435\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">every batch, as it came</text><rect x=\"360\" y=\"112\" width=\"150\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"435\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Redis</text><text x=\"435\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the queue</text><rect x=\"546\" y=\"112\" width=\"146\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"619\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">worker</text><text x=\"619\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">files what arrived</text><rect x=\"546\" y=\"200\" width=\"146\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"619\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ClickHouse</text><text x=\"619\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">traces, observations, scores</text><rect x=\"172\" y=\"200\" width=\"140\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"242\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PostgreSQL</text><text x=\"242\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">projects, keys, prices, prompts</text><path d=\"M128 136 L172 136\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"140\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">OTLP / HTTP</text><path d=\"M312 124 L360 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M312 136 L360 136\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M510 136 L546 136\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M546 124 L510 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M619 160 L619 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M546 224 L312 136\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M242 160 L242 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "What arrives is kept first and processed after. A trace is in the API only once the worker has filed it."}
```

| container | what it holds | why it is separate |
|---|---|---|
| `web` | the screens, the public API, and the endpoint that receives OTLP | it is what people and programs talk to |
| `worker` | nothing; it moves what arrived into place | ingestion can lag without slowing the screens |
| `postgres` | users, projects, keys, model prices, prompts | small, relational, changes rarely |
| `clickhouse` | traces, observations, scores | large, appended, read by aggregation |
| `redis` | the queue between `web` and `worker` | so that a burst of traces waits instead of failing |
| `minio` | every batch that arrived, as it arrived | S3-compatible storage; the source the worker reads from |

That is more machinery than Jaeger's single binary, and it is the cost of a database built for the
questions in the next sections: sums of tokens and cost by day and user over millions of
observations. It also has a consequence the transcripts show: **a span sent now is not in the API
now**. It is in the queue, then in the worker, then in ClickHouse. The captures wait twenty seconds
after each replay, which is staged and not shown.

Each secret in that compose file, `SALT`, `ENCRYPTION_KEY` and `NEXTAUTH_SECRET`, is a lab value that
opens nothing. A real deployment generates its own, keeps them out of the file, and puts the web
server behind HTTPS; the lab publishes it on 127.0.0.1 only.
