---
title: Parar num trecho de texto
version: 1
---

Um modelo não sabe onde a sua resposta termina. Ele sabe que texto costuma vir a seguir, e depois
de uma resposta numa lista de perguntas e respostas, o que costuma vir a seguir é **a próxima
pergunta**. Então um modelo a quem se pede para continuar um texto de perguntas e respostas muitas
vezes responde e depois continua escrevendo a pergunta seguinte, e a resposta dela, até escolher o
fim ou bater no limite da lição 15.

**Uma sequência de parada é um trecho de texto que encerra a geração no momento em que aparece na
saída.** Ela é conferida pelo laço, não entendida pelo modelo, e é o jeito mais barato de dizer "uma
resposta, e nada mais".

## Um modelo que segue em frente

O corpus do `toylm` tem linhas no formato `question : … ? answer : … .`, várias por linha. Aqui
está um prompt nesse formato, e o que o modelo vê dele:

```
ana@lab:~/pe$ toylm next "question : when does the café open ? answer :"
context: trigram after 'answer :'
  yes       50.0%  ####################
  at        33.3%  #############
  tomato    16.7%  #######
```

Na temperatura 0 ele escolhe `yes`, depois o ponto final, e depois o fim, que aqui ganha de uma
nova pergunta:

```
ana@lab:~/pe$ toylm generate "question : when does the café open ? answer :" --temperature 0
yes.
-- finish: end, prompt 10 tokens, output 2 tokens
```

Na temperatura padrão, com a semente 1, o sorteio depois do ponto final vai para o outro lado:

```
ana@lab:~/pe$ toylm generate "question : when does the café open ? answer :"
yes. question: is the coffee is hot.
-- finish: end, prompt 10 tokens, output 10 tokens
```

A resposta vem seguida de uma pergunta inteira que ele inventou, e a execução só termina porque o
modelo então sorteou o fim. **Nada no modelo trata uma resposta como a unidade de trabalho.**
Acrescente uma sequência de parada:

```
ana@lab:~/pe$ toylm generate "question : when does the café open ? answer :" --stop question
yes.
-- finish: stop, prompt 10 tokens, output 3 tokens
```

`finish: stop` é o terceiro motivo para um laço terminar, ao lado de `end` e `length`. A saída para
logo antes de `question`, e a palavra em si não aparece.

A parada muda só as execuções que chegam até ela. Oito sementes, sem e com ela:

```
ana@lab:~/pe$ toylm generate "question : when does the café open ? answer :" --samples 8
[seed 1] yes. question: is the coffee is hot.
[seed 2] tomato.
[seed 3] yes.
[seed 4] yes.
[seed 5] at six.
[seed 6] at six.
[seed 7] yes.
[seed 8] yes.
ana@lab:~/pe$ toylm generate "question : when does the café open ? answer :" --samples 8 --stop question
[seed 1] yes.
[seed 2] tomato.
[seed 3] yes.
[seed 4] yes.
[seed 5] at six.
[seed 6] at six.
[seed 7] yes.
[seed 8] yes.
```

Sete das oito são idênticas. A semente 1 perdeu a segunda pergunta inventada e manteve a resposta.

## O que o trigrama respondeu de fato

Olhe de novo essas oito respostas: `yes`, `tomato`, `at six`. **Nenhuma diz `seven`**, embora o
corpus diga `answer : at seven` duas vezes em resposta exatamente a essa pergunta. O motivo está na
primeira captura: o `toylm` vê só `answer :`, as duas últimas palavras, e depois de `answer :` o
arquivo dele tem `yes` mais vezes, `at` em seguida e `tomato` por último. A pergunta ficou fora da
janela. `at six` é o horário de fechar, apanhado da pergunta seguinte do corpus.

Então a sequência de parada fez o trabalho dela, e o trabalho é estreito. **Uma parada decide onde
uma resposta termina; ela não faz nada pelo acerto da resposta.** Um modelo grande lê a pergunta
inteira, então ao menos responderia com um horário. Ele também poderia seguir para a pergunta
seguinte quando o texto convida, e essa é a metade que a sequência de parada conserta.
