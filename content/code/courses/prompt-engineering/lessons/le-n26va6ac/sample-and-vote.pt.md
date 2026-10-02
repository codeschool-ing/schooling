---
title: Amostrar várias cadeias e votar
version: 1
---

A lição 26 terminou numa cadeia que soava bem e estava errada. O conserto tentador é deixar essa
cadeia mais cuidadosa: uma instrução melhor, um exemplo mais longo. **A autoconsistência
(*self-consistency*) segue outro caminho: pede várias cadeias de pensamento para a mesma pergunta e
fica com a resposta final a que a maioria chega.** Ela não tenta acertar nenhuma cadeia sozinha.
Ela conta com que as cadeias erradas errem de jeitos diferentes, enquanto as certas, com a redação
que tiverem, chegam ao mesmo número.

## Por que as amostras precisam variar

Uma votação entre cópias não é votação. À temperatura 0 um modelo pega o token de nota mais alta a
cada passo (lição 13), então o mesmo prompt dá o mesmo texto toda vez. O `toylm` mostra isso com
cinco sementes:

```
ana@lab:~/pe$ toylm generate "the café closes at" --temperature 0 --samples 5
[seed 1] six.
[seed 2] six.
[seed 3] six.
[seed 4] six.
[seed 5] six.
```

Cinco respostas idênticas não dizem nada que uma não dissesse. **As amostras precisam ser
sorteadas a uma temperatura acima de 0**, para que cada uma possa seguir um caminho diferente. O
`--samples` da lição 1 faz exatamente isso na temperatura padrão do `toylm`:

```
ana@lab:~/pe$ toylm generate "the café closes at" --samples 7
[seed 1] six.
[seed 2] noon on sunday.
[seed 3] six.
[seed 4] six.
[seed 5] six.
[seed 6] noon on sunday.
[seed 7] six.
```

Isso já é uma pequena votação, contada de olho: `six` cinco vezes, `noon on sunday` duas. As duas
são verdadeiras no corpus do café, e a próxima seção de leitura volta ao que isso quer dizer numa
votação. Um modelo grande
amostrado do mesmo jeito dá cadeias que variam na redação, na ordem dos passos e, às vezes, num
passo que dá errado.

## Cinco cadeias para o pedido do café

A pergunta é a da lição 26: três flat whites a R$ 12, duas fatias de bolo a R$ 15 e um cartão
fidelidade já com 9 carimbos. As cinco cadeias abaixo foram **escritas pelo curso como
ilustração** de cinco amostras que um modelo poderia devolver a uma temperatura acima de 0. A ana
salvou cada uma num arquivo:

```
ana@lab:~/pe$ head chains/*.txt
==> chains/s1.txt <==
The card has 9 stamps, so the first flat white is the tenth coffee and free. Two are paid: 2 x 12 = 24. Cake: 2 x 15 = 30. 24 + 30 = 54, so the answer is 54.

==> chains/s2.txt <==
Coffees: 3 x 12 = 36. One of them is the tenth stamp, so take off 12: 24. Add the cake, 30. The answer is 54.

==> chains/s3.txt <==
Three flat whites at 12 is 36 and two slices at 15 is 30. 36 + 30 = 66. The answer is 66.

==> chains/s4.txt <==
Nine stamps plus this order: the next coffee completes the card and is free. Paid: two coffees (24) and two cakes (30). The answer is 54.

==> chains/s5.txt <==
The ninth stamp means the next coffee is free, and the one after starts a new free card. One coffee paid, 12, plus cake 30. The answer is 42.
```

Três cadeias chegam a 54 por três caminhos diferentes: uma subtrai o café de graça, uma conta só
os pagos, uma raciocina sobre o cartão se completando. As duas erradas erram de jeitos
diferentes: a `s3` esquece o cartão, a `s5` inventa um segundo café de graça.

O `vote` é um programa de verdade, impresso no `lab.sh`. Ele pega o último "answer is ..." de cada
arquivo e conta:

```
ana@lab:~/pe$ vote chains/*.txt
chains/s1.txt 54
chains/s2.txt 54
chains/s3.txt 66
chains/s4.txt 54
chains/s5.txt 42
votes: 54 x3, 66 x1, 42 x1
majority: 54 (3 of 5)
```

**Só as respostas finais são comparadas; o raciocínio é jogado fora.** É isso que torna a votação
possível: cinco parágrafos com redações diferentes não dão para contar, cinco números dão. É também
por isso que cada cadeia precisa de uma expressão de resposta fixa, o mesmo hábito da linha
`Answer:` da lição 26, para um programa achar o que contar.

## O procedimento

1. Escreva um prompt de cadeia de pensamento que termine numa linha de resposta fixa.
2. Mande-o N vezes a uma temperatura acima de 0, ou uma vez com um parâmetro que peça N amostras,
   se a API tiver um.
3. Extraia a resposta final de cada retorno, e trate um retorno sem resposta como voto nenhum.
4. Fique com a resposta mais comum.

A fração que a vencedora teve também é útil. **3 de 5 é um resultado mais fraco que 5 de 5**, e um
programa pode agir sobre isso: aceitar uma votação unânime, e mandar uma dividida para uma pessoa
ou para uma segunda rodada de amostras.
