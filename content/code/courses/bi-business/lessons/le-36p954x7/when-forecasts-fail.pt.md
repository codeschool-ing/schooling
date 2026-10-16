---
title: Quando as previsões falham
version: 1
---

O único erro grande do teste veio de um evento que o histórico não continha. **Toda previsão feita a
partir do passado supõe que o futuro funciona como o passado**, e os lugares em que essa suposição
quebra são previsíveis mesmo quando os números não são. O trabalho de um analista de BI é conhecê-los
e dizer isso ao lado da previsão.

## Algo sem histórico

Um método que copia o mês do ano anterior precisa de um ano anterior. A Varanda não tem o que copiar
para:

- uma loja nova, que não tem um outubro de 2024 para repetir. O contorno comum é pegar emprestado o
  desenho de uma loja parecida e ajustar a escala, o que é uma suposição e precisa ser escrito como
  tal;
- uma linha de produtos nova, como uma linha de cozinha externa lançada em março, cujos primeiros
  meses refletem o lançamento, a vitrine e a novidade, e dizem pouco sobre o oitavo mês;
- um canal novo, em que as taxas de crescimento do começo são enormes e caem rápido, então o ritmo do
  primeiro semestre quase não diz nada sobre o segundo.

Em cada caso a previsão é um palpite vestido de método. Isso não a torna inútil, mas a faixa dela
precisa ser muito mais larga que 2,3%, e a nota ao lado precisa dizer por quê.

## Uma quebra no padrão

Às vezes o passado deixa de descrever o futuro para todo mundo ao mesmo tempo. Uma pandemia, uma
enchente que fecha uma estrada, um imposto novo, um concorrente abrindo do outro lado da rua: depois
de qualquer um deles, os meses do ano passado descrevem um mundo que não existe mais. **O sinal de uma
quebra é um teste que piora de repente**: erros que eram de 2% viram 10%, todos para o mesmo lado.
Quando isso acontece, a resposta certa é dizer que o método parou de funcionar, e não continuar
publicando o resultado dele com a faixa antiga.

## Uma previsão que muda o que prevê

A falha mais sutil é uma previsão sobre a qual as pessoas agem, de modo que a ação muda o resultado.
O Caio Barreto, diretor de operações, pede o estoque do departamento de jardim a partir da previsão
de vendas. Suponha que a previsão de um carretel de mangueira novo seja baixa. O Caio pede pouco, a
prateleira esvazia no meio do mês, clientes que queriam um saem sem ele, e as vendas do mês fecham
baixas. **A previsão agora parece certa, e foi ela que causou o número que previu.** Dados de venda
registram o que foi vendido, não o que foi procurado, então as vendas perdidas não aparecem em lugar
nenhum. A aula 18 volta às rupturas de estoque como as vendas que nunca aparecem nos dados.

A defesa é conferir a previsão contra algo que ela não poderia ter influenciado: os dias em que o
produto estava em estoque, as visitas à página dele no site, ou os pedidos que não puderam ser
atendidos.

## Quem constrói os modelos mais ricos

Tudo nesta aula cabe numa planilha, de propósito. Um cientista de dados vai além: modelos que usam o
clima, os preços, as promoções e o calendário juntos, ou que preveem milhares de produtos de uma vez.
A aula 19 de `statistics` apresenta a regressão da qual esses modelos partem, e o curso de
`machine-learning` os constrói. **Cada um deles continua sendo julgado como esta aula julgou três
fórmulas**: um teste com meses que ele não viu, os erros, o viés e a comparação com a linha de base
que ele precisa superar. Um analista que sabe pedir essas quatro coisas consegue revisar qualquer
previsão que lhe entreguem, seja como for que ela tenha sido feita.
