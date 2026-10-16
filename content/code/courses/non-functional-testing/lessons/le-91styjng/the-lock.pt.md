---
title: A trava
version: 1
---

Com o índice no lugar, uma consulta a um espetáculo custa bem menos de um milissegundo no banco.
Uma reserva ainda custa pelo menos 40 ms, porque ela paga, e a aula 1 disse que o `app.py` paga
segurando a `booking_lock`. Meça só reservas, com o terceiro argumento do `measure.py` em 1.0, para
um, quatro e dezesseis workers:

```
ana@nft:~/boxoffice$ for w in 1 4 16; do python3 measure.py $w 5 1.0 | sed -n "1,2p;4p"; done
1 workers, 5.0 s: 138 requests, 27.4 per second
status: 201 x114, 409 x24
all           138    36.5    43.6    44.5    44.8    46.4    47.7
4 workers, 5.1 s: 164 requests, 32.3 per second
status: 201 x101, 409 x63
all           164   123.2   128.0   137.5   170.3   599.8   638.8
16 workers, 5.4 s: 213 requests, 39.8 per second
status: 201 x121, 409 x92
all           213   385.8   401.2   484.9   521.7   757.9   889.8
```

O padrão da aula 8 de novo, mais nítido. **Dezesseis vezes mais workers compraram menos da metade
a mais de respostas**: 27.4 requisições por segundo com um worker, 32.3 com quatro, 39.8 com
dezesseis. As reservas que deram certo, os 201, foram 114, 101 e 121 em cerca de cinco segundos
cada, quase o mesmo número toda vez. Enquanto isso a mediana foi de 43.6 ms para 128.0 ms e para
401.2 ms. Os 409 são assentos ocupados: o `measure.py` dá a cada worker uma semente aleatória
fixa, então cada execução tenta assentos que a execução anterior já reservou.

O teto é aritmética. Uma reserva bem-sucedida segura a trava por pelo menos os 40 ms do pagamento,
então no máximo 1 / 0.040 = 25 delas conseguem terminar num segundo, seja qual for a carga; os 409
também seguram a trava, por pouco tempo, e cabem nos intervalos. Com quatro workers, o último da
fila espera três pagamentos antes do seu, que é a mediana de 128.0 ms. A lei de Little da aula 8
confere os dezesseis: 39.8 por segundo × 0.3858 s de tempo de resposta médio dá cerca de 15.4
requisições dentro, para dezesseis workers.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l09-lock\" aria-label=\"Quatro workers reservando ao mesmo tempo, desenhados num eixo de 200 milissegundos. Em cima, o app.py: a trava deixa entrar uma reserva por vez, e cada uma a segura durante o pagamento de 40 ms, então os quatro pagamentos acontecem um depois do outro e o quarto worker espera três pagamentos antes do seu. Embaixo, o app_fixed.py: cada reserva grava a sua linha, que o índice único resolve na hora, e depois paga sem trava nenhuma, então os quatro pagamentos acontecem lado a lado e os quatro terminam depois de uns 40 ms.\"><text x=\"20.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">uma trava</text><text x=\"20.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">app.py</text><text x=\"140.0\" y=\"48.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 1</text><rect x=\"150.0\" y=\"42.0\" width=\"104.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 2</text><rect x=\"150.0\" y=\"64.0\" width=\"114.4\" height=\"12.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"264.4\" y=\"64.0\" width=\"104.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"92.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 3</text><rect x=\"150.0\" y=\"86.0\" width=\"228.8\" height=\"12.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"378.8\" y=\"86.0\" width=\"104.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"114.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 4</text><rect x=\"150.0\" y=\"108.0\" width=\"343.2\" height=\"12.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"493.2\" y=\"108.0\" width=\"104.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><path d=\"M150.0 132.0 L670.0 132.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"150.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"254.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">40</text><text x=\"358.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">80</text><text x=\"462.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">120</text><text x=\"566.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">160</text><text x=\"670.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">200</text><text x=\"20.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">sem trava</text><text x=\"20.0\" y=\"192.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">app_fixed.py</text><text x=\"140.0\" y=\"178.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 1</text><rect x=\"155.2\" y=\"172.0\" width=\"104.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 2</text><rect x=\"155.2\" y=\"194.0\" width=\"104.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"222.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 3</text><rect x=\"155.2\" y=\"216.0\" width=\"104.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"244.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 4</text><rect x=\"155.2\" y=\"238.0\" width=\"104.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><path d=\"M150.0 262.0 L670.0 262.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"150.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"254.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">40</text><text x=\"358.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">80</text><text x=\"462.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">120</text><text x=\"566.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">160</text><text x=\"670.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">200</text><rect x=\"514.0\" y=\"40.0\" width=\"14.0\" height=\"10.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"534.0\" y=\"45.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">esperando a trava</text><rect x=\"514.0\" y=\"58.0\" width=\"14.0\" height=\"10.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"534.0\" y=\"63.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pagando, 40 ms</text><text x=\"670.0\" y=\"292.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ms</text></svg>", "caption": "Com o pagamento dentro da trava, quatro workers levam o tempo de quatro pagamentos. Fora dela, levam o de um.", "same": ["ms", "worker 1", "worker 2", "worker 3", "worker 4"]}
```

Agora faça as perguntas do USE, começando pelos processadores:

```
ana@nft:~/boxoffice$ python3 measure.py 16 8 1.0 > load.txt & sleep 2; top -b -n 2 -d 2 -c -o %CPU | grep "python3 [am]"; wait
     13 ana       20   0 1356948  25032  11632 S  20.0   0.2   0:42.80 python3 app.py
  11376 ana       20   0 1206116  19048  10020 S   0.0   0.1   0:00.14 python3 measure.py 16 8 1.0
     13 ana       20   0 1356948  25032  11632 S  10.0   0.2   0:43.00 python3 app.py
  11376 ana       20   0 1206116  19100  10020 S   3.0   0.1   0:00.20 python3 measure.py 16 8 1.0
