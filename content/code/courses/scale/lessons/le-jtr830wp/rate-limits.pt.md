---
title: Limites de taxa, um chamador por vez
version: 1
---

Um **limite de taxa** limita com que frequência um chamador pode pedir. Numa bilheteria, o chamador
que vale limitar é o robô que tenta comprar um show inteiro no primeiro segundo de uma abertura de
vendas; em outros lugares é uma chave de API, uma conta ou um endereço. A bilheteria limita **compras
por comprador**, identificado aqui por um cabeçalho `X-Buyer`, onde um sistema real usaria a conta
logada.

## O balde de fichas

O algoritmo comum é um **balde de fichas** (*token bucket*). Cada comprador tem um balde que guarda no
máximo `burst` fichas e se enche a `rate` fichas por segundo. Uma compra pega uma ficha; sem nenhuma
sobrando ela é recusada, e o tempo até a próxima ficha diz a quem chamou quando voltar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Um balde para um comprador, com no máximo cinco fichas. As fichas pingam de cima a duas por segundo. Cada compra tira uma ficha por baixo e segue; uma compra que acha o balde vazio é recusada com 429 e um Retry-After do tempo até a próxima ficha.\"><text x=\"250\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">taxa: 2 fichas por segundo</text><path d=\"M250 34 L250 62\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M250 62 L247.0 55.7 L253.0 55.7 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><path d=\"M 170 70 L 185 190 L 315 190 L 330 70\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"205\" cy=\"175\" r=\"9\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"227\" cy=\"175\" r=\"9\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"249\" cy=\"175\" r=\"9\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"271\" cy=\"175\" r=\"9\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"293\" cy=\"175\" r=\"9\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"345\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">rajada: 5</text><path d=\"M250 192 L250 222\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M250 222 L247.0 215.7 L253.0 215.7 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"250\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">cada compra leva uma</text><rect x=\"470\" y=\"60\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">sobra ficha</text><text x=\"580\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">→ a venda segue</text><rect x=\"470\" y=\"140\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">balde vazio</text><text x=\"580\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">→ 429, Retry-After</text></svg>", "caption": "Um balde de fichas: a taxa o enche, a rajada é o tamanho dele.", "same": ["→ 429, Retry-After"]}
```

Dois números, dois significados. `rate` é o limite a longo prazo, aqui duas compras por segundo.
`burst` é quanto um chamador quieto pode fazer de uma vez, aqui cinco, para que alguém comprando
ingressos para a família não seja punido por clicar rápido. As alternativas se comportam pior nas
bordas. Uma **janela fixa**, no máximo 120 por minuto contados por minuto do relógio, deixa um
chamador mandar 120 às 10:00:59 e mais 120 às 10:01:00. Um **balde furado** (*leaky bucket*) enfileira
os pedidos e os solta num ritmo constante, que é o que o `limit_req` do próprio nginx faz; ele suaviza
o tráfego em vez de recusá-lo.

## Testando

Este programa faz o papel de um comprador clicando o mais rápido que consegue, e conta as respostas
segundo a segundo. Salve-o como `attempts.py`:

```python
# attempts.py
"""One buyer trying to buy as fast as it can, counted second by second."""
import argparse
import http.client
import time
from collections import Counter

p = argparse.ArgumentParser()
p.add_argument("buyer")
p.add_argument("-d", "--seconds", type=int, default=5)
p.add_argument("--event", type=int, default=1)
args = p.parse_args()

conn = http.client.HTTPConnection("localhost", 8080)
retry_after = None
seconds = [Counter() for _ in range(args.seconds)]
start = time.monotonic()
while (elapsed := time.monotonic() - start) < args.seconds:
    conn.request("POST", f"/events/{args.event}/tickets",
                 headers={"X-Buyer": args.buyer, "Content-Length": "0"})
    answer = conn.getresponse()
    answer.read()
    seconds[int(elapsed)][answer.status] += 1
    if answer.status == 429:
        retry_after = answer.getheader("Retry-After")

for n, counts in enumerate(seconds):
    print(f"second {n + 1}  " + "  ".join(f"{s}: {c:3}" for s, c in sorted(counts.items())))
total = sum(seconds, Counter())
print(f"bought {total[201]}, refused {total[429]}, last Retry-After {retry_after} s")
```

O robô, por cinco segundos:

```
ana@lab:~/tickets$ python3 attempts.py bot-7
second 1  201:   6  429: 516
second 2  201:   2  429: 585
second 3  201:   2  429: 712
second 4  201:   2  429: 724
second 5  201:   2  429: 766
bought 14, refused 3303, last Retry-After 1 s
ana@lab:~/tickets$ python3 attempts.py fan-12 -d 2
second 1  201:   6  429: 598
second 2  201:   2  429: 691
bought 8, refused 1289, last Retry-After 1 s
```

**Seis compras no primeiro segundo**: as cinco do balde cheio, e mais uma que pingou enquanto o robô
as gastava. **Depois duas por segundo**, exatamente a taxa, e entre 500 e 800 recusas por segundo no
meio, cada uma respondida com `429 Too Many Requests` e `Retry-After: 1`. Catorze em cinco segundos,
que são cinco mais duas por segundo nos quatro segundos e meio depois do primeiro. Um segundo
comprador, `fan-12`, não é afetado pelo balde vazio do robô: cada chave tem o seu.

## Por que o balde fica no Redis

Um limite guardado na memória de cada cópia é um limite por cópia. Atrás do nginx, com três cópias, o
robô ganharia três baldes e três vezes a taxa, e o limite mudaria toda vez que alguém mudasse o
número de cópias. Então o balde mora no Redis, e toda cópia pergunta ao mesmo:

```
ana@lab:~/tickets$ docker compose up -d --scale app=3
 Container tickets-prometheus-1 Running 
 Container tickets-app-1 Running 
 Container tickets-replica-1 Running 
 Container tickets-redis-1 Running 
 Container tickets-db-1 Running 
 Container tickets-lb-1 Running 
 Container tickets-payments-1 Running 
 Container tickets-collector-1 Running 
 Container tickets-jaeger-1 Running 
 Container tickets-app-3 Creating 
 Container tickets-app-2 Creating 
 Container tickets-app-3 Created 
 Container tickets-app-2 Created 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Waiting 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Healthy 
 Container tickets-app-3 Starting 
 Container tickets-app-3 Started 
 Container tickets-app-2 Starting 
 Container tickets-app-2 Started 
ana@lab:~/tickets$ docker compose restart lb
 Container tickets-lb-1 Restarting 
 Container tickets-lb-1 Started 
ana@lab:~/tickets$ python3 attempts.py bot-9
second 1  201:   6  429: 490
second 2  201:   2  429: 635
second 3  201:   2  429: 592
second 4  201:   2  429: 462
second 5  201:   2  429: 611
bought 14, refused 2790, last Retry-After 1 s
```

Três cópias, e as mesmas catorze compras em cinco segundos. O preço é uma ida e volta pela rede até o
Redis em toda venda, e uma decisão sobre o que acontece quando o Redis está fora. A bilheteria
**falha aberta** (*fails open*): se o Redis não responder, a venda segue e um aviso vai para o log.
Este limite é sobre justiça entre compradores, e recusar toda venda porque a verificação de justiça
caiu transformaria uma queda do Redis numa queda da bilheteria. Um limite que protege algo frágil,
como uma busca cara, poderia razoavelmente falhar fechado.
