---
title: Prever na planilha, e testar a previsão no passado
version: 1
---

Um método é julgado pelo que teria feito num período que já aconteceu. **Isso é um teste com o
passado: finja que é fim de junho de 2025, preveja de julho a dezembro com cada método, e compare cada
previsão com o que a Varanda vendeu de fato.** O passado é o único lugar em que a resposta certa é
conhecida, então é o único lugar em que um método de previsão pode ser corrigido.

## A tabela

Acrescente uma aba. Digite o segundo semestre de 2025 e os mesmos meses de 2024, em milhares de
reais, a partir de A1:

| | A | B | C |
|---|---|---|---|
| 1 | Mês | Real 2025 | Mesmo mês 2024 |
| 2 | jul | 7140 | 6870 |
| 3 | ago | 7810 | 7380 |
| 4 | set | 8150 | 7640 |
| 5 | out | 7960 | 8020 |
| 6 | nov | 10040 | 9310 |
| 7 | dez | 12240 | 11290 |

O método com crescimento precisa do ritmo recente, e no fim de junho o ritmo recente é o primeiro
semestre de 2025 contra o primeiro semestre de 2024. Some os dois semestres na aba da aula 6, de
janeiro a junho: em I1 digite `1º sem 2024` e em J1 `42190`; em I2 digite `1º sem 2025` e em J2
`44660`. O primeiro semestre cresceu 5,9%.

## As três previsões e os seus erros

O tamanho de um erro, como parcela do que aconteceu de fato, é o **erro percentual absoluto**. Ele
precisa do erro sem o sinal, e o `MÁXIMO` entre o erro e o seu negativo dá exatamente isso. Em D1
digite `EPA ingênuo`. A previsão ingênua de todo mês é o junho de 2025, 7.330:

```localised
=ARRED(MÁXIMO(7330-B2;B2-7330)/B2*100;1)      2,7
```

Em E1 digite `EPA sazonal`. A previsão sazonal ingênua é a própria coluna C:

```localised
=ARRED(MÁXIMO(C2-B2;B2-C2)/B2*100;1)      3,8
```

Em F1 digite `Previsão cresc.` e em G1 `EPA cresc.`. A previsão é o mês do ano anterior vezes o
crescimento do semestre, e o erro dela se calcula do mesmo jeito:

```localised
=ARRED(C2*$J$2/$J$1;0)      7272
=ARRED(MÁXIMO(F2-B2;B2-F2)/B2*100;1)      1,8
```

Copie D2:G2 até a linha 7. Depois, na linha 8, tire a média de cada coluna de erro; a média dos erros
percentuais absolutos tem nome, **MAPE**, a sigla em inglês para erro percentual absoluto médio:

