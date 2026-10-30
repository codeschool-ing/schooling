---
title: Transações, e páginas lidas com um cursor
version: 1
---

**Uma transação do Firestore lê documentos, decide e escreve, e as escritas acontecem juntas ou não
acontecem.** A regra que a torna segura é a que o Spanner da aula 9 ensinou: leia dentro da transação,
nunca antes dela, porque a biblioteca cliente pode rodar a função de novo. No Firestore é ainda mais
estrita: toda leitura de uma transação precisa vir antes da primeira escrita, e uma transação que
descobre que outra mudou o que ela leu é repetida desde o começo, com o valor como ele está agora.

**A ideia errada é que um contador não precisa de transação.** Ler o estoque, subtrair e gravar de volta
parece um passo e são três, e dois clientes fazendo isso no mesmo instante leem 10, gravam 4, e doze
bananas saem de uma loja que tinha dez. Uma transação é o jeito de os dois tentarem e só um conseguir.

## As últimas dez bananas

`stock.py`:

```python
#!/usr/bin/env python3
"""Two customers try to buy 6 of the last 10 bananas at the same moment."""
import threading

from google.cloud import firestore

db = firestore.Client(project='planner-dev')
stock = db.collection('stock').document('banana')
stock.set({'units': 10})
attempts = {'c-17': 0, 'c-18': 0}


@firestore.transactional
def buy(transaction, customer, units):
    attempts[customer] += 1
    left = stock.get(transaction=transaction).get('units')
    if left < units:
        return f'{customer}: refused, {left} left'
    transaction.update(stock, {'units': left - units})
    transaction.set(db.collection('customers').document(customer).collection('orders').document(),
                    {'product': 'banana', 'units': units})
    return f'{customer}: bought {units}, {left - units} left'


def shopper(customer):
    print(buy(db.transaction(), customer, 6), f'(attempt {attempts[customer]})')


threads = [threading.Thread(target=shopper, args=(c,)) for c in attempts]
for t in threads:
    t.start()
for t in threads:
    t.join()
print('units now', stock.get().get('units'))
```

**Duas threads, dois clientes, seis bananas cada, dez em estoque.** Cada uma roda a mesma transação, e
`attempts` conta quantas vezes a função rodou para cada cliente:

```
ana@laptop:~/gcp$ python3 stock.py
c-18: bought 6, 4 left (attempt 3)
c-17: refused, 4 left (attempt 4)
units now 4
ana@laptop:~/gcp$ python3 stock.py
c-18: bought 6, 4 left (attempt 1)
c-17: refused, 4 left (attempt 2)
units now 4
```

**Em cada execução, um cliente comprou seis e o outro foi recusado, com quatro sobrando.** Na primeira
execução as duas transações colidiram mais de uma vez: cada uma leu dez, descobriu na hora do commit
que a outra tinha mexido no mesmo documento, e rodou de novo, até `c-18` confirmar na terceira
tentativa e `c-17`, na quarta, ler quatro e recusar. Na segunda execução `c-18` confirmou de cara e
`c-17` precisou de uma repetição. Qual cliente ganha, e depois de quantas tentativas, é questão de
tempo. **O estoque nunca ficou abaixo de zero**, e esse é o ponto inteiro: a conta está certa em todo
entrelaçamento, não só no de sorte.

**As bibliotecas cliente de servidor, como a do Python, travam** o que uma transação lê, e é assim que a
segunda transação soube que a leitura dela tinha ficado velha; a documentação do Google descreve os
SDKs móveis e web como otimistas, repetindo quando o commit encontra um conflito. Os dois repetem, e a
mesma regra vale para os dois: a função precisa ser segura para rodar duas vezes.

**Um documento que todo pedido grava é um hotspot próprio.** O Firestore documenta uma taxa sustentada
de cerca de uma escrita por segundo num documento. Um contador de estoque gravado por todo pedido no
pico da noite passa disso, e por isso um contador de muito tráfego é espalhado por vários documentos,
os **contadores distribuídos** (*distributed counters*) do próprio guia do Google, que uma leitura
soma.

**Um lote é a transação sem as leituras.** O `seed.py` gravou setenta e três documentos num lote, e eles
ficaram visíveis juntos, tudo ou nada, que é tudo o que uma transação promete sobre escritas. O que um
lote não consegue é ler: não há nada com que decidir, então ele nunca precisa de repetição nem disputa
o que leu. Escritas que não dependem do que está guardado, como carregar os produtos novos do dia,
cabem num lote; tudo o que lê antes de escrever, como o estoque, precisa da transação.

## Páginas, com um cursor e não com um offset

**Uma consulta lê na ordem do índice, então uma página é uma posição no índice.** O jeito de pedir a
próxima página é entregar ao Firestore o último documento da anterior, um **cursor**, e dizer "comece
depois deste". O índice é então lido a partir desse ponto, e nada antes dele é tocado.

`pages.py`:

```python
#!/usr/bin/env python3
"""Page through every order, ten at a time, with a cursor."""
from google.cloud import firestore

db = firestore.Client(project='planner-dev')
query = db.collection_group('orders').order_by('day').order_by('total_cents').limit(10)

page, last = 1, None
while True:
    docs = list((query.start_after(last) if last else query).stream())
    if not docs:
        break
    print(f'page {page}: {len(docs):>2} orders, {docs[0].get("day")} to {docs[-1].get("day")}')
    page, last = page + 1, docs[-1]
```

```
ana@laptop:~/gcp$ python3 pages.py
page 1: 10 orders, 2026-10-02 to 2026-10-05
page 2: 10 orders, 2026-10-05 to 2026-10-11
page 3: 10 orders, 2026-10-11 to 2026-10-15
page 4: 10 orders, 2026-10-15 to 2026-10-18
page 5: 10 orders, 2026-10-21 to 2026-10-27
page 6:  3 orders, 2026-10-28 to 2026-10-29
```

**Cinquenta e três pedidos em seis páginas**, cada página começando onde a anterior acabou. A consulta
ordena por `day` e depois por `total_cents`, para que dois pedidos do mesmo dia ainda tenham ordem fixa
e o cursor saiba exatamente onde parou. No Google Cloud duas ordenações são um índice composto próprio,
e o emulador, como a seção anterior descobriu, não pediu por ele.

**Um offset é o outro jeito de paginar, e é cobrado.** `offset(40).limit(10)` devolve dez documentos e,
pelo próprio exemplo da página de preços, cobra uma leitura por documento pulado também: a página
cinco custa cinquenta leituras em vez de dez, e a página cem, mil. Um cursor custa dez leituras em toda
página. O emulador devolve os mesmos documentos dos dois jeitos, e não há conta no laptop para mostrar
a diferença, e por isso ela está escrita aqui em vez de medida.
