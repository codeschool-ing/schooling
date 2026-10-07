---
title: A regra do escore z, e como ela falha
version: 1
---

Uma alternativa popular aponta todo valor cujo **escore z passa de ±3**: mais de três desvios padrão da
média. Em dados normais, isso aponta cerca de 0,3% dos valores, mais ou menos um em 370.

Ela é intuitiva, usa números que todo mundo já calcula, e tem uma falha que pesa mais justamente quando os
dados precisam de conferência.

## O valor atípico infla a própria régua

O escore z mede a distância em desvios padrão, e o desvio padrão é calculado com todos os valores, os
atípicos inclusive. Um valor atípico aumenta o desvio padrão, o que diminui todos os escores z, inclusive o
dele.

Pegue as doze cestas da Horta com o erro de R$ 2.126,00. A média vira R$ 238,62 e o desvio padrão,
R$ 595,85. O escore z do erro é (2126,00 − 238,62) ÷ 595,85 = **3,17**. Apontado, mas por pouco.

Há um motivo para ser por pouco. Numa amostra de *n* valores, **nenhum escore z pode passar de (*n* − 1) ÷
√*n***, por mais extremo que seja o valor. Para 12 valores esse teto é 3,18, então o erro está quase tão
longe quanto qualquer valor em doze poderia estar, e ainda assim mal passa de 3. Para **10 valores o teto é
2,85**: uma regra de z > 3 não consegue apontar nada em dez valores, nunca, seja o que for que eles
contenham.

## Mascaramento: dois erros escondem um ao outro

Agora suponha um segundo erro: R$ 154,75 digitado como R$ 1.547,50. Com os dois erros nas doze cestas, a
média é R$ 354,68 e o desvio padrão, R$ 703,88.

| valor | escore z |
|---|---|
| R$ 2.126,00 | 2,52 |
| R$ 1.547,50 | 1,69 |

**Nenhum é apontado.** Cada erro infla o desvio padrão o bastante para esconder o outro. Isso se chama
**mascaramento**, e piora quanto mais valores atípicos houver: uma regra de escore z acha um valor atípico
solitário, e deixa passar um grupo deles.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 250\" role=\"img\" data-fig=\"l09-masking\" aria-label=\"As doze cestas com dois erros de digitação, R$ 1.547,50 e R$ 2.126,00, numa reta de R$ 0 a R$ 2.500, desenhadas duas vezes. Em cima, a faixa da regra do escore z, a média mais ou menos três desvios padrão, vai de abaixo de zero até cerca de R$ 2.466 e contém os dois erros, então nenhum é apontado. Embaixo, a faixa da regra robusta, construída com a mediana e o MAD, vai só até cerca de R$ 247, e os dois erros ficam bem fora dela.\"><path d=\"M30.0 205.0 L640.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M30.0 205.0 L30.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"30.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M152.0 205.0 L152.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"152.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">500</text><path d=\"M274.0 205.0 L274.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"274.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.000</text><path d=\"M396.0 205.0 L396.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"396.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.500</text><path d=\"M518.0 205.0 L518.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"518.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2.000</text><path d=\"M640.0 205.0 L640.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"640.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2.500</text><text x=\"335.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">cesta, em reais</text><path d=\"M30.0 56.0 L631.8 56.0 L631.8 84.0 L30.0 84.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"var(--scan)\"></path><text x=\"30.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">regra do escore z: média ± 3 dp</text><text x=\"640.0\" y=\"44.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">nada apontado</text><circle cx=\"51.1\" cy=\"70.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"37.8\" cy=\"70.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"407.6\" cy=\"70.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"34.5\" cy=\"70.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"45.2\" cy=\"70.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"58.8\" cy=\"70.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"41.7\" cy=\"70.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"548.7\" cy=\"70.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"48.1\" cy=\"70.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"33.1\" cy=\"70.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"53.2\" cy=\"70.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"38.7\" cy=\"70.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><path d=\"M30.0 136.0 L90.3 136.0 L90.3 164.0 L30.0 164.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"var(--scan)\"></path><text x=\"30.0\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">regra robusta: mediana ± 3,5 unidades robustas</text><text x=\"640.0\" y=\"124.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">os dois apontados</text><circle cx=\"51.1\" cy=\"150.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"37.8\" cy=\"150.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"407.6\" cy=\"150.0\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"34.5\" cy=\"150.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"45.2\" cy=\"150.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"58.8\" cy=\"150.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"41.7\" cy=\"150.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"548.7\" cy=\"150.0\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"48.1\" cy=\"150.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"33.1\" cy=\"150.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"53.2\" cy=\"150.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"38.7\" cy=\"150.0\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle></svg>", "caption": "Os dois erros inflam o desvio padrão até que a faixa pela qual são julgados os contenha. A mediana e o MAD quase não os notam."}
```

## Quando a regra do escore z serve

Em amostras grandes de dados mais ou menos normais, com no máximo um ou dois valores desgarrados, a regra
do escore z funciona bem, e é perfeitamente razoável para algo como o peso dos sacos de uma envasadora. O
problema aparece com amostras pequenas, dados assimétricos e vários valores atípicos, que juntos descrevem
a maior parte dos dados em que os atípicos importam. Para esses, a regra precisa de um centro robusto e de
uma dispersão robusta, e esse é o assunto da próxima seção.
