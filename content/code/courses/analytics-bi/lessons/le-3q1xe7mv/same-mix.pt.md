---
title: Segurar a mistura parada
version: 1
---

O paradoxo de Simpson costuma ser explicado com um diagrama e deixado ali. Ele também pode ser medido,
fazendo uma pergunta precisa: **qual teria sido o total se a mistura não tivesse mudado?** Calcule as taxas
de cada ano sobre os mesmos pesos — primeiro a mistura de aparelhos de 2025, depois a de 2026:

```
lantern=# WITH r AS (
lantern(#   SELECT year, device, count(*)::numeric AS sessions,
lantern(#          count(*) FILTER (WHERE steps >= 5) / count(*)::numeric AS rate
lantern(#   FROM (SELECT extract(year FROM started_at)::int AS year, device, steps
lantern(#         FROM shop.web_sessions) s
lantern(#   GROUP BY 1, 2),
lantern-# w AS (SELECT year, device, sessions / sum(sessions) OVER (PARTITION BY year) AS share FROM r)
lantern-# SELECT 'mix of ' || w.year AS weights,
lantern-#        round(100 * sum(w.share * r.rate) FILTER (WHERE r.year = 2025), 2) AS rates_of_2025,
lantern-#        round(100 * sum(w.share * r.rate) FILTER (WHERE r.year = 2026), 2) AS rates_of_2026
lantern-# FROM w JOIN r USING (device)
lantern-# GROUP BY w.year ORDER BY w.year;
   weights   | rates_of_2025 | rates_of_2026 
-------------+---------------+---------------
 mix of 2025 |          7.37 |          7.92
 mix of 2026 |          6.32 |          6.77
(2 rows)
```

Leia a tabela por linhas. Com a mistura de 2025, a conversão vai de 7,37% para **7,92%**: as taxas de
2026, sobre os visitantes de 2025, teriam sido melhores. Com a mistura de 2026, de **6,32%** para 6,77%:
melhor de novo. Segurando a mistura parada, de um jeito ou de outro, a conversão subiu cerca de meio
ponto. A queda relatada inteira, e mais um pouco, é a mudança de mistura.

Isso divide os −0,60 ponto relatados em duas partes sobre as quais alguém pode agir:

- **as taxas melhoraram**, cerca de +0,5 ponto com a mistura fixa — o site e o checkout ficaram melhores;
- **a mistura foi para o celular**, valendo cerca de −1,1 ponto — um fato sobre de onde vêm os visitantes,
  que é pergunta do marketing, e não do site.

As duas partes não são igualmente certas. A mistura se moveu quinze pontos de participação, sobre dezenas
de milhares de sessões, e isso não é acaso. As taxas se moveram menos: os 0,9 ponto do desktop são cerca
de dois erros padrão, como a aula 9 os calcularia, e os 0,24 ponto do celular, cerca de um. Então a
leitura segura é *a queda é a mistura; o site não piorou e provavelmente melhorou um pouco*, e não *o site
melhorou*.

Isso se chama **padronização**, ou taxa ajustada pela mistura, e é a forma honesta de comparar dois
períodos cujas populações diferem. Ela exige que os grupos sejam escolhidos por um motivo: aparelho aqui,
porque as taxas diferem muito entre eles. E o leitor precisa saber qual mistura foi segurada, porque as
duas respostas acima diferem em mais de um ponto.
