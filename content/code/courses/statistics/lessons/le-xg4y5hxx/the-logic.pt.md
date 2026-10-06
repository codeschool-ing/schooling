---
title: A lógica de um teste
version: 1
---

Um teste de hipótese responde um tipo de pergunta: **o padrão na amostra é maior do que o acaso sozinho
produziria?**

A resposta nunca é provada diretamente. Em vez disso, o teste supõe o contrário — que não há padrão, só
acaso — e pergunta se os dados convivem bem com essa suposição. Se não convivem, a suposição é rejeitada, e
o padrão é chamado de **estatisticamente significativo**.

## O tribunal

A estrutura é a mesma de um julgamento criminal.

| julgamento | teste |
|---|---|
| o réu é presumido inocente | a hipótese nula é suposta verdadeira |
| a acusação apresenta provas | a amostra é coletada |
| a culpa precisa ser mostrada além de dúvida razoável | os dados precisam ser muito improváveis sob a nula |
| o veredito é culpado ou não culpado | a nula é rejeitada ou não rejeitada |

A última linha é a que as pessoas erram. Um julgamento nunca declara ninguém **inocente**: declara **não
culpado**, o que significa que as provas não foram fortes o bastante. Um teste é igual. **Não rejeitar a
hipótese nula não prova que ela é verdadeira.** Significa que os dados não deram evidência suficiente contra
ela.

## Por que argumentar ao contrário?

Seria mais natural perguntar "quão provável é que o novo sistema de rotas ajude?". O teste clássico não
responde isso, porque trata a verdade como fixa e só os dados como aleatórios — a mesma visão que a aula 12
teve dos intervalos de confiança. O que ele consegue calcular é quão provável são os dados sob uma suposição
precisa. "O novo sistema não muda nada" é preciso: diz que a média é 40 minutos. "O novo sistema ajuda" é
vago: em um minuto? em dez? Então o teste parte da afirmação precisa, e pergunta se os dados conseguem
conviver com ela.

## Quatro passos

Todo teste do resto deste curso segue os mesmos passos.

1. **Enunciar as hipóteses**: a nula e a alternativa.
2. **Escolher o nível de significância**, antes de ver os dados.
3. **Calcular uma estatística de teste** com a amostra: quão longe os dados estão do que a nula prevê, em
   unidades do próprio ruído.
4. **Decidir**: rejeitar a nula se a estatística cair onde a nula diz que raramente cairia.

As próximas quatro seções tratam de um passo cada, e a última roda o processo inteiro com as entregas da
Horta.
