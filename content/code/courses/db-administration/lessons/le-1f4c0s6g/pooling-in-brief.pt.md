---
title: Pooling, em resumo
version: 1
---

A última seção achou uma conexão segurando coisa demais por tempo demais. O outro caso comum é uma
aplicação abrindo conexões demais, ou abrindo uma nova para cada requisição, e o preço disso é o
início de processo que a primeira seção descreveu. O `pgbench --connect` abre uma conexão nova para
cada transação, então mede exatamente esse preço contra a execução de duas seções atrás:

```
ana@db:~$ pgbench --select-only --connect --client=4 --jobs=4 --time=15 bench
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
starting vacuum...end.
transaction type: <builtin: select only>
scaling factor: 10
query mode: simple
number of clients: 4
number of threads: 4
maximum number of tries: 1
duration: 15 s
number of transactions actually processed: 10892
number of failed transactions: 0 (0.000%)
latency average = 5.509 ms
average connection time = 4.264 ms
tps = 726.068665 (including reconnection times)
```

**Os mesmos quatro clientes e a mesma consulta fizeram 726 transações por segundo em vez de
90.620.** Cada conexão levou 4,264 ms para ser estabelecida, para uma busca que levava uma fração de
milissegundo depois de conectada: um processo iniciado, a autenticação feita, os caches aquecidos do
zero, e tudo jogado fora um instante depois.

## O que um pooler faz

Um **pooler de conexões** fica entre a aplicação e o servidor e mantém abertas poucas conexões reais
com o servidor. Os clientes conectam ao pooler, o que é barato, e ele lhes empresta uma conexão do
servidor pelo tempo que precisarem: por uma sessão inteira ou, no modo que mais ajuda, por uma
transação de cada vez. Centenas de conexões da aplicação passam a dividir algumas dezenas de
backends, perto do número de processadores que conseguem rodá-los, e o servidor nunca encontra os
problemas das últimas três seções.

Há dois lugares para pôr um. **O próprio driver da aplicação** costuma ter um pool, e usá-lo resolve
sozinho o padrão de uma conexão por requisição. **Um pooler separado**, sendo o PgBouncer o de
costume, atende muitas instâncias da aplicação ao mesmo tempo e é o que deixa o `max_connections`
continuar pequeno enquanto o número de clientes cresce. Escolher um modo, dimensionar o pool e o que
o pooling por transação quebra é a lição 16 do `db-performance`; rodar um pooler de forma que ele
mesmo não seja o que falha é a lição 18 do `db-reliability`.

## Pondo tudo de volta

```
ana@db:~$ dropdb bench
ana@db:~$ psql shop -c "REVOKE ALL ON customers, orders FROM app"
REVOKE
ana@db:~$ dropuser app
ana@db:~$ sudo userdel --remove app
userdel: app mail spool (/var/mail/app) not found
ana@db:~$ psql shop -Atc "SHOW max_connections"
100
```

**Um papel não pode ser removido enquanto ainda tem privilégios**, e é por isso que o `REVOKE` vem
primeiro; a lição 13 tem a ferramenta geral para isso, o `DROP OWNED`. O timeout do papel foi junto
com ele. O `userdel` só comenta que o `app` nunca teve caixa de correio. O `max_connections` está de
volta em 100, como o reset da terceira seção deixou.
