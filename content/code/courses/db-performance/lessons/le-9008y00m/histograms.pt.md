---
title: Histogramas, e a ordem no disco
version: 1
---

Uma lista de valores comuns não ajuda em nada com `placed_at`. Nenhum par de pedidos foi feito no
mesmo instante, então nenhum valor é comum, e uma pergunta como "pedidos antes de 2024" é sobre uma
**faixa**, não sobre um valor. Para isso o resumo guarda um histograma, e o que o PostgreSQL guarda
não é do tipo que a maioria das pessoas desenha.

## Linhas iguais, não larguras iguais

O histograma que você desenharia à mão corta o eixo do tempo em pedaços iguais, uma barra por mês,
e conta os pedidos em cada um. O PostgreSQL faz o contrário. Ele ordena a amostra, corta-a em **cem
baldes que guardam o mesmo número de linhas** e anota só os valores onde um balde termina e o
próximo começa. Cem baldes precisam de 101 limites, e essa lista é tudo o que ele guarda:

```
market=# SELECT n, b FROM pg_stats, unnest(histogram_bounds::text::timestamptz[]) WITH ORDINALITY AS u(b, n) WHERE tablename = 'orders' AND attname = 'placed_at' AND (n <= 3 OR n IN (12, 13) OR n >= 99);
  n  |               b               
-----+-------------------------------
   1 | 2023-01-06 12:21:36.107502-03
   2 | 2023-04-17 17:45:58.458055-03
   3 | 2023-06-02 20:37:50.19636-03
  12 | 2023-12-29 13:38:09.337447-03
  13 | 2024-01-14 16:08:56.040438-03
  99 | 2025-12-19 19:25:41.315086-03
 100 | 2025-12-25 08:47:22.106654-03
 101 | 2025-12-30 22:55:55.013606-03
(8 rows)

Time: 5.718 ms
```

