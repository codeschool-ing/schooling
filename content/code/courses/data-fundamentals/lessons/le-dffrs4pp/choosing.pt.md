---
title: Quando um fluxo compensa o que custa
version: 1
---

**O lote é o padrão, e um fluxo precisa conquistar o seu lugar com uma resposta que perde o valor em
minutos.** "Dá para ter isso em tempo real?" é um dos pedidos mais comuns que uma equipe de dados ouve, e
"tempo real" ali costuma querer dizer "mais fresco do que é hoje". Mais fresco do que hoje muitas vezes é
um job em lote que roda a cada hora em vez de toda noite.

O teste é o que alguém *faz* com a resposta, e em quanto tempo:

| pergunta na Roda Livre | o que se faz com ela | quão fresca | formato |
|---|---|---|---|
| quais estações vão ficar vazias na próxima meia hora | uma van leva bicicletas antes que a estação esvazie | minutos | fluxo |
| este cartão foi usado em quatro estações em dez minutos | a viagem é bloqueada enquanto ainda dá para bloquear | segundos | fluxo |
| viagens por estação na semana passada | Marta planeja as rotas das vans da semana seguinte | um dia | lote |
| receita por mês | o relatório financeiro | dias | lote |
| viagens de hoje até agora, na tela do escritório | as pessoas olham | uma hora serve | lote, a cada hora |

A última linha é a que merece atenção. Um número numa tela que todo mundo olha e ninguém usa para agir
quer ser ao vivo e raramente precisa ser. Um fluxo construído para ele custa tudo o que esta aula mostrou.
Há um processo que nunca para e precisa ser vigiado de noite, uma marca d'água que alguém precisa
escolher e uma decisão sobre dados atrasados. Há um estado que precisa sobreviver a uma queda, e
duplicatas a tornar inofensivas. Um job em lote a cada hora não paga nada disso, e os seus números podem
ser conferidos contra a fonte do jeito que a aula 7 fez.

## Entre os dois

Dois caminhos do meio merecem ser reconhecidos pelo nome:

- um **microlote** (*micro-batch*) roda um pequeno job em lote a cada poucos segundos ou minutos sobre o
  que chegou desde a execução anterior. O Spark Structured Streaming funciona assim por padrão, e é como
  muitas equipes conseguem o frescor de um fluxo com a simplicidade de um job em lote;
- a **captura de mudanças** (*change data capture*), da aula 4, transforma um banco de dados num fluxo
  das suas alterações, que muitas vezes é o primeiro fluxo que uma empresa tem, e é lido por um
  consumidor igualzinho ao desta aula.

## Quatro perguntas antes de construir um fluxo

1. Que decisão a resposta alimenta, e quanto tempo essa decisão pode esperar?
2. O que deve acontecer com um evento que chega atrasado, e quão atrasados os eventos podem chegar? As
   perguntas da aula 4 ao dono de uma fonte valem aqui, com as quedas desta aula em mente.
3. O que acontece se um evento for processado duas vezes? Se a resposta for "um número fica errado", as
   escritas precisam ser idempotentes antes de qualquer outra coisa ser construída.
4. Quem é acordado quando ele para, e a resposta vale isso?

Se a primeira resposta for "um dia", as outras três não precisam de resposta. O resto da trilha `data`
constrói pipelines em lote por esse motivo. `streaming`, na trilha Data Platform, é o curso para os casos
em que a primeira resposta é um número de segundos.
