---
title: O que o ajuste fino custa, e a ordem em que tentar as coisas
version: 1
---

O argumento que costuma aparecer a favor do ajuste fino é a conta: um prompt com instruções e
exemplos é longo, vai em todo pedido, e um modelo ajustado não precisaria dele. Essa parte é
verdade, e vale medir antes de acreditar. **A economia por pedido é real e pequena; o custo de
chegar lá é grande e pago adiantado.**

## A economia, medida

O `few-shot.txt` é um prompt para a classificação de mensagens do café. Ele traz a instrução, oito
exemplos e, no fim, a mensagem a classificar:

```
Sort each message from a Café Aurora customer into one category:
hours, allergens, refunds, loyalty, wifi, deliveries or other.
Reply with the category only.

Message: Are you open on Sunday afternoon?
Category: hours

Message: Does the carrot cake have nuts in it?
Category: allergens

Message: My latte was cold and I want my money back.
Category: refunds

Message: I lost my stamp card, can I get a new one?
Category: loyalty

Message: The guest network keeps logging me out.
Category: wifi

Message: Nobody signed for the milk this morning.
Category: deliveries

Message: Do you sell gift vouchers?
Category: other

Message: Is the kitchen still serving at half past five?
Category: hours

Message: Is there oat milk for the flat white?
Category:
```

O `short.txt` é o que um modelo ajustado com essas categorias precisaria: as duas últimas linhas e
mais nada. O `tok` conta os dois, e o `tok cost` põe preço neles. **Os preços na linha de comando
são ilustrativos**, 2,50 por milhão de tokens de entrada e 10,00 por milhão de tokens de saída, e
não são de provedor nenhum. A resposta é uma categoria, contada como 2 tokens de saída:

```
ana@lab:~/pe$ tok count few-shot.txt short.txt
tokens  words  chars  file
   165    121    751  few-shot.txt
    13     10     57  short.txt
ana@lab:~/pe$ tok cost few-shot.txt -o 2 -i 2.50 -p 10.00
input  165 tokens x 2.5 per million = 0.000412
output 2 tokens x 10 per million = 0.000020
one request: 0.000432
10,000 requests: 4.33
ana@lab:~/pe$ tok cost short.txt -o 2 -i 2.50 -p 10.00
input  13 tokens x 2.5 per million = 0.000032
output 2 tokens x 10 per million = 0.000020
one request: 0.000053
10,000 requests: 0.53
ana@lab:~/pe$ awk 'BEGIN { print (4.33 - 0.53) * 1000 }'
3800
```

O prompt curto tem 13 tokens contra 165, e 10.000 pedidos custam 0,53 contra 4,33. Em dez milhões
de pedidos a diferença é 3800 nas mesmas unidades. **Se isso paga o ajuste fino depende do quanto o
ajuste fino custa**. A economia também fica menor que essa se o provedor cobrar mais caro pelo modelo
ajustado do que pelo modelo base, o que é comum o bastante para conferir antes de planejar em cima.

## Os custos que não aparecem na fatura

O preço por token é a parte visível. O resto:

- juntar e rotular os dados: centenas ou milhares de exemplos, cada um conferido por uma pessoa
  que sabe a resposta certa. Em geral é o maior custo, e é tempo de gente;
- rodadas de treinamento: cada rodada é cobrada, e a primeira raramente é a última, porque você
  ajusta os dados e treina de novo;
- avaliação: um conjunto de exemplos separado, com que o modelo nunca treinou, para mostrar que
  ele melhorou e não piorou em outra coisa. Sem isso, você não distingue uma rodada boa de uma ruim;
- hospedagem: um modelo ajustado é ou um endpoint num provedor, cobrado por token e às vezes por
  hora, ou pesos que você mesmo roda, com a conta de memória da lição 8;
- fazer tudo de novo: um modelo ajustado fica preso ao modelo base de onde partiu. Quando o
  provedor aposenta essa base, ou aparece uma melhor, os dados, o treinamento e a avaliação se
  repetem na nova.

Um prompt não tem nada disso. É um arquivo de texto, muda em um minuto e passa para um modelo novo
sendo enviado a ele.

## A escada

Então a ordem em que tentar as coisas vai do mais barato ao mais caro, e você só sobe um degrau
depois de tentar e medir o de baixo:

| degrau | o que muda | lição |
|---|---|---|
| 1. escrever um prompt mais claro | a instrução: o quê, para quem, em que formato | 2, 20 |
| 2. acrescentar exemplos | alguns casos resolvidos no prompt | 21 |
| 3. acrescentar recuperação | os fatos de que a resposta precisa, buscados a cada pergunta | 11 |
| 4. ajuste fino | os pesos, a partir de centenas de exemplos rotulados | esta |

A maior parte dos problemas para no primeiro ou no segundo degrau. A recuperação é a resposta quando
o problema é conhecimento: o modelo não conhece o seu manual, e nenhuma redação conserta isso. **O
ajuste fino é para um comportamento que já funciona com um prompt longo e precisa ficar mais
barato, mais rápido ou mais consistente em grande volume.**

## Decidindo

| o problema | tente primeiro |
|---|---|
| as respostas vêm no formato ou no tom errado | um prompt mais claro, depois exemplos |
| ele não conhece os seus produtos, preços ou políticas | recuperação |
| os seus preços ou horários mudam todo mês | recuperação, nunca ajuste fino |
| o prompt funciona e custa caro demais em milhões de pedidos por dia | ajuste fino, com um conjunto de avaliação |
| ninguém concorda sobre o que é uma boa resposta | decida isso primeiro; nenhuma técnica resolve |

A lição 30 descreve um caminho do meio entre escrever um prompt e mudar os pesos, em que o próprio
prompt é aprendido a partir de exemplos.
