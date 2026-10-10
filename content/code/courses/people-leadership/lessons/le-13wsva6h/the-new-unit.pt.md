---
title: A unidade do seu trabalho mudou
version: 1
---

A maioria das pessoas que passam a gerenciar engenheiros foi promovida por ser boa engenheira.
**O trabalho em que elas eram boas agora é de outra pessoa**, e aquilo pelo que são medidas é algo
que não conseguem fazer com as próprias mãos. Essa é toda a dificuldade do primeiro ano, e quase
tudo o que dá errado nele vem de medir o trabalho novo com a régua antiga.

Este curso acompanha uma pessoa ao longo desse ano. A **Caju** é fictícia: uma empresa de Belo
Horizonte que vende software de agendamento, lembretes e faturamento para clínicas médicas, com
cerca de noventa engenheiros em onze times. Renata Moura era engenheira sênior do time Agenda, o
dono da marcação de consultas, e há duas semanas virou a gestora de engenharia dele. O time tem
sete engenheiros, uma gerente de produto chamada Helena e um backlog que já estava atrasado quando
chegou às mãos dela. O gestor da Renata é o Otávio, que cuida da engenharia do produto para
clínicas.

## A soma de Grove

Andy Grove, que dirigiu a Intel, resumiu a mudança numa linha em *High Output Management* (1983).
Com o pronome tornado neutro, ela diz:

> A entrega de quem gerencia = a entrega da sua organização + a entrega das organizações vizinhas
> sob a sua influência.

Lida como definição, é quase banal. Lida como instrução, ela reorganiza uma semana. **Nada do que a
Renata produz sozinha entra nessa soma, a não ser que mude o que o time produz.** Um pull request
que ela faz merge conta uma vez. Uma hora gasta desbloqueando a Paula, que depois entrega por três
dias sem esperar ninguém, conta três dias. Uma contratação acertada conta por anos, e uma errada
custa mais ou menos o mesmo tempo.

O segundo termo pesa tanto quanto o primeiro. O Agenda depende do time de Pagamentos para tudo o que
cobra uma clínica, e do time de plataforma para os deploys. Quando a Renata convence Pagamentos a
expor um endpoint um trimestre antes do previsto, a entrega do time dela sobe sem ninguém trabalhar
mais. Isso também é trabalho de gestão, e é invisível para quem conta commits.

## Como isso é por dentro

A soma explica uma sensação que quase toda pessoa recém-promovida relata e pouca gente espera. **No
fim de um dia cheio, não há nada para mostrar.** Nenhum branch integrado, nenhum ticket fechado,
nenhum build verde que seja seu. A primeira sexta-feira da Renata foi em quatro 1:1, uma sessão de
planejamento, uma conversa com Pagamentos sobre aquele endpoint e quarenta minutos lendo o desafio
de casa de uma candidata. Ela foi para casa achando que não tinha feito nada e, pela soma de Grove,
tinha feito uma semana razoável de trabalho.

A sensação tem uma consequência previsível. Quem se sente improdutivo volta ao trabalho que antes o
fazia se sentir produtivo, que é escrever código. A Renata pegou um ticket na segunda segunda-feira,
porque era pequeno e ninguém estava livre. Na quarta, duas pessoas esperavam decisões que só ela
podia tomar, e o ticket continuava aberto, porque ela passou em reuniões a maior parte do tempo que
pretendia dedicar a ele.

Nada disso torna o código errado para quem gerencia. A aula 2 trata dos dois formatos que esse papel
assume, e num deles escrever código faz parte do trabalho. O ponto aqui é mais estreito: **o código
deixou de ser o que mede você**, então ele é uma escolha feita por um motivo, e "é a única parte do
meu dia que parece trabalho" é um motivo que deixa o time mais lento.

## Três coisas que se movem

Ajuda nomear exatamente o que muda, porque cada uma das três tem a sua aula mais adiante.

- **A sua alavanca.** Suas horas viravam entrega na proporção de um para um. Agora uma hora pode
  virar nada, ou uma semana de progresso de outra pessoa. As aulas 3 e 4 tratam de gastá-la onde ela
  multiplica: delegar resultados e decidir quanta liberdade vai junto.
- **A sua informação.** Você sabia o estado do código porque estava nele. Agora sabe o que as pessoas
  contam, e elas contam menos à gestora do que contavam a uma colega. As aulas 5 a 7 tratam da
  reunião que corrige isso.
- **O seu efeito sobre as pessoas.** A opinião de um colega sobre o trabalho de alguém é uma opinião.
  A sua agora entra no salário, na promoção e, no pior caso, no emprego dessa pessoa. Tudo a partir
  da aula 8 depende de carregar esse peso com honestidade.

## A régua do trabalho novo

Se commits são a medida errada, qual é a certa? A resposta de Grove é a entrega do time, e num time
de software isso quer dizer o que chega aos usuários e com que confiabilidade chega. Um time que
entrega o que disse que entregaria, mantém o serviço no ar e mantém as suas pessoas é um time cuja
gestora está fazendo o trabalho — seja lá quem escreveu o código.

A dificuldade é o atraso. **As decisões de quem gerencia levam semanas ou meses para aparecer nessa
entrega**, que é o assunto da próxima seção, e é por isso que os primeiros meses parecem um voo com
instrumentos que respondem tarde.