```

**O servidor está usando 10% de um processador** no segundo retrato, contra mais de 200% quando o
banco era o gargalo. O hardware está ocioso, a vazão está plana e a latência sobe, e essa
combinação aponta para um recurso de software. A trava é ele: a utilização dela é perto de 100%,
porque sempre há uma reserva segurando; a saturação é o número de threads esperando por ela, até
quinze com dezesseis workers; e ela não levanta erro nenhum, só faz todo mundo esperar. Nenhuma
ferramenta desta aula desenha a fila de uma trava diretamente. Você a deduz pela forma, ou põe um
cronômetro em volta da espera, do jeito que o `app.py` mede as consultas; o total do
`Server-Timing` menos `db` menos `pay` é mais ou menos essa espera, para uma reserva que ficou na
fila.

## Pagar fora da trava

A trava existe por um motivo: dois clientes não podem ficar os dois com o assento 12. Ela consegue
isso fazendo um deles esperar o pagamento inteiro do outro, que é o jeito caro. O banco consegue
impor a mesma regra mais barato. **Um índice único sobre espetáculo e assento torna impossível uma
segunda linha para o mesmo assento**, então a reserva pode gravar a sua linha primeiro, deixar o
banco decidir quem ganhou, e pagar depois, sem trava nenhuma presa enquanto paga.

O `app_fixed.py` é essa mudança, e mais três menores que "Rede e infraestrutura" explica. É um
arquivo novo ao lado do `app.py`, que continua exatamente como a aula 1 o digitou. Crie-o com
`nano app_fixed.py`:

```schooling-example
{"language": "python", "file": "boxoffice/app_fixed.py", "parts": [{"code": "# boxoffice/app_fixed.py\n# The box office of lesson 1, with what lesson 9 found slow put right.\n# app.py is unchanged beside it; run one or the other on port 8000.\nimport json, os, sqlite3, time\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nfrom pathlib import Path\nfrom urllib.parse import parse_qs, urlparse\n\nDB = \"data/boxoffice.db\"\nSTATIC = Path(\"static\")\nPAYMENT_SECONDS = 0.040        # the payment provider, faked: 40 ms a call\nKINDS = {\".html\": \"text/html; charset=utf-8\", \".css\": \"text/css\",\n         \".js\": \"text/javascript\", \".svg\": \"image/svg+xml\", \".png\": \"image/png\"}\n\ndef pay(customer, cents):\n    time.sleep(PAYMENT_SECONDS)\n\ndef rows_as(names, rows):\n    return [dict(zip(names, r)) for r in rows]\n", "note": "Os mesmos imports do `app.py`, menos `threading`: **não existe mais `booking_lock`.** O resto do topo não mudou, inclusive o pagamento de 40 ms. A correção faz o pagamento parar de bloquear os outros clientes; ela não consegue deixar o provedor mais rápido."}, {"code": "class Box(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n    disable_nagle_algorithm = True     # send each answer out at once\n\n    def handle_one_request(self):\n        self.started, self.timing = time.perf_counter(), {\"db\": 0.0, \"pay\": 0.0}\n        self.db = sqlite3.connect(DB, timeout=10)\n        try:\n            super().handle_one_request()\n        finally:\n            self.db.close()\n\n    def parse_request(self):\n        self.started = time.perf_counter()   # the clock starts when a request has arrived\n        return super().parse_request()\n\n    def log_message(self, *args):\n        pass                       # quiet: a load test sends thousands\n", "note": "Duas linhas novas no tratamento, as duas explicadas em \"Rede e infraestrutura\". `disable_nagle_algorithm` manda cada resposta assim que ela é escrita. `parse_request` reinicia o relógio do servidor quando uma requisição chegou, então o `Server-Timing` deixa de contar o tempo gasto esperando um cliente perguntar."}, {"code": "    def query(self, sql, *args):\n        start = time.perf_counter()\n        rows = self.db.execute(sql, args).fetchall()\n        self.timing[\"db\"] += time.perf_counter() - start\n        return rows\n\n    def send(self, status, body, kind=\"application/json\"):\n        data = body if isinstance(body, bytes) else (json.dumps(body) + \"\\n\").encode()\n        spent = [f\"{k};dur={v * 1000:.1f}\" for k, v in self.timing.items()]\n        spent.append(f\"total;dur={(time.perf_counter() - self.started) * 1000:.1f}\")\n        self.send_response(status)\n        self.send_header(\"Content-Type\", kind)\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.send_header(\"Server-Timing\", \", \".join(spent))\n        self.end_headers()\n        self.wfile.write(data)\n\n    def do_GET(self):\n        url = urlparse(self.path)\n        parts = url.path.strip(\"/\").split(\"/\")\n        if url.path == \"/health\":\n            return self.send(200, {\"ok\": True})\n        if url.path == \"/shows\":\n            rows = self.query(\"SELECT id, title, day, price_cents FROM shows WHERE on_sale = 1\")\n            return self.send(200, rows_as((\"id\", \"title\", \"day\", \"price_cents\"), rows))\n        if len(parts) == 2 and parts[0] == \"shows\" and parts[1].isdigit():\n            show_id = int(parts[1])\n            show = self.query(\"SELECT id, title, day, price_cents, capacity FROM shows\"\n                              \" WHERE id = ?\", show_id)\n            if not show:\n                return self.send(404, {\"error\": \"no such show\"})\n            sold = self.query(\"SELECT count(*) FROM bookings WHERE show_id = ?\", show_id)[0][0]\n            body = rows_as((\"id\", \"title\", \"day\", \"price_cents\", \"capacity\"), show)[0]\n            return self.send(200, {**body, \"sold\": sold, \"left\": body[\"capacity\"] - sold})\n        if url.path == \"/search\":\n            q = parse_qs(url.query).get(\"q\", [\"\"])[0]\n            rows = self.query(\"SELECT id, title, day FROM shows\"\n                              \" WHERE on_sale = 1 AND title LIKE ?\", f\"%{q}%\")\n            return self.send(200, rows_as((\"id\", \"title\", \"day\"), rows))\n        file = STATIC / (url.path.lstrip(\"/\") or \"index.html\")\n        if file.resolve().is_relative_to(STATIC.resolve()) and file.is_file():\n            kind = KINDS.get(file.suffix, \"application/octet-stream\")\n            return self.send(200, file.read_bytes(), kind)\n        return self.send(404, {\"error\": \"not found\"})\n", "note": "O auxiliar do banco, a resposta com o cabeçalho `Server-Timing` e todas as rotas `GET` estão exatamente como no `app.py`."}, {"code": "    def do_POST(self):\n        if self.path != \"/bookings\":\n            return self.send(404, {\"error\": \"not found\"})\n        try:\n            order = json.loads(self.rfile.read(int(self.headers.get(\"Content-Length\", 0))))\n            show, seat = int(order[\"show_id\"]), int(order[\"seat\"])\n            customer = str(order[\"customer\"])\n        except (ValueError, KeyError, TypeError):\n            return self.send(400, {\"error\": \"send show_id, seat and customer\"})\n        found = self.query(\"SELECT price_cents, capacity FROM shows\"\n                           \" WHERE id = ? AND on_sale = 1\", show)\n        if not found or not 1 <= seat <= found[0][1]:\n            return self.send(404, {\"error\": \"no such seat on sale\"})\n        try:\n            cur = self.db.execute(\"INSERT INTO bookings (show_id, seat, customer)\"\n                                  \" VALUES (?, ?, ?)\", (show, seat, customer))\n            self.db.commit()\n        except sqlite3.IntegrityError:\n            return self.send(409, {\"error\": \"seat taken\"})\n        start = time.perf_counter()\n        try:\n            pay(customer, found[0][0])\n        except Exception:\n            self.db.execute(\"DELETE FROM bookings WHERE id = ?\", (cur.lastrowid,))\n            self.db.commit()\n            return self.send(502, {\"error\": \"payment failed, seat released\"})\n        self.timing[\"pay\"] += time.perf_counter() - start\n        return self.send(201, {\"id\": cur.lastrowid, \"show_id\": show, \"seat\": seat})\n", "note": "A reserva. **A linha é gravada primeiro**, e o índice único sobre espetáculo e assento decide quem fica com o assento: dois inserts para o mesmo assento não podem dar certo os dois, então o segundo recebe um `IntegrityError` e um 409, sem pagar. Só então o cliente é cobrado, sem trava nenhuma presa, e vinte clientes podem estar pagando ao mesmo tempo. Se o pagamento levantou um erro, a linha é apagada, devolvendo o assento, e a resposta é um 502."}, {"code": "class Server(ThreadingHTTPServer):\n    request_queue_size = 128           # connections waiting to be accepted\n\nif __name__ == \"__main__\":\n    db = sqlite3.connect(DB)\n    db.execute(\"CREATE UNIQUE INDEX IF NOT EXISTS one_booking_per_seat\"\n               \" ON bookings (show_id, seat)\")\n    db.close()\n    host = os.environ.get(\"BOXOFFICE_HOST\", \"127.0.0.1\")\n    server = Server((host, 8000), Box)\n    print(f\"boxoffice on http://{host}:8000\", flush=True)\n    server.serve_forever()", "note": "Uma classe de servidor cuja fila de conexões esperando para serem aceitas guarda 128 em vez das 5 que o Python usa por padrão, explicada em \"Rede e infraestrutura\". Na partida ela cria o índice único de que a reserva depende. Esse índice começa por `show_id`, então ele também atende a contagem das reservas de um espetáculo, que é a correção de \"O banco de dados\" feita de outro jeito."}]}
```

Pare o `app.py` com `Ctrl+C` no terminal dele. Monte um banco novo, para que as reservas das
execuções acima não ocupem os assentos, e inicie o servidor novo nesse terminal:

```
ana@nft:~/boxoffice$ python3 seed.py
1000 shows, 295112 bookings
```

```sh
python3 app_fixed.py
```

Ele imprime a mesma linha `boxoffice on http://127.0.0.1:8000` que o `app.py`, depois de um
instante montando o seu índice. O banco novo não tem mais o índice `bookings_by_show`, e não
precisa dele: o índice único do `app_fixed.py` começa por `show_id` e responde a contagem tão bem
quanto.

