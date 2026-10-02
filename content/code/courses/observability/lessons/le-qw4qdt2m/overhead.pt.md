---
title: Quanto custa
version: 1
---

Envolver cada chamada ao banco e cada requisição HTTP num span é trabalho, e "é barato" é uma
afirmação a medir, não a repetir. O `bench.py` manda 300 pedidos direto ao `orders`, um depois do
outro, e informa quanto cada um levou. Cada pedido é real: uma inserção no banco, uma chamada ao
payments, uma atualização e uma mensagem na fila.

```python
import statistics
import time

import requests

times = []
for n in range(300):
    start = time.perf_counter()
    requests.post("http://orders:8081/orders", timeout=5,
                  json={"sku": "tea-500g", "qty": 1, "total_cents": 3450, "card": "4111 1111 1111 1111"})
    times.append((time.perf_counter() - start) * 1000)
print(f"300 orders: median {statistics.median(times):.1f} ms, mean {statistics.mean(times):.1f} ms")
```

Rodado uma vez contra o `orders` como o laboratório o roda, e de novo com o lançador retirado. O
Compose lê o `compose.override.yaml` por cima do `compose.yaml` quando ele existe, e é assim que o
comando é trocado sem editar o arquivo principal:

```
ana@obs:~/shop$ docker compose run --rm sandbox python bench.py 2>/dev/null
300 orders: median 25.1 ms, mean 26.0 ms
ana@obs:~/shop$ cat compose.override.yaml
services:
  orders:
    command: waitress-serve --port 8081 --threads 16 orders.app:app
ana@obs:~/shop$ docker compose up -d orders 2>&1 | tail -1
 Container shop-orders-1 Started 
ana@obs:~/shop$ docker compose run --rm sandbox python bench.py 2>/dev/null
300 orders: median 24.1 ms, mean 24.8 ms
ana@obs:~/shop$ rm compose.override.yaml && docker compose up -d orders 2>&1 | tail -1
 Container shop-orders-1 Started 
```

**25,1 milissegundos contra 24,1 na mediana**, e 26,0 contra 24,8 na média: cerca de um
milissegundo por pedido, uns quatro por cento, por quatro spans e a exportação deles. A maior parte
dos 25 milissegundos de um pedido é o banco e a chamada ao payments, então a instrumentação é uma
fatia pequena de uma requisição que faz trabalho de verdade. Numa requisição que quase não faz
nada, um acerto de cache respondido em um décimo de milissegundo, o mesmo custo fixo seria a maior
parte do tempo gasto.

Duas coisas que esta medição não diz. Ela rodou com o processor em lote, então a exportação
aconteceu fora do caminho da requisição; a aula 2 mostrou o que o processor simples somaria. E é
uma execução de 300 numa máquina: **uma diferença de um milissegundo está perto do ruído entre duas
execuções**, o que já é a conclusão útil. O custo que vale preocupação raramente é o envolver. É um
span por item dentro de um laço de dez mil, um atributo que serializa um objeto inteiro, ou guardar
todo rastro de um serviço movimentado, e a aula 12 trata do último deles.
