---
title: O horizonte, e a única transação que o segura
version: 1
---

A crença que esta seção substitui é razoável: **uma transação que não faz nada não custa nada.**
Ela não segura nenhuma trava (lock) que alguém queira, não lê linha nenhuma, a conexão fica ali
quieta. A verdade é que uma transação aberta pode ser a coisa mais cara do servidor sem fazer nada,
por causa do que ela impede o servidor de jogar fora.

## Todo update deixa uma cópia para trás

O PostgreSQL nunca altera uma linha onde ela está. Um `UPDATE` grava uma **nova versão** da linha e
marca a antiga como encerrada pela transação que a atualizou; um `DELETE` só faz a marcação. A
versão antiga fica na tabela, ocupando o seu espaço, porque alguém ainda pode precisar vê-la: uma
transação que começou antes do update tem de continuar lendo a linha como ela era. É assim que
leitores e escritores evitam bloquear uns aos outros, e `sql-databases` e `db-administration` partem
disso. O custo é que **alguém precisa voltar e remover as versões antigas**, e esse alguém é o
`VACUUM`.

O `VACUUM` só pode remover uma versão que ninguém mais consegue ver. Para decidir isso, ele consulta
o **snapshot** mais antigo ainda em uso no servidor: um snapshot é o retrato que uma transação tem de
quais outras transações já tinham feito commit quando ela olhou. Toda versão encerrada antes de o
snapshot mais antigo ser tirado é invisível para todo mundo, e pode sair. Toda versão encerrada
depois dele tem de ficar, caso o dono daquele snapshot peça por ela. Essa linha divisória é o
**horizonte**, e o servidor só o move para a frente tão depressa quanto o snapshot mais antigo
deixa.

## Segurando o horizonte, de propósito

Você precisa de dois terminais. No primeiro, que vamos chamar de **Sessão A**, abra uma transação em
`REPEATABLE READ`, que tira um snapshot na primeira consulta e o mantém até o fim, e leia alguma
coisa:

```
market=# BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN
Time: 0.833 ms

market=*# SELECT sum(price_cents) FROM products;
    sum     
------------
 1279989100
(1 row)

Time: 9.859 ms
```

Depois deixe a Sessão A em paz. No segundo terminal, a **Sessão B**, mude o preço de um produto e
peça ao `VACUUM` que limpe a tabela. O `VERBOSE` faz com que ele diga o que fez:

```
market=# UPDATE products SET price_cents = price_cents + 100 WHERE id = 7;
UPDATE 1
Time: 3.669 ms

market=# VACUUM (VERBOSE) products;
INFO:  vacuuming "market.public.products"
INFO:  finished vacuuming "market.public.products": index scans: 0
pages: 0 removed, 649 remain, 2 scanned (0.31% of total)
tuples: 0 removed, 50001 remain, 1 are dead but not yet removable
removable cutoff: 1098934, which was 2 XIDs old when operation ended
frozen: 0 pages from table (0.00% of total) had 0 tuples frozen
index scan not needed: 0 pages from table (0.00% of total) had 0 dead item identifiers removed
avg read rate: 0.000 MB/s, avg write rate: 64.212 MB/s
buffer usage: 26 hits, 0 misses, 3 dirtied
```

O relatório continua com as mesmas linhas para o armazenamento TOAST da tabela, onde ficam os
valores longos; as linhas acima são a tabela em si. O `UPDATE` produziu uma versão antiga, e o
`VACUUM` a encontrou e **não a removeu**: `1 are dead but not yet removable`. A linha de baixo diz
por quê. O `removable cutoff` é o horizonte, a transação `1098934`, e ele tem `2 XIDs old`: duas
transações receberam número desde então, o `UPDATE` entre elas, e o servidor não pode esquecer nada
que veio depois do corte.

Quem está segurando? A `pg_stat_activity` tem uma linha por conexão, e a coluna `backend_xmin` é o
horizonte que cada uma está segurando:

