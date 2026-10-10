---
title: Dando voz à boxoffice
version: 1
---

A boxoffice, como a aula 1 a escreveu, não diz nada sobre si. Ela desliga o próprio log de
requisições, porque um teste de carga manda milhares de requisições e uma linha impressa para cada
uma faria do terminal a parte mais lenta do sistema, e ela não conta nada. **Uma aplicação que
ninguém instrumentou é uma caixa-preta em produção**: o único jeito de saber que ela está lenta é ser
uma das pessoas esperando.

Esta seção dá a ela as duas coisas que o resto da aula lê: uma linha de log JSON por requisição, com
um id de requisição, e um endereço `/metrics` do qual o Prometheus consegue colher números. Ela faz
isso sem tocar no `app.py`. **O arquivo da aula 1 fica exatamente como está**, e todas as outras
aulas continuam rodando ele; o arquivo novo o importa e o embrulha, que também é como funciona um
agente de APM, de dentro do mesmo processo.

Em `~/boxoffice`, crie o `observed.py` com `nano observed.py`. O botão de copiar leva o arquivo
inteiro sem as notas.

```schooling-example
{"language": "python", "file": "boxoffice/observed.py", "parts": [{"code": "# boxoffice/observed.py\n# app.py, unchanged, with what an operator needs from it: one JSON log line\n# per request, a request id, and /metrics in Prometheus's text format.\nimport json, os, sys, threading, time, uuid\nfrom datetime import datetime, timezone\nfrom http.server import ThreadingHTTPServer\nimport app\n", "note": "`import app` carrega o arquivo da aula 1 como módulo, e as últimas linhas dele só sobem um servidor quando ele é executado diretamente, então importá-lo não sobe nada. Tudo daqui para baixo reaproveita `app.Box`, o handler, sem mudar nada nele: o `app.py` continua sendo o arquivo que todas as outras aulas executam."}, {"code": "BUCKETS = (0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5)\nlock = threading.Lock()\ncounts = {}                    # (method, route, status) -> requests\nhistograms = {}                # route -> [one count per bucket, +Inf, sum]\n", "note": "Todo o estado das métricas: uma contagem por método, rota e status, e por rota um histograma. Os `BUCKETS` são limites superiores em segundos, de 5 ms a 2,5 s; uma duração é contada em todo balde abaixo do qual ela cabe, que é como o Prometheus espera receber um histograma."}, {"code": "def route_of(path):\n    parts = path.split(\"?\")[0].strip(\"/\").split(\"/\")\n    if len(parts) == 1 and parts[0] in (\"health\", \"shows\", \"search\", \"bookings\"):\n        return \"/\" + parts[0]\n    if len(parts) == 2 and parts[0] == \"shows\":\n        return \"/shows/{id}\"\n    return \"other\"\n", "note": "A rota, não o caminho. `/shows/990` e `/shows/991` são o mesmo endpoint, e um rótulo com o caminho faria mil séries a partir de uma. Qualquer coisa desconhecida vira `other`, então um estranho pedindo endereços aleatórios também não consegue criar séries."}, {"code": "def observe(method, route, status, seconds):\n    with lock:\n        key = (method, route, str(status))\n        counts[key] = counts.get(key, 0) + 1\n        h = histograms.setdefault(route, [0] * (len(BUCKETS) + 1) + [0.0])\n        for i, le in enumerate(BUCKETS):\n            if seconds <= le:\n                h[i] += 1\n        h[len(BUCKETS)] += 1\n        h[-1] += seconds\n", "note": "Uma requisição observada: o contador sobe um, e também sobe cada balde pelo menos tão grande quanto a duração dela. O lock está ali porque o `ThreadingHTTPServer` atende cada conexão numa thread própria, e duas threads somando na mesma contagem ao mesmo tempo podem perder uma das somas."}, {"code": "def exposition():\n    out = [\"# TYPE boxoffice_requests_total counter\"]\n    with lock:\n        for (method, route, status), n in sorted(counts.items()):\n            out.append(f'boxoffice_requests_total{{method=\"{method}\",route=\"{route}\",'\n                       f'status=\"{status}\"}} {n}')\n        out.append(\"# TYPE boxoffice_request_duration_seconds histogram\")\n        for route, h in sorted(histograms.items()):\n            for le, n in zip(BUCKETS + (\"+Inf\",), h):\n                out.append(f'boxoffice_request_duration_seconds_bucket{{route=\"{route}\",le=\"{le}\"}} {n}')\n            out.append(f'boxoffice_request_duration_seconds_sum{{route=\"{route}\"}} {h[-1]:.6f}')\n            out.append(f'boxoffice_request_duration_seconds_count{{route=\"{route}\"}} {h[len(BUCKETS)]}')\n    return (\"\\n\".join(out) + \"\\n\").encode()\n", "note": "O formato de texto que o Prometheus lê: uma linha `# TYPE`, depois uma linha por série com os rótulos entre chaves e o valor. O balde com rótulo `+Inf` guarda todas as requisições, e `_sum` e `_count` deixam uma consulta calcular uma média, se algum dia quiser uma."}, {"code": "class Observed(app.Box):\n    def parse_request(self):\n        self.started = time.perf_counter()   # from the request, not the idle wait\n        return super().parse_request()\n\n    def end_headers(self):\n        if getattr(self, \"request_id\", None):\n            self.send_header(\"X-Request-Id\", self.request_id)\n        super().end_headers()\n", "note": "Duas mudanças pequenas em como o `Box` responde. O relógio recomeça quando chega a linha da requisição, porque numa conexão reaproveitada o handler está esperando o cliente desde a requisição anterior, e essa espera não é tempo do servidor. Toda resposta ganha um cabeçalho `X-Request-Id`."}, {"code": "    def send(self, status, body, kind=\"application/json\"):\n        self.request_id = self.headers.get(\"X-Request-Id\") or uuid.uuid4().hex[:16]\n        super().send(status, body, kind)\n        seconds = time.perf_counter() - self.started\n        route = route_of(self.path)\n        observe(self.command, route, status, seconds)\n        print(json.dumps({\n            \"ts\": datetime.now(timezone.utc).isoformat(timespec=\"milliseconds\"),\n            \"level\": \"error\" if status >= 500 else \"info\",\n            \"request_id\": self.request_id, \"method\": self.command, \"route\": route,\n            \"path\": self.path, \"status\": status, \"ms\": round(seconds * 1000, 1),\n            **({\"error\": self.error} if getattr(self, \"error\", None) else {}),\n        }), flush=True)\n        self.request_id = self.error = None\n", "note": "O `send` é por onde sai toda resposta do `app.py`, então é o único lugar para observar todas elas. O id da requisição é o do próprio cliente, se ele mandou um, ou um novo e aleatório. Depois que a resposta é escrita, a requisição é contada e uma linha JSON é impressa, com `level` dizendo `error` para qualquer 5xx."}, {"code": "    def guarded(self, handler):\n        try:\n            handler()\n        except Exception as e:     # a crash still answers, and is still counted\n            self.error = repr(e)\n            self.send(500, {\"error\": \"internal error\"})\n\n    def do_GET(self):\n        if self.path == \"/metrics\":\n            data = exposition()\n            self.send_response(200)\n            self.send_header(\"Content-Type\", \"text/plain; version=0.0.4\")\n            self.send_header(\"Content-Length\", str(len(data)))\n            self.end_headers()\n            return self.wfile.write(data)\n        self.guarded(super().do_GET)\n\n    def do_POST(self):\n        self.guarded(super().do_POST)\n", "note": "Uma requisição que levanta uma exceção no `app.py` fecharia a conexão sem resposta, e sem linha de log nem contagem: a falha que um operador mais precisa ver ficaria invisível. O `guarded` a transforma num 500, registrado com a exceção. O `/metrics` é respondido aqui e nunca contado, para as visitas do próprio Prometheus não diluírem os números."}, {"code": "def serve():\n    host = os.environ.get(\"BOXOFFICE_HOST\", \"127.0.0.1\")\n    server = ThreadingHTTPServer((host, 8000), Observed)\n    print(f\"boxoffice, observed, on http://{host}:8000\", file=sys.stderr, flush=True)\n    server.serve_forever()\n\nif __name__ == \"__main__\":\n    serve()", "note": "A mensagem de início vai para a saída de erro e as linhas de log para a saída padrão, para o shell mandar o log para um arquivo enquanto o terminal ainda diz que o servidor subiu. O `serve` é uma função para outro arquivo poder importar este e subi-lo, como fazem as aulas 23 e 24."}]}
```

## Rodando

Pare o `app.py` com `Ctrl+C` se ele ainda estiver rodando no primeiro terminal, e suba ali a versão
observada, com o log indo para um arquivo:

```sh
cd ~/boxoffice
python3 observed.py > requests.log
```

O terminal mostra uma linha, a mensagem de início, porque ela vai para a saída de erro e o `>` manda
para o arquivo só a saída padrão:

```
ana@nft:~/boxoffice$ python3 observed.py > requests.log
boxoffice, observed, on http://127.0.0.1:8000
```

No segundo terminal, peça três coisas: um espetáculo, uma reserva que manda o seu próprio id de
requisição, e um endereço que não existe. Depois leia o log:

```
ana@nft:~/boxoffice$ curl -si localhost:8000/shows/990
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 07:34:51 GMT
Content-Type: application/json
Content-Length: 119
Server-Timing: db;dur=17.9, pay;dur=0.0, total;dur=18.4
X-Request-Id: e23e5e735f854139

