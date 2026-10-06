---
title: A regra da IQR
version: 1
---

A aula 6 já apresentou a regra mais usada para apontar candidatos. Um valor é candidato a atípico se fica
a mais de **1,5 IQR** além da caixa:

- abaixo de **Q1 − 1,5 × IQR**, ou
- acima de **Q3 + 1,5 × IQR**.

Essas duas linhas se chamam **cercas**. O boxplot desenha todo valor além delas como um ponto separado, e
por isso os boxplots costumam ser o primeiro lugar onde se vê um valor atípico.

## Aplicada aos dados da Horta

Para os doze tempos de entrega, Q1 = 32,625, Q3 = 41,75 e a IQR = 9,125. As cercas ficam em 18,94 e 55,44
minutos. Uma entrega, a de 61 minutos, fica além da cerca superior. Ela foi para Barão Geraldo, o bairro
mais distante da Horta, então é um extremo genuíno até que alguém mostre o contrário.

Para as 400 cestas, Q1 = R$ 42,56, Q3 = R$ 106,38 e a cerca superior fica em R$ 202,12. **Dezessete cestas**
ficam além dela, de R$ 203,05 até R$ 421,78.

## Dezessete candidatos não são dezessete problemas

Em dados assimétricos à direita, como as cestas, a regra da IQR aponta a cauda longa por construção. A
cauda não é feita de erros: é feita de casas reais fazendo compras grandes. Uma regra pensada para dados
mais ou menos simétricos sempre vai apontar alguma coisa em dados assimétricos, e em 400 cestas
assimétricas ela aponta cerca de 4% delas.

Isso não torna a regra inútil. Torna-a uma **lista de coisas para olhar**, que é tudo o que qualquer uma
destas regras é. Para as cestas, uma olhada rápida nas dezessete — quantos itens cada uma tinha, que
clientes as fizeram, se alguma se repete de forma suspeita — basta para dizer se pertencem.

## Por que 1,5?

Foi John Tukey quem escolheu. Em dados com distribuição normal, as cercas de 1,5 IQR ficam a cerca de 2,7
desvios padrão da média, então apontam uns 0,7% dos valores: mais ou menos um em 140. É raro o bastante
para merecer um olhar e comum o bastante para pegar algo em algumas centenas de valores. Um multiplicador
maior, 3 IQR, às vezes é usado para apontar só os valores "muito distantes". A escolha é uma convenção, não
uma lei, e deve ser declarada quando a regra é usada.

## A força dela

A regra da IQR é construída com quartis, e quartis são robustos: os valores atípicos que ela procura não
conseguem mover muito as cercas. Isso parece um detalhe técnico. A próxima seção mostra por que é o ponto
todo.
