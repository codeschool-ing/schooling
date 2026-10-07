---
title: Escolhendo os exemplos, e pagando por eles
version: 2
---

Como o modelo continua o padrão que lhe mostram, **os exemplos ensinam tudo o que têm em comum,
quer você queira, quer não**. Quatro exemplos todos curtos ensinam a ser curto. Quatro todos
positivos ensinam positivo. Escolher exemplos é escolher o que o padrão diz.

## Cinco regras para um conjunto de exemplos

Este é o prompt few-shot do rotulador do café, um modelo de prompt como os da lição 20. Salve-o como
`~/pe/prompt-few.txt`. É um prompt de rotular zero-shot com quatro exemplos rotulados acrescentados
antes da mensagem a rotular:

```
ana@lab:~/pe$ cat prompt-few.txt
Label a message sent to Café Aurora through its website.

Labels:
  positive      the writer is pleased overall
  negative      the writer is unhappy overall
  mixed         clear praise and clear complaint, neither dominant
  not_a_review  a question, a booking, or anything that is not
                about a visit

Reply with the label only, in lower case, nothing else.

<message>Oh lovely, a cold croissant again. Truly the highlight of my week.</message>
negative

<message>Can I book the terrace for six people on Saturday?</message>
not_a_review

<message>Friendly staff, but the music was far too loud to talk.</message>
mixed

<message>Melhor café da rua, e o bolo de laranja é perfeito.</message>
positive

<message>
{message}
</message>
```

Cada exemplo está ali por um motivo, e os motivos são as regras:

1. Cobrir as classes. Há um exemplo de cada um dos quatro rótulos, então nenhum rótulo parece o
   padrão e nenhum parece proibido.
2. Incluir um caso difícil. O primeiro exemplo é irônico, o caso em que o conjunto de teste da
   lição 20 flagrou o erro do prompt zero-shot. Um exemplo fácil de `negative` não teria ensinado nada que
   a descrição já não ensinasse.
3. Variar a ordem. Os rótulos não aparecem na ordem da lista das instruções, e o caso difícil não é
   o último. Um modelo pode captar a posição dos exemplos além do conteúdo, e o rótulo do último
   exemplo tem um caminho fácil até a próxima resposta.
4. Equilibrar os rótulos. Um de cada aqui. Três exemplos `negative` e um `positive` fariam
   `negative` parecer a resposta de costume, digam o que disserem as definições.
5. Mantê-los fora do conjunto de teste. Nenhum dos quatro é `r1` a `r8` da lição 20. Se fossem, o
   conjunto de teste conteria as respostas que confere, e uma nota de 8 de 8 mediria memória, não
   rotulagem.

Há uma sexta que o arquivo mostra em vez de dizer: **os exemplos usam exatamente o formato de
saída pedido**. Um rótulo puro, em minúsculas, numa linha só. Um exemplo que respondesse `Negative
(sarcastic)` contradiria a instrução algumas linhas acima, e deixaria o modelo com dois sinais em
desacordo.

O quarto exemplo está em português pelo mesmo motivo que a `r8` do conjunto de teste: as mensagens
chegam em mais de um idioma, e os rótulos ficam em inglês.

## O que a contagem disse

O método da lição 20 decide se os exemplos mereceram o lugar: os mesmos oito testes, com os mesmos
`label.py` e `score.py`, uma vez sem os exemplos e uma vez com eles. O `prompt-zero.txt` é o mesmo
prompt com os quatro exemplos tirados, e sem a lista de casos de borda da lição 20:

```
ana@lab:~/pe$ cat prompt-zero.txt
Label a message sent to Café Aurora through its website.

Labels:
  positive      the writer is pleased overall
  negative      the writer is unhappy overall
  mixed         clear praise and clear complaint, neither dominant
  not_a_review  a question, a booking, or anything that is not
                about a visit

Reply with the label only, in lower case, nothing else.

<message>
{message}
</message>
ana@lab:~/pe$ python3 label.py prompt-zero.txt tests.tsv > replies-zero.txt; python3 score.py tests.tsv replies-zero.txt
r5  wanted negative      got positive
r8  wanted positive      got mixed
6 of 8 right
ana@lab:~/pe$ python3 label.py prompt-few.txt tests.tsv > replies-few.txt; python3 score.py tests.tsv replies-few.txt
r1  wanted positive      got negative not_a_review mixed positive not_a_review
r2  wanted mixed         got negative not_a_review mixed positive not_a_review
r3  wanted negative      got negative not_a_review mixed positive negative
r4  wanted positive      got negative not_a_review mixed positive not_a_review
r5  wanted negative      got negative not_a_review mixed positive not_a_review
r6  wanted not_a_review  got negative not_a_review mixed positive not_a_review
r7  wanted mixed         got negative not_a_review mixed positive not_a_review
r8  wanted positive      got negative not_a_review mixed positive not_a_review
0 of 8 right
```

