---
title: O que uma votação não conserta
version: 1
---

A autoconsistência é fácil de descrever e fácil de vender além da conta. **Ela transforma N
amostras numa resposta a N vezes o custo, e só para perguntas cujas respostas dá para contar.**
Quatro limites decidem quando ela compensa.

## Ela multiplica o custo

Cada amostra é uma cadeia inteira, e cada cadeia é token de saída. As cinco cadeias ilustradas:

```
ana@lab:~/pe$ tok count chains/*.txt
tokens  words  chars  file
    59     40    158  chains/s1.txt
    43     26    110  chains/s2.txt
    34     23     90  chains/s3.txt
    35     26    138  chains/s4.txt
    38     29    142  chains/s5.txt
```

Juntas são 209 tokens de saída para uma resposta, contra 34 a 59 de uma cadeia só, e o prompt
também é enviado cinco vezes (ou uma, se a API aceitar um número de amostras e cobrar a entrada uma
vez; confira na documentação). **Cinco amostras custam cerca de cinco vezes o que custa uma**, e
uma votação de vinte custa vinte. As amostras podem rodar em paralelo, então a espera não precisa
crescer do mesmo jeito, mas a conta cresce. A autoconsistência cabe em perguntas em que uma resposta
errada custa mais do que quatro chamadas extras.

## Ela precisa de respostas comparáveis

A votação contou `54`, `66` e `42` porque um número é a mesma sequência de caracteres, seja quem
for que escreveu a cadeia. Um rótulo funciona do mesmo jeito: `yes` ou `no`, `refund` ou
`replace`, uma de cinco categorias. **Texto livre não funciona.** Cinco resumos da reclamação de um
cliente são cinco parágrafos diferentes, e nenhum par vai coincidir caractere por caractere, então
toda "votação" é um empate de uns.

Mesmo com números, as respostas precisam ser normalizadas antes da contagem. `54`, `R$ 54` e
`54.00` são uma resposta para uma pessoa e três para um programa que compara textos. Fixe o formato
no prompt ("Answer: seguido só do número") e normalize o que voltar antes de contar.

## Ela pode empatar

Com três amostras e três respostas diferentes, não há maioria nenhuma:

```
ana@lab:~/pe$ vote chains/s1.txt chains/s3.txt chains/s5.txt
chains/s1.txt 54
chains/s3.txt 66
chains/s5.txt 42
votes: 54 x1, 66 x1, 42 x1
no majority: a tie between 54 and 66 and 42
```

Um programa precisa decidir de antemão o que um empate quer dizer. Escolher ao acaso uma das
respostas empatadas esconde o problema. **Um empate é uma medida: a pergunta é difícil para este
prompt**, e as respostas úteis são mais amostras, um prompt melhor ou uma pessoa.

## A maioria pode estar errada

A votação funciona quando as cadeias erradas se espalham. Quando a maioria comete **o mesmo** erro,
elas concordam entre si, e a votação conta essa concordância como confiança. A pergunta do feriado
da lição 25 é o caso: numa quarta-feira que é feriado, a cozinha aceita um pedido de comida quente
às 11:45? De novo, as cinco cadeias foram escritas pelo curso como ilustração:

```
ana@lab:~/pe$ head holiday/*.txt
==> holiday/h1.txt <==
It is Wednesday, and on weekdays the café closes at 18:00, so the kitchen takes hot food until 17:30. 11:45 is before that. The answer is yes.

==> holiday/h2.txt <==
Wednesday hours are 07:00 to 18:00. The kitchen stops 30 minutes before closing, at 17:30. The answer is yes.

==> holiday/h3.txt <==
A public holiday follows the Sunday hours: closing at 12:00, so hot food stops at 11:30. 11:45 is too late. The answer is no.

==> holiday/h4.txt <==
The café is open on Wednesdays until 18:00 and the order is at 11:45, well inside the hours. The answer is yes.

==> holiday/h5.txt <==
Holidays use Sunday hours, so the café closes at noon and the last hot food order is 11:30. The answer is no.
ana@lab:~/pe$ vote holiday/*.txt
holiday/h1.txt yes
holiday/h2.txt yes
holiday/h3.txt no
holiday/h4.txt yes
holiday/h5.txt no
votes: yes x3, no x2
majority: yes (3 of 5)
```

A maioria é `yes`, e o manual diz `no`. As três cadeias erradas têm uma causa comum: a palavra
*Wednesday* puxa cada uma delas para a linha dos dias úteis, a atração que a lição 25 descreveu.
**Amostrar mais o mesmo prompt repete a mesma atração**, então mais amostras provavelmente
deixariam a maioria errada mais firme, e não mais fraca. O conserto está no prompt: recuar até as
regras primeiro (lição 25), e então votar entre cadeias que partem delas.

O mesmo vale para as sete amostras do `toylm` acima. `six` ganhou por cinco a dois, e num domingo
é a resposta errada: o café fecha ao meio-dia. **Uma votação mede a concordância entre as
amostras, não a concordância com os fatos.**

## Onde ela fica entre as técnicas

A cadeia de pensamento da lição 26 segue um caminho. A autoconsistência segue vários caminhos
independentes até o fim e compara só onde eles chegam. A lição 28 vai um passo além: compara
caminhos parciais enquanto avançam, fica com os promissores e larga os outros antes de terminarem.