```localised
=ARRED(MÉDIA(D2:D7);1)      15,7
=ARRED(MÉDIA(E2:E7);1)      5,3
=ARRED(MÉDIA(G2:G7);1)      2,3
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"Um gráfico de linhas de julho a dezembro de 2025, em milhares de reais. As vendas reais sobem de 7.140 em julho a 12.240 em dezembro. A previsão sazonal ingênua, o mesmo mês do ano anterior, corre logo abaixo da linha real em todos os meses menos outubro. A previsão ajustada pelo crescimento fica quase em cima da linha real, menos em outubro, onde fica 6,7% acima. A previsão ingênua, junho repetido, é uma linha reta em 7.330 que perde inteiro o pico de novembro e dezembro.\" data-fig=\"l08-backtest\"><path d=\"M70.0 290.0 L560.0 290.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62.0\" y=\"294.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6.000</text><path d=\"M70.0 215.7 L560.0 215.7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62.0\" y=\"219.7\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8.000</text><path d=\"M70.0 141.4 L560.0 141.4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62.0\" y=\"145.4\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10.000</text><path d=\"M70.0 67.1 L560.0 67.1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62.0\" y=\"71.1\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">12.000</text><text x=\"100.0\" y=\"310.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">jul</text><text x=\"186.0\" y=\"310.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ago</text><text x=\"272.0\" y=\"310.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">set</text><text x=\"358.0\" y=\"310.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">out</text><text x=\"444.0\" y=\"310.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nov</text><text x=\"530.0\" y=\"310.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dez</text><path d=\"M100.0 240.6 L186.0 240.6 L272.0 240.6 L358.0 240.6 L444.0 240.6 L530.0 240.6\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"2 4\"></path><path d=\"M100.0 257.7 L186.0 238.7 L272.0 229.1 L358.0 215.0 L444.0 167.1 L530.0 93.5\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></path><path d=\"M100.0 242.8 L186.0 222.7 L272.0 212.5 L358.0 197.5 L444.0 146.8 L530.0 69.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><path d=\"M100.0 247.7 L186.0 222.8 L272.0 210.1 L358.0 217.2 L444.0 139.9 L530.0 58.2\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2.5\"></path><path d=\"M580.0 60.0 L602.0 60.0\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2.5\"></path><text x=\"608.0\" y=\"64.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">real 2025</text><path d=\"M580.0 90.0 L602.0 90.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><text x=\"608.0\" y=\"94.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ano anterior × cresc.</text><path d=\"M580.0 120.0 L602.0 120.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></path><text x=\"608.0\" y=\"124.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mês do ano anterior</text><path d=\"M580.0 150.0 L602.0 150.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"2 4\"></path><text x=\"608.0\" y=\"154.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">junho repetido</text><text x=\"580.0\" y=\"190.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">erro médio</text><text x=\"580.0\" y=\"210.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">× cresc.</text><text x=\"712.0\" y=\"210.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2,3%</text><text x=\"580.0\" y=\"230.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ano anterior</text><text x=\"712.0\" y=\"230.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5,3%</text><text x=\"580.0\" y=\"250.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">junho</text><text x=\"712.0\" y=\"250.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">15,7%</text><text x=\"352.0\" y=\"173.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">out: +6,7%</text><text x=\"70.0\" y=\"340.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">milhares de reais; previsões feitas com dados até junho de 2025</text></svg>", "caption": "O teste com o passado. Cada previsão desenhada contra o que aconteceu. O mês do ano anterior ajustado pelo crescimento do primeiro semestre erra 2,3% em média, e o seu único erro grande é outubro, onde a campanha mudou de lugar."}
```

## O que o teste diz

**O método ingênuo erra 15,7% em média, e 40,1% em dezembro.** É o método que ignora a estação, e a
estação é a maior parte do que acontece com a Varanda entre julho e dezembro.

**O mês do ano anterior erra 5,3%,** e erra para um lado só: fica abaixo do real em cinco meses de
seis. A Varanda cresceu, e esse método supõe que não. O único mês acima do real é outubro, com 0,8%, e
a aula 7 diz por quê.

**O mês do ano anterior vezes o crescimento do semestre erra 2,3%.** Cinco dos seus seis meses ficam a
até 2,4% do que aconteceu, e a previsão do semestre inteiro, 53.467 contra um real de 53.340, erra
0,2%. O único erro grande é outubro, 6,7% acima. Nenhum método que só lê o histórico teria visto esse:
a campanha que fez o outubro de 2024 grande foi para novembro em 2025, e nada no histórico de vendas
dizia que isso ia acontecer.

Esse foi o resultado que a Lívia levou ao Otávio: o método mais simples que mantém a estação e o ritmo
acertou com erro de poucos por cento em cinco meses de seis, e errou uns 7% no mês em que uma decisão
mudou o calendário. **A segunda metade dessa frase é tão útil quanto a primeira.** Ela diz que tipo de
evento esse método não enxerga, e portanto o que perguntar antes de confiar na próxima previsão:
alguma campanha, mudança de preço ou inauguração está mudando de lugar este ano?
