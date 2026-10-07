---
title: O que uma votação não conserta
version: 2
---

A autoconsistência é fácil de descrever e fácil de vender além da conta. **Ela transforma N
amostras numa resposta a N vezes o custo, e só para perguntas cujas respostas dá para contar.**
Quatro limites decidem quando ela compensa.

## Ela multiplica o custo

Cada amostra é uma cadeia inteira, e cada cadeia são tokens de saída. As sete cadeias:

```
ana@lab:~/pe$ tok count chains/*.txt
tokens  words  chars  file
   230    166    767  chains/s1.txt
   288    209    991  chains/s2.txt
   167    119    563  chains/s3.txt
   222    159    754  chains/s4.txt
   201    142    659  chains/s5.txt
   228    158    696  chains/s6.txt
   203    147    651  chains/s7.txt
```

Juntas, são 1.539 tokens de saída para uma resposta, contra 167 a 288 de uma cadeia só, e o prompt
também vai sete vezes (ou uma, se a API aceitar um número de amostras e cobrar a entrada uma vez só;
confira a documentação). **Sete amostras custam umas sete vezes o que custa uma**, e uma votação de
vinte custa vinte. As amostras podem rodar em paralelo, então a espera não precisa crescer do mesmo
jeito, mas a conta cresce. A autoconsistência cabe em perguntas onde uma resposta errada custa mais
que as chamadas extras.

## Ela precisa de respostas comparáveis

A votação contou `54`, `66`, `72` e `78` porque um número é a mesma sequência de caracteres, seja
quem for que escreveu a cadeia. Um rótulo funciona do mesmo jeito: `yes` ou `no`, `refund` ou
`replace`, uma de cinco categorias. **Texto livre não funciona.** Cinco resumos da reclamação de um
cliente são cinco parágrafos diferentes, e nenhum par vai coincidir caractere por caractere, então
toda "votação" é um empate de uns.

Mesmo com números, as respostas precisam ser normalizadas antes da contagem. `54`, `R$ 54` e
`54.00` são uma resposta para uma pessoa e três para um programa que compara textos. Fixe o formato
no prompt ("Answer: seguido só do número") e normalize o que voltar antes de contar.

## Ela pode empatar

Com três amostras e três respostas diferentes, não há maioria nenhuma:

```
ana@lab:~/pe$ vote chains/s1.txt chains/s2.txt chains/s6.txt
chains/s1.txt    72
chains/s2.txt    54
chains/s6.txt    78
votes: 72 x1, 54 x1, 78 x1
no majority: a tie between 72 and 54 and 78
```

Um programa precisa decidir de antemão o que um empate quer dizer. Escolher uma das respostas
empatadas ao acaso esconde o problema. **Um empate é uma medição: a pergunta é difícil para este
prompt**, e as respostas úteis são mais amostras, um prompt melhor, ou uma pessoa.

## A maioria pode estar errada

A votação funciona quando as cadeias erradas se espalham. Quando a maioria das cadeias comete **o
mesmo** erro, elas concordam entre si, e a votação conta essa concordância como confiança. O pedido
do café acima já mostrou isso, com o 66 vencendo. A pergunta do feriado da lição 25 mostra de um jeito
ainda mais claro: numa quarta-feira que é feriado, a cozinha pode aceitar um pedido de comida quente
às 11:45?

```
ana@lab:~/pe$ cat prompts/holiday-vote.txt
Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday. On Sundays it opens at 08:00 and closes at 12:00. The kitchen stops taking hot food orders 30 minutes before closing. On public holidays the café follows the Sunday hours.

Today is Wednesday, and it is a public holiday. At 11:45 a customer asks for a hot toastie. Can the kitchen take the order? Think it through, then end with one line: The answer is yes, or The answer is no.
ana@lab:~/pe$ mkdir -p holiday; for i in 1 2 3 4 5; do ask - --temperature 0.8 --seed $i --plain < prompts/holiday-vote.txt > holiday/h$i.txt; done
ana@lab:~/pe$ vote holiday/*.txt
holiday/h1.txt   yes
holiday/h2.txt   yes
holiday/h3.txt   yes
holiday/h4.txt   yes
holiday/h5.txt   (no answer line: no vote)
votes: yes x4
majority: yes (4 of 4 answers, 5 files)
ana@lab:~/pe$ tail -1 holiday/h5.txt
Since today is Wednesday, which is a public holiday, Café Aurora follows the Sunday hours, which means it opens at 08:00 and closes at 12:00. The kitchen stops taking hot food orders 30 minutes before closing, which would be 10:30 on a regular Wednesday. However, since it's a public holiday, the kitchen closes at 12:00, making the 30 minutes before closing 11:30. Since the customer ordered at 11:45, which is after 11:30, the kitchen is no longer taking hot food orders.
```

Quatro votos em `yes`, unânime entre as respostas que tinham linha de resposta, e o manual diz `no`.
A quinta amostra é a única que raciocinou até as 11:30 e chegou à conclusão certa, e nunca escreveu a
linha de resposta, então não votou. **A votação foi tão confiante quanto uma votação pode ser, e
errada.** Cada `yes` foi puxado do mesmo jeito, pela palavra *quarta-feira* em direção ao horário de
dia de semana, o puxão que a lição 25 descreveu, então mais amostras do mesmo prompt muito
provavelmente deixariam a maioria errada mais firme, não mais fraca. A correção está no prompt: recuar
para as regras primeiro (lição 25), e então votar entre cadeias que partem delas.

O mesmo vale para as sete amostras do `toylm` na seção de leitura anterior. `six` ganhou por cinco a dois, e num domingo
é a resposta errada: o café fecha ao meio-dia. **Uma votação mede a concordância entre as
amostras, não a concordância com os fatos.**

## Onde ela fica entre as técnicas

A cadeia de pensamento da lição 26 segue um caminho. A autoconsistência segue vários caminhos
independentes até o fim e compara só onde eles chegam. A lição 28 vai um passo além: compara
caminhos parciais enquanto avançam, fica com os promissores e larga os outros antes de terminarem.
