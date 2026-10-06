---
title: Qual modelo, e ele se ajusta?
version: 1
---

As quatro distribuições respondem quatro tipos de pergunta. Escolher uma começa pela variável aleatória,
não pelos dados.

| a variável | o modelo | os parâmetros |
|---|---|---|
| qualquer valor numa faixa, nenhum favorecido | uniforme | as duas pontas |
| sucessos num número fixo de tentativas independentes | binomial | *n* e *p* |
| eventos num intervalo, ao acaso, a uma taxa constante | Poisson | a taxa λ |
| uma medida feita de muitos efeitos pequenos e independentes | normal | μ e σ |

Entregas atrasadas entre as dez de hoje: uma contagem com número fixo de tentativas, então binomial.
Reclamações amanhã: uma contagem sem número fixo de tentativas, então Poisson. O peso do próximo saco: uma
medida com muitas influências pequenas, então normal.

## Conferindo o ajuste

Um modelo é uma afirmação sobre os dados, e afirmações se conferem. A conferência mais simples é pôr as
previsões do modelo ao lado do que aconteceu.

Aqui estão os últimos 60 dias de reclamações, contra o que uma distribuição de Poisson com λ = 2,4 espera em
60 dias:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 260\" role=\"img\" data-fig=\"l08-poisson\" aria-label=\"As barras mostram quantos de 60 dias tiveram 0, 1, 2 e até 8 reclamações: 5, 17, 16, 8, 12, 2, e nenhum com 6 ou mais. Os pontos mostram o que uma distribuição de Poisson com média 2,4 espera em 60 dias: cerca de 5,4, 13,1, 15,7, 12,5, 7,5, 3,6, 1,4, 0,5 e 0,2. Os dois seguem a mesma forma, com os altos e baixos que sessenta dias produzem.\"><path d=\"M70.0 50.0 L70.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 205.0 L70.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"205.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 166.2 L570.0 166.2\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 166.2 L70.0 166.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"166.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M70.0 127.5 L570.0 127.5\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 127.5 L70.0 127.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"127.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M70.0 88.8 L570.0 88.8\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 88.8 L70.0 88.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"88.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><path d=\"M70.0 50.0 L570.0 50.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 50.0 L70.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><text x=\"70.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">dias</text><path d=\"M86.3 205.0 L86.3 166.2 L118.9 166.2 L118.9 205.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"102.6\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">0</text><path d=\"M140.7 205.0 L140.7 73.2 L173.3 73.2 L173.3 205.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"157.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1</text><path d=\"M195.0 205.0 L195.0 81.0 L227.6 81.0 L227.6 205.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"211.3\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2</text><path d=\"M249.3 205.0 L249.3 143.0 L282.0 143.0 L282.0 205.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"265.7\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3</text><path d=\"M303.7 205.0 L303.7 112.0 L336.3 112.0 L336.3 205.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"320.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4</text><path d=\"M358.0 205.0 L358.0 189.5 L390.7 189.5 L390.7 205.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"374.3\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5</text><path d=\"M412.4 205.0 L412.4 205.0 L445.0 205.0 L445.0 205.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"428.7\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">6</text><path d=\"M466.7 205.0 L466.7 205.0 L499.3 205.0 L499.3 205.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"483.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">7</text><path d=\"M521.1 205.0 L521.1 205.0 L553.7 205.0 L553.7 205.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"537.4\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">8</text><path d=\"M70.0 205.0 L570.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"102.6\" cy=\"162.8\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"157.0\" cy=\"103.8\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"211.3\" cy=\"83.5\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"265.7\" cy=\"107.8\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"320.0\" cy=\"146.7\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"374.3\" cy=\"177.0\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"428.7\" cy=\"193.8\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"483.0\" cy=\"201.2\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"537.4\" cy=\"203.8\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><text x=\"320.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">reclamações num dia</text><path d=\"M390 30 L404 30 L404 42 L390 42 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"410.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">dias observados</text><circle cx=\"397.0\" cy=\"56.0\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><text x=\"410.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">Poisson, média 2,4</text></svg>", "caption": "Sessenta dias reais contra o modelo. Nenhuma amostra bate com um modelo barra a barra; a pergunta é se a forma e a dispersão concordam."}
```

| reclamações | 0 | 1 | 2 | 3 | 4 | 5 | 6+ |
|---|---|---|---|---|---|---|---|
| dias observados | 5 | 17 | 16 | 8 | 12 | 2 | 0 |
| dias esperados | 5,4 | 13,1 | 15,7 | 12,5 | 7,5 | 3,6 | 2,1 |

Os dois não batem barra a barra, nem deveriam: 60 dias são uma amostra, e amostras oscilam. Os dias com uma
reclamação saíram cerca de quatro a mais que o esperado, os dias com quatro cerca de quatro e meio a mais,
e os dias com três cerca de quatro e meio a menos. O que importa é que a forma concorda — um pico em 1 e 2,
uma queda depois de 4 — e que a média e a variância, 2,18 e 1,85, estão perto, como devem estar numa
Poisson.

Se diferenças assim são maiores do que o acaso produziria é uma pergunta com resposta precisa. O teste
qui-quadrado da aula 16 a dá, usando exatamente esta tabela de contagens observadas e esperadas.

## Sinais de alerta

- **Um modelo que prevê o impossível**: pesos negativos, mais entregas atrasadas que entregas.
- **Uma variância longe da que o modelo implica**: uma Poisson cuja variância é três vezes a média, uma
  binomial com muito mais dispersão que *np*(1 − *p*).
- **Dois picos**, que nenhum destes quatro modelos produz.
- **Uma condição quebrada**: tentativas que não são independentes, uma taxa que muda ao longo do dia.

Quando um sinal de alerta aparece, o modelo ainda pode servir para o meio da distribuição, mas as caudas
dele não merecem confiança.
