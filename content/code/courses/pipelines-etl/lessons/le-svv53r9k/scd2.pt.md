---
title: A dimensão que muda devagar, carregada
version: 1
---

`warehouse-modeling` desenhou a dimensão de clientes como **tipo 2**: quando um cliente se muda, a
linha antiga não é sobrescrita, é fechada, e uma linha nova é aberta, para que uma venda feita
enquanto ele morava em São Paulo continue sendo uma venda de São Paulo depois da mudança. Aquela
lição a desenhou. Esta precisa carregá-la, toda noite, a partir de uma loja que só sabe onde alguém
mora *agora*.

A carga são três comandos numa transação:

```
-- marts.dim_customer: a slowly changing dimension of type 2. One row per
-- customer per place they have lived, each valid from one moment to the next.
CREATE TABLE IF NOT EXISTS marts.dim_customer (
  customer_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id  integer     NOT NULL,
  city         text        NOT NULL,
  state        text        NOT NULL,
  valid_from   timestamptz NOT NULL,
  valid_to     timestamptz,                -- NULL while it is still true
  is_current   boolean     NOT NULL);

BEGIN;
-- 1. Close the current version of every customer who moved.
UPDATE marts.dim_customer d
   SET valid_to = s.updated_at, is_current = false
  FROM staging.customers s
 WHERE d.customer_id = s.customer_id AND d.is_current
   AND (d.city, d.state) IS DISTINCT FROM (s.city, s.state);

-- 2. Open a version for every customer who has none current: the new ones,
--    and the ones just closed, from the moment the last version ended.
INSERT INTO marts.dim_customer (customer_id, city, state, valid_from, valid_to, is_current)
SELECT s.customer_id, s.city, s.state,
       coalesce((SELECT max(d.valid_to) FROM marts.dim_customer d
                  WHERE d.customer_id = s.customer_id), s.created_at),
       NULL, true
  FROM staging.customers s
 WHERE NOT EXISTS (SELECT 1 FROM marts.dim_customer d
                    WHERE d.customer_id = s.customer_id AND d.is_current);

-- 3. A customer the shop no longer has asked to be forgotten: every version goes.
DELETE FROM marts.dim_customer d
 WHERE NOT EXISTS (SELECT 1 FROM staging.customers s WHERE s.customer_id = d.customer_id);
COMMIT;
```

1. **Fechar** a versão atual de cada cliente cuja cidade ou estado não bate mais com a loja. `IS
   DISTINCT FROM` em vez de `<>`, para que uma mudança de ou para `NULL` conte como mudança.
2. **Abrir** uma versão para cada cliente que não tem nenhuma atual — os novos, e os que o primeiro
   comando acabou de fechar. A versão nova começa onde a última terminou, então não há vão nem
   sobreposição entre elas.
3. **Apagar** toda versão de um cliente que a loja não tem mais. A próxima seção trata de por que
   esse passo não é opcional.

O laboratório toca os dias de 4 a 15 de março, rodando o `nightly.sh` depois de cada um. No dia 15, o
cliente 3145 se muda de São Paulo para o Rio de Janeiro:

```
ana@vm:~/etl$ psql -d wh -c "SELECT customer_key, customer_id, city, state, valid_from, valid_to, is_current FROM marts.dim_customer WHERE customer_id = 3145 ORDER BY valid_from"
 customer_key | customer_id |      city      | state |       valid_from       |        valid_to        | is_current 
--------------+-------------+----------------+-------+------------------------+------------------------+------------
         3133 |        3145 | São Paulo      | SP    | 2025-05-01 12:00:00-03 | 2026-03-15 08:16:38-03 | f
         5393 |        3145 | Rio de Janeiro | RJ    | 2026-03-15 08:16:38-03 |                        | t
(2 rows)

ana@vm:~/etl$ psql -d wh -c "SELECT count(*) AS versions, count(DISTINCT customer_id) AS customers, count(*) FILTER (WHERE NOT is_current) AS closed FROM marts.dim_customer"
 versions | customers | closed 
----------+-----------+--------
     5413 |      5366 |     47
(1 row)
```

Duas linhas para um cliente: São Paulo até 08:16:38 de 15 de março, Rio de Janeiro desse momento em
diante, com o fim de uma e o começo da outra iguais até o segundo. Na dimensão inteira, 47 versões
foram fechadas em quinze dias.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l07-scd2\" aria-label=\"O cliente 3145 numa linha do tempo. A versão 3133, São Paulo, vale de 1º de maio de 2025 até 08:16:38 de 15 de março de 2026. A versão 5393, Rio de Janeiro, vale a partir desse momento, sem fim. Uma venda em 11 de março aponta para a versão 3133, porque aconteceu enquanto essa versão era verdade.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M40.0 160.0 L690.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"40.0\" y=\"110.0\" width=\"430.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">chave 3133 · São Paulo</text><rect x=\"470.0\" y=\"110.0\" width=\"210.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"575.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">chave 5393 · Rio de Janeiro</text><text x=\"678.0\" y=\"100.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ainda vale</text><path d=\"M470.0 80.0 L470.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"470.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">mudou em 15 de março, 08:16:38</text><circle cx=\"400.0\" cy=\"160.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"400.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">venda, 11 de março</text><path d=\"M400.0 154.0 L400.0 142.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><text x=\"40.0\" y=\"182.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1º de maio de 2025</text></svg>", "caption": "O fim de uma versão é o começo da próxima. Um fato é ligado à versão cujo intervalo contém o momento da venda."}
```

## O que a dimensão não sabe

**Ela só sabe o que viu.** A carga lê a loja uma vez por noite, então um cliente que se muda duas
vezes num dia parece ter se mudado uma, para o segundo endereço — o primeiro nunca foi visto. A
captura de mudanças da lição 5 é o remédio: cada atualização chega, e cada uma pode fechar uma
versão.

**E ela começa no dia em que começa.** Na primeira noite cada cliente ganhou uma versão válida desde o
dia do cadastro, porque a cidade atual na loja era tudo o que havia. Um cliente que se mudou em
janeiro fica registrado como tendo morado sempre onde morava em 1º de março. Isso é uma decisão, e o
comentário da tabela deveria dizê-lo; uma dimensão montada mais tarde a partir de um histórico
completo de mudanças saberia mais.
