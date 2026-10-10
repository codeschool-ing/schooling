---
title: Restrições sem uma trava longa
version: 1
---

Todo ingresso agora tem portão, e o esquema deveria dizer isso: `gate` deveria ser `NOT NULL`, para
que um bug futuro que o esqueça seja recusado pelo banco em vez de guardado. `ALTER COLUMN gate SET
NOT NULL` faz isso, e precisa antes conferir que nenhuma linha existente é `NULL`: uma **leitura da
tabela inteira sob `ACCESS EXCLUSIVE`**, que em dois milhões de linhas é o mesmo tipo de parada da
seção 05.

O PostgreSQL oferece um caminho em volta, em dois passos.

**Primeiro, acrescentar a regra sem conferir o passado.** Uma restrição `CHECK` acrescentada como
`NOT VALID` vale para toda linha nova e atualizada a partir daquele momento, e **as linhas existentes
não são conferidas**, então ela só precisa da trava por um instante.

**Depois, validá-la.** O `VALIDATE CONSTRAINT` lê a tabela para provar que as linhas antigas
obedecem à regra, mas toma a trava mais fraca `SHARE UPDATE EXCLUSIVE`, então leituras e escritas
continuam enquanto ele lê.

E desde o PostgreSQL 12, **o `SET NOT NULL` pula a leitura quando um `CHECK (col IS NOT NULL)`
válido já o prova**. Os três passos, cronometrados, com vendas rodando durante a validação:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c '\timing on' -c 'ALTER TABLE tickets ADD CONSTRAINT gate_set CHECK (gate IS NOT NULL) NOT VALID'
Timing is on.
ALTER TABLE
Time: 2.388 ms
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c '\timing on' -c 'ALTER TABLE tickets VALIDATE CONSTRAINT gate_set'
Timing is on.
ALTER TABLE
Time: 258.539 ms
ana@lab:~/tickets$ python3 load.py -m POST -c 4 -d 8 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1186 in 8.0 s = 147.4 per second
latency   p50 12.4 ms  p95 74.7 ms  p99 80.3 ms  max 84.8 ms
status    201: 1186
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c '\timing on' -c 'ALTER TABLE tickets ALTER COLUMN gate SET NOT NULL'
Timing is on.
ALTER TABLE
Time: 1100.553 ms (00:01.101)
ana@lab:~/tickets$ docker compose logs db | grep 'canceling autovacuum'
db-1  | 2026-10-10 05:50:23.909 UTC [786] ERROR:  canceling autovacuum task
```

- `ADD CONSTRAINT … NOT VALID` levou **2,4 ms**: só catálogo, por um instante de `ACCESS EXCLUSIVE`.
- `VALIDATE CONSTRAINT` leu a tabela em **259 ms**, e as vendas ao lado, **1186 com o pior caso em
  85 ms**, não sentiram.
- `SET NOT NULL` achou a restrição válida e não leu nada, e mesmo assim levou **1,1 segundo**, por um
  motivo que não é o trabalho dele. O último comando explica: o **autovacuum** do PostgreSQL estava
  limpando a tabela depois do preenchimento, segurando uma trava que conflita com `ACCESS
  EXCLUSIVE`. Quando um autovacuum bloqueia alguém por mais que o `deadlock_timeout`, um segundo por
  padrão, o PostgreSQL o cancela e registra `canceling autovacuum task`, e esse segundo é o tempo que
  a mudança esperou. Com o `lock_timeout` definido como na seção 04, uma espera assim fica limitada,
  seja qual for a causa.

O mesmo padrão funciona para chaves estrangeiras: `ADD CONSTRAINT … FOREIGN KEY … NOT VALID`, depois
`VALIDATE CONSTRAINT`. Quando `gate` é `NOT NULL`, o `CHECK` fica redundante e pode ser descartado,
o que é instantâneo.
