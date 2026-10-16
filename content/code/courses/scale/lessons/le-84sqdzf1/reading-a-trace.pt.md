---
title: Lendo um rastro
version: 1
---

O Jaeger tem uma página para rastros em `http://localhost:16686` no laboratório, e os mesmos dados
por uma API. Para ler rastros no terminal, como o resto do curso faz, este programa curto pede à API o
rastro mais recente de uma operação e o imprime como uma árvore. Salve-o como `trace.py`:

```schooling-example
{"language": "python", "file": "trace.py", "parts": [{"code": "# trace.py\n\"\"\"Print the latest trace of one operation as a tree, from Jaeger's API.\nWith --count, print how many traces of it Jaeger holds from the last hour instead.\"\"\"\nimport json\nimport sys\nimport urllib.parse\nimport urllib.request\nfrom datetime import datetime, timedelta, timezone", "note": "Um leitor pequeno da API de consulta do Jaeger, para que um rastro possa ser lido no terminal. A página do Jaeger na porta 16686 mostra os mesmos rastros num navegador."}, {"code": "\ncount = \"--count\" in sys.argv\nargs = [a for a in sys.argv[1:] if a != \"--count\"]\noperation = args[0] if args else \"POST /events/{id}/tickets\"\nnow = datetime.now(timezone.utc)\nquery = urllib.parse.urlencode({\n    \"query.service_name\": \"tickets\",\n    \"query.operation_name\": operation,\n    \"query.start_time_min\": (now - timedelta(hours=1)).isoformat(),\n    \"query.start_time_max\": now.isoformat(),\n    \"query.search_depth\": 1000 if count else 1,\n})\nwith urllib.request.urlopen(f\"http://localhost:16686/api/v3/traces?{query}\") as answer:\n    found = json.load(answer)[\"result\"][\"resourceSpans\"]\n", "note": "Ele pede os rastros de uma operação do `tickets` na última hora: o mais recente, ou até mil com `--count`."}, {"code": "spans = []\nfor group in found:\n    service = next(a[\"value\"][\"stringValue\"] for a in group[\"resource\"][\"attributes\"]\n                   if a[\"key\"] == \"service.name\")\n    for scope in group[\"scopeSpans\"]:\n        for span in scope[\"spans\"]:\n            spans.append({**span, \"service\": service})\n", "note": "A resposta é o próprio JSON do OTLP: spans agrupados pelo serviço que os produziu. Isto os achata numa lista, cada span marcado com o serviço."}, {"code": "if count:\n    print(len({s[\"traceId\"] for s in spans}), \"traces of\", operation)\n    sys.exit()\n"}, {"code": "ids = {s[\"spanId\"] for s in spans}\nchildren = {}\nfor span in spans:\n    parent = span.get(\"parentSpanId\") if span.get(\"parentSpanId\") in ids else None\n    children.setdefault(parent, []).append(span)\nstart = min(int(s[\"startTimeUnixNano\"]) for s in spans)\nprint(f\"trace {spans[0]['traceId']}\")", "note": "Cada span nomeia o pai pelo id; um span cujo pai não está no rastro é uma raiz. Isso é tudo o que faz de um rastro uma árvore."}, {"code": "\n\ndef show(span, depth):\n    begin = (int(span[\"startTimeUnixNano\"]) - start) / 1e6\n    took = (int(span[\"endTimeUnixNano\"]) - int(span[\"startTimeUnixNano\"])) / 1e6\n    print(f\"{'  ' * depth}{span['name']:<{30 - 2 * depth}} {span['service']:<9}\"\n          f\" at {begin:5.1f} ms  took {took:5.1f} ms\")\n    for child in sorted(children.get(span[\"spanId\"], []), key=lambda s: int(s[\"startTimeUnixNano\"])):\n        show(child, depth + 1)\n\n\nfor root in children.get(None, []):\n    show(root, 0)", "note": "Cada span é impresso recuado sob o pai, com quando começou em relação ao rastro e quanto levou."}]}
```

Uma venda, depois uma pausa, porque o SDK manda os lotes a cada cinco segundos e o Collector espera
até mais um, e então o rastro:

```
ana@lab:~/tickets$ curl -s -X POST localhost:8080/events/1/tickets; echo
{"event": 1, "seat": 1, "code": "cb5ad8d5b5fd9bea"}
ana@lab:~/tickets$ sleep 7
ana@lab:~/tickets$ python3 trace.py
trace 50257c23c4e03af564a04c50844cf11d
POST /events/{id}/tickets      tickets   at   0.0 ms  took  68.6 ms
  charge                       tickets   at   0.1 ms  took  38.3 ms
    POST /charges              payments  at  14.7 ms  took  23.2 ms
  UPDATE events                tickets   at  54.4 ms  took   4.0 ms
  sign                         tickets   at  58.5 ms  took   5.2 ms
  INSERT tickets               tickets   at  63.9 ms  took   2.9 ms
```

