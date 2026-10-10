---
title: A segunda versão da Coreto
version: 1
---

Davi jogou fora a primeira versão e passou uma semana com o registro de incidentes, o histórico de
deploys e os líderes de time — perguntando, desta vez, o que doía em vez do que eles queriam. O que
ele achou não foram seis problemas de mesmo peso. **Era um problema aparecendo em seis lugares.**

## O diagnóstico

O negócio da Coreto se concentra em momentos. Um show disputado abre vendas às 10h de uma terça, e
uma boa parte da receita do mês daquela casa chega na meia hora seguinte. A Coreto faz umas doze
dessas grandes aberturas de vendas por ano, e é nelas que a reputação da empresa se ganha ou se
perde.

Os relatórios de incidente apontavam todos para o mesmo código. Quando um comprador escolhe um
assento, o módulo de reservas do `coreto-core` segura o lugar enquanto ele paga, e faz isso
travando linhas no banco de dados. Sob a carga de uma abertura, as travas fazem fila, o checkout
estoura o tempo, e os compradores veem assentos sumirem e voltarem. Todos os times mexem nesse
módulo — Checkout, Bilheteria, Mobile e Pagamentos têm funcionalidades que tocam numa reserva de
assento —, então ninguém é dono dele, e cada mudança é revisada por quem estiver por perto.

Davi escreveu o diagnóstico em três frases:

> A Coreto ganha sua reputação em umas doze grandes aberturas de vendas por ano, e é exatamente
> nelas que falha. As falhas vêm do código de reserva de assentos no módulo de reservas, que todos
> os times mudam e nenhum time possui. Todo o resto nas listas dos times é real, e nada disso nos
> custa uma casa de shows como uma abertura que falha.

Ele é conferível: o registro de incidentes ou confirma que as falhas nas aberturas vêm das reservas
de assento, ou não confirma. E ele ordena: diz com todas as letras que os outros problemas são
menores.

## A política orientadora

> Proteger a abertura de vendas primeiro. Até que o caminho da reserva de assentos aguente a carga
> de uma abertura, o trabalho nesse caminho vem antes de qualquer outro investimento técnico, e nada
> entra nele sem evidência de um teste de carga.

Pergunte o que isso exclui, e as respostas são concretas. **A migração para microsserviços não
começa este ano** — não porque microsserviços estejam errados, mas porque uma migração na empresa
inteira tiraria a atenção de todos os times do único caminho que importa. O framework de front-end
espera. Um projeto de custo de nuvem pode seguir só se não tocar no caminho de reservas durante a
temporada de aberturas.

## As ações coerentes

1. **Dar um dono ao módulo de reservas.** Quatro engenheiros de Checkout e Pagamentos formam um
   time de Reservas a partir de 1º de março. Mudanças no código de reserva de assentos precisam da
   revisão deles.
2. **Construir o teste de carga antes de mudar o código.** O time de Plataforma constrói um teste
   repetível que reproduz o tráfego de uma abertura, para que toda mudança no caminho possa ser
   medida contra ele.
3. **Pagar a dívida da reserva de assentos.** O time novo passa os dois primeiros trimestres
   tirando as travas de linha do caminho da reserva, medido pelo teste de carga.
4. **Congelar o caminho durante as aberturas.** Nenhum deploy no módulo de reservas nas 24 horas
   antes de uma grande abertura, por regra e não por pedido.

Essas ações se reforçam. O dono torna possível a regra de revisão; o teste de carga torna o
trabalho na dívida mensurável e deixa o congelamento menos necessário com o tempo; o congelamento
compra segurança enquanto o trabalho anda. Tire qualquer uma e as outras funcionam pior. Compare com
a primeira versão, em que tirar a linha 5 não mudaria nada nas linhas 1 a 4.

## O que aconteceu com as metas

Parte da primeira versão sobreviveu, rebaixada de estratégia a consequência. **"Chegar a 99,99% de
disponibilidade" virou um jeito de saber se a estratégia está funcionando**, medido nos dias de
abertura em vez de na média do mês. "Pagar a dívida técnica" virou uma dívida específica com um
time nela. "Migrar para microsserviços" saiu do documento, e Davi escreveu que tinha saído — a aula
3 é sobre essa lista de coisas que uma estratégia não vai fazer, e por que ela pertence à página.

A segunda versão desagradou dois líderes de time, cujos projetos agora esperam um ano. Esse é o
preço de um documento que escolhe, e uma primeira versão que não desagradou ninguém não tinha pago.
