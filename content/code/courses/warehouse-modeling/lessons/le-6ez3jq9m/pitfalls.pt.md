---
title: O que dá errado no tipo 2, e como pegar
version: 1
---

Uma dimensão tipo 2 pode estar errada de jeitos que deixam toda consulta rodando. Três propriedades
precisam valer para cada cliente, e cada uma é uma consulta para conferir:

- **exatamente uma linha atual**;
- **nenhuma sobreposição de duas versões no tempo**, ou um fato na sobreposição encontraria duas linhas
  e seria contado duas vezes;
- **nenhum buraco entre o fim de uma versão e o começo da próxima**, ou um fato no buraco não
  encontraria linha nenhuma e cairia fora da junção.

```sql
-- Three things every type 2 dimension must satisfy, checked.
SELECT
  (SELECT count(*) FROM (SELECT customer_id FROM dim_customer WHERE is_current
                         GROUP BY customer_id HAVING count(*) <> 1))       AS not_one_current,
  (SELECT count(*) FROM dim_customer a JOIN dim_customer b
     ON a.customer_id = b.customer_id AND a.customer_key < b.customer_key
    AND a.valid_from < b.valid_to AND b.valid_from < a.valid_to)            AS overlapping_pairs,
  (SELECT count(*) FROM (SELECT valid_to, lead(valid_from) OVER
                           (PARTITION BY customer_id ORDER BY valid_from) AS next_from
                         FROM dim_customer WHERE customer_key > 0)
    WHERE next_from IS NOT NULL AND next_from <> valid_to)                AS gaps;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < checks.sql
┌─────────────────┬───────────────────┬───────┐
│ not_one_current │ overlapping_pairs │ gaps  │
│      int64      │       int64       │ int64 │
├─────────────────┼───────────────────┼───────┤
│               0 │                 0 │     0 │
└─────────────────┴───────────────────┴───────┘
```

Três zeros. Essa consulta pertence à carga, rodada depois de toda carga, fazendo-a falhar se algum
número não for zero. É assim que o warehouse descobre antes do gerente.

## Quatro jeitos de os zeros deixarem de ser zeros

**Duas mudanças num período.** Uma foto só vê o estado em cada extração. O cliente 1225 se mudou de
Brasília para Maringá em 28 de novembro de 2025 e virou regular no dia 30:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT customer_id, changed_at, field, old_value, new_value FROM staging.customer_changes WHERE customer_id IN (SELECT customer_id FROM staging.customer_changes WHERE field IN ('tier', 'city', 'state') AND changed_at >= '2025-11-01' AND changed_at < '2025-12-01' GROUP BY customer_id HAVING count(DISTINCT changed_at) > 1) ORDER BY changed_at"
┌─────────────┬──────────────────────────┬─────────┬───────────┬───────────┐
│ customer_id │        changed_at        │  field  │ old_value │ new_value │
│    int64    │ timestamp with time zone │ varchar │  varchar  │  varchar  │
├─────────────┼──────────────────────────┼─────────┼───────────┼───────────┤
│        1225 │ 2025-11-28 18:47:05-03   │ city    │ Brasília  │ Maringá   │
│        1225 │ 2025-11-28 18:47:05-03   │ state   │ DF        │ PR        │
│        1225 │ 2025-11-30 19:16:04-03   │ tier    │ reader    │ regular   │
└─────────────┴──────────────────────────┴─────────┴───────────┴───────────┘
```

A extração de dezembro mostra as duas mudanças de uma vez, e a `dim_customer_m` registra uma versão
começando em 1º de dezembro. Dois dias como reader em Maringá se perderam, e a mudança fica datada três
dias depois. O registro de mudanças guarda isso; uma foto não consegue. **Quanto mais espaçadas as
fotos, mais disso há**, e a única cura é uma fonte melhor: um registro, ou captura de mudanças.

**Um fato que chega atrasado.** Uma venda da semana passada carregada hoje precisa receber a versão que
valia na semana passada, e não a atual. A carga da lição 2 liga pelo horário do pedido, então faz isso
certo; uma carga que procurasse `is_current` não faria.

**Uma mudança que chega atrasada.** A origem informa uma mudança de endereço de dois meses atrás. A
versão nova deveria começar dois meses atrás, a antiga deveria encurtar, e as vendas no meio deveriam
apontar para a chave nova. Isso significa atualizar linhas fato, o que é caro, e é o motivo de alguns
times aceitarem a mudança na data em que ficaram sabendo dela, e anotarem isso.

**Um cliente apagado na origem.** Uma foto que não contém mais um cliente não significa que ele deixou
de existir no passado. A resposta usual é fechar a versão atual dele e deixar o histórico, e nunca apagar
linhas para as quais os fatos apontam.
