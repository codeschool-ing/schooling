---
title: Um limite que corta o laço
version: 1
---

Um máximo de tokens de saída é fácil de confundir com uma instrução de tamanho, como se ajustá-lo
em 50 pedisse ao modelo uma resposta de cinquenta tokens. Ele não pede nada. **O modelo escreve
exatamente como teria escrito, e o laço é parado quando a contagem chega ao limite**, onde quer que
isso caia numa frase. O modelo nunca fica sabendo que existia um limite.

A lição 1 mostrou os dois jeitos de a geração acabar: o modelo escolhe o fim, ou um limite é
atingido. O `toylm` diz qual dos dois na última linha. Sem um limite apertado o modelo termina
sozinho:

```
ana@lab:~/pe$ toylm generate "the menu has" --temperature 0
soup, bread and cake.
-- finish: end, prompt 3 tokens, output 6 tokens
```

Com `--max-tokens 3`:

```
ana@lab:~/pe$ toylm generate "the menu has" --temperature 0 --max-tokens 3
soup, bread
-- finish: length, prompt 3 tokens, output 3 tokens
```

`finish: length` diz que o laço foi parado de fora. Os três tokens foram `soup`, a vírgula e
`bread`, e o quarto nunca foi gerado.

## Alguns laços nunca acabam sozinhos

O limite também é o que para um modelo que, sem ele, seguiria para sempre. Na temperatura 0, o
`toylm` escreve isto depois de `the cat`:

```
ana@lab:~/pe$ toylm generate "the cat" --temperature 0 --max-tokens 20
sleeps and the cat sleeps and the cat sleeps and the cat sleeps and the cat sleeps and the cat
-- finish: length, prompt 2 tokens, output 20 tokens
```

Depois de `cat sleeps` a palavra mais provável é `and`, depois de `and the` é `cat`, e depois de
`the cat` é `sleeps` de novo, então a decodificação gulosa dá voltas no mesmo círculo. **Sem o
limite o laço nunca acabaria.** Um modelo grande pode cair no mesmo tipo de círculo, repetindo uma
linha ou um item de lista, e o limite é o que transforma uma requisição que nunca voltaria numa que
volta comprida demais. A lição 17 mostra os controles que desencorajam o círculo desde o começo.

## Uma resposta cortada parece terminada

Leia de novo a saída da execução com `--max-tokens 3` sem a última linha: *the menu has soup,
bread*. É uma frase gramatical, e diz uma coisa falsa, porque o cardápio também tem bolo. **Uma
resposta cortada raramente parece cortada.** Uma lista para depois de um item, um parágrafo para
depois de uma frase, uma sequência de passos para antes do passo que importava, e quem não confere o
motivo segue em frente como se estivesse completa.

Então a regra para código que chama um modelo é simples: **confira por que ele parou antes de usar o
que escreveu.** Toda API de modelo devolve um motivo de término de algum tipo, com o nome que for; o
`toylm` o chama de `finish`, e `length` é o valor que quer dizer "isto foi cortado". Trate esse valor
como erro ou como uma nova tentativa com limite maior, nunca como resposta.

## Um objeto JSON cortado não é JSON

A saída estruturada torna o problema visível em vez de silencioso, o que é melhor e continua sendo
uma falha. Aqui está uma resposta no formato que um programa poderia pedir, escrita pelo curso, e o
tamanho dela em tokens:

```
ana@lab:~/pe$ cat reply.json
{"sentiment": "negative", "topic": "waiting time", "summary": "Waited fifteen minutes for a tea at noon; the staff were kind about it."}
ana@lab:~/pe$ tok count reply.json
tokens  words  chars  file
    36     20    137  reply.json
```

Trinta e seis tokens. Um limite abaixo disso corta o objeto antes da chave de fechamento. O `head -c`
faz o papel do limite aqui, cortando o arquivo no meio do resumo, onde um limite de tokens poderia
cair:

```
ana@lab:~/pe$ head -c 70 reply.json > cut.json; cat cut.json; echo
{"sentiment": "negative", "topic": "waiting time", "summary": "Waited 
```

O objeto completo passa na conferência do schema, e o cortado nem é JSON:

```
ana@lab:~/pe$ validate review.schema.json reply.json
valid
ana@lab:~/pe$ validate review.schema.json cut.json
not JSON: Unterminated string starting at: line 1 column 63 (char 62)
```

**Um limite que serve para prosa pode ser fatal para JSON**, porque prosa cortada continua sendo
prosa e um objeto cortado não é um objeto. Ponha o limite com folga acima da maior resposta que
você espera, e confira o motivo de término mesmo assim, porque "a maior resposta que você espera" é
um palpite. As lições 18 e 19 tratam de saída estruturada e de validá-la e consertá-la.
