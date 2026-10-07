---
title: Escolhendo paletas nas suas ferramentas
version: 1
---

Você raramente vai desenhar uma paleta do zero, e não deveria precisar. Existem boas em toda
ferramenta, com nomes que valem a pena conhecer.

## matplotlib

| tipo | nomes a procurar |
|---|---|
| sequencial | `viridis`, `cividis`, `magma`, `Blues`, `Greys` |
| divergente | `RdBu`, `PuOr`, `BrBG` |
| categórica | `tab10`, as cores padrão das linhas; ou uma lista com os hex de Okabe e Ito |

Um colormap é passado pelo nome, `cmap="cividis"`, para qualquer função que pinte por valor, como o
`imshow` ou o `scatter`. Para um mapa divergente, passe também o meio, para o zero cair no centro
claro: no matplotlib, `matplotlib.colors.TwoSlopeNorm(vcenter=0)`.

## ColorBrewer

As paletas por trás de `RdBu`, `Blues` e muitas outras vêm do **ColorBrewer**, desenhado pela
cartógrafa Cynthia Brewer para mapas. O site dele deixa você escolher o tipo, sequencial, divergente
ou qualitativa, o número de classes e se ela precisa sobreviver ao daltonismo ou a uma fotocópia, e dá
os valores hex. É o melhor lugar único para escolher a paleta de um coroplético (aula 8).

## Planilhas e ferramentas de BI

O Excel e o LibreOffice deixam você definir à mão a cor de cada série: digite os valores hex em vez de
escolher de olho. As escalas da formatação condicional recebem uma cor de mínimo, de ponto médio e de
máximo, o que basta para montar uma escala sequencial honesta (duas cores) ou divergente (três, com o
ponto médio no valor que significa algo). O Power BI e o Tableau trazem paletas seguras para daltonismo
e divergentes nos painéis de formatação; a aula 20 compara as ferramentas.

## Uma última conferência, venha de onde vier

**Olhe o gráfico em cinza**, como a aula 11 sugeriu, e **num simulador de daltonismo**, como a aula 14
mostra. Uma paleta que passa nos dois está pronta para o dado.