Leia de cima para baixo. O pedido levou **68,6 ms** no total. **A cobrança levou 38,3 ms disso**, e
dentro da cobrança o span do próprio payments levou 23,2 ms, **começando 14,7 ms depois de a cobrança
começar**. Depois o `UPDATE` levou 4,0 ms, a assinatura 5,2 ms e o `INSERT` 2,9 ms. Dois serviços,
uma árvore, um id de rastro, e o tempo de cada passo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O rastro da primeira venda desenhado como uma linha do tempo de 0 a 70 milissegundos. A barra do pedido cobre 68,6 ms. A barra da cobrança começa logo e dura 38,3 ms; dentro dela, a barra do próprio payments começa em 14,7 ms e dura 23,2 ms. Depois da cobrança vêm três barras curtas: o update, 4,0 ms, a assinatura, 5,2 ms, e o insert, 2,9 ms.\"><text x=\"20\" y=\"31\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">POST /events/{id}/tickets</text><rect x=\"230.0\" y=\"20\" width=\"452.75999999999993\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">charge</text><rect x=\"230.66\" y=\"52\" width=\"252.77999999999997\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">POST /charges</text><rect x=\"327.02\" y=\"84\" width=\"153.11999999999998\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UPDATE events</text><rect x=\"589.04\" y=\"116\" width=\"26.4\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"159\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sign</text><rect x=\"616.0999999999999\" y=\"148\" width=\"34.32\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT tickets</text><rect x=\"651.74\" y=\"180\" width=\"19.139999999999997\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><path d=\"M230.0 212 L230.0 218\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"230.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M296.0 212 L296.0 218\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"296.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><path d=\"M362.0 212 L362.0 218\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"362.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><path d=\"M428.0 212 L428.0 218\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"428.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">30</text><path d=\"M494.0 212 L494.0 218\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"494.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">40</text><path d=\"M560.0 212 L560.0 218\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"560.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">50</text><path d=\"M626.0 212 L626.0 218\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"626.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">60</text><path d=\"M692.0 212 L692.0 218\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"692.0\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">70</text><path d=\"M230 212 L692.0 212\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"220\" y=\"232\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ms</text></svg>", "caption": "A primeira venda: mais da metade dela é a cobrança, e parte da cobrança é o intervalo antes de o payments responder."}
```

**Os intervalos informam tanto quanto os spans.** Os 14,6 ms entre a bilheteria começar a cobrança e
o payments começar a responder são tempo gasto no trabalho de nenhum dos dois lados: abrir uma
conexão TCP, o cliente HTTP do Python se preparando, o pedido atravessando a rede. Esta foi a primeira
venda desde que a bilheteria subiu, e a primeira consulta em cada conexão com o banco também é mais
lenta, que é por que o `UPDATE` levou 4 ms aqui. O rastro da seção 08, um minuto depois, mostra o
mesmo intervalo em 1,8 ms.

Uma leitura é uma árvore menor:

```
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 999999, "host": "dd4bf75a071b"}
ana@lab:~/tickets$ sleep 7
ana@lab:~/tickets$ python3 trace.py 'GET /events/{id}'
trace 2add1a888db764a7e5c1661b5065ee66
GET /events/{id}               tickets   at   0.0 ms  took  14.5 ms
  SELECT events                tickets   at   0.1 ms  took  13.9 ms
```

Quase todos os seus 14,5 ms são a consulta na réplica. O histograma da aula 7 dizia que as leituras
eram rápidas no percentil 95; este rastro diz qual parte de uma leitura foi lenta, que é a pergunta
que um histograma não sabe responder.

## O que o Collector viu

O exportador `debug` escreve uma linha por lote que encaminha:

```
ana@lab:~/tickets$ docker compose logs collector --no-log-prefix | grep 'Traces' | tail -2
2026-10-10T06:22:12.317Z	info	Traces	{"resource": {"service.instance.id": "1806cab2-143b-4e55-a339-a0ca5bab6217", "service.name": "otelcol", "service.version": "0.162.0"}, "otelcol.component.id": "debug", "otelcol.component.kind": "exporter", "otelcol.signal": "traces", "resource spans": 1, "spans": 6}
2026-10-10T06:22:17.319Z	info	Traces	{"resource": {"service.instance.id": "1806cab2-143b-4e55-a339-a0ca5bab6217", "service.name": "otelcol", "service.version": "0.162.0"}, "otelcol.component.id": "debug", "otelcol.component.kind": "exporter", "otelcol.signal": "traces", "resource spans": 1, "spans": 3}
```

Cada linha é um lote: `resource spans` é de quantos serviços ele veio, aqui um de cada vez, e `spans`
quantos spans ele levava, **6 e depois 3**. Esses números não batem com as árvores acima, e não é
para bater. Um lote leva os spans que chegaram ao Collector naquele segundo, de qualquer serviço que
os tenha mandado: os spans do payments e os da bilheteria viajam separados, e toda coleta do
Prometheus em `/metrics` também é um pedido, com um span próprio. **O Collector encaminha spans, não
rastros**, e o Jaeger monta as árvores pelos ids. É isso que deixa os spans de um rastro chegarem de
serviços diferentes, em momentos diferentes, por Collectors diferentes.
