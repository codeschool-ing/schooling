---
title: O desvio padrão
version: 1
---

O **desvio padrão** é a raiz quadrada da variância. Ele desfaz o quadrado das unidades e traz a medida de
volta à escala dos dados.

- Davi: √66 = **8,12 minutos**.
- Lia: √1,14 = **1,07 minuto**.

Agora os números podem ser ditos em voz alta. As entregas do Davi ficam tipicamente a uns 8 minutos da
média dele; as da Lia, a cerca de 1 minuto da dela. O desvio padrão do Davi é quase oito vezes o da Lia,
e esse é o número que o despachante da Horta gostaria de ter antes de prometer um horário a alguém.

## O que o número significa

O desvio padrão é, grosso modo, **uma distância típica até a média**. Não é exatamente a distância média
— essa era o desvio médio absoluto, 6,5 minutos para o Davi — porque os quadrados dão peso extra aos
valores distantes. Ele é sempre pelo menos tão grande quanto o desvio médio absoluto, e quase sempre um
pouco maior.

Um guia aproximado, que a aula 8 torna preciso para uma forma importante: em muitos dados reais, cerca de
dois terços dos valores ficam a até um desvio padrão da média. Para os doze tempos de entrega da Horta,
com média 38,96 e desvio padrão 9,77 minutos, a faixa de 29,19 a 48,73 contém 8 dos 12. Nas 400 cestas,
83% ficam a até um desvio padrão da média, mais que dois terços porque a cauda longa à direita infla o
desvio padrão. O guia é um guia, e a forma dos dados decide quanto ele vale.

## Os símbolos

O desvio padrão amostral se escreve *s*, e a variância amostral, *s*². A fórmula, com *x̄* a média e *n* o
número de valores, é *s* = √( Σ(*x* − *x̄*)² ÷ (*n* − 1) ). O Σ, a letra grega sigma maiúscula, significa
"some sobre todos os valores". Cada pedaço dela é um passo da tabela da seção anterior: desvio, quadrado,
soma, divisão por *n* − 1, raiz quadrada.

## Na planilha

Com os tempos do Davi em A2:A9:

```localised
=VAR.A(A2:A9)        66
=DESVPAD.A(A2:A9)    8,12403840463596
```

Esses são os valores que o LibreOffice Calc devolveu. O `.A` vem de *amostra*, e divide por *n* − 1. Cada
uma tem também uma versão `.P`, de *população*, que divide por *n*. Nos oito tempos do Davi, `DESVPAD.P`
devolve 7,60. A próxima seção trata de qual escolher, e a resposta é quase sempre `.A`.

## Zero, e nunca negativo

Um desvio padrão zero significa que todos os valores são iguais: nenhuma dispersão. Ele nunca pode ser
negativo, porque é a raiz quadrada de uma média de quadrados. Um desvio padrão negativo num relatório é um
erro, sempre.
