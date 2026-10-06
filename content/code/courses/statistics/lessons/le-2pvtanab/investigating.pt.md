---
title: Investigando um candidato
version: 1
---

Uma regra produz uma lista. O que transforma a lista em conhecimento é voltar a cada candidato e perguntar
de onde ele veio. É o passo mais pulado, porque é o que não dá para automatizar.

## Perguntas a fazer a cada candidato

**É possível?** Uma entrega de −5 minutos, uma cesta de R$ 0,00 com doze itens, um cliente de 212 anos:
valores impossíveis são erros, ponto. O conselho da aula 5 de olhar a amplitude de uma coluna antes de
qualquer outra coisa pega a maioria deles.

**O registro concorda consigo mesmo?** Uma cesta de R$ 2.126,00 com três itens é suspeita. Uma cesta de
R$ 421,78 com 43 itens não é. As outras colunas da mesma linha são a evidência mais barata que existe.

**A origem concorda?** O recibo original, o registro do pagamento, o log do entregador. Se a operadora de
pagamento cobrou R$ 212,60, os R$ 2.126,00 da tabela são um erro de digitação, e o conserto é corrigir.

**Pertence à população?** O pedido de um restaurante, um teste da equipe, um pedido feito por uma empresa
parceira que revende: registros reais, mas não das casas de que a análise trata.

**Há um padrão?** Vários candidatos do mesmo dia, do mesmo entregador ou da mesma versão do aplicativo
apontam para uma causa comum: um leitor quebrado, o dia de treinamento de um funcionário novo, um defeito
que entrou numa versão. Um padrão costuma ser uma descoberta mais valiosa que qualquer valor atípico.

## A noite de chuva

Os boxplots da aula 6 apontaram uma entrega no Centro: 45,5 minutos, onde a mediana era 30,5. Os registros
da Horta respondem as três primeiras perguntas de uma vez. O pedido tinha catorze itens, era uma noite de
chuva, e o log do entregador mostra o tempo. É possível, coerente e confirmado, e pertence à população das
entregas no Centro. Fica.

Essa resposta também é informação. Se noites de chuva produzem com regularidade entregas como essa, uma
promessa de "30 minutos no Centro" precisa de uma ressalva para a chuva, e a aula 19 pode pôr a chuva num
modelo dos tempos de entrega.

## Quem confere

Quem analisa muitas vezes não consegue conferir as origens: não tem os recibos, nem acesso ao sistema que
os produziu. O passo prático é **mandar a lista para quem é dono dos dados**, com o motivo pelo qual cada
valor foi apontado. "Estas 17 cestas passam de R$ 202; alguma delas é pedido de teste ou de cliente
empresarial?" é uma pergunta que um gerente de vendas responde numa tarde, e que nenhuma regra responde.
