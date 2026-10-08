---
title: O que quem lê vê enquanto você carrega
version: 1
---

Uma carga escreve numa tabela que as pessoas estão lendo. **O comando que ela usa decide se elas
percebem.** Dois jeitos de substituir o conteúdo de uma tabela pequena, cada um mantido aberto por
cinco segundos com `pg_sleep`, como uma carga lenta ficaria, com um leitor chegando no meio:

Primeiro, `TRUNCATE` e encher de novo:

```sql
BEGIN; TRUNCATE marts.dim_shop; INSERT INTO marts.dim_shop SELECT * FROM raw.shops; SELECT pg_sleep(5); COMMIT;
```

Depois, `DELETE` e encher de novo:

```sql
BEGIN; DELETE FROM marts.dim_shop; INSERT INTO marts.dim_shop SELECT * FROM raw.shops; SELECT pg_sleep(5); COMMIT;
```

O leitor, com um limite de dois segundos para esperar uma trava, tentou uma vez durante cada um:

```
ana@vm:~/etl$ psql -d wh -c "SET lock_timeout = '2s'" -c "SELECT count(*) FROM marts.dim_shop"
SET
ERROR:  canceling statement due to lock timeout
LINE 1: SELECT count(*) FROM marts.dim_shop
                             ^
ana@vm:~/etl$ psql -d wh -c "SET lock_timeout = '2s'" -c "SELECT count(*) FROM marts.dim_shop"
SET
 count 
-------
     7
(1 row)
```

**O `TRUNCATE` deixou o leitor do lado de fora.** Ele pega a trava mais forte que o PostgreSQL tem,
porque não apaga linhas — joga fora os arquivos da tabela — e ninguém pode ler uma tabela cujos
arquivos estão sendo jogados fora. O leitor esperou, perdeu a paciência e falhou; um painel teria
travado.

**O `DELETE` deixou o leitor entrar, e mostrou a ele as linhas antigas.** Cada linha é marcada como
apagada pela transação de carga, e até essa transação ser confirmada, todos os outros ainda as veem. O
leitor recebeu sete lojas, a tabela como estava antes de a carga começar.

## Escolhendo

| | `TRUNCATE` + insert | `DELETE` + insert |
|---|---|---|
| leitores durante a carga | esperam, ou falham | veem as linhas antigas |
| velocidade numa tabela grande | rápida: nenhuma linha é tocada | mais lenta: cada linha é marcada, e limpa depois |
| o que fica para trás | nada | linhas mortas, até o `VACUUM` recuperá-las |

Para uma tabela de sete lojas, o `DELETE` não custa nada e deixa os leitores satisfeitos. Para uma
tabela de cem milhões de linhas, nenhum dos dois é certo: a carga monta uma **tabela nova** ao lado
da antiga, e troca as duas com dois `ALTER TABLE ... RENAME` numa transação, que segura a trava forte
por milissegundos em vez de durante a carga inteira. A lição 19 mede quanto custa uma carga grande, e
é lá que a troca se paga.