## A regra continua valendo

Uma correção que deixa as reservas mais rápidas deixando duas pessoas comprarem um assento não é
correção, então confira a regra primeiro, nas condições mais hostis que você conseguir montar.
Este script inicia vinte threads que tentam todas reservar o assento 1 do espetáculo 990 no mesmo
instante:

```python
# boxoffice/race.py
# Twenty customers try to book seat 1 of show 990 at the same moment, and
# the script counts the answers they got.
import http.client, json, threading
from collections import Counter

answers, lock, start = Counter(), threading.Lock(), threading.Barrier(20)

def book(n):
    conn = http.client.HTTPConnection("127.0.0.1", 8000, timeout=30)
    body = json.dumps({"show_id": 990, "seat": 1, "customer": f"racer{n}"})
    start.wait()                       # all twenty send together
    conn.request("POST", "/bookings", body)
    status = conn.getresponse().status
    with lock:
        answers[status] += 1

threads = [threading.Thread(target=book, args=(n,)) for n in range(20)]
for t in threads:
    t.start()
for t in threads:
    t.join()
print(dict(sorted(answers.items())))
```

`threading.Barrier(20)` segura cada thread até as vinte estarem prontas, então as requisições
saem juntas:

```
ana@nft:~/boxoffice$ python3 race.py
{201: 1, 409: 19}
ana@nft:~/boxoffice$ sqlite3 data/boxoffice.db "SELECT customer FROM bookings WHERE show_id = 990 AND seat = 1"
racer1
```

