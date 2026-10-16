---
title: Por que uma mudança de esquema pode parar um sistema
version: 1
---

Um sistema que escala muda com frequência, e uma mudança de código costuma vir com uma mudança de
esquema: uma coluna nova, um índice novo, uma restrição, um tipo mais largo. Numa tabela pequena
elas são instantâneas e ninguém pensa nelas. **Numa tabela grande e movimentada, o mesmo comando
pode parar toda escrita nela por segundos ou minutos**, e a causa raramente é o trabalho do próprio
comando.

Duas coisas tornam uma mudança de esquema perigosa, e esta aula mede as duas na bilheteria.

**A trava de que ela precisa.** O PostgreSQL protege a estrutura de uma tabela com travas de forças
diferentes. Um `SELECT` comum toma a mais fraca, `ACCESS SHARE`; um `INSERT` toma `ROW EXCLUSIVE`;
nenhum bloqueia o outro. A maioria das formas de `ALTER TABLE` toma a mais forte, **`ACCESS
EXCLUSIVE`**, que conflita com tudo, leituras inclusive, porque o formato da tabela está para mudar
debaixo delas. Segurá-la por um milissegundo é inofensivo. **Esperar por ela** não é, como a seção
03 mostra.

**O trabalho que ela faz enquanto segura.** Algumas mudanças só editam o catálogo e terminam em
milissegundos. Outras reescrevem toda linha da tabela, ou a leem inteira, com a trava segura, e numa
tabela de milhões de linhas isso leva segundos ou minutos. A seção 05 separa as mudanças comuns nos
dois grupos.

| | toma | bloqueia |
|---|---|---|
| `SELECT` | `ACCESS SHARE` | só `ACCESS EXCLUSIVE` |
| `INSERT`, `UPDATE`, `DELETE` | `ROW EXCLUSIVE` | `SHARE` e mais fortes, `ACCESS EXCLUSIVE` inclusive |
| `CREATE INDEX` | `SHARE` | escritas |
| `CREATE INDEX CONCURRENTLY`, `VALIDATE CONSTRAINT` | `SHARE UPDATE EXCLUSIVE` | outras mudanças de esquema, não leituras nem escritas |
| a maioria dos `ALTER TABLE`, `DROP TABLE` | `ACCESS EXCLUSIVE` | tudo |

A tabela é uma versão curta da que está na documentação do PostgreSQL, que lista todo comando e todo
par de travas que conflitam, e vale ser lida uma vez.

## Uma tabela que vale mudar

A tabela `tickets` da bilheteria tem um punhado de linhas das aulas anteriores. Para que as mudanças
levem um tempo mensurável, dê a ela dois milhões de ingressos, mais ou menos o que um vendedor de
ingressos movimentado grava em algumas semanas:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c 'INSERT INTO tickets (event_id, seat, code) SELECT 1 + n % 100, 1000000 + n, md5(n::text) FROM generate_series(1, 2000000) AS n'
INSERT 0 2000000
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "SELECT pg_size_pretty(pg_total_relation_size('tickets'))"
 pg_size_pretty 
----------------
 276 MB
(1 row)
```

276 MB, com os índices. Mantenha a pilha rodando pelo resto da aula; toda seção muda esta mesma
tabela.
