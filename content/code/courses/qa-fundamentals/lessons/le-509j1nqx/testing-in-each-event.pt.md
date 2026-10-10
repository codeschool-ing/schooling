---
title: O teste em cada evento
version: 1
---

**Os eventos do Scrum são onde o time conversa, e cada um tem um momento em que o conhecimento de teste muda
o resultado.** Quem testa e os trata como reuniões a aguentar perde a maior parte do valor deles; quem sabe o
que levar a cada um faz uma boa parte do trabalho ali.

## Planejamento da sprint: perguntas antes de compromissos

O planejamento é onde o time decide o que consegue terminar. É também o momento mais barato da sprint inteira
para descobrir que uma história não foi entendida, e o trabalho de quem testa é fazer isso acontecer em voz
alta:

- **fazer as quatro perguntas da aula 2** a toda história: quem, fazendo o quê, em que condições, quanto
  basta;
- **perguntar como vai ser testada**, e deixar a resposta mudar a estimativa. "Meia de quarta para
  estudantes" parece pequeno até alguém perceber que muda todo caso de preço;
- **nomear as combinações**, o hábito da aula 6: o que acontece quando esta história encontra as que já foram
  construídas?

No planejamento do Cine Aurora para a funcionalidade de cupons, a Lia perguntou se um cupom se combina com o
desconto de quarta. Ninguém sabia. A história foi dividida: cupons sozinhos nesta sprint, a combinação na
próxima, depois de a Joana decidir. Essa única pergunta valeu mais que um dia de teste.

## Daily scrum: mantendo o teste visível

Quinze minutos é pouco, e o teste é fácil de deixar de fora. O hábito que vale a pena ter é dizer o que está
esperando teste e o que o teste achou, para "código pronto" não ser relatado como "pronto". Quando três
histórias estão esperando a Lia no dia sete, a daily é onde o time percebe a minicascata se formando e faz
algo a respeito, por exemplo o Rafael testando uma delas.

## Revisão da sprint: o produto encontra seus usuários

A revisão é o evento mais parecido com o teste de aceitação da aula 9, e acontece a cada sprint. A Célia
participa das revisões do Cine Aurora, e as reações dela são informação que nenhum teste produz: *"no balcão a
gente nunca digitaria o dia com três letras"* disse ao time mais sobre a entrada `Wed` da aula 6 do que
qualquer teste tinha dito. Nos quadrantes da aula 11, a revisão é Q3, e quem testa pode ajudá-la a ser um
preparando um passeio curto pelo que mudou e pelo que ainda é incerto.

## Retrospectiva: defeitos como evidência sobre o processo

A retrospectiva é onde a prevenção da aula 1 acontece no Scrum. Todo defeito que escapou, ou quase escapou,
durante a sprint é evidência sobre como o time trabalha, e a pergunta é a da aula 2: **por que isso foi
possível?** Na retrospectiva do Cine Aurora depois do domingo das 9:30, a resposta foi "ninguém perguntou quem
digita os horários das sessões", e a ação foi uma linha na lista do planejamento: para toda entrada nova,
perguntar de onde ela vem. A aula 18 dá à retrospectiva um método para achar causas, e não culpados.

## Refinamento do backlog

Não é um dos cinco eventos, mas é uma prática que quase todo time Scrum tem: uma ou duas horas em cada sprint
para olhar adiante as histórias que vêm. Para quem testa é a melhor hora da sprint, porque é prevenção no seu
estado mais barato. Uma história refinada com quem testa na sala chega ao planejamento com as ambiguidades já
achadas.
