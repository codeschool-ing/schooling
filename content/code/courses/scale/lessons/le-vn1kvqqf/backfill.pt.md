---
title: Preenchendo em lotes
version: 1
---

A coluna nova `gate` existe, e os ingressos novos ganham um valor. Dois milhões de antigos têm
`NULL`, e precisam ser preenchidos antes de a coluna virar obrigatória. O comando óbvio é um
`UPDATE`:

```sql
UPDATE tickets SET gate = CASE WHEN id % 2 = 0 THEN 'A' ELSE 'B' END WHERE gate IS NULL;
```

Ele funciona, e é o jeito errado numa tabela movimentada, por três motivos que crescem com a tabela:

- **É uma transação.** Toda linha que ele atualiza fica travada até ele confirmar, então qualquer
  outra escrita nessas linhas espera a rodada inteira.
- **O log dele é uma rajada.** Toda linha atualizada é uma nova versão de linha no WAL, mandada a
  toda réplica de uma vez, então as réplicas da aula 2 ficam para trás pelo tempo que levarem para
  aplicá-la.
- **Ele não pode ser pausado nem retomado.** Parado no meio, desfaz tudo, e o trabalho se perde.

## Um procedimento que confirma pelo caminho

Um **procedimento** no PostgreSQL pode confirmar no meio do trabalho, o que um comando único não
pode. Este percorre a tabela por `id` em faixas de `batch` linhas, atualiza as linhas de cada faixa
que ainda não têm portão, confirma, pausa vinte milissegundos para que outro trabalho tenha a sua
vez, e segue. Salve como `backfill.sql`:

```sql
-- backfill.sql
CREATE OR REPLACE PROCEDURE backfill_gate(batch int) LANGUAGE plpgsql AS $$
DECLARE
  lo   bigint := 0;
  last bigint;
BEGIN
  SELECT max(id) INTO last FROM tickets;
  WHILE lo < last LOOP
    UPDATE tickets SET gate = CASE WHEN id % 2 = 0 THEN 'A' ELSE 'B' END
    WHERE id > lo AND id <= lo + batch AND gate IS NULL;
    lo := lo + batch;
    COMMIT;
    PERFORM pg_sleep(0.02);
  END LOOP;
END
$$;
```

O `CREATE OR REPLACE PROCEDURE` só o define. Primeiro o padrão para linhas novas, depois o
procedimento, depois uma rodada com lotes de 50 000 linhas e, em outro terminal, quinze segundos de
vendas:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "ALTER TABLE tickets ALTER COLUMN gate SET DEFAULT 'A'"
ALTER TABLE
ana@lab:~/tickets$ docker compose cp backfill.sql db:/tmp/backfill.sql
 tickets-db-1 Copying backfill.sql to tickets-db-1:/tmp/backfill.sql
 tickets-db-1 Copied backfill.sql to tickets-db-1:/tmp/backfill.sql
ana@lab:~/tickets$ docker compose exec db psql -U tickets -f /tmp/backfill.sql
CREATE PROCEDURE
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c '\timing on' -c 'CALL backfill_gate(50000)'
Timing is on.
CALL
Time: 53493.510 ms (00:53.494)
ana@lab:~/tickets$ python3 load.py -m POST -c 4 -d 15 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  2132 in 15.1 s = 141.6 per second
latency   p50 19.1 ms  p95 64.6 ms  p99 112.4 ms  max 334.6 ms
status    201: 2132
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c 'SELECT gate, count(*) FROM tickets GROUP BY gate ORDER BY gate'
 gate |  count  
------+---------
 A    | 1003569
 B    | 1001437
(2 rows)
```

O preenchimento levou **53,5 segundos**, e a bilheteria mal percebeu: **2132 vendas em quinze
segundos, 141,6 por segundo, pior caso em 335 ms**, perto do ritmo normal dela num processador. Cada
lote segurou as travas de linha por uma fração de segundo e gravou um pedaço modesto de log, e as
pausas deixaram as vendas e a réplica acompanharem.

A contagem final não tem grupo `NULL`: as linhas antigas ganharam `A` ou `B`, e as vendas feitas
durante e depois do preenchimento ganharam `A` do padrão.

## Ajustando um preenchimento

O tamanho do lote e a pausa são os dois botões, e os dois são medidos e não chutados:

- **um lote maior** termina antes e segura cada trava por mais tempo;
- **uma pausa maior** protege o resto do sistema e estica o tempo total;
- **a ordem deve seguir um índice**, aqui a chave primária, para que cada lote ache as suas linhas
  sem varrer, e um lote interrompido possa ser retomado do último `id` que alcançou.

Acompanhe o `replay_lag` da réplica, da aula 2, enquanto ele roda. Se crescer, a pausa está curta.
