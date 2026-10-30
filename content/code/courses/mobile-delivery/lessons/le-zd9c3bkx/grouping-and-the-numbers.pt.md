---
title: Agrupamento, e os números que as lojas vigiam
version: 1
---

**Mil relatórios de crash raramente são mil bugs; quase sempre são três bugs, cada um relatado
centenas de vezes.** O trabalho mais útil de um coletor é **agrupar**: decidir quais relatórios são o
mesmo problema, para que a equipe veja uma lista curta de issues com contagens, e não uma enxurrada de
relatórios.

## Como os relatórios são agrupados

Principalmente pela **pilha**: o tipo do erro e os quadros do topo do código que estava rodando, sem
as partes que variam de uma ocorrência para outra, como endereços. Dois relatórios com a mesma
exceção lançada da mesma função no mesmo arquivo são uma issue. É por isso que os símbolos importam
duas vezes: uma pilha sem símbolos não se agrupa bem, porque o mesmo bug parece diferente em dois
builds cujos nomes foram encurtados de jeitos diferentes.

O agrupamento é um palpite e às vezes erra. Um bug pode se dividir em várias issues quando quebra em
lugares diferentes; dois bugs podem se juntar quando quebram na mesma função genérica, como o
tratador de erros de uma biblioteca de rede. Todo coletor deixa uma pessoa juntar e separar issues à
mão.

## As duas taxas

| | o que ela conta | o que ela diz |
|---|---|---|
| **sessões sem crash** | a fração das sessões do app que terminaram sem crash | com que frequência o app quebra enquanto é usado |
| **usuários sem crash** | a fração das pessoas que não viram um crash no período | quantas pessoas os crashes alcançam |

A regra da lição 8 usou usuários sem crash, porque uma decisão de release é sobre quantas pessoas
saem machucadas. Um crash que atinge uma pessoa quarenta vezes quase não mexe nos usuários sem crash
e derruba as sessões sem crash: os dois números discordam exatamente quando um crash se concentra em
poucas pessoas.

## Os limites que o Google Play vigia

O **Android vitals** do Google Play calcula uma **taxa de crash percebida pelo usuário** por app e por
modelo de celular, e trata um app acima do limite como de mau comportamento, o que afeta a
visibilidade dele na loja. Os limites, da documentação de desenvolvedor do Android em outubro de
2026:

| | geral, entre aparelhos | num modelo de celular |
|---|---|---|
| taxa de crash percebida pelo usuário | 1,09% | 8% |
| taxa de ANR percebida pelo usuário, lição 14 | 0,47% | 8% |

**O limite por modelo é o que pega uma equipe de surpresa**: um app que vai bem na média pode passar
de 8% num celular popular, e o Play pode mostrar um aviso a quem tem aquele modelo. A Apple não
publica um número equivalente; o App Store Connect mostra contagens de crash por versão e aparelho, e
o **Xcode Organizer** mostra os logs de crash de quem compartilha diagnósticos.

## O que fazer com a lista

Ordene as issues por **pessoas afetadas**, e não por contagem. Leia o release mais novo primeiro.
Corrija a issue cuja contagem subiu com o release, porque essa é sua, antes da que está ali há um ano.
E acrescente uma migalha sempre que um relatório deixou você adivinhando o que a pessoa estava
fazendo; o próximo relatório vai dizer.
