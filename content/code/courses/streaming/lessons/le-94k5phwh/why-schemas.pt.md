---
title: Por que um stream precisa de um esquema
version: 1
---

**Uma mensagem no Kafka é uma chave e um valor, e os dois são bytes.** O broker nunca olha dentro
deles: guarda o que o produtor mandou e entrega a quem pedir. Então o formato de uma venda — que
campos ela tem, como se chamam, de que tipo é cada um — não está escrito em nenhum lugar que o
Kafka enxergue. Ele vive em dois lugares ao mesmo tempo: no código que escreve as vendas e no
código que as lê. Enquanto os dois foram escritos no mesmo dia pela mesma pessoa, eles concordam.

A ideia errada é que o JSON resolve isso por ser autodescritivo. O JSON carrega os **nomes** dos
campos em cada mensagem, o que não é o mesmo que carregar um acordo sobre eles. Um leitor que
encontra um nome que não conhece o ignora, e um leitor que não encontra um nome que esperava recebe
nada e segue em frente. Nada falha, e o problema é justamente esse.

## Um campo renomeado numa segunda-feira

Eis um leitor do tipo que toda equipe escreve primeiro. Ele soma o dinheiro por loja de todas as
vendas de um tópico de vendas em JSON, e usa `.get` com um valor padrão, porque alguém já o viu
quebrar numa venda sem um campo. Salve como `~/work/totals.py`:

```python
"""totals.py: money per shop, from every JSON sale in a topic."""
import json
import sys
import uuid
from collections import Counter

from confluent_kafka import Consumer

topic = sys.argv[1] if len(sys.argv) > 1 else "sales-json"
consumer = Consumer({"bootstrap.servers": "localhost:9092",
                     "group.id": f"totals-{uuid.uuid4()}",
                     "auto.offset.reset": "earliest"})
consumer.subscribe([topic])

cents, count = Counter(), 0
while (msg := consumer.poll(10)) is not None:
    sale = json.loads(msg.value())
    cents[sale["shop"]] += sale.get("cents", 0)
    count += 1
consumer.close()

print(f"{count} sales")
for shop, total in sorted(cents.items()):
    print(f"{shop:12} {total / 100:10.2f}")
```

O `group.id` é novo a cada execução, então cada execução lê o tópico desde a primeira mensagem; o
`poll(10)` sem devolver nada por dez segundos é tomado como o fim. Crie um tópico de vendas em
JSON, ponha nele vinte vendas com o caixa da lição 1 e some:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales-json --partitions 3
Created topic sales-json.
ubuntu@stream:~/work$ python tills.py --count 20 --rate 0 --topic sales-json
sent 20 sales to sales-json, the last one at 09:02:55
ubuntu@stream:~/work$ python totals.py
20 sales
caruaru          398.50
joao-pessoa      159.90
natal            877.10
olinda           330.80
recife           531.30
```

Agora os caixas são atualizados. O software novo está certo em tudo menos numa coisa: o programador
achou `amount` um nome mais claro que `cents`. Salve como `~/work/till_v2.py`:

```python
"""till_v2.py: five sales from the new till software, which calls the money `amount`."""
import json

from confluent_kafka import Producer

producer = Producer({"bootstrap.servers": "localhost:9092"})
for n in range(1, 6):
    sale = {"sale": f"rec-9{n:05d}", "shop": "recife", "book": "bk-04", "qty": 1,
            "amount": 7900, "at": f"2026-03-02T11:0{n}:00-03:00"}
    producer.produce("sales-json", key="recife", value=json.dumps(sale))
producer.flush()
print("sent 5 sales from the new till")
```

Mais cinco vendas do Recife, e os totais de novo:

```
ubuntu@stream:~/work$ python till_v2.py
sent 5 sales from the new till
ubuntu@stream:~/work$ python totals.py
25 sales
caruaru          398.50
joao-pessoa      159.90
natal            877.10
olinda           330.80
recife           531.30
```

**Vinte e cinco vendas, e o total do Recife não se mexeu**: 531.30 antes do caixa novo e 531.30
depois, embora o Recife tenha acabado de vender cinco exemplares de `bk-04` a 79.00 cada. Os 395.00
estão no tópico, num campo chamado `amount`, e `sale.get("cents", 0)` devolveu cinco vezes o 0 que
mandaram devolver. Nenhum erro, nenhum aviso, nenhuma linha de log. A contagem de vendas está
certa, o que faz o total parecer conferido.

É esse o formato da falha que um esquema existe para evitar. O produtor e o consumidor nunca se
encontraram; eles compartilhavam um **palpite** sobre como é uma venda, escrito em dois programas,
e um deles mudou a sua metade. Uma queda teria sido melhor: alguém teria ido olhar. O relatório que
vai para a gerente amanhã está errado, e nada no sistema sabe disso.

## Onde o acordo precisa morar

O conserto não é um `.get` melhor. Um leitor que quebra na primeira venda sem `cents` pelo menos
teria dito alguma coisa, e um leitor que tenta `cents`, depois `amount`, depois `price` só espalhou
o palpite por mais lugares. O que faltava era uma **descrição escrita de uma venda**, que os dois
lados usem e que não possa mudar sem que alguém confira a mudança contra os leitores. Essa
descrição é um **esquema**, e o resto desta lição é a maquinaria em volta de um:

- um formato que não pode ser escrito sem esquema, o **Avro**, na próxima seção;
- um serviço que guarda cada versão e dá um número a cada uma, o **registro de esquemas**
  (*schema registry*);
- uma regra que o registro aplica a cada versão nova antes de aceitá-la, a **compatibilidade**.

A lição 2 disse que um evento deve carregar uma versão do próprio formato. Um registro é onde essas
versões ficam guardadas, e o número que o produtor põe em cada mensagem é como um leitor encontra
aquela com que a mensagem foi escrita.
