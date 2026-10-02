---
title: Propor muitos prompts, dar nota a cada um, ficar com o melhor
version: 1
---

O jeito comum de melhorar um prompt é lê-lo, decidir o que soa mais claro e reescrevê-lo. Isso
funciona até certo ponto, e se apoia numa suposição: a de que o prompt que se lê melhor para você é
o que funciona melhor no modelo. A lição 30 mostrou que o melhor prompt nem precisa ser feito de
palavras. **A engenharia de prompt automática abandona a suposição e mede no lugar dela: gerar
muitos prompts candidatos, dar nota a cada um em exemplos cuja resposta você conhece, e ficar com o
de nota mais alta.**

O método tem quatro partes. Propor exige um modelo que escreva prompts; pontuar exige o modelo que
você vai usar, rodado por um programa que conta:

1. Propor. Um modelo vê alguns exemplos da tarefa e recebe o pedido de escrever instruções que os
   produziriam, muitas vezes seguidas.
2. Pontuar. Cada candidato roda num conjunto de exemplos rotulados, e uma métrica conta quantas
   respostas dele estão certas.
3. Ficar. A nota mais alta vence.
4. Refinar, se você quiser. Pede-se ao modelo variações do vencedor, que também recebem nota.

O nome vem de um artigo de 2022, "Large Language Models Are Human-Level Prompt Engineers", que
chamou o método de APE.

## Pedindo instruções a um modelo

O passo de propor é ele mesmo um prompt, um *metaprompt*: um prompt cuja saída é um prompt. Ele
mostra pares de entrada e saída e deixa a instrução para o modelo completar. Este, e os candidatos
abaixo dele, foram escritos pelo curso como ilustração:

```localised
Dei uma instrução e quatro entradas a uma amiga. Ela leu a instrução
e escreveu uma saída para cada entrada. Aqui estão os pares:

Entrada: coffee     Saída: hot
Entrada: tea        Saída: hot
Entrada: bread      Saída: fresh
Entrada: terrace    Saída: open

A instrução era:

  - Descreva o item em uma palavra.
  - Dê o adjetivo que um café usaria para cada item.
  - Diga como cada coisa costuma estar no café.
```

Pedido de novo com amostragem ligada (lição 13), o mesmo metaprompt dá outras redações, e é isso que
você quer aqui: **o trabalho de quem propõe é a variedade, e o de quem pontua é o julgamento.**

## Pontuando, de verdade

O `ape` faz a metade da pontuação na bancada. Ele recebe um arquivo de modelos de prompt, um por
linha, com `{x}` onde vai a entrada, e um arquivo de exemplos, com a entrada e a primeira palavra
esperada separadas por uma tabulação. Ele preenche cada modelo com cada entrada, deixa o `toylm`
continuar com temperatura 0, e dá um ponto quando a primeira palavra da resposta é a esperada.

Os candidatos abaixo são o que uma pessoa poderia escrever, mais dois simples:

```
ana@lab:~/pe$ cat candidates.txt
Describe the {x} in one word:
question : what is the {x} like ? answer :
{x}
it is a cold day and the {x} is
the {x} is
ana@lab:~/pe$ cat tests.tsv
coffee	hot
tea	hot
bread	fresh
terrace	open
ana@lab:~/pe$ ape candidates.txt tests.tsv
0/4  Describe the {x} in one word:
        coffee  wanted hot     got is
        tea     wanted hot     got is
        bread   wanted fresh   got is
        terrace wanted open    got is
0/4  question : what is the {x} like ? answer :
        coffee  wanted hot     got yes
        tea     wanted hot     got yes
        bread   wanted fresh   got yes
        terrace wanted open    got yes
0/4  {x}
        coffee  wanted hot     got is
        tea     wanted hot     got is
        bread   wanted fresh   got is
        terrace wanted open    got is
4/4  it is a cold day and the {x} is
4/4  the {x} is
best: it is a cold day and the {x} is
```

A instrução que uma pessoa escreveria primeiro não fez ponto nenhum. Nem a pergunta no formato que o
próprio arquivo do café usa, que parece a mais esperta das cinco. **Os modelos de prompt que venceram
são os que servem a este modelo, e ninguém os teria escolhido lendo.**

O motivo está no que o `toylm` consegue ver. Ele olha as duas últimas palavras (lição 1), então
depois do modelo em forma de pergunta ele vê `answer :` e mais nada, e responde `yes` seja qual for
o item. A instrução termina em `word:`, e esse é um par que ele nunca viu:

```
ana@lab:~/pe$ toylm next "describe the coffee in one word :"
context: bigram after ':'
  is        25.0%  ##########
  yes       25.0%  ##########
  at        16.7%  #######
  when      16.7%  #######
  tomato     8.3%  ###
  what       8.3%  ###
```

Ele recua para o que vem depois de dois-pontos em qualquer lugar do arquivo, e `is` e `yes` empatam
no topo. Só os dois modelos de prompt que terminam em `the {x} is` põem o item onde o modelo
consegue vê-lo.

Um modelo grande vê muito mais que duas palavras, e seguiria bem a instrução. **A lição vale do mesmo
jeito: o prompt que serve a um modelo é um fato sobre aquele modelo, descoberto testando.** Uma
redação que se lê bem e uma redação que pontua bem podem diferir também num modelo grande, de
maneiras bem mais difíceis de explicar do que esta. Medir as encontra sem precisar da explicação.
