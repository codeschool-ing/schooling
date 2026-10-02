---
title: Escolhendo os exemplos, e pagando por eles
version: 1
---

Como o modelo continua o padrão que lhe mostram, **os exemplos ensinam tudo o que têm em comum,
quer você queira, quer não**. Quatro exemplos todos curtos ensinam a ser curto. Quatro todos
positivos ensinam positivo. Escolher exemplos é escolher o que o padrão diz.

## Cinco regras para um conjunto de exemplos

Este é o prompt few-shot do rotulador do café, gravado num arquivo na bancada. É o prompt zero-shot
da lição 20 com quatro exemplos rotulados acrescentados antes da mensagem a rotular:

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
2. Incluir um caso difícil. O primeiro exemplo é irônico, o caso que o conjunto de teste da lição
   20 pegou o prompt zero-shot errando. Um exemplo fácil de `negative` não teria ensinado nada que
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

## Os exemplos são pagos a cada pedido

Um prompt é enviado inteiro a cada pedido, e os exemplos dele também. O `tok` conta as duas versões
com o tokenizador da lição 3:

```
ana@lab:~/pe$ tok count prompt-zero.txt prompt-few.txt
tokens  words  chars  file
    87     57    407  prompt-zero.txt
   172    105    750  prompt-few.txt
```

Os quatro exemplos levaram o prompt de 87 tokens para 172, quase o dobro, antes de qualquer
mensagem ser acrescentada. A preços ilustrativos dados na linha de comando, 2,50 por milhão de
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
