---
title: Quem testa num time XP
version: 1
---

**Os primeiros livros de XP não tinham ninguém que testasse.** Quem programava escrevia os testes de unidade, o
cliente escrevia os testes de aceitação, e isso deveria bastar. Os times que tentaram acharam a lacuna depressa:
clientes não são treinados para pensar nos casos que ninguém mencionou, e quem testa o próprio código divide os
pontos cegos dele. Lisa Crispin e Tip House escreveram *Testing Extreme Programming* em 2002 exatamente sobre essa
lacuna, e o papel que descreveram é próximo do que este curso vem construindo.

## O que sai das mãos de quem testa

Num time XP, duas coisas que quem testa fazia passam a ser feitas por outra pessoa, e mais cedo.

- **Conferir que o código faz o que quem programou quis.** Os testes automatizados de quem programa, escritos
  antes do código, cobrem isso. Quem testa e passa o dia rodando de novo o que as verificações de unidade já
  provam está perdendo o dia.
- **Rodar a suíte de regressão à mão.** A integração contínua roda todas as verificações várias vezes por dia. As
  velhas semanas de teste de regressão manual da aula 10 não existem.

## O que vem para as mãos de quem testa

O que toma o lugar é o trabalho que mais precisa dos hábitos de quem testa.

**Ajudar o cliente a escrever testes de aceitação.** A Joana sabe quanto um ingresso deve custar; não pensa
naturalmente em 59, 60 e 61, nem num estudante numa quarta. A Lia senta com ela e transforma a regra em exemplos,
que é o trabalho dos critérios de aceitação da aula 12 e, na aula 17, do ATDD. No XP esses exemplos viram testes
do cliente automatizados que rodam em todo build.

**Explorar.** Verificações automatizadas só confirmam o que alguém pensou em escrever. As perguntas que ninguém
escreveu são de quem testa: a idade digitada como palavra, o horário da sessão com um dígito, o pedido de sete
ingressos. Num time XP, explorar é quase tudo o que sobra para uma pessoa fazer, e importa mais, não menos, porque
todo o resto é automatizado.

**Fazer par.** Quem testa também pode fazer par com quem programa. Quando a Lia faz par com o Rafael, ela não
digita o código; faz as perguntas enquanto ele é escrito. Dez minutos disso, ela diz, poupam uma tarde de relatos.

## Integração contínua do lado de quem testa

A integração contínua muda o que uma verificação falhando quer dizer. Antes dela, uma verificação que falhava na
semana três apontava para três semanas de mudanças. Agora aponta para a última hora.

| | antes da IC | com IC |
|---|---|---|
| quando as verificações de regressão rodam | no fim de um ciclo | a cada junção, várias vezes por dia |
| quanto mudou desde que passaram pela última vez | semanas de trabalho | uma mudança |
| quem percebe uma falha | quem testa, depois | quem acabou de juntar, na hora |
| o que um build vermelho quer dizer | "alguém quebrou alguma coisa" | "minha mudança quebrou alguma coisa" |

A regra que faz isso funcionar é a que os times acham mais difícil: **um build vermelho é corrigido antes de
qualquer outra coisa**. Um time que deixa o build vermelho por dias perdeu o que a IC tinha para dar, porque cada
falha nova se esconde atrás da velha. É o parar a linha da aula 13, aplicado a um build.

## O custo de acreditar nas verificações

Um risco cresce num time XP em vez de encolher. Com centenas de verificações automatizadas passando toda hora, o
time começa a ler verde como "funciona". Quer dizer que o código faz o que as verificações dizem. Se as
verificações dizem a coisa certa, se falta um caso, se a funcionalidade deveria existir: nada disso fica verde.
Manter o time honesto sobre essa diferença é parte do trabalho de quem testa em qualquer time, e um time XP é o
que mais precisa disso.
