---
title: A pergunta a que todo gráfico precisa sobreviver
version: 1
---

Quando Bia mostrou o primeiro rascunho a Marta, Marta olhou o gráfico de story points concluídos por sprint, que subia para a direita, e perguntou: **"E daí?"**

É a pergunta mais útil que alguém pode fazer a um gráfico, e a maioria dos gráficos numa revisão não consegue responder. Os pontos subiram. Isso quer dizer que as lojas recebem suas funcionalidades mais cedo? Quer dizer que o time está trabalhando mais, ou estimando maior, ou dividindo o trabalho de outro jeito? A aula 9 mostrou que pontos preveem pouco, e a aula 7 mostrou com que facilidade eles inflam. O gráfico estava correto e não sustentava decisão nenhuma, então saiu.

## O teste

Um gráfico tem lugar numa revisão se alguém consegue dizer, numa frase cada:

1. **o que ele mostra**, em palavras que uma pessoa de fora do time entende;
2. **por que mudou**, ou por que não mudou;
3. **o que alguém deveria fazer a respeito**, inclusive "nada; continuem assim".

A terceira frase é a que derruba a maioria dos gráficos. "Os deploys foram de 5 por mês para 20" passa na primeira; "porque o time agora solta cada item quando ele fica pronto" passa na segunda; "então as correções chegam às lojas em um dia, e outros times deveriam considerar a mesma regra" passa na terceira. Esse gráfico fica.

## Gráficos que reprovam

Alguns gráficos reprovam sempre, e reconhecê-los poupa um rascunho:

| gráfico | por que reprova |
|---|---|
| story points ou velocidade | mede as estimativas do time, não algo que um cliente sente |
| tickets fechados | premia dividir o trabalho, e conta a correção de um erro de digitação como uma funcionalidade |
| linhas de código, commits | premia atividade; a melhor mudança do trimestre pode ter apagado código |
| utilização, % do tempo ocupado | aula 12: um time totalmente ocupado é um time lento |
| um número por dev | aula 8: mede pessoas umas contra as outras, e o time para de dividir o trabalho |
| qualquer coisa sem comparação | um número sozinho, sem nada com que comparar, não aponta para lugar nenhum |

A última linha é a mais comum. "Tempo de ciclo mediano: 4 dias" é um fato; "4 dias, contra 23 em julho" é uma constatação. Todo número numa revisão precisa do seu **antes** ao lado e, se ainda não há um antes, precisa dizer isso.

## Quando a resposta incomoda

O teste corta para os dois lados. Um gráfico que sobrevive ao "e daí?" com uma resposta de que o time não gosta fica, e o incidente de 30 de setembro é o exemplo óbvio: um deploy com falha, 54 minutos de cobranças em dobro, 212 delas, e o orçamento de erro 201% gasto. O "e daí" é que as funcionalidades de outubro esperam. Deixá-lo de fora tornaria a revisão mais agradável e menos crível, e as pessoas na sala já sabem dele: os lojistas de Marta ligaram para ela.
