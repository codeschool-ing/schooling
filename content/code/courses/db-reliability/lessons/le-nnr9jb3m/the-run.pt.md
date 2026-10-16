---
title: A execução, contra o que se esperava
version: 1
---

Três nós, todos atualizados. Rode:

```
ana@vm:~$ ./rehearsal.sh
03:14:05 healthy: 3 members, leader pg1, lag 0
03:14:10 killing pg1
orders ok: 16, failed: 24
first failure: 03:14:16
back at: 03:14:41 ok on 5443
new rows in the table: 16
+ Cluster: shop (7697144668418349739) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Replica | streaming |  2 |         0 |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  2 |         0 |
| pg3    | 127.0.0.1:5443 | Leader  | running   |  2 |           |
+--------+----------------+---------+-----------+----+-----------+
```

Comparado com o plano:

| | esperado | medido |
|---|---|---|
| novo líder | em cerca de 30 segundos | `pg3`, na timeline 2 |
| pedidos durante a falha | falham, depois passam | 24 falharam, 16 passaram |
| segundos sem pedidos | cerca de 30 | 31, de 03:14:10 a 03:14:41 |
| linhas contra pedidos dados como `ok` | iguais | 16 e 16 |
| o nó morto | de volta como réplica | `pg1` em streaming na timeline 2 |

Tudo como esperado, e um detalhe que merece uma linha nos resultados: a primeira falha veio às
03:14:16, **seis segundos** depois do kill, e não um. Pelos horários, a tentativa que começou logo
depois do kill esperou o timeout de cinco segundos antes de falhar, que é o timeout fazendo o seu
trabalho; sem ele, esse é o pedido que teria travado.

## O que a primeira execução encontrou

Na primeira vez que este ensaio rodou, enquanto este curso estava sendo escrito, ele **nunca
terminou**. Uma das conexões do `orders.sh`, aberta pelo HAProxy no instante em que o líder morreu,
ficou esperando uma resposta que nunca viria: o HAProxy segurou aberto o lado do cliente, sem nada
atrás, e o `psql` não tinha limite próprio. Oito minutos depois ainda estava esperando, e o ensaio com
ela; o `timeout client` do HAProxy no arquivo da lição 19 é de trinta minutos.

Para o ensaio isso foi um incômodo. Para uma aplicação é o incidente que a lição 22 não mostrou: uma
thread de requisição presa por meia hora numa conexão, depois outra, até não sobrar nenhuma e o shop
cair **depois** que o failover já terminou. O achado virou uma linha no topo do script,
`export PGCONNECT_TIMEOUT=5`, que faz toda conexão desistir depois de cinco segundos. Virou também uma
ação para a aplicação de verdade: um timeout de conexão na configuração do driver, e um statement timeout para as
consultas, os dois mais curtos do que qualquer coisa que um cliente esperaria.

É para isso que serve um ensaio. Nada nas lições 16 a 19 previu este problema; ele apareceu na
primeira vez que a cadeia inteira foi levada a falhar junta.
