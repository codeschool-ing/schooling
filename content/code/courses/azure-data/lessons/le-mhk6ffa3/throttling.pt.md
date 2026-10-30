---
title: A requisição que sofre throttling, e a partição que a causa
version: 1
---

**Quando as operações de um segundo precisam de mais unidades de requisição do que aquele segundo
tem, o Cosmos DB recusa o resto**: HTTP 429, *request rate is large*, com subestado 3200 quando a causa
é o orçamento de vazão, e nada é gravado. A resposta traz um cabeçalho, `x-ms-retry-after-ms`, dizendo
quanto esperar até a requisição poder dar certo. As bibliotecas esperam esse tempo e mandam de novo, e
é por isso que um programa encontra o throttling primeiro como lentidão e só depois, se encontrar, como
erro. Esta seção é ensinada a partir da documentação da Microsoft, com um programa rodado no emulador
para mostrar que o emulador nunca diz não.

## O orçamento é por segundo e por partição

A vazão de um contêiner é dividida igualmente entre as partições físicas dele, e a documentação limita
uma partição física a 10.000 RU/s e 50 GB. Um contêiner com 30.000 RU/s em três partições físicas tem
então 10.000 por segundo em cada uma. **Uma requisição sofre throttling quando a própria partição
acabou, seja o que for que as outras ainda tenham.** Uma partição lógica, todos os itens com a mesma
chave, mora numa partição física, então 10.000 RU/s é também o máximo que uma chave consegue ter.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 296\" role=\"img\" aria-label=\"Dois contêineres de 30.000 RU/s, cada um espalhado por três partições físicas com orçamento de 10.000 RU/s cada. À esquerda, com chave por dia: a chave de hoje, 2026-10-30, pede 14.000 RU/s à partição dela, enche até o limite e recebe respostas 429, enquanto as outras duas partições ficam quase paradas. À direita, com chave por cliente: a mesma carga se espalha a cerca de 4.900 RU/s em cada partição, abaixo do limite.\" data-fig=\"l13-hot\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">uma chave por dia</text><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/day</text><line x1=\"20\" y1=\"70\" x2=\"320\" y2=\"70\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"320\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">10.000 RU/s por partição física</text><rect x=\"32\" y=\"70\" width=\"76\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"36\" y=\"70.0\" width=\"68\" height=\"150.0\" rx=\"2\" fill=\"var(--amber)\"/><text x=\"70\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partição 1</text><text x=\"70\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2026-10-30</text><text x=\"70\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--ink)\" font-weight=\"600\">429</text><rect x=\"132\" y=\"70\" width=\"76\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"136\" y=\"215.5\" width=\"68\" height=\"4.5\" rx=\"2\" fill=\"var(--phosphor)\"/><text x=\"170\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partição 2</text><text x=\"170\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">…</text><rect x=\"232\" y=\"70\" width=\"76\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"236\" y=\"215.5\" width=\"68\" height=\"4.5\" rx=\"2\" fill=\"var(--phosphor)\"/><text x=\"270\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partição 3</text><text x=\"270\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">…</text><text x=\"380\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">uma chave por cliente</text><text x=\"380\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/customerId</text><line x1=\"380\" y1=\"70\" x2=\"680\" y2=\"70\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"680\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">10.000 RU/s por partição física</text><rect x=\"392\" y=\"70\" width=\"76\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"396\" y=\"146.5\" width=\"68\" height=\"73.5\" rx=\"2\" fill=\"var(--phosphor)\"/><text x=\"430\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partição 1</text><text x=\"430\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">c-1 … c-7</text><rect x=\"492\" y=\"70\" width=\"76\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"496\" y=\"148.0\" width=\"68\" height=\"72.0\" rx=\"2\" fill=\"var(--phosphor)\"/><text x=\"530\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partição 2</text><text x=\"530\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">c-8 …</text><rect x=\"592\" y=\"70\" width=\"76\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"596\" y=\"146.5\" width=\"68\" height=\"73.5\" rx=\"2\" fill=\"var(--phosphor)\"/><text x=\"630\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partição 3</text><text x=\"630\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">…</text><text x=\"360\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Os mesmos 14.600 RU/s, dentro do mesmo contêiner de 30.000 RU/s.</text></svg>", "caption": "A vazão de um contêiner é dividida entre as partições físicas, e uma chave que manda tudo para uma delas sofre throttling enquanto o contêiner está quase parado."}
```

**Uma chave que concentra a carga é uma partição quente**, e a escolha de chave da lição 11 é onde ela é
evitada. Com chave por dia, todo pedido de uma noite de promoção vai para a chave de hoje e a partição
dela, e sofre throttling enquanto dois terços da capacidade paga ficam parados. Com chave por cliente,
os mesmos pedidos se espalham por todas as partições. Nenhuma opção aumenta o teto de uma chave: mais
vazão acrescenta partições e espalha as outras chaves mais fino, e a quente continua sozinha na dela.

## Lendo os sintomas

O monitoramento da Microsoft para o Cosmos DB mostra dois números que vale conhecer pelo nome. **Total
requests dividido por código de status** conta os 429. **Normalized RU Consumption**, escrito como a
métrica se escreve, é a fração do orçamento gasta pela partição mais ocupada, minuto a minuto, e 100%
quer dizer que pelo menos uma partição gastou tudo o que tinha em pelo menos um segundo daquele
minuto. Um contêiner cujo consumo normalizado fica em 100% enquanto o consumo total é baixo tem uma
partição quente, e a correção é a chave, não a vazão. A documentação diz também que uma pequena parte
de 429, alguns por cento, com latência aceitável é um contêiner fazendo o seu trabalho: as repetições
os absorvem, e a capacidade está sendo usada em vez de ficar parada.

## O que o emulador faz em vez disso

**O emulador nunca faz throttling.** O `flood.py` cria um contêiner de 400 RU/s e grava 2.000 pedidos
nele tão rápido quanto um programa consegue, somando as tentativas com throttling que a biblioteca
informa depois de cada escrita:

`flood.py`:

```python
import time

from azure.cosmos import CosmosClient, PartitionKey

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
client = CosmosClient("http://localhost:8081", KEY)
db = client.create_database_if_not_exists("quitanda")
orders = db.create_container_if_not_exists("promo", PartitionKey("/customerId"),
                                           offer_throughput=400)

retried, start = 0, time.time()
for i in range(2000):
    orders.upsert_item({"id": f"o-{i:05d}", "customerId": f"c-{i % 50}", "totalCents": 4890})
    headers = orders.client_connection.last_response_headers
    retried += int(headers.get("x-ms-throttle-retry-count", 0))
took = time.time() - start
print(f"2000 writes in {took:.1f} s, {2000 / took:.0f} a second, {retried} retried after a 429")
```

```
ana@laptop:~/azure$ python flood.py
2000 writes in 12.8 s, 156 a second, 0 retried after a 429
```

**2.000 escritas em 12,8 segundos, 156 por segundo, num contêiner criado com 400 RU/s, e nenhuma foi
repetida.** O Azure não foi consultado. Com as 6 unidades de requisição ilustrativas por escrita da
seção anterior, 400 RU/s aguentam cerca de 66 escritas por segundo, então aqueles 12,8 segundos teriam
levado cerca de 850 delas. O resto teria recebido 429 e sido repetido depois da espera que cada
resposta indicasse, esticando o mesmo programa para uns trinta segundos. **Um teste de carga contra o
emulador mede o seu programa e o seu notebook, nunca o Cosmos DB.** A capacidade de um projeto se
confere com a aritmética desta lição e com uma conta real e um orçamento, não aqui.