**Um 201 e dezenove 409, e exatamente uma linha na tabela** para esse assento, de `racer1`. Qual
corredor ganha muda de uma execução para outra; que só um ganhe é a propriedade sob teste, e o
índice único é o que a garante.

## Reservas, depois

```
ana@nft:~/boxoffice$ for w in 1 4 16; do python3 measure.py $w 5 1.0 | sed -n "1,2p;4p"; done
1 workers, 5.0 s: 136 requests, 27.2 per second
status: 201 x112, 409 x24
all           136    36.7    43.7    45.6    46.3    48.7    57.0
4 workers, 5.0 s: 576 requests, 114.5 per second
status: 201 x347, 409 x229
all           576    34.8    44.4    61.4    72.6   116.5   191.8
16 workers, 5.2 s: 1147 requests, 219.1 per second
status: 201 x489, 409 x658
all          1147    70.5    48.0   147.8   257.9   647.8  1281.5
```

| workers | 201 por segundo antes | 201 por segundo depois | mediana depois |
|---|---|---|---|
| 1 | 22.8 | 22.4 | 43.7 ms |
| 4 | 19.8 | 69.4 | 44.4 ms |
| 16 | 22.4 | 94.0 | 48.0 ms |

As reservas bem-sucedidas por segundo são as contagens de 201 divididas pelos segundos
decorridos. Com um worker nada mudou, e nada poderia mudar: um cliente por vez continua pagando
por 40 ms. **A correção é sobre concorrência, não sobre uma reserva**, e com quatro e dezesseis
workers as reservas bem-sucedidas por segundo se multiplicaram enquanto a mediana ficou perto dos
40 ms de um pagamento.

A cauda não sumiu. Com dezesseis workers o p95 é 257.9 ms e o p99 647.8 ms, então alguma outra
coisa agora faz algumas reservas esperarem. Toda reserva agora é uma escrita, e o SQLite deixa uma
conexão fazer commit por vez, então uma fila de commits é a primeira suspeita; "Rede e
infraestrutura" olha o disco. Remover um gargalo sempre revela o próximo, e **o teste termina
quando o próximo está além da carga que o requisito pede**, não quando não sobra nenhum.
