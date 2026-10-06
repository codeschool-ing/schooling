---
title: Para que servem as pessoas
version: 1
---

A aula 9 terminou com um juiz que aprovou uma resposta sobre entrega expressa para um cliente que
tinha perguntado sobre a entrega padrão. Nada medido até aqui sabe dizer se aquilo foi um deslize raro
ou um hábito do juiz. Só uma pessoa lendo as mesmas respostas sabe, e esse é o trabalho das pessoas
numa avaliação: **não avaliar o tráfego, mas fixar o padrão contra o qual o juiz é medido.**

A aritmética decide. Uma chamada ao juiz custa uma fração de centavo e não precisa de ninguém; uma
pessoa tem de ler a pergunta, a resposta e todas as fontes antes de decidir, e esse tempo sai do dia
de trabalho de alguém. Pessoas não conseguem avaliar uma semana. Conseguem avaliar sessenta respostas
com cuidado, e essas sessenta dizem até onde se pode confiar no juiz que avalia a semana.

Três coisas saem de uma rodada de rotulagem humana, e cada uma é usada mais adiante no curso:

- **Uma medida do juiz.** Com que frequência o judge-1 concorda com as pessoas, e em que tipos de
  resposta não concorda. É a última seção desta aula.
- **Rótulos de referência.** Respostas com um veredicto combinado, guardadas por id, contra as quais
  toda versão seguinte do juiz, do prompt ou do modelo é conferida. A aula 13 monta um conjunto de
  avaliação com elas.
- **Uma rubrica melhor.** Pessoas que discordam acharam uma pergunta que a rubrica não respondia.
  Escrever a resposta é a coisa mais útil que uma rodada de rotulagem produz, e as próximas seções
  mostram isso acontecendo.

## Quais respostas as pessoas leem

As três amostras da aula 9 valem, com os números trocados. Uma amostra **uniforme** quando os rótulos
vão medir o juiz, para que a medida seja do juiz no tráfego comum. Uma **dirigida**, polegares para
baixo e recusas, quando o objetivo é achar falhas para corrigir. Nunca as duas misturadas numa nota.

Esta aula não usa nenhuma das duas, por uma razão que importa mais do que o método. As pessoas rotulam
**as respostas do conjunto de avaliação**: as trinta perguntas da aula 8, respondidas uma vez por cada
versão, sessenta respostas ao todo. Uma pergunta do conjunto tem um id que não muda, então um rótulo
escrito hoje ainda nomeia a mesma resposta depois que o prompt, o modelo ou o juiz mudaram. Um rótulo
num trace da terça passada nomeia uma conversa que nunca mais vai acontecer.

Os rótulos desta aula, e as duas pessoas que os escreveram, são escritos pelo curso. A Ana é a
desenvolvedora de todas as aulas até aqui; o Bruno trabalha na equipe de atendimento da loja. Aquilo
em que eles discordam foi escolhido para mostrar o que dois leitores cuidadosos de uma rubrica vaga
fazem, e os números que vêm a seguir são calculados dos rótulos deles exatamente como seriam de
rótulos reais.

## O que as pessoas veem

Uma pessoa avaliando uma resposta vê o que o juiz vê: a pergunta, a resposta e as fontes. As
plataformas da aula 6 chamam isso de **fila de anotação** (*annotation queue*): o Langfuse e o
LangSmith guardam uma lista de traces para pessoas avaliarem, com os veredictos guardados como notas
(*scores*) no trace. As regras da aula 2 valem para as pessoas como valem para o juiz. Elas leem o que
um cliente digitou, então leem com os dados pessoais removidos, e só o quanto a avaliação precisa.
