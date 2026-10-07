---
title: Uma falha é uma pergunta, com duas respostas
version: 1
---

Um teste que falhou diz que os dados e a regra discordam. Ele não diz qual dos dois está errado, e
**decidir isso é o trabalho**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l12-two-answers\" aria-label=\"Um teste que falha leva a uma pergunta: a regra está errada, ou os dados? Se a regra está errada, corrija o teste para ele dizer o que é de fato verdade, e mantenha-o. Se os dados estão errados, mantenha o teste como está e corrija os dados de onde eles vêm. Apagar o teste aparece riscado, como o movimento que nunca está certo.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"270.0\" y=\"16.0\" width=\"180.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">um teste falha</text><rect x=\"270.0\" y=\"86.0\" width=\"180.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">a regra ou os dados?</text><path d=\"M360.0 56.0 L360.0 84.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"40.0\" y=\"150.0\" width=\"230.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"155.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">a regra está errada</text><rect x=\"450.0\" y=\"150.0\" width=\"230.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">os dados estão errados</text><path d=\"M300.0 126.0 L200.0 148.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M420.0 126.0 L520.0 148.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"155.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">estreitar o teste até ele ser verdade</text><text x=\"565.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">corrigir na origem; o teste fica</text><path d=\"M155.0 190.0 L155.0 202.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M565.0 190.0 L565.0 202.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"360.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">apagar o teste</text><path d=\"M300.0 244.0 L420.0 244.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path></svg>", "caption": "As duas respostas mantêm um teste. O único movimento errado é o que não mantém nenhum."}
```

A Ana pega primeiro os 5.809 pedidos sem cliente, e os conta por loja:

```
ana@vm:~/etl$ psql -d wh -c "SELECT s.name, s.channel, count(*) FILTER (WHERE o.customer_id IS NULL) AS no_customer, count(*) AS orders FROM dbt_staging.stg_orders o JOIN raw.shops s USING (shop_id) GROUP BY 1, 2 ORDER BY 2, 1"
   name    | channel | no_customer | orders 
-----------+---------+-------------+--------
 Online    | online  |           7 |   6757
 Batel     | store   |         652 |   1440
 Cambuí    | store   |         752 |   1704
 Moinhos   | store   |         596 |   1320
 Paulista  | store   |        1618 |   3593
 Pinheiros | store   |        1273 |   2801
 Savassi   | store   |         911 |   2085
(7 rows)
```

As seis livrarias têm milhares cada uma, e o site, sete. Claro que têm: **um caixa vende para quem
entrar**, e a maioria das pessoas compra um livro sem dar o nome. A loja nunca prometeu um cliente em
todo pedido; a Ana acreditou nisso porque o site promete. A regra estava errada, não os dados.

As linhas de pedido são o mesmo tipo de erro pelo outro lado. O `order_id` não é único no
`stg_order_lines` porque um pedido tem várias linhas: a lição 6 estabeleceu o grão como *uma linha
por linha de pedido*, e a chave desse grão é o pedido **e** o número da linha. O teste conferiu a
chave errada.

Nenhum dos dois testes deve ser apagado, porém. Cada um guardava uma crença verdadeira dita de forma
ampla demais, e a versão mais estreita ainda vale a conferência toda noite. Um teste simplesmente
removido quando falha deixa de proteger qualquer coisa; **um teste corrigido diz, no projeto, como os
dados de fato são** — que é o que o próximo leitor do modelo precisa saber.

E quando a resposta é a outra — a regra está certa e os dados a quebraram — o teste fica como está, e
a correção vai para cima, de onde vêm as linhas ruins. Calar um teste verdadeiro para o build ficar
verde é o único movimento que nunca está certo.