A consulta desempacota `histogram_bounds` em linhas numeradas e fica com oito dos 101. O primeiro
balde vai de 6 de janeiro a 17 de abril de 2023, **101 dias**. O último vai de 25 a 30 de dezembro de
2025, **cinco dias e meio**. Os dois guardam 1% dos pedidos, uns 20.000, então a largura de um balde
diz o quanto os pedidos eram esparsos ali: o `market.sql` fez cada ano mais movimentado que o
anterior, e os baldes estreitam à medida que os pedidos se amontoam.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Um histograma de quando os dois milhões de pedidos foram feitos, de 2023 a 2025, desenhado do jeito que o PostgreSQL o guarda: cem baldes que guardam cada um um por cento dos pedidos. O primeiro balde cobre 101 dias de 2023 e é uma barra baixa e larga; o último cobre cinco dias e meio no fim de 2025 e é alto e estreito. Toda barra tem a mesma área, e as barras sobem da esquerda para a direita porque mais pedidos foram feitos a cada ano.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cada barra guarda 1% dos pedidos, cerca de 20.000</text><rect x=\"53.22\" y=\"201.12\" width=\"59.11\" height=\"8.88\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"112.33\" y=\"190.52\" width=\"26.93\" height=\"19.48\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"139.26\" y=\"184.51\" width=\"20.58\" height=\"25.49\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"159.84\" y=\"180.58\" width=\"17.83\" height=\"29.42\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"177.68\" y=\"174.42\" width=\"14.75\" height=\"35.58\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"192.42\" y=\"169.56\" width=\"12.97\" height=\"40.44\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"205.39\" y=\"165.83\" width=\"11.88\" height=\"44.17\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"217.27\" y=\"173.01\" width=\"14.18\" height=\"36.99\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"231.46\" y=\"158.15\" width=\"10.12\" height=\"51.85\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"241.57\" y=\"157.17\" width=\"9.93\" height=\"52.83\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"251.5\" y=\"158.64\" width=\"10.21\" height=\"51.36\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"261.72\" y=\"154.21\" width=\"9.4\" height=\"55.79\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"271.12\" y=\"148.65\" width=\"8.55\" height=\"61.35\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"279.67\" y=\"143.56\" width=\"7.9\" height=\"66.44\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"287.57\" y=\"149.2\" width=\"8.63\" height=\"60.8\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"296.2\" y=\"142.62\" width=\"7.79\" height=\"67.38\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"303.99\" y=\"142.06\" width=\"7.72\" height=\"67.94\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"311.71\" y=\"141.08\" width=\"7.61\" height=\"68.92\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"319.32\" y=\"144.18\" width=\"7.97\" height=\"65.82\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"327.29\" y=\"138.45\" width=\"7.33\" height=\"71.55\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"334.62\" y=\"133.52\" width=\"6.86\" height=\"76.48\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"341.48\" y=\"130.22\" width=\"6.58\" height=\"79.78\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"348.06\" y=\"130.28\" width=\"6.58\" height=\"79.72\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"354.64\" y=\"134.5\" width=\"6.95\" height=\"75.5\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"361.59\" y=\"130.55\" width=\"6.6\" height=\"79.45\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"368.19\" y=\"126.65\" width=\"6.29\" height=\"83.35\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"374.49\" y=\"123.85\" width=\"6.09\" height=\"86.15\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"380.57\" y=\"124.25\" width=\"6.12\" height=\"85.75\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"386.69\" y=\"124.6\" width=\"6.14\" height=\"85.4\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"392.84\" y=\"116.35\" width=\"5.6\" height=\"93.65\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"398.44\" y=\"112.0\" width=\"5.35\" height=\"98.0\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"403.79\" y=\"125.88\" width=\"6.24\" height=\"84.12\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"410.03\" y=\"114.28\" width=\"5.48\" height=\"95.72\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"415.51\" y=\"113.2\" width=\"5.42\" height=\"96.8\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"420.93\" y=\"111.52\" width=\"5.33\" height=\"98.48\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"426.26\" y=\"108.72\" width=\"5.18\" height=\"101.28\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"431.44\" y=\"109.63\" width=\"5.23\" height=\"100.37\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"436.66\" y=\"106.02\" width=\"5.05\" height=\"103.98\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"441.71\" y=\"117.43\" width=\"5.67\" height=\"92.57\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"447.38\" y=\"102.9\" width=\"4.9\" height=\"107.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"452.27\" y=\"110.35\" width=\"5.26\" height=\"99.65\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"457.54\" y=\"107.93\" width=\"5.14\" height=\"102.07\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"462.68\" y=\"101.69\" width=\"4.84\" height=\"108.31\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"467.52\" y=\"105.68\" width=\"5.03\" height=\"104.32\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"472.55\" y=\"92.97\" width=\"4.48\" height=\"117.03\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"477.03\" y=\"106.8\" width=\"5.08\" height=\"103.2\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"482.12\" y=\"94.15\" width=\"4.53\" height=\"115.85\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"486.65\" y=\"89.23\" width=\"4.34\" height=\"120.77\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"490.99\" y=\"98.67\" width=\"4.71\" height=\"111.33\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"495.7\" y=\"86.84\" width=\"4.26\" height=\"123.16\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"499.96\" y=\"89.96\" width=\"4.37\" height=\"120.04\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"504.33\" y=\"96.42\" width=\"4.62\" height=\"113.58\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"508.95\" y=\"95.62\" width=\"4.59\" height=\"114.38\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"513.54\" y=\"89.33\" width=\"4.35\" height=\"120.67\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"517.89\" y=\"94.99\" width=\"4.56\" height=\"115.01\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"522.45\" y=\"91.24\" width=\"4.42\" height=\"118.76\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"526.87\" y=\"99.89\" width=\"4.76\" height=\"110.11\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"531.63\" y=\"86.84\" width=\"4.26\" height=\"123.16\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"535.89\" y=\"79.37\" width=\"4.02\" height=\"130.63\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"539.91\" y=\"85.88\" width=\"4.23\" height=\"124.12\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"544.13\" y=\"79.06\" width=\"4.01\" height=\"130.94\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"548.14\" y=\"85.81\" width=\"4.22\" height=\"124.19\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"552.36\" y=\"72.79\" width=\"3.82\" height=\"137.21\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"556.19\" y=\"86.77\" width=\"4.26\" height=\"123.23\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"560.44\" y=\"77.4\" width=\"3.96\" height=\"132.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"564.4\" y=\"69.97\" width=\"3.75\" height=\"140.03\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"568.15\" y=\"70.08\" width=\"3.75\" height=\"139.92\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"571.9\" y=\"75.87\" width=\"3.91\" height=\"134.13\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"575.81\" y=\"79.62\" width=\"4.02\" height=\"130.38\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"579.83\" y=\"77.73\" width=\"3.97\" height=\"132.27\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"583.8\" y=\"81.3\" width=\"4.08\" height=\"128.7\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"587.87\" y=\"78.03\" width=\"3.98\" height=\"131.97\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"591.85\" y=\"66.99\" width=\"3.67\" height=\"143.01\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"595.52\" y=\"73.06\" width=\"3.83\" height=\"136.94\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"599.35\" y=\"68.87\" width=\"3.72\" height=\"141.13\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"603.07\" y=\"82.75\" width=\"4.12\" height=\"127.25\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"607.19\" y=\"68.55\" width=\"3.71\" height=\"141.45\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"610.9\" y=\"74.03\" width=\"3.86\" height=\"135.97\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"614.76\" y=\"65.7\" width=\"3.64\" height=\"144.3\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"618.39\" y=\"53.03\" width=\"3.34\" height=\"156.97\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"621.73\" y=\"62.71\" width=\"3.56\" height=\"147.29\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"625.3\" y=\"55.98\" width=\"3.41\" height=\"154.02\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"628.7\" y=\"48.03\" width=\"3.24\" height=\"161.97\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"631.94\" y=\"57.11\" width=\"3.43\" height=\"152.89\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"635.37\" y=\"55.16\" width=\"3.39\" height=\"154.84\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"638.76\" y=\"54.06\" width=\"3.36\" height=\"155.94\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"642.13\" y=\"55.85\" width=\"3.4\" height=\"154.15\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"645.53\" y=\"66.07\" width=\"3.65\" height=\"143.93\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"649.17\" y=\"62.83\" width=\"3.56\" height=\"147.17\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"652.74\" y=\"62.17\" width=\"3.55\" height=\"147.83\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"656.29\" y=\"48.11\" width=\"3.24\" height=\"161.89\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"659.53\" y=\"50.48\" width=\"3.29\" height=\"159.52\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"662.82\" y=\"50.41\" width=\"3.29\" height=\"159.59\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"666.1\" y=\"54.61\" width=\"3.38\" height=\"155.39\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"669.48\" y=\"59.07\" width=\"3.48\" height=\"150.93\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"672.96\" y=\"58.39\" width=\"3.46\" height=\"151.61\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"676.42\" y=\"40.0\" width=\"3.09\" height=\"170.0\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"679.5\" y=\"54.71\" width=\"3.38\" height=\"155.29\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"682.88\" y=\"48.32\" width=\"3.24\" height=\"161.68\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><rect x=\"686.13\" y=\"49.26\" width=\"3.26\" height=\"160.74\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.4\"></rect><path d=\"M50 210 L690 210\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M50.0 210 L50.0 215\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"50.0\" y=\"226\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">2023</text><path d=\"M263.13868613138686 210 L263.13868613138686 215\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"263.13868613138686\" y=\"226\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">2024</text><path d=\"M476.86131386861314 210 L476.86131386861314 215\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"476.86131386861314\" y=\"226\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">2025</text><path d=\"M690.0 210 L690.0 215\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"690.0\" y=\"226\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">2026</text><path d=\"M82.8 196 L82.8 120\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><text x=\"76.77525682616923\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">primeiro balde: 101 dias</text><path d=\"M687.8 37 L687.8 28 L676.1 28\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><text x=\"672.126263855096\" y=\"28\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--amber)\">último balde: 5,6 dias</text><text x=\"50\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">placed_at</text></svg>", "caption": "Os 101 limites de orders.placed_at, como barras. Cada balde guarda 1% dos pedidos, então a barra é alta onde os pedidos são densos e larga onde são esparsos."}
```

Desenhados como barras de área igual, os 101 limites são o formato do negócio. Nada na tabela diz
"os pedidos cresceram todo ano"; o histograma descobriu isso numa amostra de 30.000 linhas.

## Uma faixa, estimada

Peça os pedidos antes de 2024 e compare com a contagem:

```
market=# EXPLAIN SELECT * FROM orders WHERE placed_at < '2024-01-01';
                                         QUERY PLAN                                         
