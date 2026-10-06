---
title: Poder
version: 1
---

O **poder** de um teste é a probabilidade de ele rejeitar a hipótese nula quando um certo efeito está de
fato presente:

**poder = 1 − β**

É a probabilidade de achar o que você procura, se existir. Um estudo com 80% de poder para uma melhora de
dois minutos detecta uma melhora real de dois minutos quatro vezes em cinco.

## O poder do teste da Horta

O teste da Horta teve 25 entregas, desvio padrão de uns 6 minutos e um teste unilateral a 5%. Com que
frequência ele detectaria uma melhora real? Uma simulação responde direto: gere 4.000 testes de 25 entregas
sob cada melhora verdadeira, rode o teste em cada um e conte as rejeições.

| melhora verdadeira | poder simulado |
|---|---|
| 1 minuto | 21% |
| 2 minutos | 48% |
| 3 minutos | 79% |

Para uma melhora de dois minutos, o teste era mais ou menos um **cara ou coroa**: acharia a melhora cerca de
metade das vezes e a perderia cerca de metade das vezes. Para uma melhora de um minuto, a perderia quatro
vezes em cinco.

Então o resultado não significativo da aula 13 diz muito menos do que parecia. O teste simplesmente não era
grande o bastante para ter boa chance de detectar uma melhora do tamanho que importaria.

## O que move o poder

Quatro coisas, todas visíveis no desenho da seção anterior.

- **O tamanho do efeito.** Efeitos maiores afastam a curva da alternativa da curva da nula, e são mais
  fáceis de ver.
- **O tamanho da amostra.** Mais dados estreitam as duas curvas, pelo √*n* do erro padrão.
- **O ruído.** Um desvio padrão menor também estreita as duas curvas: medir com mais precisão é como ter mais
  dados.
- **O nível de significância.** Um α maior move a linha em direção à alternativa e sobe o poder, ao custo de
  mais alarmes falsos.

Das quatro, o tamanho da amostra costuma ser a que você controla.

## Uma fórmula, aproximada

Para um teste unilateral de uma média, uma aproximação normal dá o poder como a área da curva normal padrão
abaixo de *δ* ÷ EP − 1,645, em que *δ* é a melhora verdadeira e EP o erro padrão. Para uma melhora de dois
minutos com EP = 1,2: 2 ÷ 1,2 − 1,645 = 0,022, e a área abaixo de 0,022 é 0,51. Perto dos 48% simulados; a
pequena diferença são as caudas mais grossas da distribuição t com 24 graus de liberdade.

```localised
=DIST.NORMP.N(2/(6/RAIZ(25)) - INV.NORMP.N(0,95); VERDADEIRO)      0,508701453763093
```
