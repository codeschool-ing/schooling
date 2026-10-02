---
title: O que o modelo não vê dentro de um token
version: 1
---

Um modelo que escreve parágrafos fluentes em várias línguas parece saber, com certeza, como se
escreve uma palavra. **Ninguém lhe mostrou a grafia.** Mostraram números de tokens, e o que ele
sabe sobre as letras dentro de um token teve de aprender por tabela, em textos onde alguém por acaso
soletrou a palavra. Daí vêm três tropeços conhecidos, e cada um aparece no que o `tok` imprime.

## Contar letras

"Quantas vezes a letra r aparece em strawberry?" ficou famosa porque os modelos erravam sem parar.
Eis o que o modelo recebe:

```
ana@lab:~/pe$ tok show "How many r are in strawberry?"
"How" " many" " r" " are" " in" " strawberry" "?"
5299 1991 428 553 306 101830 30
7 tokens, 29 characters (o200k_base)
```

A palavra sobre a qual é a pergunta é um número só, 101830. **Os três r não estão na entrada**;
estão dentro de um token, e o modelo precisa responder com o que aprendeu sobre a grafia desse
token, um fato como qualquer outro, que ele pode ter aprendido pela metade. Uma pessoa que conta
letras olha para as letras. O modelo não tem para onde olhar.

## Escrever uma palavra ao contrário

Inverter uma palavra é trivial para um programa e desajeitado para um modelo, pelo mesmo motivo:

```
ana@lab:~/pe$ tok show "yrrebwarts"
"yr" "reb" "warts"
3866 19100 115451
3 tokens, 10 characters (o200k_base)
```

`strawberry` de trás para frente são três tokens que não têm nada a ver com o original: `"yr"`,
`"reb"`, `"warts"`. **Nada nos números 3866, 19100 e 115451 diz que eles soletram 101830 ao
contrário.** Para produzi-los, o modelo precisa saber as letras da palavra na ordem normal e
remontá-las em pedaços de outro formato, um passo por token.

## Dígitos em blocos

Os números também são cortados, e o corte depende de como estão escritos:

```
ana@lab:~/pe$ tok show "1234567"; tok show "1,234,567"
"123" "456" "7"
7633 19354 22
3 tokens, 7 characters (o200k_base)
"1" "," "234" "," "567"
16 11 20771 11 34904
5 tokens, 9 characters (o200k_base)
```

A mesma quantidade dá três tokens numa forma e cinco na outra, e em nenhuma delas é um dígito por
token. Somar dois números exige alinhar unidade com unidade e dezena com dezena, e quando `1234567`
chega como `123`, `456` e `7`, as unidades estão no fim de um bloco que o outro número talvez não
tenha. Os modelos grandes fazem contas melhor do que isso sugere, e ainda cometem erros que uma
calculadora nunca comete, sem nenhum sinal no texto de que erraram.

## O que fazer

Dois remédios, e os dois voltam neste curso:

- **Transformar as letras em tokens.** Peça que a palavra seja soletrada primeiro, uma letra por
  linha, e depois contada: escrita assim, cada letra vira um token próprio, e o modelo conta coisas
  que consegue ver. A lição 26 faz o mesmo com o raciocínio, pedindo que os passos sejam escritos
  antes da resposta.
- **Passar o trabalho para um programa.** Contar, inverter e fazer contas têm respostas exatas que
  umas poucas linhas de código produzem sempre. A lição 6 deixa o modelo pedir uma calculadora, e
  essa é a ferramenta certa para 4 × 27.90, acertasse o modelo ou não.

Nada disso é motivo para desconfiar do que um modelo escreve sobre o sentido das coisas. **Um modelo
é bom no que é visível nos tokens, que é quais pedaços vêm depois de quais**, e fraco no que está
escondido dentro deles. Saber de que lado dessa linha uma tarefa cai é quase tudo para saber se a
resposta precisa ser conferida.
