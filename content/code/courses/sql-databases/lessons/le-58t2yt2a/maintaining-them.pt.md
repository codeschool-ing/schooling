---
title: Criar, encontrar e remover sem derrubar nada
version: 2
---

## `CREATE INDEX` toma um bloqueio

Construir um índice significa ler a tabela inteira, e por padrão o PostgreSQL segura um bloqueio que
impede **escritas** naquela tabela pela construção inteira. Numa tabela grande isso são minutos, e a
fila da aula 3 se forma atrás: as escritas esperam, e tudo o que chega depois espera atrás delas.

```sql
CREATE INDEX CONCURRENTLY ON orders (customer_id);
```

`CONCURRENTLY` constrói sem impedir escritas. O custo é real e vale conhecer:

- Ele faz **duas passadas** pela tabela, então demora aproximadamente o dobro.
- Ele espera toda transação que começou antes dele terminar — então uma transação longa da aula 8
  segura a construção indefinidamente.
- Se falhar, ele deixa um índice **inválido**: presente no catálogo, mantido em toda escrita, usado
  por nada. Você tem que derrubá-lo e começar de novo.

```sql
SELECT indexrelid::regclass FROM pg_index WHERE NOT indisvalid;
```

Rode isso depois de qualquer construção que falhe, e ponha na lista de conferência de qualquer
migração que crie um índice.

**E `CONCURRENTLY` não pode rodar dentro de um bloco de transação.** A maioria das ferramentas de
migração envolve cada migração numa transação, então uma construção de índice precisa ser marcada
como exceção — toda ferramenta tem um jeito de dizer isso, e achar antes da implantação é mais fácil
que durante.

O `DROP INDEX CONCURRENTLY` existe pela mesma razão e se comporta igual.

O equivalente do MySQL é o DDL online: `ALTER TABLE … ADD INDEX` com `ALGORITHM=INPLACE, LOCK=NONE`
permite leituras e escritas durante a construção, e o servidor avisa se a combinação que você pediu
não é suportada para aquela mudança.

## Achar os que ninguém usa

```sql
SELECT relname AS table, indexrelname AS index,
       idx_scan AS times_used,
       pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM   pg_stat_user_indexes
ORDER BY idx_scan, pg_relation_size(indexrelid) DESC;
```

Uma linha com `times_used` em zero e tamanho em gigabytes é um imposto pago por nada. Três ressalvas
antes de derrubá-lo, e cada uma já pegou alguém:

**O contador começa na última redefinição de estatísticas**, que pode ter sido no último reinício. Um
zero num banco que subiu na terça não quer dizer nada.

**Um índice único pode estar fazendo o outro trabalho dele.** Ele pode impor uma restrição fielmente
por anos sem que uma única consulta o busque, e derrubá-lo remove a garantia. Confira se ele sustenta
uma restrição antes de acreditar no número.

**Réplicas mantêm contadores próprios.** Um índice usado só pelas consultas de relatório que rodam
numa réplica de leitura mostra zero buscas no primário. Se você tem réplicas, olhe todas elas, e este
é o erro que transforma uma limpeza num incidente.

O MySQL oferece o `sys.schema_unused_indexes`, com as mesmas ressalvas.

## Achar os duplicados

Dois índices em que um é prefixo do outro — `(customer_id)` ao lado de `(customer_id, placed_at)` —
são um índice a mais, pela razão do prefixo à esquerda. Eles se acumulam porque dois chamados pediram
duas consultas e ninguém as comparou.

```sql
SELECT indrelid::regclass AS table, array_agg(indexrelid::regclass) AS indexes
FROM   pg_index
GROUP BY indrelid, indkey
HAVING count(*) > 1;
```

Isso acha duplicados exatos; o caso do prefixo precisa de um olho, e vale os cinco minutos em
qualquer tabela com mais de quatro índices.

## Inchaço, e reconstruir

Índices acumulam entradas mortas pela mesma razão que tabelas — as versões de linha da aula 8 — e um
índice que sofreu muitos updates pode acabar bem maior do que o dado nele justifica. O sintoma é um
índice que cresce enquanto a contagem de linhas não.

```sql
REINDEX INDEX CONCURRENTLY orders_customer_id_idx;      -- PostgreSQL 12 and later
```

Antes da versão 12 um reindex segurava um bloqueio pela duração, e o contorno usual era construir um
índice novo concorrentemente com outro nome e derrubar o antigo. Vale saber em que versão você está
antes de planejar a janela de manutenção, porque numa delas você não precisa de janela.

## O fluxo de trabalho

Quatro passos, e o primeiro é o que as pessoas pulam:

1. **Meça.** Rode `EXPLAIN` na consulta lenta e descubra o que ela está fazendo. É a aula 10, e ela é
   a próxima por um motivo.
2. **Acrescente o índice**, concorrentemente, e com a ordem de colunas que a seção
   `composite-indexes` defende.
3. **Confirme que ele é usado.** Rode `EXPLAIN` na mesma consulta de novo. Um índice que o planejador
   recusou é um custo sem benefício, e a lista `when-it-is-not-used` é onde você procura o motivo.
4. **Confira de novo mais tarde.** Padrões de consulta mudam, e o índice que ganhou o lugar dele ano
   passado pode estar na lista dos não usados agora.

O que é a regra do começo da aula, com os passos escritos:

> **Não acrescente um índice porque parece provável que ajude. Acrescente porque você olhou — e
> volte para olhar de novo.**

Olhar é a próxima aula, e tudo daqui fica mais fácil de decidir quando você sabe ler um plano.
