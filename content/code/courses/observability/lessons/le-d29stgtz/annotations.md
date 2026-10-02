---
title: Annotations: marking what people did
version: 1
---

A graph shows what the system did. **An annotation marks what people did**: a deploy, a
configuration change, the start of an incident. Without them, the first question about any bump in
any graph is *did somebody change something?*, and the answer lives in a chat log. The deploy
pipeline's robot, with its token, marks a release of payments:

```
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" -H 'Content-Type: application/json' -d '{"dashboardUID": "shop", "tags": ["deploy"], "text": "payments 1.4.1"}' localhost:3000/api/annotations | jq -c .
{"id":1,"message":"Annotation added"}
```

The release makes every charge 600 milliseconds slower, the lab's fault file standing in for a bad
version. Two minutes later it is rolled back, and the rollback is marked too:

```
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" -H 'Content-Type: application/json' -d '{"dashboardUID": "shop", "tags": ["deploy", "rollback"], "text": "payments back to 1.4.0"}' localhost:3000/api/annotations | jq -c .
{"id":2,"message":"Annotation added"}
```

Both are stored with their time and tags, and any dashboard that draws `deploy` annotations, as the
shop's does, puts them on every panel. `jq` prints the times in UTC:

```
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" 'localhost:3000/api/annotations?tags=deploy' | jq -r '.[] | [(.time/1000 | strftime("%H:%M:%S")), .text, (.tags | join(","))] | @tsv'
10:31:09	payments back to 1.4.0	deploy,rollback
10:29:09	payments 1.4.1	deploy
```

The checkout's 99th percentile over the same minutes was then asked of Prometheus as a **range
query**, one value every fifteen seconds, from two minutes before the deploy to four after it:

```sh
curl -sG localhost:9090/api/v1/query_range \
  --data-urlencode 'query=histogram_quantile(0.99, sum by (le) (rate(http_server_request_duration_seconds_bucket{job="storefront",route="/checkout"}[1m])))' \
  --data-urlencode start=$START --data-urlencode end=$END --data-urlencode step=15
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"The checkout's 99th percentile, from the Prometheus range query the transcript printed, one point every 15 seconds, with the two annotations drawn as vertical lines. Before the deploy annotation at 0 seconds the line sits at 0.05 seconds. Fifteen seconds after it, it jumps to 0.98 and stays near 0.995. The rollback annotation is at 120 seconds, but the line stays high until 165 seconds and drops to 0.05 only at 180, because each point is a rate over the minute before it.\"><defs><marker id=\"ann-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M90 260 L680 260\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M90 260 L90 50\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><text x=\"82\" y=\"160.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0.5 s</text><text x=\"82\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1 s</text><text x=\"155.55555555555554\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><text x=\"286.66666666666663\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">60 s</text><text x=\"417.77777777777777\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">120 s</text><text x=\"548.8888888888889\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">180 s</text><text x=\"680.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">240 s</text><path d=\"M90.0 250.06 L122.77777777777777 250.06 L155.55555555555554 250.06 L188.33333333333331 64.42000000000002 L221.11111111111111 61.76000000000002 L253.88888888888889 61.099999999999994 L286.66666666666663 61.0 L319.44444444444446 61.0 L352.22222222222223 61.0 L385.0 61.0 L417.77777777777777 61.0 L450.5555555555556 61.29999999999998 L483.3333333333333 62.25999999999999 L516.1111111111111 68.91999999999999 L548.8888888888889 250.06 L581.6666666666667 250.02 L614.4444444444445 246.76 L647.2222222222222 246.74 L680.0 246.76\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M155.55555555555554 260 L155.55555555555554 40\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"159.55555555555554\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">deploy: payments 1.4.1</text><path d=\"M417.77777777777777 260 L417.77777777777777 40\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"421.77777777777777\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">rollback: back to 1.4.0</text><text x=\"385\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">seconds from the deploy annotation</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">checkout p99 around a deploy and its rollback</text></svg>", "caption": "Drawn from the numbers above. The annotations say when somebody acted; the line says when the users felt it, a window later at each end."}
```

**The annotations say when somebody acted; the line says when users felt it.** The deploy at 0
seconds shows on the line fifteen seconds later, at the next point. The rollback at 120 seconds does
not show until 180: for a whole minute the panel said checkouts were still slow while they were
already fast again. Each point is a rate over the minute before it, and that minute still held slow
checkouts. The person who rolled back and watched the panel would have spent that minute wondering
whether the rollback had worked.

That lag is the window, and the next section is about choosing it. The annotation is what makes the
lag readable at all: **with the line and the mark on one panel, cause and effect are one glance
apart**. An incident's timeline in lesson 17 starts from exactly these marks.
