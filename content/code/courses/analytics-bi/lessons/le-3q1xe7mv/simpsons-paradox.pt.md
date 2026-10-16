---
title: Melhor em todo aparelho, pior no total
version: 1
---

A seção sobre porcentagens terminou com uma pergunta: a conversão da Lantern caiu de fato? Divida as
mesmas sessões por aparelho:

```
lantern=# SELECT extract(year FROM started_at)::int AS year,
lantern-#        coalesce(device, 'all') AS device,
lantern-#        count(*) AS sessions,
lantern-#        round(100.0 * count(*) FILTER (WHERE steps >= 5) / count(*), 2) AS conversion_pct
lantern-# FROM shop.web_sessions
lantern-# GROUP BY 1, ROLLUP (device) ORDER BY 1, 2;
 year | device  | sessions | conversion_pct 
------+---------+----------+----------------
 2025 | all     |    28194 |           7.37
 2025 | desktop |    13180 |          11.14
 2025 | mobile  |    15014 |           4.06
 2026 | all     |    31806 |           6.77
 2026 | desktop |    10141 |          12.04
 2026 | mobile  |    21665 |           4.30
(6 rows)
```

A conversão no desktop subiu de 11,14% para 12,04%. No celular, de 4,06% para 4,30%. **Os dois grupos
melhoraram, e o total caiu**, de 7,37% para 6,77%. Nenhum número está errado.

Isso é o **paradoxo de Simpson**: uma tendência que vale dentro de todo grupo se inverte quando os grupos
são juntados. Não é raro nem truque dos dados. Acontece sempre que duas coisas são verdade ao mesmo tempo:
os grupos têm taxas muito diferentes, e os tamanhos deles mudam entre os dois períodos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"simpson\" aria-label=\"Conversão em 2025 e 2026 para três grupos, como pares de pontos ligados por uma linha. O desktop sobe de 11,14 para 12,04 por cento. O celular sobe de 4,06 para 4,30 por cento. Todas as sessões juntas caem de 7,37 para 6,77 por cento. Embaixo, a parcela de sessões no celular sobe de 53,3 por cento em 2025 para 68,1 por cento em 2026.\"><text x=\"200.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0%</text><line x1=\"200.0\" y1=\"40\" x2=\"200.0\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"0.5\" stroke-dasharray=\"2 3\"></line><text x=\"262.85714285714283\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2%</text><line x1=\"262.85714285714283\" y1=\"40\" x2=\"262.85714285714283\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"0.5\" stroke-dasharray=\"2 3\"></line><text x=\"325.7142857142857\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4%</text><line x1=\"325.7142857142857\" y1=\"40\" x2=\"325.7142857142857\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"0.5\" stroke-dasharray=\"2 3\"></line><text x=\"388.57142857142856\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6%</text><line x1=\"388.57142857142856\" y1=\"40\" x2=\"388.57142857142856\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"0.5\" stroke-dasharray=\"2 3\"></line><text x=\"451.42857142857144\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8%</text><line x1=\"451.42857142857144\" y1=\"40\" x2=\"451.42857142857144\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"0.5\" stroke-dasharray=\"2 3\"></line><text x=\"514.2857142857142\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10%</text><line x1=\"514.2857142857142\" y1=\"40\" x2=\"514.2857142857142\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"0.5\" stroke-dasharray=\"2 3\"></line><text x=\"577.1428571428571\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12%</text><line x1=\"577.1428571428571\" y1=\"40\" x2=\"577.1428571428571\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"0.5\" stroke-dasharray=\"2 3\"></line><text x=\"640.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">14%</text><line x1=\"640.0\" y1=\"40\" x2=\"640.0\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"0.5\" stroke-dasharray=\"2 3\"></line><text x=\"30\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">desktop</text><line x1=\"550.1142857142858\" y1=\"70\" x2=\"578.4\" y2=\"70\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><circle cx=\"550.1142857142858\" cy=\"70\" r=\"4.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.5\"></circle><circle cx=\"578.4\" cy=\"70\" r=\"5.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"542.1142857142858\" y=\"56\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">11,14%</text><text x=\"586.4\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">12,04%</text><text x=\"30\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">celular</text><line x1=\"327.6\" y1=\"120\" x2=\"335.1428571428571\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><circle cx=\"327.6\" cy=\"120\" r=\"4.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.5\"></circle><circle cx=\"335.1428571428571\" cy=\"120\" r=\"5.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"319.6\" y=\"106\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4,06%</text><text x=\"343.1428571428571\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">4,30%</text><text x=\"30\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">todas as sessões</text><line x1=\"431.62857142857143\" y1=\"170\" x2=\"412.77142857142854\" y2=\"170\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><circle cx=\"431.62857142857143\" cy=\"170\" r=\"4.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.5\"></circle><circle cx=\"412.77142857142854\" cy=\"170\" r=\"5.5\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"439.62857142857143\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7,37%</text><text x=\"404.77142857142854\" y=\"156\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">6,77%</text><text x=\"30\" y=\"225\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">parcela de sessões no celular</text><text x=\"200.0\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2025: 53,3%</text><text x=\"420.0\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">2026: 68,1%</text><text x=\"640\" y=\"270\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" font-style=\"italic\">cinza: 2025 · colorido: 2026</text></svg>", "caption": "Cada aparelho converte melhor em 2026; o total converte pior, porque agora é feito em sua maior parte do aparelho que sempre converteu pior.", "same": ["desktop"]}
```

As duas são verdade aqui. O desktop converte cerca de três vezes melhor que o celular. E a mistura se
mexeu:

```
lantern=# SELECT extract(year FROM started_at)::int AS year, device, count(*) AS sessions,
lantern-#        round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY extract(year FROM started_at)), 1) AS share_pct
lantern-# FROM shop.web_sessions
lantern-# GROUP BY extract(year FROM started_at), device ORDER BY 1, 2;
 year | device  | sessions | share_pct 
------+---------+----------+-----------
 2025 | desktop |    13180 |      46.7
 2025 | mobile  |    15014 |      53.3
 2026 | desktop |    10141 |      31.9
 2026 | mobile  |    21665 |      68.1
(4 rows)
```

Em 2025, pouco mais da metade das sessões veio de celulares; em 2026, mais de dois terços. O crescimento da
Lantern em 2026 veio em grande parte das redes sociais, e as visitas das redes sociais chegam pelo
celular. Então o total de 2026 é uma média com muito mais peso no grupo que converte pouco. Cada grupo
melhorou; a média piorou porque agora é feita principalmente do grupo que sempre foi pior.

Qual número está certo? **Os dois, para perguntas diferentes.** "O site está convertendo visitantes
melhor que no ano passado?" — sim, em cada aparelho, em cerca de um ponto no desktop. "De cada cem
sessões, quantas compram?" — menos que no ano passado, porque os visitantes são outros. Um relatório que
dá só o total responde a segunda pergunta enquanto todo mundo o lê como a primeira.

A pergunta que pega isso: **a mistura do que está sendo contado mudou entre os dois períodos?**