--------------------------------------------------------------------------------------------
 Index Scan using orders_placed_at_idx on orders  (cost=0.43..8213.26 rows=223019 width=37)
   Index Cond: (placed_at < '2024-01-01 00:00:00-03'::timestamp with time zone)
(2 rows)

Time: 1.381 ms

market=# SELECT count(*) FROM orders WHERE placed_at < '2024-01-01';
 count  
--------
 221610
(1 row)

Time: 18.928 ms
```

**223.019 estimados, 221.610 contados**, 0,6% de distância. A conta só precisa dos limites acima. Do
limite 1 ao limite 12 são onze baldes inteiros, todos antes de 2024: 11% das linhas. O décimo
segundo balde vai de 29 de dezembro de 2023 a 14 de janeiro de 2024, e 2024 começa dentro dele, 2,4
dias depois do início de um balde de 16,1 dias. O planejador supõe que as linhas dentro de um balde
estão **espalhadas por igual**, então pega também esses 15% do balde: 11,15% de dois milhões dá
223.000, o número do plano.

Essa distribuição uniforme é a única suposição, e numa faixa curta é ela que aparece:

```
market=# EXPLAIN SELECT * FROM orders WHERE placed_at >= '2025-06-01' AND placed_at < '2025-06-02';
                                                                       QUERY PLAN                                                                       
