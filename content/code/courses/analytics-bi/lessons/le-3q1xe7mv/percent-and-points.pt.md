---
title: Por cento e pontos percentuais
version: 1
---

A conversão do site da Lantern — sessões que terminaram numa compra — por ano:

```
lantern=# SELECT extract(year FROM started_at)::int AS year, count(*) AS sessions,
lantern-#        count(*) FILTER (WHERE steps >= 5) AS purchases,
lantern-#        round(100.0 * count(*) FILTER (WHERE steps >= 5) / count(*), 2) AS conversion_pct
lantern-# FROM shop.web_sessions
lantern-# GROUP BY 1 ORDER BY 1;
 year | sessions | purchases | conversion_pct 
------+----------+-----------+----------------
 2025 |    28194 |      2078 |           7.37
 2026 |    31806 |      2152 |           6.77
(2 rows)
```

De 7,37% para 6,77%. Duas frases descrevem essa mudança, e as duas estão certas:

- a conversão **caiu 0,60 ponto percentual**, a diferença entre as duas taxas;
- a conversão **caiu 8,1%**, a diferença como parcela de onde ela começou: 0,60 dividido por 7,37.

Elas são ouvidas de jeitos muito diferentes. "A conversão caiu 8%" numa reunião pode ser ouvido como oito
pontos, o que teria levado a conversão a quase nada, e mesmo ouvido certo soa maior que "0,6 ponto". Quem
escolheu a versão relativa pode não ter querido dramatizar: muitas ferramentas calculam *variação %* por
padrão.

Três hábitos evitam isso:

- **Diga "pontos" para a diferença entre duas porcentagens**, e "por cento" só para uma mudança relativa,
  e, quando importar, dê as duas: *caiu 0,6 ponto, de 7,37% para 6,77%*.
- **Dê os dois níveis**, não só a mudança. Um leitor que vê 7,37% e 6,77% não pode ser enganado por
  nenhuma das duas frases.
- **Cuidado com mudanças relativas em taxas pequenas.** Uma taxa de reembolso que vai de 1% para 2%
  *dobrou*, o que é verdade e também é um cliente em cem.

Essa mudança esconde ainda algo maior que a escolha de palavras, que é o assunto da seção do paradoxo: se
a conversão caiu de fato.

A pergunta que pega isso: **esta mudança é em pontos ou em por cento, e a frase diz isso?**
