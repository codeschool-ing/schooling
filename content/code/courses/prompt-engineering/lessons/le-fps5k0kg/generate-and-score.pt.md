---
title: Propor muitos prompts, dar nota a cada um, ficar com o melhor
version: 2
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
mostra pares de entrada e saída e pede a instrução que os produziria. Salvo como
`~/pe/prompts/meta.txt` e amostrado cinco vezes, a uma temperatura acima de 0 (lição 13):

```
ana@lab:~/pe$ cat prompts/meta.txt
I gave a friend an instruction and four inputs. The friend read the
instruction and wrote one output for each input. Here are the pairs:

Input: coffee     Output: hot
Input: tea        Output: hot
Input: bread      Output: fresh
Input: terrace    Output: open

What was the instruction? Reply with the instruction alone, in one line.
ana@lab:~/pe$ ask - --temperature 0.8 --seed 1 --samples 5 --max-tokens 40 < prompts/meta.txt
[seed 1] A "hot day" is a hot piece of bread that is left out to get fresh under an open sky.
[seed 2] The instruction appears to be: "If the input is coffee or tea, the output is hot; if the input is bread, the output is fresh; if the input is terrace, the output is
[seed 3] The instruction is: "If you drink it, it's hot. If you eat it, it's fresh. If you go there, it's open."
[seed 4] Input the name of the food or drink and output its typical temperature, and for other inputs, input the name and output its typical state or condition.
[seed 5] The instruction is "Cook the [food]" and the food is assumed to be the ones mentioned in the inputs.
```

Cinco propostas, e elas não são igualmente boas. A semente 3 enuncia uma regra que se encaixa nos
quatro pares. A semente 4 é mais prolixa e também se encaixa. A semente 2 devolve os pares como regra
e foi cortada pelo limite; as sementes 1 e 5 não fazem sentido. Tudo bem: **o trabalho do propositor
é variedade, e o do avaliador é julgamento**, e nada nas propostas ganhou confiança ainda.

## Pontuando, de verdade

O `ape` faz a metade da pontuação. Ele recebe um arquivo de modelos de prompt, um por linha, com
`{x}` onde vai a entrada, e um arquivo de exemplos, com a entrada e a primeira palavra esperada
separadas por uma tabulação. Ele preenche cada modelo com cada entrada, deixa o modelo continuar com
temperatura 0, e dá um ponto quando a primeira palavra da resposta é a esperada. O modelo é o
`toylm`, ou, com `--ask`, o modelo para o qual o `ask` manda. Salve-o como `~/pe/bin/ape` e torne-o
executável:

```python
#!/usr/bin/env python3
"""ape CANDIDATES TESTS [--ask]: score prompt templates against labelled examples.

Automatic prompt engineering in its smallest form. CANDIDATES has one prompt
template per line, with {x} where the input goes. TESTS has one example per
line, the input and the expected first word separated by a tab. Each
template is filled with each input, the model continues it at temperature 0,
and the template scores one point for every reply whose first word is the
expected one, ignoring case. The model is toylm, or with --ask the model ask
sends to; the method does not change with the model.
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
use_ask = "--ask" in sys.argv
args = [a for a in sys.argv[1:] if a != "--ask"]
cands = [l.rstrip("\n") for l in open(args[0], encoding="utf-8") if l.strip()]
tests = [l.rstrip("\n").split("\t") for l in open(args[1], encoding="utf-8") if l.strip()]


def reply(prompt):
    if use_ask:
        command = [os.path.join(HERE, "ask"), prompt, "--temperature", "0", "--max-tokens", "5",
                   "--plain"]
    else:
        command = [os.path.join(HERE, "toylm"), "generate", prompt, "--temperature", "0",
                   "--max-tokens", "3"]
    out = subprocess.run(command, capture_output=True, text=True).stdout
    words = out.splitlines()[0].split() if out.strip() else []
    return words[0].strip(".,!:").lower() if words else ""


results = []
for c in cands:
    got = [(x, want, reply(c.replace("{x}", x))) for x, want in tests]
    score = sum(1 for _, want, r in got if r == want)
    results.append((score, c, got))
    print("%d/%d  %s" % (score, len(tests), c))
    for x, want, r in got:
        if r != want:
            print("        %-7s wanted %-7s got %s" % (x, want, r or "(nothing)"))
best = max(results, key=lambda r: r[0])
print("best: %s" % best[1])
```

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

Um modelo grande vê muito mais que duas palavras. Os mesmos cinco modelos de prompt, os mesmos
quatro exemplos, pontuados no modelo local:

```
ana@lab:~/pe$ ape candidates.txt tests.tsv --ask
0/4  Describe the {x} in one word:
        coffee  wanted hot     got rich
        tea     wanted hot     got delicate
        bread   wanted fresh   got crusty
        terrace wanted open    got elegant
0/4  question : what is the {x} like ? answer :
        coffee  wanted hot     got rich
        tea     wanted hot     got delicious?
        bread   wanted fresh   got it
        terrace wanted open    got the
0/4  {x}
        coffee  wanted hot     got coffee
        tea     wanted hot     got tea
        bread   wanted fresh   got bread
        terrace wanted open    got a
1/4  it is a cold day and the {x} is
        tea     wanted hot     got steaming
        bread   wanted fresh   got freshly
        terrace wanted open    got covered
2/4  the {x} is
        bread   wanted fresh   got the
        terrace wanted open    got a
best: the {x} is
```

A classificação virou. A instrução que uma pessoa escreveria primeiro é seguida à perfeição, *rich,
delicate, crusty, elegant*, uma palavra cada e todas descrições justas, e não pontua nada, porque os
quatro rótulos foram escritos para o arquivo do `toylm`. Os dois modelos que venceram no `toylm`
fazem 1 e 2, e o segundo continua sendo o `best`, com metade dos pontos. **O prompt que serve a um
modelo é um fato sobre aquele modelo, descoberto testando**, e a nota também: ela mede o modelo, o
prompt e os rótulos juntos. A próxima seção de leitura trata do terceiro.
