---
title: Linhas estruturadas, escritas para serem consultadas
version: 1
---

Uma linha de log escrita para uma pessoa ler, `checkout failed for c-1027 after 512ms`, é fácil de
escrever e difícil de interrogar: cada pergunta vira uma expressão regular que quebra quando alguém
edita a frase. **Uma linha escrita como JSON é um registro**, com campos que uma consulta pode nomear.
A API da loja escreve um objeto por requisição: o status, o caminho, a latência e o cliente.

Não há API de verdade neste laboratório, então as linhas vêm de um programa que escreve 300 delas como
a API escreveria, com uma semente fixa para que as contagens desta seção sejam as mesmas toda vez que
ele rodar. `/checkout` falha 6% das requisições e fica lento 8% das vezes, `/cart` falha 2%:

```python
# traffic.py: 300 log lines from the shop's API, as CloudWatch Logs events
import json
import random
import time

rng = random.Random(7)
now = int(time.time() * 1000)
paths = ["/", "/cart", "/checkout", "/search"]
failing = {"/checkout": 0.06, "/cart": 0.02}

events = []
for i in range(300):
    path = rng.choice(paths)
    slow = path == "/checkout" and rng.random() < 0.08
    line = {
        "status": 503 if rng.random() < failing.get(path, 0) else 200,
        "path": path,
        "ms": rng.randint(700, 1500) if slow else rng.randint(20, 90),
        "customer": f"c-{rng.randint(1000, 1039)}",
    }
    events.append({"timestamp": now - (300 - i) * 1000, "message": json.dumps(line)})

print(json.dumps(events))
```

A saída já tem o formato que o `put-log-events` recebe: uma lista de eventos, cada um com um timestamp
em milissegundos e uma mensagem.

```
ana@laptop:~/aws/logs$ python3 traffic.py > events.json
ana@laptop:~/aws/logs$ jq length events.json && jq -r '.[0].message' events.json
300
{"status": 200, "path": "/checkout", "ms": 26, "customer": "c-1004"}
ana@laptop:~/aws/logs$ aws logs create-log-stream --log-group-name /shop/api --log-stream-name api-1
ana@laptop:~/aws/logs$ aws logs put-log-events --log-group-name /shop/api --log-stream-name api-1 --log-events file://events.json --query 'rejectedLogEventsInfo'
null
```

`rejectedLogEventsInfo` é `null`: todo evento foi aceito. O CloudWatch recusa eventos com mais de 14
dias ou mais de duas horas no futuro, e avisa nesse campo, que vale conferir em qualquer programa que
mande logs.

## Padrões de filtro

`filter-log-events` recebe um **padrão de filtro**, uma pequena linguagem própria: uma palavra solta
casa com linhas que a contêm, e `{ $.status >= 500 }` casa com linhas JSON cujo campo `status` seja 500
ou mais.

```
ana@laptop:~/aws/logs$ aws logs filter-log-events --log-group-name /shop/api --filter-pattern '{ $.status >= 500 }' --query 'length(events)'
300
ana@laptop:~/aws/logs$ aws logs filter-log-events --log-group-name /shop/api --filter-pattern 'checkout' --query 'length(events)'
69
```

A palavra casou com 69 linhas, as requisições a `/checkout`. **O padrão JSON casou com as 300**, o que
está errado: só um punhado de linhas tem status 500 ou mais. O moto aplica padrões de palavra simples e
ignora os JSON. Na AWS o segundo comando contaria os erros, que é o que a próxima seção faz de outro
jeito.