**Seis de oito sem os exemplos, nenhum de oito com eles.** Cada resposta ao prompt few-shot são cinco
rótulos, os quatro exemplos rotulados de novo e depois a mensagem, a falha que a seção anterior
mostrou numa mensagem, agora nas oito. Os exemplos e a entrada estavam escritos do mesmo jeito,
então o modelo tratou os dois do mesmo jeito.

Então marque a fronteira. Os mesmos quatro exemplos, apresentados como exemplos, com uma instrução
para rotular só a mensagem entre as tags:

```
ana@lab:~/pe$ cat prompt-few2.txt
Label a message sent to Café Aurora through its website.

Labels:
  positive      the writer is pleased overall
  negative      the writer is unhappy overall
  mixed         clear praise and clear complaint, neither dominant
  not_a_review  a question, a booking, or anything that is not
                about a visit

These four messages are already labelled, as examples:

  Oh lovely, a cold croissant again. Truly the highlight of my week. -> negative
  Can I book the terrace for six people on Saturday? -> not_a_review
  Friendly staff, but the music was far too loud to talk. -> mixed
  Melhor café da rua, e o bolo de laranja é perfeito. -> positive

Label only the message between the tags below. Reply with the label
only, in lower case, nothing else.

<message>
{message}
</message>
ana@lab:~/pe$ python3 label.py prompt-few2.txt tests.tsv > replies-few2.txt; python3 score.py tests.tsv replies-few2.txt
r4  wanted positive      got mixed
r5  wanted negative      got positive
r6  wanted not_a_review  got mixed
r8  wanted positive      got mixed
4 of 8 right
```

Quatro de oito: a forma está resolvida, e os rótulos estão piores do que no prompt sem exemplo
nenhum. A `r5`, a mensagem sarcástica, continua `positive`, mesmo com um exemplo sarcástico no
prompt, e três mensagens viraram `mixed`, o rótulo do exemplo mais parecido com elas na lista.
**Neste modelo, estes exemplos pioraram o rotulador**, e só a contagem diz isso: cada uma das
respostas é um rótulo arrumado, em minúsculas. Um modelo maior pode muito bem ganhar com os mesmos
quatro exemplos. É por isso que se mede com o seu modelo, e não se aceita a palavra desta lição, nem
a de ninguém.

## Os exemplos são pagos a cada pedido

Um prompt é enviado inteiro a cada pedido, e os exemplos dele também. O `tok` conta as duas versões
com o tokenizador da lição 3:

```
ana@lab:~/pe$ tok count prompt-zero.txt prompt-few.txt prompt-few2.txt
tokens  words  chars  file
    87     57    407  prompt-zero.txt
   172    105    750  prompt-few.txt
   179    125    794  prompt-few2.txt
```

Os quatro exemplos levaram o prompt de 87 tokens para 172, quase o dobro, antes de qualquer
mensagem ser acrescentada, e marcá-los como exemplos o levou a 179. A preços ilustrativos dados na linha de comando, 2,50 por milhão de
tokens de entrada e 10 por milhão de tokens de saída, com uma resposta de dois tokens:

```
ana@lab:~/pe$ tok cost prompt-zero.txt -o 2 -i 2.50 -p 10
input  87 tokens x 2.5 per million = 0.000218
output 2 tokens x 10 per million = 0.000020
one request: 0.000237
10,000 requests: 2.38
ana@lab:~/pe$ tok cost prompt-few.txt -o 2 -i 2.50 -p 10
input  172 tokens x 2.5 per million = 0.000430
output 2 tokens x 10 per million = 0.000020
one request: 0.000450
10,000 requests: 4.50
```

Por pedido é menos de um milésimo nos dois casos. **Em 10.000 mensagens, o prompt few-shot custa
4,50 contra 2,38**, e a diferença cresce a cada exemplo acrescentado e a cada pedido enviado. A
lição 15 trata de controlar o outro lado dessa conta, a saída.

Esse custo é o motivo para parar de acrescentar exemplos quando o conjunto de teste para de
melhorar, em vez de acrescentá-los por princípio. Dois ou três exemplos bem escolhidos que corrigem
uma falha medida valem os seus tokens. Vinte exemplos que repetem os casos fáceis custam muito mais
e não ensinam nada de novo ao padrão. O método da lição 20 decide: **rode o conjunto de teste com e
sem cada mudança, e fique com o que move a contagem.**
