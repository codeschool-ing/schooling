---
title: Como o Spark pode fazer um join
version: 1
---

**Um join precisa de todas as linhas de uma chave, dos dois lados, na mesma tarefa.** Há dois jeitos
de arranjar isso, e a aula 4 os nomeou para o MapReduce: mover os dois lados por chave para que se
encontrem, que é um shuffle, ou copiar o lado pequeno inteiro para cada tarefa que lê o grande, que
não é. O Spark tem cinco estratégias físicas construídas sobre essas duas ideias, e o plano diz qual
escolheu.

| estratégia | o que se move | quando o Spark a escolhe |
|---|---|---|
| broadcast hash join | o lado pequeno, inteiro, para cada executor | um join por igualdade cujo lado menor é estimado abaixo de `spark.sql.autoBroadcastJoinThreshold`, 10 MB, ou recebe um hint |
| sort-merge join | os dois lados, embaralhados por chave, depois ordenados | um join por igualdade sem nenhum lado pequeno o bastante: o padrão |
| shuffle hash join | os dois lados, embaralhados por chave, sem ordenação | um join por igualdade quando se pede, por hint ou por `spark.sql.join.preferSortMergeJoin=false` |
| broadcast nested loop join | o lado pequeno, inteiro | um join sem igualdade na condição, como um intervalo |
| produto cartesiano | cada par de partições | sem igualdade e sem lado em broadcast: o último recurso |

**As duas que importam quase todo dia são as duas primeiras.** Um broadcast hash join monta uma
tabela hash do lado pequeno e passa o lado grande por ela, partição por partição, sem shuffle nenhum
no lado grande. Um sort-merge join embaralha os dois lados no mesmo número de partições pela chave do
join, ordena cada partição e percorre os dois fluxos ordenados juntos. Ele nunca precisa que um lado
caiba na memória, porque uma ordenação pode despejar em disco, e é por isso que é o padrão.

Um shuffle hash join pula a ordenação e monta uma tabela hash por partição: mais rápido quando o lado
menor de uma partição cabe na memória, e uma falha quando não cabe. Por padrão o Spark só o escolhe
quando mandam.

**Hints passam por cima do planejador** quando o programa sabe algo que as estimativas não sabem. Na
API de DataFrame, `F.broadcast(df)` ou `df.hint("broadcast")`, `df.hint("merge")` e
`df.hint("shuffle_hash")`; em SQL, as mesmas palavras num comentário depois do `SELECT`:

```sql
SELECT /*+ BROADCAST(b) */ b.category, count(*)
FROM clicks c JOIN books b ON c.book_id = b.book_id
GROUP BY b.category
```

**Um hint é um pedido, não uma ordem.** Se a estratégia não consegue fazer aquele join, como um
broadcast pedido do lado esquerdo de um left outer join, cujas linhas têm de ser todas mantidas, o
Spark ignora o hint e registra um aviso.
