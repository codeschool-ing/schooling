---
title: Calibragem, ou saber quanto custa construir um desenho
version: 1
---

Duas imagens do arquiteto diante do código são comuns, e as duas estão erradas. Na primeira, o
arquiteto já passou do código: o tempo dele vale demais para isso, e programar seria um passo para
trás. Na segunda, o arquiteto é o melhor programador do prédio e pega pessoalmente as
funcionalidades mais difíceis. **O motivo para um arquiteto continuar programando não é status nem
heroísmo. É calibragem**: continuar em contato com quanto custa construir um desenho, para que o
próximo desenho tenha o preço certo.

## O que calibragem quer dizer

Um instrumento está calibrado quando as leituras dele batem com a realidade. Um arquiteto é uma
espécie de instrumento. Cada desenho que ele propõe carrega uma leitura implícita de quanto trabalho
dá, de quanto vai doer para operar e de quão difícil vai ser mudar. Essas leituras vêm da
experiência com o sistema real, e **a experiência se desgasta quando para de ser renovada**. O
código muda, o build muda, as bibliotecas mudam, e os hábitos do time mudam. Quem abriu o
repositório pela última vez há um ano está lendo um instrumento que desregulou enquanto ninguém
olhava.

A desregulagem não se sente. Ninguém percebe a própria noção de "isso é trabalho de duas semanas"
ficando menos precisa. Ela só aparece quando um desenho encontra as pessoas que vão construí-lo, e
aí é o tempo delas que paga o erro.

## A tarde de Renata

Seis meses depois de assumir o cargo, Renata propôs uma mudança no jeito como Payments registra um
pagamento. Em vez de gravar o lançamento no razão e chamar o banco na mesma requisição, Payments
gravaria o lançamento e uma mensagem numa única transação, e um worker separado leria as mensagens
e chamaria o banco. É um padrão conhecido, o transactional outbox, uma das respostas ao problema de
entrega garantida da aula 7 de `architecture`, e ela estimou duas semanas.

O time do Bruno disse seis. Renata achou que eles estavam sendo cautelosos e se ofereceu para
parear com Ícaro por uma tarde na primeira parte, para mostrar como era pequeno.

A tarde não foi como ela esperava:

- a suíte de testes do monólito agora levava **41 minutos**, contra os 12 de que ela se lembrava,
  e falhou duas vezes num teste sem relação com a mudança deles;
- o código de pagamentos tinha passado para uma versão mais nova do framework web, cujo tratamento
  de transações ela nunca tinha usado, e a "transação única" levou uma hora de leitura para sair
  certa;
- fazer o deploy do worker exigia uma entrada nova na configuração de deploy de Platform, que
  precisava de revisão do time da Paula, que se reunia às quintas.

Uma mudança que ela teria chamado de trabalho de uma hora no último ano como engenheira tomou quase
o dia inteiro e não chegou à produção naquela semana. **As seis semanas do time não eram cautela.
Estavam calibradas, e as duas dela não.** Ela refez a estimativa e, o que foi mais útil, pôs a suíte
de 41 minutos no registro de riscos da proposta seguinte, porque ela multiplica o custo de toda
mudança que qualquer pessoa desenhe.

Nada no desenho dela estava errado. Estava com o preço errado, e um desenho com o preço errado está
errado de um jeito mais lento: é aprovado contra um custo que não vai cumprir, e a diferença é paga
por um time que não o escolheu.

## O que o código diz e o diagrama não

A aula 2 descreveu o slide que discorda do código. Um arquiteto que não lê nem escreve código não
tem como notar a discordância, porque o slide é tudo o que ele vê. Três coisas só são visíveis de
dentro do código:

- **As dependências reais.** O diagrama mostra Payments chamando o Tracking por uma API. O código
  mostra que Payments também lê uma tabela do Tracking diretamente, um acesso adicionado durante um
  incidente dois anos atrás, e é por isso que uma mudança de esquema no Tracking quebrou os
  pagamentos na primavera passada.
- **O custo do ciclo comum.** Quanto tempo leva fazer uma mudança, rodar os testes, conseguir uma
  revisão e fazer o deploy. Um desenho que exige cinco deploys coordenados é barato onde um deploy
  leva dez minutos e caro onde leva um dia.
- **Para onde vai a atenção do time.** Os arquivos que todo mundo mexe toda semana, o módulo que
  ninguém ousa mudar, o contorno com um comentário dizendo "temporário" desde 2019.

**Nada disso aparece numa revisão de desenho.** Aparece quando você tenta mudar alguma coisa, e por
isso o instrumento se mantém calibrado mudando coisas.

## Os dois arquitetos de Fowler

Martin Fowler fez esse argumento numa coluna curta da *IEEE Software* em 2003, "Who Needs an
Architect?". Ele contrastou duas espécies, com nomes em latim de brincadeira. O *Architectus
reloadus* é a pessoa que toma todas as decisões importantes, sob o argumento de que os
desenvolvedores não têm experiência para tomá-las. O *Architectus oryzus* é quem se mantém atento ao
que acontece no projeto, identifica as questões importantes e cuida delas antes que fiquem sérias —
e cuja atividade mais importante, no relato de Fowler, é orientar os desenvolvedores para que eles
mesmos deem conta de mais coisas.

O detalhe que importa para esta aula é como Fowler imagina o segundo tipo trabalhando: programando
com um desenvolvedor de manhã e participando de uma sessão de requisitos à tarde. A colaboração é o
trabalho, e programar é parte do que mantém a colaboração honesta. Um arquiteto que decide tudo de
fora do código é *reloadus* por padrão, por mais colaborativo que pretenda ser, porque não tem com o
que colaborar.

O livro *The Software Architect Elevator* (2020), de Gregor Hohpe, dá à mesma ideia um prédio. O
arquiteto anda de elevador entre a cobertura, onde se discutem estratégia e orçamento, e a casa de
máquinas, onde os sistemas rodam. O valor está na viagem: levar o que a casa de máquinas sabe até
quem decide, e trazer as decisões para baixo numa forma que a casa de máquinas consiga usar. **Um
arquiteto que fica na cobertura não tem nada para levar para cima.**

## Calibragem e autoridade

A aula 3 separou a autoridade formal, o cargo, da autoridade conquistada, o histórico. A calibragem
é uma parte grande da segunda. Um time escuta de um jeito o comentário de revisão de quem já sentiu
a suíte de 41 minutos, e de outro o de quem não sentiu, e tem razão: o primeiro comentário vem de
uma leitura do sistema, o segundo de uma leitura de um diagrama.

O contrário é igualmente visível. A estimativa original de duas semanas de Renata não era segredo.
Todos os engenheiros de Payments a ouviram e, se ela a tivesse defendido em vez de parear, eles
teriam descontado em silêncio a proposta seguinte dela também. **Errar diante do time e corrigir a
partir do código custou a ela uma tarde e comprou mais credibilidade do que a estimativa certa
teria comprado.**

Nada disso pede que um arquiteto seja o melhor programador de algum time, nem que esteja em dia com
cada biblioteca. Pede que ele fique perto o bastante do trabalho para que a sua noção do custo
continue batendo com a do time. A próxima seção é sobre qual código faz isso sem atrapalhar ninguém.
