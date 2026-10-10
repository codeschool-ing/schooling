---
title: Mantendo o hábito
version: 1
---

Ninguém decide parar de programar. **Isso para uma tarde cancelada de cada vez**, porque toda outra
demanda da semana de um arquiteto tem uma pessoa por trás e o código não tem. Esta seção é sobre
manter o hábito de propósito: proteger o tempo, escolher o trabalho, ser revisado como todo mundo, e
perceber os sinais de que a calibragem da primeira seção desregulou.

## Proteja o tempo, ou ele some

As duas meias jornadas por semana de Renata não sobreviveram ao primeiro mês no cargo. Cada uma era
o horário óbvio para uma reunião de que outra pessoa precisava, e cada reunião era mais urgente do
que uma correção por que ninguém esperava. No fim do segundo mês, ela não tinha escrito código
nenhum.

O que funcionou foi tratar o tempo como um compromisso com nome. Ela bloqueou as manhãs de terça e
quinta na agenda, como "Pareamento com Payments" e "Ferramentas de Platform", contou a quem marca o
tempo dela para que elas serviam, e passou a remarcá-las em vez de apagá-las quando algo urgente de
fato aparecia. **Duas manhãs, umas oito horas, são um quinto de uma semana de trabalho**, e isso
basta. O objetivo é calibragem, não produção: um quinto de semana mantido toda semana faz mais do
que uma semana inteira uma vez por trimestre, porque o instrumento desregula entre as leituras.

Uma empresa pequena pode facilitar ainda mais. Alguns arquitetos do tamanho da Carreto passam um
sprint em cada quatro dentro de um time, como membros, com o tech lead do time no comando do
trabalho deles. Outros mantêm as meias jornadas semanais e acrescentam uma semana dentro de um time
sempre que começa uma mudança grande. A forma importa menos que a regularidade.

## Escolha um trabalho que você consiga terminar

A regra da seção anterior decide o que pegar: trabalho útil, pelo qual ninguém espera, e que caiba
em duas meias jornadas por semana. Na prática, Renata mantém uma lista curta, combinada com os tech
leads:

- uma **correção pequena** de cada vez, do backlog de um time, escolhida com esse time;
- as **funções de fitness e ferramentas** de que ela é dona, que sempre têm algo a melhorar;
- um **spike ou um esqueleto** quando um desenho dela está para ser construído;
- um **horário fixo de pareamento** que gira entre os times, algumas semanas com cada um.

**Terminar faz parte do objetivo.** Uma mudança que chega à produção passa pelos testes, pela
revisão, pelo pipeline e pelo monitoramento, e cada um deles é parte do custo de um desenho. Um
branch abandonado depois de três semanas ensina a primeira meia jornada e nada depois dela.

## Seja revisado como todo mundo

O código de um arquiteto passa pela revisão do time, segue os padrões do time e pode ser recusado.
É fácil de dizer e fácil de errar nas duas direções. Um time que aprova os pull requests do
arquiteto sem olhar não está revisando; um arquiteto que discute cada comentário com a autoridade
do cargo transformou a revisão numa prova de hierarquia.

O terceiro pull request de Renata em Payments foi revisado por Ícaro. Ele pediu que ela renomeasse
duas funções para seguir as convenções do módulo e apontou que ela tinha acrescentado um teste com
um sleep, coisa que o time tinha combinado parar de fazer um ano antes. Os dois pedidos estavam
certos. Ela corrigiu, e disse isso na conversa da revisão.

**Essa troca fez mais pelo time do que o código dela.** Ícaro viu que a revisão é sobre o código e
não sobre a pessoa, e que ela vale de baixo para cima. O time viu que as convenções que escreveu
valem para a arquiteta também. E Renata ficou sabendo de um acordo do time que nenhum documento
registrava, o que é calibragem de outro tipo: saber como o time trabalha, não só como o código
funciona.

## Os sinais de desregulagem

A calibragem falha em silêncio, então ajuda saber como a desregulagem aparece de fora. Estes são os
sinais que Renata mantém no topo das suas notas, como perguntas para se fazer uma vez por mês:

- **Consigo rodar o sistema na minha máquina hoje?** Não em teoria — hoje, a partir de um checkout
  limpo. Se o ambiente local seguiu em frente sem ela, o código também seguiu.
- **Sei quanto tempo levam o build e os testes?** Se a resposta é um número do ano passado,
  provavelmente está errada, e todo desenho precificado com ela está com o preço errado.
- **A minha estimativa está perto da do time?** Um time que diz sistematicamente o dobro ou o triplo
  do que o arquiteto diz está ou pondo gordura ou calibrado. A aula 14 mostrou como descobrir qual
  dos dois: pergunte o que faria levar tanto tempo.
- **Os meus comentários de revisão são sobre desenho, ou só sobre estilo?** Comentários sobre nomes
  e formatação são o que sobra quando quem revisa já não entende o que a mudança faz com o sistema.
- **Quando foi a última vez que eu pus algo em produção?** Um mês está bem. Um trimestre é um
  alerta. Um ano é o arquiteto da aula 17, que desenha caixas que ninguém constrói.

Nenhuma das cinco precisa de métrica ou de painel. São perguntas para dez minutos honestos, e a
resposta para a maioria delas é "vá mudar alguma coisa pequena esta semana".

## O que muda com a senioridade, e o que não muda

À medida que a Carreto cresce, Renata vai programar menos. Uma arquiteta que atende quinze times não
consegue parear com cada um num rodízio que volte antes que a calibragem se perca, e o papel vai se
inclinar mais para o nível corporativo da aula 4. Isso é esperado, e não é um fracasso.

O que não deve mudar é que a quantidade continue acima de zero, e que continue no código sobre o
qual são as decisões. **Um arquiteto que programa um pouco no sistema real continua calibrado; um
que programa muito em projetos paralelos, não.** Um projeto de fim de semana numa linguagem nova faz
bem à curiosidade do arquiteto, e não diz nada sobre quanto tempo a suíte de testes de Payments leva
este mês.

O hábito também dura mais que o papel. Os engenheiros que aprendem com um arquiteto que pareia,
aceita comentários de revisão e corrige bugs pequenos estão aprendendo que senioridade não quer dizer
sair do código, e alguns deles vão ser arquitetos. A aula 16 traça as fronteiras entre o arquiteto, o
tech lead e o engenheiro sênior. O argumento desta aula é que manter a mão no código é uma das coisas
que os três têm em comum.
