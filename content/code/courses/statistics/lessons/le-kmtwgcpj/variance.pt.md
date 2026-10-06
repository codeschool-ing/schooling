---
title: A variância
version: 1
---

Para usar todo valor, parta da distância de cada valor até a média, o **desvio**.

Para o Davi, cuja média é 35, os desvios são 22 − 35 = −13, depois −9, −4, 0, 3, 5, 9 e 9. O próximo passo
óbvio é tirar a média deles, e ele falha: **os desvios em relação à média sempre somam zero**, como a aula
3 mostrou. As entregas rápidas anulam exatamente as lentas.

Algo precisa impedir que os sinais se anulem. A escolha padrão é **elevar ao quadrado** cada desvio, o
que torna todos positivos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 330\" role=\"img\" data-fig=\"l05-deviations\" aria-label=\"Os oito tempos de entrega do Davi, cada um ligado à média de 35 por uma linha horizontal. Abaixo de cada linha, o desvio e o quadrado dele: menos 13 ao quadrado dá 169, menos 9 dá 81, menos 4 dá 16, 0 dá 0, 3 dá 9, 5 dá 25, 9 dá 81 e 9 dá 81. Os quadrados somam 462.\"><path d=\"M130.0 280.0 L610.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M130.0 280.0 L130.0 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"130.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M210.0 280.0 L210.0 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"210.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">25</text><path d=\"M290.0 280.0 L290.0 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"290.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><path d=\"M370.0 280.0 L370.0 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"370.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">35</text><path d=\"M450.0 280.0 L450.0 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"450.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><path d=\"M530.0 280.0 L530.0 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"530.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">45</text><path d=\"M610.0 280.0 L610.0 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"610.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><text x=\"370.0\" y=\"311.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">minutos</text><path d=\"M370.0 24.0 L370.0 280.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"20.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">desvio</text><text x=\"80.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">ao quadrado</text><path d=\"M370.0 40.0 L162.0 40.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"162.0\" cy=\"40.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><text x=\"40.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">−13</text><text x=\"115.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">169</text><path d=\"M370.0 68.0 L226.0 68.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"226.0\" cy=\"68.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><text x=\"40.0\" y=\"68.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">−9</text><text x=\"115.0\" y=\"68.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">81</text><path d=\"M370.0 96.0 L306.0 96.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"306.0\" cy=\"96.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><text x=\"40.0\" y=\"96.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">−4</text><text x=\"115.0\" y=\"96.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">16</text><circle cx=\"370.0\" cy=\"124.0\" r=\"5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><text x=\"40.0\" y=\"124.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0</text><text x=\"115.0\" y=\"124.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><path d=\"M370.0 152.0 L418.0 152.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"418.0\" cy=\"152.0\" r=\"5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><text x=\"40.0\" y=\"152.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">+3</text><text x=\"115.0\" y=\"152.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">9</text><path d=\"M370.0 180.0 L450.0 180.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"450.0\" cy=\"180.0\" r=\"5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><text x=\"40.0\" y=\"180.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">+5</text><text x=\"115.0\" y=\"180.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">25</text><path d=\"M370.0 208.0 L514.0 208.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"514.0\" cy=\"208.0\" r=\"5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><text x=\"40.0\" y=\"208.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">+9</text><text x=\"115.0\" y=\"208.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">81</text><path d=\"M370.0 236.0 L514.0 236.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"514.0\" cy=\"236.0\" r=\"5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><text x=\"40.0\" y=\"236.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">+9</text><text x=\"115.0\" y=\"236.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">81</text><text x=\"20.0\" y=\"311.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">soma dos quadrados 462</text></svg>", "caption": "Cada desvio é uma distância até a média. Ao quadrado, os negativos param de anular os positivos, e os valores distantes pesam muito mais que os próximos."}
```

## A variância do Davi à mão

| tempo | desvio | ao quadrado |
|---|---|---|
| 22 | −13 | 169 |
| 26 | −9 | 81 |
| 31 | −4 | 16 |
| 35 | 0 | 0 |
| 38 | 3 | 9 |
| 40 | 5 | 25 |
| 44 | 9 | 81 |
| 44 | 9 | 81 |
| | **soma** | **462** |

A soma dos desvios ao quadrado, 462, se chama **soma dos quadrados**. A variância é essa soma dividida
pelo número de valores menos um:

```localised
s² = 462 ÷ (8 − 1) = 66
```

A variância do Davi é **66**. A mesma tabela para a Lia dá uma soma dos quadrados de 8, e uma variância de
8 ÷ 7 = **1,14**.

A divisão por 7 em vez de 8 não é erro de impressão. É a **variância amostral**, a versão usada quando os
dados são uma amostra de algo maior — aqui, oito das muitas entregas de um entregador. A seção depois da
próxima explica por quê.

## Por que quadrados, e não só distâncias?

Ignorar os sinais e tirar a média das distâncias simples também funciona, e tem nome, **desvio médio
absoluto**. Para o Davi, ele é 6,5 minutos. É mais fácil de explicar e menos sensível a valores extremos.

Os quadrados venceram por motivos matemáticos: fazem a álgebra funcionar em resultados posteriores, o
teorema central do limite da aula 11 e a regressão da aula 19 entre eles. Elevar ao quadrado tem um
efeito colateral que vale conhecer. **Um valor distante conta desproporcionalmente**: o −13 do Davi
contribui com 169 para a soma, mais que o −4, o 3 e o 5 dele juntos.

## O problema das unidades

Os tempos do Davi estão em minutos, então os desvios ao quadrado estão em **minutos ao quadrado**, e a
variância também. "Uma variância de 66 minutos quadrados" não descreve nada que alguém consiga imaginar.
A variância é a grandeza certa para a matemática e a errada para um relatório. A próxima seção resolve
isso com uma raiz quadrada.
