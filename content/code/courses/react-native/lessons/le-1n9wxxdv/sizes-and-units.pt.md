---
title: Pontos, porcentagens e o tamanho da janela
version: 1
---

**Um número num estilo do React Native é um pixel independente de densidade**, que o Android chama de *dp* e
o iOS de *ponto*. Não leva unidade escrita depois, e quer dizer o mesmo tamanho físico em todo celular, cerca
de um 160 avos de polegada. Uma linha de 62 de altura tem 62 num celular pequeno e num grande, e cobre mais
pixels reais naquele cuja tela é mais densa.

## Nada de px, em ou rem

As unidades do CSS não estão aqui. Não há `px` para escrever, porque o número já é a unidade; nem `em` ou
`rem`, porque nada propaga um tamanho de fonte em relação ao qual medir; nem `vh` ou `vw`. O que sobra:

| escrito como | quer dizer | o planner usa para |
|---|---|---|
| `16` | 16 pontos | quase tudo |
| `"50%"` | metade do tamanho do pai naquele eixo | nada ainda; um leiaute de duas colunas usaria |
| `flex: 1` | uma parte do espaço livre | a barra da semana |
| `aspectRatio: 16 / 9` | a altura a partir da largura, ou o contrário | uma capa de curso na aula 13 |

## A janela, quando importa

Um leiaute escrito em flex e porcentagens se adapta sozinho, e a próxima seção mede o planner na largura de
um tablet para mostrar isso. Quando uma decisão depende do tamanho, *duas colunas acima de 600 pontos de
largura*, o componente pergunta pela janela:

```tsx
const { width, height, fontScale } = useWindowDimensions();
```

O `useWindowDimensions` renderiza o componente de novo quando a janela muda, ao girar, num tablet com a tela
dividida, num dobrável aberto. **Leia-o no componente que decide**, não uma vez na abertura numa constante,
que é o erro que deixa um tablet girado com o leiaute de celular.

## O tamanho de texto da pessoa

O `fontScale` nessa resposta é o tamanho de texto escolhido pela pessoa, nas configurações de acessibilidade
do celular, como multiplicador. O React Native o aplica sozinho a cada `fontSize`: um `Text` de 17 é desenhado
com 17 vezes a escala. **Não brigue com ele.** Uma linha com `height` fixo corta o próprio texto em escalas
grandes; dê às linhas `padding` e deixe o texto definir a altura, como fazem as linhas do planner. O
`maxFontSizeMultiplier` num `Text` limita a escala onde um leiaute realmente não pode crescer, os rótulos de
uma barra de abas por exemplo, e é uma decisão a tomar sabendo que ela tira algo de alguém que pediu.

## Pixels reais, quando precisar

O `PixelRatio.get()` devolve a densidade, 2 ou 3 na maioria dos celulares, e o
`PixelRatio.roundToNearestPixel` ajusta um valor a um pixel inteiro do aparelho, o que impede uma linha fina de
borrar. O `StyleSheet.hairlineWidth` é a linha mais fina que a tela consegue desenhar. Isso importa para um ou
outro divisor e para imagens, como a aula 4 disse; nada mais no planner precisa deles.
