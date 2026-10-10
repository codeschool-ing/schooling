---
title: Lendo um histograma
version: 1
---

Um histograma não guarda latências; guarda **contagens por faixa**. Aqui estão as faixas da venda,
somadas nas três cópias, dez segundos depois de os geradores pararem:

```
ana@lab:~/tickets$ docker compose exec prometheus promtool query instant http://localhost:9090 'sum by (le) (tickets_request_seconds_bucket{route="/events/{id}/tickets"})'
{le="0.005"} => 0 @[1791612628.076]
{le="0.01"} => 839 @[1791612628.076]
{le="0.025"} => 4857 @[1791612628.076]
{le="0.05"} => 9303 @[1791612628.076]
{le="0.1"} => 12404 @[1791612628.076]
{le="0.25"} => 13236 @[1791612628.076]
{le="0.5"} => 13251 @[1791612628.076]
{le="1.0"} => 13251 @[1791612628.076]
{le="2.5"} => 13251 @[1791612628.076]
{le="5.0"} => 13251 @[1791612628.076]
{le="+Inf"} => 13251 @[1791612628.076]
```

Leia como uma tabela acumulada. Das 13 251 vendas, 839 levaram até 10 ms, 4857 até 25 ms, 9303 até
50 ms, **12 404 até 100 ms**, 13 236 até 250 ms, e todas até 500 ms. O total bate com o que o gerador
contou, 13 250, mais a única venda da seção 05.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"O histograma de latência da venda como barras de pedidos por faixa: nenhum abaixo de 5 milissegundos, 839 de 5 a 10, 4018 de 10 a 25, 4446 de 25 a 50, 3101 de 50 a 100, 832 de 100 a 250 e 15 de 250 a 500. Uma linha marca o percentil 95, que cai dentro da faixa de 100 a 250 milissegundos; o histograma só sabe que ele está em algum lugar dessa faixa.\"><rect x=\"50\" y=\"210.0\" width=\"70\" height=\"1\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"85\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">0</text><text x=\"85\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">≤5</text><rect x=\"142\" y=\"180.81739130434784\" width=\"70\" height=\"29.18260869565217\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"177\" y=\"170.81739130434784\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">839</text><text x=\"177\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5–10</text><rect x=\"234\" y=\"70.24347826086955\" width=\"70\" height=\"139.75652173913045\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"269\" y=\"60.24347826086955\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">4018</text><text x=\"269\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10–25</text><rect x=\"326\" y=\"55.356521739130415\" width=\"70\" height=\"154.64347826086959\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"361\" y=\"45.356521739130415\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">4446</text><text x=\"361\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">25–50</text><rect x=\"418\" y=\"102.1391304347826\" width=\"70\" height=\"107.8608695652174\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"453\" y=\"92.1391304347826\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">3101</text><text x=\"453\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50–100</text><rect x=\"510\" y=\"181.0608695652174\" width=\"70\" height=\"28.93913043478261\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"545\" y=\"171.0608695652174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">832</text><text x=\"545\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100–250</text><rect x=\"602\" y=\"209.47826086956522\" width=\"70\" height=\"1\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"637\" y=\"199.47826086956522\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">15</text><text x=\"637\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">250–500</text><path d=\"M40 210 L690 210\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"365\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">milissegundos</text><text x=\"555\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o p95 está em algum lugar aqui</text><path d=\"M555 30 L555 158\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path></svg>", "caption": "13 251 vendas separadas em faixas. O percentil 95 está na faixa de 100–250 ms, e é tudo o que o histograma consegue dizer."}
```

## Como um percentil sai das faixas

O percentil 95 é a latência abaixo da qual ficam 95% dos pedidos: 95% de 13 251 é 12 588. A tabela
diz que 12 404 ficam abaixo de 100 ms e 13 236 abaixo de 250 ms, então o 12 588º está **em algum
lugar entre 100 e 250 ms**. É tudo o que o histograma sabe. O `histogram_quantile` então supõe que
os pedidos estão espalhados por igual dentro da faixa e interpola: 184 dos 832 pedidos daquela
faixa, cerca de 22% do caminho de 100 a 250 ms, o que dá uns 133 ms na rodada inteira, e 120 ms nos
trinta segundos sobre os quais a seção 06 perguntou.

Então **um percentil tirado de um histograma é uma estimativa, e o erro dela é definido pelas
faixas.** Aqui a resposta está numa faixa de 150 ms de largura, e qualquer valor dentro dela é
igualmente compatível com as contagens. O gerador mediu 118 ms exatos porque guardou toda latência.
Duas consequências:

- **Escolha os limites das faixas em volta dos valores que importam.** Se a meta é "95% das vendas
  abaixo de 250 ms", um limite em exatamente 0,25 deixa essa pergunta exata, faça a interpolação o
  que fizer no resto. A seção 10 o usa.
- **A contagem de uma faixa pode ser somada entre cópias, e um percentil não.** O `sum by (le)` somou
  as faixas das três cópias antes de calcular um percentil para a bilheteria inteira. Três percentis
  por cópia tirados em média estariam errados, pelo motivo que a aula 2 deu sobre medianas entre
  shards. É por isso que histogramas são o jeito padrão de guardar latência num sistema com muitas
  cópias.

## Por dentro e por fora

Para leituras, a bilheteria disse 20 ms e o gerador mediu 30 ms, e **os dois estão certos**. O
histograma é medido dentro do tratador, do momento em que o pedido é lido ao momento em que a
resposta é escrita. O relógio do gerador também inclui o nginx, duas viagens pela rede e o tempo que
um pedido espera para ser aceito. Numa leitura que leva poucos milissegundos, essa parte de fora é
uma fatia grande; numa venda de cem milissegundos, pequena, e é por isso que essas duas concordaram.
**Uma latência medida dentro de um serviço é um limite inferior do que os usuários dele vivem.**