{"id": 990, "title": "The Tempest", "day": "2027-07-11", "price_cents": 4000, "capacity": 300, "sold": 7, "left": 293}
ana@nft:~/boxoffice$ curl -s -H "X-Request-Id: ana-test-1" -X POST localhost:8000/bookings -d '{"show_id": 990, "seat": 12, "customer": "ana"}'
{"id": 295113, "show_id": 990, "seat": 12}
ana@nft:~/boxoffice$ curl -s localhost:8000/nope
{"error": "not found"}
ana@nft:~/boxoffice$ cat requests.log
{"ts": "2026-10-10T07:34:51.794+00:00", "level": "info", "request_id": "e23e5e735f854139", "method": "GET", "route": "/shows/{id}", "path": "/shows/990", "status": 200, "ms": 18.6}
{"ts": "2026-10-10T07:34:51.901+00:00", "level": "info", "request_id": "ana-test-1", "method": "POST", "route": "/bookings", "path": "/bookings", "status": 201, "ms": 67.6}
{"ts": "2026-10-10T07:34:51.936+00:00", "level": "info", "request_id": "c404708b1eb84a4b", "method": "GET", "route": "other", "path": "/nope", "status": 404, "ms": 0.7}
```

Toda resposta agora carrega um `X-Request-Id`, e o mesmo id está na linha dela no log. A reserva
manteve o id que o cliente mandou, `ana-test-1`, que é o que deixa quem chamou, outro serviço ou uma
verificação sintética dizer *esta aqui* e ser achado. O endereço que não existe foi registrado com
a rota `other`, então um estranho digitando caminhos aleatórios cria linhas no log, mas nenhuma
série nova nas métricas.

As mesmas três requisições, como o Prometheus vai lê-las, filtradas para os contadores e o
histograma da reserva:

```
ana@nft:~/boxoffice$ curl -s localhost:8000/metrics | grep -E 'TYPE|_total|route="/bookings"'
# TYPE boxoffice_requests_total counter
boxoffice_requests_total{method="GET",route="/shows/{id}",status="200"} 1
boxoffice_requests_total{method="GET",route="other",status="404"} 1
boxoffice_requests_total{method="POST",route="/bookings",status="201"} 1
# TYPE boxoffice_request_duration_seconds histogram
boxoffice_request_duration_seconds_bucket{route="/bookings",le="0.005"} 0
boxoffice_request_duration_seconds_bucket{route="/bookings",le="0.01"} 0
boxoffice_request_duration_seconds_bucket{route="/bookings",le="0.025"} 0
boxoffice_request_duration_seconds_bucket{route="/bookings",le="0.05"} 0
boxoffice_request_duration_seconds_bucket{route="/bookings",le="0.1"} 1
boxoffice_request_duration_seconds_bucket{route="/bookings",le="0.25"} 1
boxoffice_request_duration_seconds_bucket{route="/bookings",le="0.5"} 1
boxoffice_request_duration_seconds_bucket{route="/bookings",le="1.0"} 1
boxoffice_request_duration_seconds_bucket{route="/bookings",le="2.5"} 1
boxoffice_request_duration_seconds_bucket{route="/bookings",le="+Inf"} 1
boxoffice_request_duration_seconds_sum{route="/bookings"} 0.067578
boxoffice_request_duration_seconds_count{route="/bookings"} 1
```

A reserva levou `0.067578` segundos, então foi contada em todo balde de `le="0.1"` para cima e em
nenhum abaixo. **Cada balde conta as requisições que levaram no máximo aquele tempo**, e é por isso
que os números só crescem da esquerda para a direita; a próxima seção lê um percentil a partir
deles.

Nada aqui é específico de Python. Toda linguagem tem uma biblioteca cliente do Prometheus que mantém
esses contadores para você, e um SDK do OpenTelemetry que faz o mesmo e consegue mandá-los para
qualquer lugar. O arquivo acima faz à mão o que essas bibliotecas fazem, escrito por extenso para
você enxergar.
