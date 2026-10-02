---
title: O limite como orçamento
version: 1
---

O limite de saída costuma ser visto como uma rede de segurança contra texto desgovernado. **Ele
também é o único número de uma requisição que limita quanto ela pode custar**, e esse é o motivo
para ajustá-lo de propósito em vez de deixá-lo no padrão.

## Tokens de saída custam mais

A lição 3 mostrou que uma API de modelo cobra por token, pelo que entra e pelo que sai. **Os tokens
de saída têm preço separado dos de entrada, e na maioria das tabelas de preço custam várias vezes
mais.** Escrever um token exige um passo completo do modelo a cada vez, enquanto o prompt pode ser
processado de uma passada. Os preços mudam com frequência e variam de modelo para modelo, então os
valores abaixo são ilustrativos, dados na linha de comando, e não de provedor nenhum: 2 por milhão
de tokens de entrada e 8 por milhão de tokens de saída, sem moeda definida.

Uma requisição que pede a um modelo para classificar uma avaliação:

```
ana@lab:~/pe$ cat request.txt
You read customer reviews of Café Aurora. For the review below, reply with
one JSON object with three fields: "sentiment" (positive, neutral or
negative), "topic" (two or three words) and "summary" (one sentence).
Reply with the object and nothing else.

Review:
Waited fifteen minutes for a tea at noon. The staff were kind about it.
ana@lab:~/pe$ tok count request.txt
tokens  words  chars  file
    79     55    335  request.txt
```

Se a resposta tiver mais ou menos o tamanho do objeto de 36 tokens da seção anterior, digamos 40
tokens:

```
ana@lab:~/pe$ tok cost request.txt -o 40 -i 2 -p 8
input  79 tokens x 2 per million = 0.000158
output 40 tokens x 8 per million = 0.000320
one request: 0.000478
10,000 requests: 4.78
```

Os 40 tokens de saída custam o dobro dos 79 de entrada. Se a mesma requisição deixar o modelo
escrever 400 tokens, porque o limite permitiu e nada no prompt desencorajou:

```
ana@lab:~/pe$ tok cost request.txt -o 400 -i 2 -p 8
input  79 tokens x 2 per million = 0.000158
output 400 tokens x 8 per million = 0.003200
one request: 0.003358
10,000 requests: 33.58
```

A entrada não mudou. **A conta de dez mil requisições foi de 4,78 para 33,58, tudo por causa da
saída.** É isso que uma resposta sem limite custa em escala, e é também mais ou menos o que você
paga quando um modelo cai num laço como o da seção anterior e roda até um limite de 400.

## Um limite é um orçamento por requisição

Como a geração para no limite, **o limite vezes o preço de saída é o máximo que a saída de uma
requisição pode custar**. Com um limite de 400 no preço ilustrativo acima, a saída de nenhuma
requisição custa mais que 0,0032, faça o modelo o que fizer. Isso torna o limite o número para
raciocinar quando você estima uma conta mensal: requisições por mês vezes os tokens de entrada,
mais requisições vezes o limite, nos dois preços.

Ajuste-o a partir da tarefa, não do hábito:

- para uma classificação ou um objeto JSON pequeno, um pouco acima da maior resposta válida,
  medida com um tokenizador como o `tok count` fez acima;
- para prosa, a partir do tamanho que você quer de fato, com folga para o modelo terminar a frase;
- para qualquer coisa aberta, a partir do que você pode pagar por requisição, e então trate
  `length` como o resultado que ele é.

## Pedir brevidade e impor brevidade

Há dois jeitos de manter uma resposta curta, e eles fazem trabalhos diferentes. **Pedir brevidade
no prompt muda o que o modelo escreve; o limite só muda onde ele é cortado.** Um prompt que diz
"uma frase" ou "responda com o objeto e nada mais", como faz o `request.txt`, empurra a continuação
provável para uma resposta curta e completa. O limite não faz isso. Ele só consegue parar uma
resposta longa no meio.

Então use os dois, por motivos diferentes. A instrução é como você consegue uma resposta curta e
completa. O limite é a garantia para as vezes em que a instrução não é seguida, e o motivo de
término é como você descobre qual das duas coisas aconteceu. Um limite sem a instrução produz
sobretudo respostas cortadas; uma instrução sem o limite deixa sem teto o custo de um dia ruim.

Algumas APIs já mudaram o nome desse parâmetro ou o que ele conta, por exemplo se os tokens que um
modelo gasta raciocinando antes de responder entram nele. Leia a referência atual do modelo que você
chama, e a data dela.