--------------------------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using orders_placed_at_idx on orders  (cost=0.43..127.77 rows=3117 width=37)
   Index Cond: ((placed_at >= '2025-06-01 00:00:00-03'::timestamp with time zone) AND (placed_at < '2025-06-02 00:00:00-03'::timestamp with time zone))
(2 rows)

Time: 0.761 ms
```

Um dia, 1º de junho de 2025, estimado em **3117** onde a aula 1 contou **2801**. O dia fica dentro de
um balde de seis dias e meio, de 30 de maio a 6 de junho, e o planejador lhe dá cerca de um sexto
das 20.000 linhas do balde. O primeiro de junho foi um dia mais calmo que o dia médio do seu balde,
então a estimativa ficou 11% acima. Um histograma mais fino estreitaria o balde, e a seção 05 mostra
a configuração que compra um.

Mais um detalhe: uma coluna que tem valores comuns os deixa fora do histograma. A lista da seção 03
cobre esses valores, e os baldes dividem o que sobra, então um valor é descrito por um dos dois e
nunca pelos dois.

## Correlação: onde as linhas ficam no disco

O último número do resumo, `correlation`, não é sobre quantas linhas batem. É sobre **onde elas
estão**. Ele compara a ordem dos valores com a ordem das linhas nos arquivos da tabela: 1 quer dizer
ordenados do mesmo jeito, 0 quer dizer sem relação, -1 quer dizer ordenados ao contrário.

A seção 02 mostrou `placed_at` com **1** e `customer_id` com **0.0064**. Peça uns cem mil pedidos por
cada uma:

```
market=# EXPLAIN SELECT * FROM orders WHERE placed_at >= '2025-12-01';
                                         QUERY PLAN                                         
--------------------------------------------------------------------------------------------
 Index Scan using orders_placed_at_idx on orders  (cost=0.43..3913.06 rows=106093 width=37)
   Index Cond: (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone)
(2 rows)

Time: 2.094 ms

market=# EXPLAIN SELECT * FROM orders WHERE customer_id <= 10000;
                                         QUERY PLAN                                          
---------------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=1271.92..19228.42 rows=103160 width=37)
   Recheck Cond: (customer_id <= 10000)
   ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..1246.13 rows=103160 width=0)
         Index Cond: (customer_id <= 10000)
(4 rows)

Time: 0.886 ms
```

Duas condições que devolvem cada uma uns 5% da tabela, 106.093 e 103.160 linhas estimadas, e dois
planos diferentes. Para `placed_at` o planejador escolheu um index scan simples e lhe deu custo
**3.913**. Para `customer_id` ele montou primeiro um bitmap e lhe deu custo **19.228**, cinco vezes
mais.

As linhas são o motivo. Os pedidos de dezembro de 2025 ficam um ao lado do outro no fim da tabela,
porque foram gravados nessa ordem, então um index scan que os lê na ordem de `placed_at` lê cada
página da tabela uma vez, em sequência. Os pedidos dos clientes 1 a 10.000 estão espalhados por
todas as partes da tabela, e lê-los na ordem de `customer_id` pularia de página em página e voltaria
muitas vezes à mesma página. O planejador põe preço nesses pulos por meio de `correlation`, e o
bitmap scan da aula 4 é o jeito dele de evitá-los: junta as páginas primeiro, ordena-as, lê cada uma
uma vez.

A correlação também é o que torna possível o índice BRIN da aula 8. Ele só funciona numa coluna cujos
valores seguem a ordem física da tabela, e `correlation` é onde você confere isso antes de criar um.
