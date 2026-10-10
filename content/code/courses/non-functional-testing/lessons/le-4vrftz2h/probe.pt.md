---
title: Uma sonda sua
version: 1
---

Uma verificação sintética é um script com três deveres: percorrer uma jornada que um cliente
percorre, decidir a cada passo se o que voltou está certo, e dizer o veredito de um jeito com que
uma máquina consiga agir. **A decisão é a parte que as pessoas esquecem.** Um script que busca uma
página e imprime o código de status é um curl num laço; uma sonda sabe qual resposta é uma falha
antes de perguntar.

A jornada aqui é a da própria bilheteria: listar os espetáculos à venda, abrir o primeiro, reservar
um assento nele. Cada passo tem três coisas a conferir, e cada uma pega um defeito diferente:

- **o status**, que pega o servidor recusando ou quebrando;
- **o corpo**, que pega um servidor respondendo 200 sem nada de útil dentro — uma lista de
  espetáculos vazia, uma reserva de outro assento;
- **o tempo**, que pega o servidor que ainda funciona e ficou lento demais para ser usado, a falha
  que um código de status nunca mostra.

Os limites são o mesmo tipo de número que a aula 1 pediu, para uma requisição de cada vez: 300 ms
para listar ou abrir, 500 ms para reservar, medidos no cliente. **Eles são de propósito mais folgados
que um requisito de percentil**, porque uma requisição isolada pode dar azar, e uma sonda que reprova
por azar é uma sonda que alguém aprende a ignorar.

Em `~/monitor`, o diretório que a aula 22 criou, crie o `probe.py`:

```schooling-example
{"language": "python", "file": "monitor/probe.py", "parts": [{"code": "# monitor/probe.py\n# One synthetic customer: list the shows, open one, book a seat. Prints one\n# line and exits 0 if every step met its threshold, 1 if any step did not.\nimport json, random, sys, time, urllib.error, urllib.request\nfrom datetime import datetime\n", "note": "Só a biblioteca padrão, como a boxoffice, então a sonda roda em qualquer máquina que tenha Python e mais nada, o que importa quando ela passa a rodar em máquinas das quais você não cuida no resto do tempo."}, {"code": "BASE = \"http://127.0.0.1:8000\"\nCUSTOMER = \"synthetic-probe\"         # every booking it makes says so\nLIMIT_MS = {\"list\": 300, \"show\": 300, \"book\": 500}\n", "note": "Tudo o que muda entre ambientes fica no alto. `CUSTOMER` é o nome da própria sonda, para toda reserva que ela faz poder ser separada de uma real. `LIMIT_MS` é o limite por passo, as cinco partes da aula 1 em miniatura: a operação, a estatística (esta requisição) e o número."}, {"code": "def call(method, path, body=None):\n    data = json.dumps(body).encode() if body is not None else None\n    req = urllib.request.Request(BASE + path, data=data, method=method,\n                                 headers={\"Content-Type\": \"application/json\"})\n    start = time.perf_counter()\n    try:\n        with urllib.request.urlopen(req, timeout=5) as r:\n            status, raw, rid = r.status, r.read(), r.headers.get(\"X-Request-Id\")\n    except urllib.error.HTTPError as e:\n        status, raw, rid = e.code, e.read(), e.headers.get(\"X-Request-Id\")\n    ms = (time.perf_counter() - start) * 1000\n    return status, json.loads(raw or b\"null\"), ms, rid\n", "note": "Uma requisição HTTP, cronometrada do lado do cliente, do jeito que um cliente espera por ela. Um 4xx ou 5xx levanta `HTTPError` no `urllib`, então ele é capturado e vira de novo um status. Um servidor que não está lá levanta outra coisa, que o `journey` não captura e as últimas linhas capturam. O id da requisição volta no cabeçalho do `observed.py`."}, {"code": "steps = []\n\ndef check(name, status, want, ms, rid):\n    steps.append(f\"{name}={status}/{ms:.0f}ms\")\n    if status != want:\n        raise AssertionError(f\"{name}: wanted {want}, got {status} (request {rid})\")\n    if ms > LIMIT_MS[name]:\n        raise AssertionError(f\"{name}: {ms:.0f} ms is over {LIMIT_MS[name]} ms (request {rid})\")\n", "note": "Cada passo deixa o seu status e o seu tempo em `steps`, para a linha de resultado dizer até onde a jornada chegou. O `check` reprova no status errado ou num tempo acima do limite, e a mensagem leva o id da requisição, para a falha poder ser procurada no log do servidor."}, {"code": "def journey():\n    status, shows, ms, rid = call(\"GET\", \"/shows\")\n    check(\"list\", status, 200, ms, rid)\n    if not shows:\n        raise AssertionError(\"list: no show on sale\")\n    status, show, ms, rid = call(\"GET\", f\"/shows/{shows[0]['id']}\")\n    check(\"show\", status, 200, ms, rid)\n    if show[\"left\"] < 1:\n        raise AssertionError(\"show: no seat left to book\")\n    for _ in range(5):\n        seat = random.randint(1, show[\"capacity\"])\n        status, booked, ms, rid = call(\"POST\", \"/bookings\",\n                                       {\"show_id\": show[\"id\"], \"seat\": seat, \"customer\": CUSTOMER})\n        if status != 409:              # 409: a real customer has that seat, try another\n            break\n    check(\"book\", status, 201, ms, rid)\n    if booked.get(\"seat\") != seat:\n        raise AssertionError(f\"book: asked for seat {seat}, got {booked}\")\n", "note": "A jornada: listar os espetáculos, abrir o primeiro, reservar um assento aleatório dele. Um 409 quer dizer que um cliente real já tem aquele assento, que é a bilheteria funcionando, então a sonda tenta outro assento até cinco vezes. O corpo também é conferido: um 201 que reservou outro assento é uma falha que nenhum código de status mostraria."}, {"code": "if __name__ == \"__main__\":\n    try:\n        journey()\n        verdict, why = \"PASS\", []\n    except (AssertionError, OSError, ValueError, KeyError) as e:\n        verdict, why = \"FAIL\", [f\"-- {e}\"]\n    print(\" \".join([datetime.now().strftime(\"%H:%M:%S\"), verdict] + steps + why), flush=True)\n    sys.exit(0 if verdict == \"PASS\" else 1)", "note": "Uma linha, um código de saída. `0` quer dizer que todo passo passou e `1` que algum não passou, que é com o que um agendador, um laço do shell ou o alerta da aula 24 conseguem agir sem ler a linha."}]}
```

## Rodando

A sonda mira o `observed.py`, a versão da bilheteria da aula 22, para as falhas dela poderem ser
procuradas num log. No primeiro terminal, em `~/boxoffice`:

```sh
python3 observed.py > requests.log
```

No segundo, em `~/monitor`, rode a sonda uma vez e peça o código de saída:

```
ana@nft:~/monitor$ python3 probe.py; echo "exit $?"
16:33:05 PASS list=200/34ms show=200/16ms book=201/56ms
exit 0
```

Três passos, três status, três tempos, e `exit 0`. A listagem levou mais que abrir um espetáculo,
embora o servidor trabalhe muito menos para ela: o que a sonda cronometra inclui tudo o que acontece
do lado do cliente além do lado do servidor, que é o motivo para cronometrar de fora.

Agora pare o servidor com `Ctrl+C` no primeiro terminal e rode a sonda de novo:

```
ana@nft:~/monitor$ python3 probe.py; echo "exit $?"
16:33:06 FAIL -- <urlopen error [Errno 111] Connection refused>
exit 1
```

Nenhum passo recebeu resposta, então não há status para imprimir, e o erro é do sistema
operacional: nada escutando na porta. **Esta é a falha que as métricas da aula 22 não conseguem
ver**, porque o processo que a contaria é justamente o que sumiu. As métricas simplesmente param, e
o `up` só vai a 0 se o próprio Prometheus ainda estiver rodando e conseguir chegar aonde a boxoffice
estava.
