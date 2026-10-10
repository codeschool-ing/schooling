---
title: Desistindo rápido, de propósito
version: 1
---

Uma mudança de esquema que não consegue a trava deve **falhar rápido em vez de esperar**, porque
esperar é o que bloqueia todo mundo. O `lock_timeout` do PostgreSQL define quanto tempo um comando
pode esperar por uma trava antes de desistir com um erro. Os mesmos três terminais da última seção,
com o `ALTER TABLE` agora limitado a dois segundos de espera:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "SET lock_timeout = '2s'" -c 'ALTER TABLE tickets ADD COLUMN scanned_at timestamptz'
SET
ERROR:  canceling statement due to lock timeout
```

A mudança desistiu com **`canceling statement due to lock timeout`**, e nada mudou. As vendas
rodando ao lado:

```
ana@lab:~/tickets$ python3 load.py -m POST -c 4 -d 8 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1037 in 8.0 s = 129.5 per second
latency   p50 11.7 ms  p95 75.5 ms  p99 80.9 ms  max 1190.2 ms
status    201: 1037
```

**1037 vendas em oito segundos, com o pior caso em 1,19 s**: a parada durou do momento em que as
vendas começaram até o `ALTER` desistir, cerca de um segundo, em vez de toda a duração da transação
longa. Baixar o limite encurta a parada ainda mais.

## Tentar de novo, em vez de esperar

Uma mudança que falha no `lock_timeout` é tentada de novo, um instante depois, até achar uma brecha.
O padrão que toda ferramenta de migração séria usa é:

1. definir o `lock_timeout` com algo curto, de algumas centenas de milissegundos a uns dois
   segundos;
2. rodar a mudança;
3. num tempo esgotado de trava, esperar um pouco e tentar de novo, até um limite;
4. se ela nunca passar, parar e achar a transação longa em vez de esperar mais.

O **`statement_timeout`** é o parceiro dele: limita quanto tempo um comando pode rodar no total,
espera inclusive. Definido na sessão da migração, ele impede que uma mudança que acabou reescrevendo
a tabela segure a trava por minutos.

## Achando o que está no caminho

Quando uma mudança continua esgotando o tempo, alguma coisa segura uma trava por muito tempo, e o
`pg_stat_activity` dá o nome: a coluna `xact_start` diz quando a transação de cada conexão começou,
e uma transação que começou há uma hora é a suspeita. A mais comum é a **ociosa em transação**
(*idle in transaction*): um programa que abriu uma transação, fez uma consulta e ficou esperando
outra coisa antes de confirmar. O `idle_in_transaction_session_timeout` do PostgreSQL encerra essas
sessões depois de um tempo definido, e defini-lo para as conexões da aplicação tira de um banco
movimentado o segurador de travas longas mais comum.
