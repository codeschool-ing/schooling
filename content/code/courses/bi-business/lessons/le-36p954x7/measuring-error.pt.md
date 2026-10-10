---
title: Medir o erro, e transformá-lo numa faixa
version: 1
---

O teste com o passado produziu três colunas de erros. Esta seção dá nome ao que há nelas, diz qual
resumo merece confiança e transforma o erro do melhor método na faixa de que o Otávio precisava. **Um
erro é medido para que a próxima previsão possa dizer o quanto provavelmente vai errar.**

## Quatro palavras para um erro

Pegue o outubro do método com crescimento: ele previu 8.490 e a Varanda vendeu 7.960.

| palavra | o que é | outubro |
|---|---|---|
| erro | previsão menos real | +530, acima |
| erro percentual | o erro como parcela do real | +6,7% |
| erro percentual absoluto | o mesmo, sem o sinal | 6,7 |
| MAPE | a média dos erros percentuais absolutos nos meses testados | 2,3, de julho a dezembro |

**O sinal importa para uma pergunta e o tamanho para outra.** O tamanho diz o quanto uma previsão
costuma errar. O sinal diz se ela pende para um lado, que é o assunto da próxima parte.

## Viés: um erro que pende sempre para o mesmo lado

O método sazonal ingênuo errou 5,3% em média, mas essa média esconde um padrão: ele ficou abaixo do
real em cinco meses de seis. Um método que erra para um lado só tem **viés**, e o viés é pior do que o
tamanho sugere, porque se acumula. Planeje o estoque com uma previsão que fica sempre 5% abaixo e todo
mês falta produto. No semestre inteiro, a previsão sazonal ingênua ficou 5,3% abaixo do real no
total: 50.510 contra 53.340. Os erros do método com crescimento foram para os dois lados, +1,8, 0,0,
−0,8, +6,7, −1,8 e −2,4, então os erros mensais se anularam em boa parte e o semestre saiu com 0,2%
de diferença.

**Olhe os sinais antes da média.** Um MAPE pequeno com todos os erros de um lado é um método ao qual
falta um ingrediente, aqui o crescimento da empresa. Um MAPE maior com erros dos dois lados é um
método certo na média e ruidoso mês a mês.

## Sempre contra a linha de base

Um MAPE de 2,3% não quer dizer nada sozinho. É bom? Depende de quão difícil é prever a série, e o
jeito de medir isso é a linha de base. Contra os 15,7% do método ingênuo, o método com crescimento
elimina 85% do erro. **Um método novo que alguém proponha, por mais engenhoso que seja, precisa bater
2,3% nos mesmos meses para valer alguma coisa**, e se só bater os 15,7% do ingênuo não provou nada
que uma fórmula de planilha já não fizesse.

## Do teste para uma faixa

Agora o primeiro trimestre de 2026. O método é o vencedor: cada mês de 2025, vezes o crescimento de
2025 sobre 2024, que foi de 5,7%. Para janeiro:

```localised
=ARRED(6890*98000/92700;0)      7284
```

Fevereiro e março dão 6.882 e 7.844, então o trimestre soma 22.010, R$ 22,0 milhões. Para a faixa,
pegue o erro típico do teste, 2,3%, para cada lado:

```localised
=ARRED(7284*(1-2,3/100);0)      7116
=ARRED(7284*(1+2,3/100);0)      7452
```

A faixa do trimestre vai de 21.504 a 22.516. **Foi isso que a Lívia mandou ao Otávio: R$ 22,0
milhões, provavelmente entre 21,5 e 22,5**, e uma nota dizendo que o pior mês do teste errou 6,7%,
então uma campanha ou uma mudança de preço entrando ou saindo do trimestre empurraria o resultado
para fora da faixa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Três meses de 2026, de janeiro a março. Em cada um, um losango marca a previsão, 7.284, 6.882 e 7.844 mil reais, com uma barra curta para o erro típico de 2,3% para cada lado e uma barra mais longa e mais clara para o pior erro do teste, 6,7% para cada lado.\" data-fig=\"l08-range\"><path d=\"M192.5 30.0 L192.5 230.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"192.5\" y=\"248.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6.500</text><path d=\"M313.3 30.0 L313.3 230.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"313.3\" y=\"248.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">7.000</text><path d=\"M434.2 30.0 L434.2 230.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"434.2\" y=\"248.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">7.500</text><path d=\"M555.0 30.0 L555.0 230.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"555.0\" y=\"248.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8.000</text><path d=\"M675.8 30.0 L675.8 230.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"675.8\" y=\"248.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8.500</text><text x=\"106.0\" y=\"69.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">janeiro</text><path d=\"M264.0 62.0 H499.9 V68.0 H264.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M341.5 59.0 H422.5 V71.0 H341.5 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M377.0 65.0 L382.0 56.0 L387.0 65.0 L382.0 74.0 Z\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></path><text x=\"382.0\" y=\"51.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7.284</text><text x=\"106.0\" y=\"134.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">fevereiro</text><path d=\"M173.4 127.0 H396.2 V133.0 H173.4 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M246.6 124.0 H323.1 V136.0 H246.6 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M279.8 130.0 L284.8 121.0 L289.8 130.0 L284.8 139.0 Z\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></path><text x=\"284.8\" y=\"116.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6.882</text><text x=\"106.0\" y=\"199.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">março</text><path d=\"M390.3 192.0 H644.3 V198.0 H390.3 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M473.7 189.0 H560.9 V201.0 H473.7 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M512.3 195.0 L517.3 186.0 L522.3 195.0 L517.3 204.0 Z\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></path><text x=\"517.3\" y=\"181.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7.844</text><path d=\"M120.0 272.0 H142.0 V282.0 H120.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"150.0\" y=\"281.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">erro típico, ±2,3%</text><path d=\"M340.0 274.0 H362.0 V280.0 H340.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"370.0\" y=\"281.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pior erro, ±6,7%</text><text x=\"700.0\" y=\"281.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">milhares de reais</text></svg>", "caption": "O primeiro trimestre de 2026 mostrado como uma previsão deve ser: cada mês um número, com a faixa que o teste justificou e, mais clara, o tamanho do erro do pior mês do teste."}
```

A faixa é uma regra prática, não um intervalo estatístico: diz "este método costumava errar mais ou
menos isto", a partir de seis meses de evidência. Um estatístico calcularia um intervalo com uma
probabilidade declarada, que é matéria de `statistics`. Para decidir quanto estoque pedir em
fevereiro, a regra prática carrega a maior parte do valor, e é honesta sobre de onde veio.
