---
title: Um achado é uma pergunta
version: 1
---

1.324 clientes têm um horário de consentimento anterior ao momento em que a conta foi criada. Lido ao
pé da letra, eles concordaram com marketing antes de existirem como clientes. Antes de chamar isso de
defeito, dá para perguntar ao dado com mais precisão:

```sql
-- Consent recorded before the account existed: by how much, and on which day.
SET ROLE ipe_owner;
SELECT consent_at::date = created_at::date AS same_day,
       count(*)                            AS customers,
       max(created_at - consent_at)        AS largest_gap,
       count(*) FILTER (WHERE lower(email) IN (SELECT lower(email) FROM sales.customers
                                               GROUP BY 1 HAVING count(*) > 1)) AS duplicates
FROM sales.customers
WHERE consent_at < created_at
GROUP BY 1
ORDER BY 1 DESC;
```

```
ana@lab:~/gov$ psql -f consent-gap.sql
SET
 same_day | customers |    largest_gap    | duplicates 
----------+-----------+-------------------+------------
 t        |      1316 | 15:19:10          |          5
 f        |         8 | 373 days 10:09:52 |          8
(2 rows)
```

Os 1.324 se dividem em dois grupos que não têm nada em comum:

- **1.316 no mesmo dia**, nunca mais de umas quinze horas de distância. A data bate e a hora não. Essa
  é a assinatura de dois relógios, ou de uma hora gravada num lugar e uma data em outro — alguma
  coisa no jeito como o formulário de cadastro escreveu as suas duas colunas. **O banco não sabe dizer
  qual**; sabe dizer onde perguntar: a quem construiu o formulário.
- **8 em outro dia**, até um ano de distância, e **os 8 são clientes duplicados**. Quando essas pessoas
  se cadastraram pela segunda vez, a conta nova recebeu o consentimento da primeira. Esse está
  explicado, e está errado: um consentimento pertence ao ato de dá-lo, e a aula 7 o guarda como evento
  exatamente por isso.

Cinco linhas do primeiro grupo também pertencem a endereços duplicados, então aparecem nas duas
histórias.

## Quem decide o quê

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l9-loop\" aria-label=\"A vida de um achado de qualidade de dados. Uma consulta o mede. O achado é uma pergunta, levada ao dono da tabela. O dono decide. A correção acontece na origem que produziu o dado. Uma regra que roda todo dia o mantém corrigido, e os resultados dela alimentam a próxima medição.\"><defs><marker id=\"dg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"50.0\" width=\"124.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"82.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">medir</text><text x=\"82.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">consulta e contagem</text><path d=\"M144.0 82.0 L158.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"160.0\" y=\"50.0\" width=\"124.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"222.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">perguntar</text><text x=\"222.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as linhas, a evidência</text><path d=\"M284.0 82.0 L298.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"300.0\" y=\"50.0\" width=\"124.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"362.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">decidir</text><text x=\"362.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o dono</text><path d=\"M424.0 82.0 L438.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"440.0\" y=\"50.0\" width=\"124.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"502.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">corrigir na origem</text><text x=\"502.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">formulário, importação</text><path d=\"M564.0 82.0 L578.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"580.0\" y=\"50.0\" width=\"124.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"642.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">manter uma regra</text><text x=\"642.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">todo dia, registrada</text><path d=\"M 642 114 L 642 160 L 82 160 L 82 116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#dg-ah-paper-dim)\"></path><text x=\"360.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o histórico de cada execução é a próxima medição</text></svg>", "caption": "Ninguém muda o dado entre medi-lo e o dono decidir."}
```

Cada achado das duas últimas seções vai para o dono da sua tabela, com a evidência e uma resposta
proposta:

| achado | dono | decisão |
|---|---|---|
| 23 e-mails malformados, mais 7 terminados em `.con` | chefe de vendas | perguntar a cada cliente no próximo pedido; barrar os novos na porta (seção 8) |
| 12 duplicados | chefe de vendas | ligar cada par, manter as duas linhas até alguém desenhar uma fusão — pedidos, receitas e solicitações apontam para as duas |
| 3 pedidos em 2027 | chefe de vendas | achar a importação que os escreveu; corrigir as datas a partir da origem, e não por palpite |
| 14 pedidos sem cadastro | chefe de vendas | não é defeito; documentar (seção 9) e fazer a regra dizer isso (seção 7) |
| 1.316 consentimentos no mesmo dia | encarregado | perguntar ao time que construiu o formulário; até lá, a prova é o log de eventos da aula 7, e não esta coluna |
| 8 consentimentos herdados | encarregado | o consentimento da conta anterior não é um consentimento da posterior; revogá-lo na duplicada |

Duas coisas sobre essa tabela. **Ninguém apaga nada**: um cliente duplicado é duas linhas para as
quais o resto do banco aponta, e apagar uma quebra uma eliminação ou um pedido de acesso. E **a
correção acontece onde o dado é produzido**: corrigir três datas à mão corrige três linhas, e a
importação que as escreveu vai escrever a quarta no mês que vem.
