---
title: Clientes que esperam
version: 1
---

A aula 9 recusou o excesso de trabalho com `429` e `503` e um `Retry-After`, e descobriu que uma
recusa só diminui a carga se quem chama escutar. O `load.py` não escutava: um trabalhador recusado
pedia de novo na hora. Aqui está ele com uma opção para escutar, `--polite`, que aplica esta aula ao
lado de quem chama. Salve-o por cima do `load.py` antigo:

```schooling-example
{"language": "python", "file": "load.py", "parts": [{"code": "# load.py\n\"\"\"A closed-loop load generator: each worker sends a request, waits, sends the next.\nWith --polite, a worker that is refused waits as long as Retry-After asks, and a\nrandom part of that again, before asking.\"\"\"\nimport argparse\nimport http.client\nimport random\nimport threading\nimport time\nfrom collections import Counter\nfrom urllib.parse import urlsplit", "note": "O gerador de carga da aula 1, com um acréscimo."}, {"code": "\np = argparse.ArgumentParser()\np.add_argument(\"url\")\np.add_argument(\"-c\", \"--workers\", type=int, default=4)\np.add_argument(\"-d\", \"--seconds\", type=float, default=10)\np.add_argument(\"-m\", \"--method\", default=\"GET\")\np.add_argument(\"--events\", type=int, default=1)\np.add_argument(\"--polite\", action=\"store_true\")\nargs = p.parse_args()", "note": "O `--polite` o liga."}, {"code": "\nu = urlsplit(args.url)\nlatencies, statuses, lock = [], Counter(), threading.Lock()\ndeadline = time.monotonic() + args.seconds"}, {"code": "\n\ndef worker(n):\n    conn = http.client.HTTPConnection(u.hostname, u.port, timeout=10)\n    mine, seen, i = [], Counter(), n\n    while time.monotonic() < deadline:\n        path = u.path.replace(\"{event}\", str(i % args.events + 1))\n        i += args.workers"}, {"code": "        start = time.monotonic()\n        try:\n            conn.request(args.method, path, headers={\"Content-Length\": \"0\"})\n            r = conn.getresponse()\n            r.read()\n        except OSError as e:\n            seen[type(e).__name__] += 1\n            conn.close()\n            conn = http.client.HTTPConnection(u.hostname, u.port, timeout=10)\n            continue"}, {"code": "        mine.append(time.monotonic() - start)\n        seen[r.status] += 1\n        if args.polite and r.status in (429, 503):\n            wait = float(r.getheader(\"Retry-After\") or 1)\n            time.sleep(wait * random.uniform(1, 2))", "note": "**Um trabalhador educado que é recusado espera** o quanto o `Retry-After` diz, vezes um fator aleatório entre um e dois, antes do próximo pedido. O tempo é medido antes da espera, então as latências continuam sendo as da bilheteria."}, {"code": "    with lock:\n        latencies.extend(mine)\n        statuses.update(seen)\n\n\nstarted = time.monotonic()\nthreads = [threading.Thread(target=worker, args=(n,)) for n in range(args.workers)]\nfor t in threads:\n    t.start()\nfor t in threads:\n    t.join()\nelapsed = time.monotonic() - started\n\nlatencies.sort()\n\n\ndef pct(q):\n    return latencies[min(len(latencies) - 1, int(q * len(latencies)))] * 1000\n\n\ntotal = sum(statuses.values())\nprint(f\"requests  {total} in {elapsed:.1f} s = {total / elapsed:.1f} per second\")\nif latencies:\n    print(f\"latency   p50 {pct(0.50):.1f} ms  p95 {pct(0.95):.1f} ms\"\n          f\"  p99 {pct(0.99):.1f} ms  max {latencies[-1] * 1000:.1f} ms\")\nprint(\"status    \" + \"  \".join(f\"{k}: {v}\" for k, v in sorted(statuses.items(), key=str)))"}]}
```

Uma política com recuo e variação, para quem chama e ouviu quanto esperar: esperar isso, mais uma
fração aleatória, para que mil compradores recusados não voltem todos no mesmo segundo.

Agora a bilheteria sobrecarregada da aula 9, com 8 vagas em vez de 32 para que a espera aconteça na
porta, e 128 trabalhadores comprando por vinte segundos. Primeiro como antes, depois educados:

```
ana@lab:~/tickets$ docker compose up -d payments
 Container tickets-payments-1 Recreate 
 Container tickets-payments-1 Recreated 
 Container tickets-payments-1 Starting 
 Container tickets-payments-1 Started 
ana@lab:~/tickets$ MAX_IN_FLIGHT=8 docker compose up -d app
 Container tickets-replica-1 Running 
 Container tickets-redis-1 Running 
 Container tickets-db-1 Running 
 Container tickets-app-1 Recreate 
 Container tickets-app-1 Recreated 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-db-1 Waiting 
 Container tickets-replica-1 Waiting 
 Container tickets-replica-1 Healthy 
 Container tickets-db-1 Healthy 
 Container tickets-app-1 Starting 
 Container tickets-app-1 Started 
ana@lab:~/tickets$ python3 load.py -m POST 'http://localhost:8080/events/{event}/tickets' --events 50 -c 128 -d 20
requests  8797 in 20.4 s = 432.1 per second
latency   p50 252.6 ms  p95 712.3 ms  p99 1054.2 ms  max 1811.5 ms
status    201: 1493  503: 7304
ana@lab:~/tickets$ python3 load.py -m POST 'http://localhost:8080/events/{event}/tickets' --events 50 -c 128 -d 20 --polite
requests  3587 in 21.9 s = 163.7 per second
latency   p50 48.1 ms  p95 109.7 ms  p99 136.7 ms  max 190.6 ms
status    201: 1949  503: 1638
```

| | impacientes | educados |
|---|---|---|
| vendidos | 1493 | 1949 |
| recusados | 7304 | 1638 |
| resposta mediana | 253 ms | 48 ms |
| percentil 99 | 1054 ms | 137 ms |

**A mesma bilheteria, o mesmo número de compradores, e 31% mais ingressos vendidos.** Os
trabalhadores impacientes gastaram a única CPU da bilheteria sendo recusados: 7304 vezes em vinte
segundos, cada uma uma conexão, uma thread e uma resposta que não vendeu nada, enquanto as vendas
esperavam atrás delas. Os trabalhadores educados ficaram longe por um ou dois segundos quando foram
mandados, as recusas caíram para menos de um quarto, e as vendas admitidas rodaram na velocidade de
uma bilheteria ocupada, e não sitiada.

Isso é a contrapressão funcionando de ponta a ponta: a bilheteria diz que está cheia, e quem chama
ouve. A aula 9 construiu a primeira metade; esta aula é a segunda.
