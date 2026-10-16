---
title: O que o MapReduce tornou difícil
version: 1
---

**O MapReduce resolveu o problema para o qual foi feito: uma passada sobre um arquivo muito grande,
em máquinas que falham, escrita por quem nunca tinha escrito código distribuído.** Ele não foi feito
para o que as pessoas passaram a pedir dele, e quatro limites as levaram a substituí-lo.

**Toda pergunta de vários passos são vários jobs.** Um join seguido de um agrupamento seguido de uma
ordenação são três jobs, cada um com o próprio início, a própria leitura do HDFS e a própria escrita
replicada. Nada os liga a não ser arquivos, então nada consegue otimizar entre eles. Uma ferramenta
para encadear jobs foi a primeira coisa que toda equipe escreveu.

**A iteração é ruinosa.** A conta da seção anterior, aplicada a um algoritmo que roda o mesmo passo
cinquenta vezes: cinquenta leituras da entrada, cinquenta escritas replicadas, cinquenta inícios.

**A latência é de minutos.** Mesmo um job pequeno num cluster de verdade passava a maior parte de um
minuto sendo agendado e iniciando processos. Bom para um lote noturno, inútil para um analista que
faz uma pergunta e espera a resposta.

**Tudo se escreve como um map e um reduce.** Um filtro, um join, um top dez e uma janela no tempo têm
de ser expressos nesses dois formatos, à mão, em Java no caso comum. A intenção do programa some no
encanamento, e com ela qualquer chance de o framework ver que dois passos poderiam ser fundidos ou um
deles pulado.

O que veio depois atacou isso por dois lados. **Linguagens de nível mais alto compiladas em jobs
MapReduce**: o Hive transformava SQL em cadeias deles (aula 12), e o Pig fazia o mesmo para uma
linguagem de script. Eles consertaram a expressividade e mantiveram o custo. **Motores novos
substituíram o modelo por baixo**: o Spark, da Universidade da Califórnia em Berkeley, por volta de
2010, mantinha os dados na memória entre os passos, planejava um programa inteiro de uma vez e o
rodava como uma aplicação. A próxima aula começa ali.