```
market=# SELECT pid, state, backend_xmin, age(backend_xmin) FROM pg_stat_activity WHERE backend_xmin IS NOT NULL AND pid <> pg_backend_pid();
 pid |        state        | backend_xmin | age 
-----+---------------------+--------------+-----
 557 | idle in transaction |      1098934 |   2
(1 row)

Time: 30.577 ms
```

Uma sessão, **idle in transaction**, segurando a transação `1098934`. É a Sessão A: ela não pede nada
há vários segundos, não vai pedir nada até alguém digitar nela, e é o motivo de a versão morta
ficar. Volte à Sessão A, leia o mesmo total de novo e faça commit:

```
market=*# SELECT sum(price_cents) FROM products;
    sum     
------------
 1279989100
(1 row)

Time: 10.726 ms

market=*# COMMIT;
```

O total é **o mesmo de antes**, embora a Sessão B tenha somado cem centavos ao produto 7 nesse meio
tempo. É o `REPEATABLE READ` cumprindo o que promete, e é exatamente por isso que o `VACUUM` não
pôde remover a versão antiga: a Sessão A ainda tinha direito de lê-la, e leu. Com a transação
encerrada, rode o mesmo `VACUUM` na Sessão B:

```
market=# VACUUM (VERBOSE) products;
INFO:  vacuuming "market.public.products"
INFO:  finished vacuuming "market.public.products": index scans: 0
pages: 0 removed, 649 remain, 2 scanned (0.31% of total)
tuples: 1 removed, 50000 remain, 0 are dead but not yet removable
removable cutoff: 1098936, which was 0 XIDs old when operation ended
frozen: 0 pages from table (0.00% of total) had 0 tuples frozen
index scan bypassed: 1 pages from table (0.15% of total) have 1 dead item identifiers
avg read rate: 0.000 MB/s, avg write rate: 0.000 MB/s
buffer usage: 55 hits, 0 misses, 0 dirtied
WAL usage: 3 records, 1 full page images, 8501 bytes
system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
INFO:  vacuuming "market.pg_toast.pg_toast_16498"
INFO:  finished vacuuming "market.pg_toast.pg_toast_16498": index scans: 0
```

`1 removed`, e o corte avançou para `1098936`, a transação mais nova que existe, porque não há mais
ninguém atrás dele.

## O que segura um horizonte, e o que não segura

A Sessão A o segurou com um `REPEATABLE READ` explícito, que é o jeito mais claro de ver. Três
outras coisas o seguram em aplicações comuns, e a seção 05 desta aula encontra cada uma delas na
`pg_stat_activity`:

- **Uma transação que já escreveu alguma coisa** e não terminou. O número dela fica em
  `backend_xid`, e toda versão feita depois dela tem de esperar, qualquer que seja o nível de
  isolamento. A aplicação que abre uma transação, atualiza um pedido e chama um serviço de pagamento
  antes do commit faz isso em toda compra.
- **Um comando que ainda está rodando.** Um relatório que leva vinte minutos segura o seu snapshot
  por vinte minutos, e o mesmo vale para um `pg_dump`, que lê o banco inteiro num único snapshot para
  que a cópia seja consistente.
- **Um cursor ou uma transação `REPEATABLE READ` longa** que um analista abriu num cliente e
  esqueceu.

O que **não** segura é uma transação ociosa no nível padrão, `READ COMMITTED`, que só leu: ela tira
um snapshot novo a cada comando e o solta quando o comando termina. As outras diferenças entre os dois
níveis estão na aula 14; aqui só esta importa.

O horizonte também é **do banco, não da tabela**. A Sessão A leu `products`, mas uma sessão que
segura o horizonte impede o `VACUUM` de limpar todas as tabelas do banco, inclusive as que ela nunca
tocou. A próxima seção mede o que isso faz com uma tabela sob updates constantes.
