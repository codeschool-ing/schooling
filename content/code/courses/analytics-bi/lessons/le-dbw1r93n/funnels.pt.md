---
title: Um funil conta até onde as pessoas chegaram
version: 1
---

Um **funil** é um caminho com etapas numa ordem fixa, e uma contagem de quantos chegaram a cada uma. O
caminho da Lantern são os cinco eventos do plano de rastreamento da aula 8, e o `web_sessions` registra
quantas etapas cada visita percorreu, então o funil é uma junção só: cada sessão contra cada etapa a que
chegou.

```
lantern=# SELECT step, event,
lantern-#        desktop, round(100.0 * desktop / lag(desktop) OVER (ORDER BY step), 1) AS desktop_pct,
lantern-#        mobile, round(100.0 * mobile / lag(mobile) OVER (ORDER BY step), 1) AS mobile_pct
lantern-# FROM (SELECT p.step, p.event,
lantern(#              count(*) FILTER (WHERE s.device = 'desktop') AS desktop,
lantern(#              count(*) FILTER (WHERE s.device = 'mobile') AS mobile
lantern(#       FROM tracking.plan p JOIN shop.web_sessions s ON s.steps >= p.step
lantern(#       GROUP BY p.step, p.event) f
lantern-# ORDER BY step;
 step |    event     | desktop | desktop_pct | mobile | mobile_pct 
------+--------------+---------+-------------+--------+------------
    1 | visit        |   23321 |             |  36679 |           
    2 | product_view |   13504 |        57.9 |  15382 |       41.9
    3 | add_to_cart  |    5361 |        39.7 |   4654 |       30.3
    4 | checkout     |    3431 |        64.0 |   2425 |       52.1
    5 | purchase     |    2689 |        78.4 |   1541 |       63.5
(5 rows)
```

Cada etapa tem dois números que valem a leitura. A contagem é quantas sessões chegaram até ali; a
porcentagem é a parcela da etapa anterior que seguiu em frente. No desktop, 57,9% das visitas olharam um
produto, 39,7% delas puseram algo no carrinho, 64,0% dessas chegaram ao checkout e 78,4% dessas pagaram. O
celular perde mais em todas as etapas, e a maior diferença está logo na primeira: 41,9% das visitas no
celular olham um produto, contra 57,9% no desktop.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"funnel\" aria-label=\"Dois funis lado a lado, desktop e celular, cinco etapas cada: visita, visualização de produto, carrinho, checkout e compra. Cada barra é a parcela das visitas que chegou à etapa. Desktop: 100, 57,9, 23,0, 14,7 e 11,5 por cento. Celular: 100, 41,9, 12,7, 6,6 e 4,2 por cento. O celular é mais estreito em todas as etapas, e a maior perda isolada nos dois fica entre ver o produto e pôr no carrinho.\"><text x=\"200\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">desktop</text><rect x=\"50.0\" y=\"44\" width=\"300.0\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"200\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">visit  ·  100,0%</text><rect x=\"113.14266112087816\" y=\"92\" width=\"173.71467775824368\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"200\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">product_view  ·  57,9%</text><rect x=\"165.5182024784529\" y=\"140\" width=\"68.96359504309422\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"200\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">add_to_cart  ·  23,0%</text><rect x=\"177.93190686505724\" y=\"188\" width=\"44.13618626988551\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"200\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">checkout  ·  14,7%</text><rect x=\"182.70442948415592\" y=\"236\" width=\"34.591141031688174\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"200\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">purchase  ·  11,5%</text><text x=\"540\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">celular</text><rect x=\"390.0\" y=\"44\" width=\"300.0\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"540\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">visit  ·  100,0%</text><rect x=\"477.0947953870062\" y=\"92\" width=\"125.81040922598763\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"540\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">product_view  ·  41,9%</text><rect x=\"520.9673109953925\" y=\"140\" width=\"38.06537800921508\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"540\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">add_to_cart  ·  12,7%</text><rect x=\"530.082881212683\" y=\"188\" width=\"19.83423757463399\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"540\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">checkout  ·  6,6%</text><rect x=\"533.6980288448431\" y=\"236\" width=\"12.603942310313803\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"540\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">purchase  ·  4,2%</text></svg>", "caption": "Cada barra é a parcela de todas as visitas que chegou até ali. O celular começa com mais visitas e termina com menos compras.", "same": ["desktop"]}
```

A porcentagem de etapa a etapa é a que leva à ação, porque diz **onde** as pessoas saem. A conversão total
— compras sobre visitas, 2.689 de 23.321 no desktop, 11,5% — é o produto das quatro, e melhorar qualquer
uma delas a move. Um time que só olha o número total sabe que algo mudou, e não onde.

A maior perda nos dois funis fica entre ver um produto e pô-lo no carrinho: seis em dez sessões no desktop
e sete em dez no celular param ali. Isso é normal numa loja, onde a maioria das visitas é só olhar; a
pergunta útil não é por que ela é grande, e sim se ela se mexeu.
