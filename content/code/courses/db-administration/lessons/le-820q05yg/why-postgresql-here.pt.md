---
title: Por que este curso tem o formato do PostgreSQL
version: 1
---

Toda lição daqui em diante é escrita sobre o PostgreSQL 16, e isso é uma escolha com motivos, não
uma preferência.

**Dá para ser dono de tudo.** O PostgreSQL é gratuito, com uma licença que deixa qualquer um rodar,
mudar e distribuir, e o Ubuntu o instala com um comando. O curso precisa de um servidor que você
possa instalar, configurar, encher, quebrar e atualizar no seu próprio computador, e dos quatro só o
PostgreSQL e o MySQL permitem isso sem uma conversa sobre licença. O SQL Server tem uma edição
Developer gratuita e o Oracle uma edição gratuita com limites, e os dois são uma coisa mais pesada
para pôr numa máquina de prática.

**Ele mostra como chegou lá.** Todo ajuste é uma linha num arquivo que você lê, toda estatística é
uma view que você consulta, e o log diz o que o servidor está fazendo em frases simples. Muito do que
um motor comercial esconde atrás de um painel o PostgreSQL deixa na sua frente, que é exatamente do
que precisa quem está aprendendo o ofício.

**É para onde o trabalho está indo.** Aplicações novas, os serviços gerenciados dos provedores de
nuvem e as migrações para fora de motores comerciais foram todos em direção ao PostgreSQL na última
década, e o MySQL é a outra escolha comum. Um DBA que conhece bem o PostgreSQL é empregável, e a
lição 21 é sobre o motivo mais comum para uma empresa chamar um: mover um banco para ele.

**E ele é rigoroso.** O PostgreSQL não compara um número com um texto convertendo um dos dois em
silêncio, e não converte um valor para outro tipo a não ser que se peça. O MySQL, em comparação,
decide que `'1abc' = 1` é verdadeiro e registra um aviso que ninguém lê. Para um administrador esse
rigor é uma qualidade: o que o servidor aceitou é o que ele guardou.

## O que muda quando o motor não é o PostgreSQL

As ideias deste curso valem para os outros, e a tabela da primeira seção é o mapa. Quando o assunto
de uma lição é um em que outro motor é notoriamente diferente, ela diz isso numa frase: o MySQL para
conexões e replicação, o SQL Server para o log, o Oracle para o undo. Quando a lição é sobre um
mecanismo só do PostgreSQL — o vacuum, o arquivo `pg_hba.conf`, os clusters do postgresql-common —, ela
também diz, para você saber o que não procurar em outro lugar.

As lições 1 e 2 não pedem que você digite nada. **A lição 3 monta o seu servidor**, e daí em diante
toda transcrição do curso é algo que você pode rodar e comparar.
