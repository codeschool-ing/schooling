---
title: Para que servem as pessoas
version: 2
---

A aula 9 terminou com um juiz que reprovou toda recusa que viu, as certas também, e reprovou respostas
que claramente respondiam à pergunta. Nada medido até aqui diz quanto se pode confiar nos números dele.
Só uma pessoa lendo as mesmas respostas consegue, e esse é o trabalho das pessoas numa avaliação:
**não avaliar o tráfego, mas fixar o padrão contra o qual o juiz é medido.**

A aritmética decide. Uma chamada ao juiz custa uma fração de centavo e não precisa de ninguém; uma
pessoa precisa ler a pergunta, a resposta e cada fonte antes de decidir, e esse tempo sai do dia de
trabalho de alguém. Pessoas não conseguem avaliar uma semana. Conseguem avaliar algumas dezenas de
respostas com cuidado, e elas dizem quanto se pode confiar no juiz que avalia a semana.

Três coisas saem de uma rodada de rotulagem humana, e cada uma é usada mais adiante no curso:

- **Uma medida do juiz.** Com que frequência o juiz concorda com as pessoas, e em que tipos de
  resposta não concorda. É a última seção desta aula.
- **Rótulos de referência.** Respostas com um veredicto acordado, guardadas por id, contra as quais
  toda versão futura do juiz, do prompt ou do modelo é conferida. A aula 13 constrói um conjunto de
  avaliação a partir delas.
- **Uma rubrica melhor.** Pessoas que discordam acharam uma pergunta que a rubrica não respondia.
  Escrever a resposta é a coisa mais útil que uma rodada de rotulagem produz, e as próximas seções
  mostram isso acontecendo.

## Quais respostas as pessoas leem

As três amostras da aula 9 valem, com os números trocados. Uma amostra **uniforme** quando os rótulos
vão medir o juiz, para que a medida seja do juiz no tráfego comum. Uma amostra **dirigida**, polegares
para baixo e recusas, quando o objetivo é achar falhas para consertar. Nunca as duas misturadas numa
nota.

Esta aula não usa nenhuma das duas, por um motivo que importa mais que o método. As pessoas rotulam as
**respostas do conjunto de avaliação**: as vinte e quatro perguntas da aula 8, respondidas uma vez por
cada versão, quarenta e oito respostas ao todo. Uma pergunta do conjunto tem um id que não muda, então
um rótulo escrito hoje ainda nomeia a mesma resposta depois que o prompt, o modelo ou o juiz mudaram.
Um rótulo num trace da terça passada nomeia uma conversa que nunca mais vai acontecer.

Os rótulos desta aula, e as duas pessoas que os escreveram, são escritos pelo curso, lendo as quarenta
e oito respostas que as suas execuções muito provavelmente vão reproduzir. A Ana é a desenvolvedora de
todas as aulas até aqui; o Bruno trabalha no atendimento da loja. Aquilo em que discordam foi escolhido
para mostrar o que dois leitores cuidadosos de uma rubrica vaga fazem, e os números a seguir são
calculados dos rótulos deles exatamente como seriam de rótulos reais.

## O que as pessoas veem

Uma pessoa avaliando uma resposta vê o que o juiz vê: a pergunta, a resposta e as fontes. As
plataformas da aula 6 chamam isso de **fila de anotação**: o Langfuse e o LangSmith guardam uma lista
de traces para pessoas avaliarem, com os veredictos guardados como notas no trace. As mesmas regras da
aula 2 valem para as pessoas e para o juiz. Elas leem o que um cliente digitou, então leem com a
remoção feita, e só o tanto que a avaliação precisa.
