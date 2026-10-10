---
title: Anotando, e tirando
version: 1
---

A decisão foi não. O que falta é desfazer a mudança de um jeito que deixe a próxima pessoa em
situação melhor do que se ela nunca tivesse sido feita — o que quer dizer removê-la **e** guardar o
que se aprendeu, porque o mesmo índice vai ser proposto de novo por alguém que leu o mesmo livro.

## Guarde a definição antes de apagar

```
market=# SELECT pg_get_indexdef('orders_customer_placed_idx'::regclass);
                                          pg_get_indexdef                                           
----------------------------------------------------------------------------------------------------
 CREATE INDEX orders_customer_placed_idx ON public.orders USING btree (customer_id, placed_at DESC)
(1 row)

Time: 1.483 ms

market=# DROP INDEX orders_customer_placed_idx;
DROP INDEX
Time: 76.534 ms
EXIT 0
```

O `pg_get_indexdef` imprime o comando exato que reconstruiria o índice, como o servidor o guarda: o
esquema, o método e a ordem das colunas. Copie-o para o registro abaixo antes do `DROP`. Um índice
removido sem a definição é um índice que ninguém consegue repor depressa no dia em que se descobre
que alguém precisava dele — e a aula 11 mostrou que "ninguém usa" é uma afirmação com exceções.

O próprio drop levou **76 milissegundos** e uma trava `ACCESS EXCLUSIVE` em `orders` durante esse
tempo, o que numa máquina virtual quieta não é nada. Numa tabela movimentada, `DROP INDEX
CONCURRENTLY` faz o mesmo sem bloquear escritas, ao preço de demorar mais; a aula 11 seção 06 trata
de fazer isso com segurança.

## Um registro da mudança

Toda otimização, mantida ou não, merece um registro curto onde a equipe guarda as decisões — um
chamado, um arquivo no repositório ao lado das migrações, uma página do runbook de que trata a aula
24 do `db-administration`. Seis linhas bastam, e cada uma está ali porque a falta dela já custou um
dia a alguém:

```localised
mudança    CREATE INDEX orders_customer_placed_idx ON public.orders USING btree (customer_id, placed_at DESC)
motivo     a lista de pedidos do cliente é metade das transações; o plano ordena
medida     carga da aula 2, 3 execuções x 30 s antes e depois, placar zerado entre elas
resultado  média do comando 0,107 -> 0,089 ms; latência de escrita dentro do ruído; taxa dentro do ruído
custo      60 MB (o índice ao lado do qual ficaria tem 18 MB); mais uma entrada por pedido gravado
decisão    apagado: cerca de 1% de um processador economizado, enquanto dois outros comandos tomam a maior parte do servidor
```

**`medida` é a linha que as pessoas deixam de fora**, e é a que faz o registro valer a leitura. Sem
ela, "0,107 para 0,089" não pode ser conferido, repetido ou comparado com a medida do ano que vem
num banco maior, em que o mesmo índice pode muito bem valer a pena.

## Quando olhar de novo

Uma decisão como esta é verdadeira sobre o banco como foi medido. Ela deixa de ser verdadeira quando
os números mudam: a lista de pedidos do cliente sobe no placar, os clientes passam a ter centenas de
pedidos cada em vez de dez, ou o servidor chega ao joelho da curva da aula 23. O registro diz o que
foi medido, então, no dia em que qualquer uma dessas coisas acontecer, repetir a medida é uma hora de
trabalho, e não uma semana de discussão.

É disso que este curso tratou desde a primeira aula: **dar nome ao suspeito, medir, mudar uma coisa,
medir de novo do mesmo jeito, e decidir pelos números**. Na maior parte das vezes os números dizem
sim. O hábito vale o mesmo quando dizem não.

Rode o `~/reset-market.sh` para deixar o `market` como o curso o encontrou.
