---
title: O que os estudos pequenos erram
version: 1
---

Um estudo com pouco poder não é só um estudo que perde muitos efeitos reais. Quando ele acha um, tende a
**exagerá-lo**. Isso se chama **maldição do vencedor**, e é um dos motivos de efeitos publicados tantas vezes
encolherem quando alguém tenta repeti-los.

## Vendo acontecer

Suponha que o novo sistema de rotas economize de fato **1 minuto** por entrega. Rode o teste de 25 entregas
4.000 vezes e fique só com os testes que saíram significativos, como faria uma revista científica ou um
gerente:

| melhora verdadeira | poder | melhora média nos testes significativos |
|---|---|---|
| 1 minuto | 21% | 2,61 minutos |
| 2 minutos | 48% | 2,95 minutos |
| 3 minutos | 79% | 3,45 minutos |

Quando a melhora verdadeira é de 1 minuto, os testes que chegam à significância informam, em média, **2,61
minutos**: mais de duas vezes e meia a verdade.

## Por que acontece

Com 25 entregas, a média amostral oscila uns 1,2 minuto para cada lado. Para uma melhora de um minuto, só os
testes que calharam de oscilar na direção favorável — mostrando uma melhora grande por sorte — passam da
linha de significância. Selecionar os significativos é selecionar os sortudos. Quanto menor o poder, mais
sorte é preciso para passar da linha, e maior o exagero.

Com 79% de poder, a maioria dos testes passa da linha sem precisar de sorte, e os significativos exageram
muito menos.

## As consequências

**Um resultado significativo de um estudo pequeno provavelmente superestima o efeito.** Se o teste de 25
entregas da Horta tivesse saído significativo, a estimativa da melhora deveria ser tratada como um palpite
do lado alto, não como a economia esperada.

**Um resultado não significativo de um estudo pequeno diz pouco.** O teste da aula 13 não achou melhora, e
tinha só uma chance de cara ou coroa de achar uma real de dois minutos. "Testamos e não funcionou" é uma
afirmação forte que um teste com 48% de poder não consegue sustentar.

**O remédio é o mesmo de todos os outros problemas desta aula: planejar o estudo com poder adequado, antes de
coletar os dados.** Um estudo dimensionado para 80% de poder para detectar o menor efeito que importa acha
efeitos reais com confiabilidade e os informa sem muito exagero.
