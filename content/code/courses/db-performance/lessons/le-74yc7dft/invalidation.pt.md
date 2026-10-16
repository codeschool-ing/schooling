---
title: Invalidação, e o valor velho gravado de volta
version: 1
---

O conserto óbvio para o minuto velho é apagar a chave quando o dado muda: quem escreve confirma o
pedido, depois apaga `dashboard:7`, e a leitura seguinte falha no cache e busca a verdade. Isso é a
**invalidação**, e é o que quase toda aplicação com cache faz. É também a origem da frase mais famosa
sobre caches, a de que invalidar é uma das duas coisas difíceis da computação. A crença a corrigir é
a de que apagar ao escrever fecha a janela. **Ela a estreita, e deixa uma corrida que grava um valor
velho de volta depois do delete.**

## A corrida

Três coisas acontecem, nesta ordem, em dois processos diferentes:

1. Um leitor não acha a chave e roda a consulta do painel. O banco responde com os pedidos como estão
   agora.
2. Antes de o leitor guardar essa resposta, quem escreve faz um pedido, confirma e apaga a chave.
3. O leitor, que não sabe nada da escrita, guarda a resposta que leu no passo 1.

O delete do passo 2 removeu uma chave que ainda nem estava lá. O valor guardado no passo 3 foi lido
antes da escrita, e agora fica no cache, com cara de novo, por um TTL inteiro. Nada falhou, nenhum
erro apareceu, e quem escreveu fez tudo certo.

Em produção isso exige que o leitor demore entre a consulta e o `SET`, uma pausa de poucos
milissegundos no momento errado, o que sob carga acontece todo dia. Para ver isso de propósito, o
programa abaixo faz os três papéis num único processo, **na ordem que perde**. O entrelaçamento é
forçado; todo o resto, o banco, o commit e o Redis, é de verdade. Salve-o como `race.py` ao lado do
`dashboard.py`, de onde ele pega as conexões e a consulta:

```python
# race.py: two readers and a writer, interleaved by hand in the order that loses.
import json, sys
import psycopg, redis
from dashboard import TTL, cache, db, from_database

SELLER, KEY, VERSION = 7, "dashboard:7", "dashboard:7:version"
guarded = len(sys.argv) > 1 and sys.argv[1] == "guarded"
count = lambda rows: sum(n for _, n, _ in rows)
cache.delete(KEY)

# A: a reader misses, and reads the database.
version_seen = cache.get(VERSION)
rows = from_database(SELLER)
print(f"A  missed, read {count(rows)} orders from the database")

# B: a writer places an order, commits, and invalidates the key.
db.execute("INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents)"
           " VALUES (42, %s, now(), 'pending', 1990)", (SELLER,))
cache.incr(VERSION)
cache.delete(KEY)
print(f"B  placed an order and deleted {KEY}")

# A: the reader finishes, and stores what it read.
if not guarded:
    cache.set(KEY, json.dumps(rows), ex=TTL)
    print(f"A  stored {count(rows)} orders, for {TTL} s")
else:
    with cache.pipeline() as p:
        p.watch(VERSION)
        if p.get(VERSION) != version_seen:
            print("A  did not store: the key was invalidated while it was reading")
        else:
            p.multi()
            p.set(KEY, json.dumps(rows), ex=TTL)
            p.execute()
            print(f"A  stored {count(rows)} orders, for {TTL} s")

# C: the next reader.
cached = cache.get(KEY)
print(f"C  cache says {count(json.loads(cached)) if cached else 'nothing'},"
      f" database says {count(from_database(SELLER))}")
```

Rode-o como está, e depois com `guarded`:

```
ana@vm:~$ python3 race.py
A  missed, read 92 orders from the database
B  placed an order and deleted dashboard:7
A  stored 92 orders, for 60 s
C  cache says 92, database says 93
ana@vm:~$ python3 race.py guarded
A  missed, read 93 orders from the database
B  placed an order and deleted dashboard:7
A  did not store: the key was invalidated while it was reading
C  cache says nothing, database says 94
```

A primeira rodada é a corrida. O leitor leu **92**, quem escreve fez o pedido 93 e apagou a chave, o
leitor guardou o seu 92 mesmo assim, e o leitor seguinte, C, recebeu 92 enquanto o banco dizia
**93**. Esse 92 seria servido por sessenta segundos, e seria servido mesmo que quem escreve tivesse
apagado a chave uma segunda vez, um instante cedo demais.

## Fechando a corrida

A rodada protegida acrescenta uma **versão** para cada chave. Quem escreve incrementa
`dashboard:7:version` antes de apagar, e o leitor anota a versão antes da consulta. Na hora de
guardar a resposta, ele pede ao Redis para vigiar a versão com `WATCH`, compara com a que anotou, e só
guarda dentro de uma transação `MULTI`/`EXEC`, que o Redis recusa se a chave vigiada mudou no meio. Na
rodada protegida a versão tinha mudado, então o leitor **não guardou**, e C não achou nada no cache e
foi ao banco buscar **94**. Uma gravação que não acontece custa uma consulta a mais; uma gravação
errada custa um TTL de respostas erradas.

Outras respostas para a mesma corrida, cada uma com o seu custo:

- **Apagar duas vezes**: quem escreve apaga, espera um pouco mais do que uma leitura leva e apaga de
  novo. Simples, e só tão bom quanto o palpite sobre quanto uma leitura leva.
- **Write-through**: quem escreve calcula o valor novo e o guarda. Elimina a falta no cache, e troca a
  corrida por outra, entre dois escritores guardando na ordem errada.
- **Um TTL curto**, aceitando a corrida. Para um painel essa costuma ser a escolha certa: a janela é
  rara, e um minuto a limita.

## Quem precisa invalidar

A parte difícil numa aplicação de verdade não são as quatro linhas do `race.py`. É saber **todas as
chaves que uma escrita afeta**. Um pedido muda o painel do vendedor, a lista de pedidos do cliente, a
contagem de pendentes, o número de vendas de um produto e qualquer página que mostre algum deles.
Todo caminho de código que grava pedidos precisa apagar todas essas chaves, inclusive o job noturno,
a tela de administração e a importação em massa que alguém escrever no ano que vem. Cada uma
esquecida é uma tela velha que nenhum teste percebe, porque o teste que escreve e depois lê costuma
rodar antes de o cache ter qualquer coisa.

Esse custo cresce com o número de coisas em cache e o número de lugares que escrevem. É um dos
motivos de a seção 06 olhar para um cache que o próprio banco mantém.
