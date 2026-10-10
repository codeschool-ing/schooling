---
title: O que a palavra qualidade quer dizer, três vezes
version: 1
---

**A definição mais comum de qualidade em software é "não ter bug", e ela falha no primeiro exemplo.**
Uma bilheteria sem defeito nenhum que leva quatro minutos para vender um ingresso não tem bug. Ninguém
a chamaria de boa. Uma bilheteria com um erro de digitação na página de ajuda vende ingresso o dia todo
e é claramente melhor. A ausência de defeitos é parte da qualidade, e está longe de ser toda ela.

Três definições fizeram a maior parte do trabalho desde os anos 1950, e vale a pena guardar cada uma,
porque cada uma manda você olhar para um lugar diferente.

## Conformidade com os requisitos

Philip Crosby, escrevendo sobre indústria em 1979, definiu qualidade como **conformidade com os
requisitos**. Um produto é bom se faz o que foi especificado para fazer. É a definição que quem testa usa
toda vez que compara uma saída com uma regra escrita, e ela tem uma grande força: dá para verificar. O
`tickets.py` cobra R$ 36,00 de quem tem sessenta anos, a regra diz meia, e isso é um defeito pela
definição de Crosby sem discussão possível.

A fraqueza dela apareceu na aula 1. A regra dizia *maiores de 60*, o código do Rafael estava conforme
uma das leituras, e o resultado saiu errado mesmo assim. **A conformidade só é tão boa quanto o requisito
com que ela se conforma.** Um produto pode cumprir cada palavra escrita e ainda falhar com as pessoas
para quem ela foi escrita.

## Adequação ao uso

Joseph Juran tinha dito o contrário quase trinta anos antes, no seu manual de 1951: qualidade é
**adequação ao uso**. Um produto é bom se quem o usa consegue fazer o que veio fazer. Isso pega o que a
definição de Crosby deixa passar. A Célia, na bilheteria, saberia num segundo que quem tem sessenta anos
paga meia, dissesse a frase o que dissesse, porque sabe *para que* a bilheteria serve.

A fraqueza é o espelho. Adequação ao uso é difícil de verificar antes de alguém usar a coisa, e usuários
diferentes querem coisas diferentes. O cliente fiel quer comprar em dois toques; o contador do cinema quer
todo ingresso registrado com seu desconto, para o relatório mensal à distribuidora. Os dois são usos.
Nenhum está escrito até alguém perguntar.

## Valor para alguém

Gerald Weinberg, em 1992, deu a definição que a maioria de quem testa cita hoje: **qualidade é valor para
alguém**. Parece vaga e é a mais útil das três, por causa das duas últimas palavras. Ela obriga a fazer a
pergunta que as outras pulam: *para quem?* O cliente, a gerente da bilheteria, o contador, o
desenvolvedor que vai mexer neste código no ano que vem. Eles valorizam coisas diferentes, e uma decisão
sobre qualidade é uma decisão sobre de quem é o valor que mais conta desta vez.

James Bach e Michael Bolton acrescentaram depois três palavras, **"que importa"**: valor para alguém *que
importa*. Não é cinismo. É a constatação de que o relatório de quem testa vai para alguém que precisa
decidir, e a decisão depende de quem é o problema.

## O que quem testa faz com três definições

Use as três, nessa ordem. A **conformidade** te dá algo para verificar: a regra escrita. A **adequação ao
uso** te diz onde a regra escrita provavelmente está errada ou calada: onde quer que as pessoas que usam o
produto fossem se surpreender. O **valor para alguém** te diz a quem perguntar quando você não consegue
decidir, e de quem a surpresa importa mais.

O ingresso da pessoa de sessenta anos falha nas três. Não está conforme a lei que a regra queria seguir;
não é adequado a uma aposentada comprando um ingresso; e a pessoa a quem ele custa, no balcão com um
recibo na mão, importa muito para um cinema cujos clientes fiéis são na maioria aposentados. Um defeito
que falha numa definição merece uma discussão. Um que falha nas três não é discussão.

O resto desta aula divide a palavra de um segundo jeito: qualidade do **produto**, que é sobre o que as
três definições falavam, e qualidade do **processo** que o fez, que é a metade em que a garantia de
qualidade trabalha.
