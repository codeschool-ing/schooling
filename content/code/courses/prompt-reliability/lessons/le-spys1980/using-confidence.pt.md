---
title: Usando uma confiança declarada
version: 2
---

Uma confiança vale ser coletada se ajuda a decidir o que fazer com uma resposta. O uso comum é um
limiar: **responder automaticamente acima dele, e mandar o resto para uma pessoa**. Subir o limiar
responde menos mensagens e, se a confiança quer dizer alguma coisa, acerta mais delas. Essa troca se
chama cobertura contra acurácia.

O `calibrate.py --thresholds` imprime essa troca para alguns limiares. O jeito de usá-lo é escolher
num conjunto e conferir em outro que não teve parte na escolha. Aqui, escolha no dev:

```
ana@lab:~/triage$ pl run prompts/v9-confidence.txt cases/dev.jsonl --out runs/v9-dev.jsonl
40 calls, prompt c31bed19, llama3.2:3b, written to runs/v9-dev.jsonl
ana@lab:~/triage$ python3 calibrate.py runs/v9-dev.jsonl --thresholds
stated         n  mean said  accuracy
0.00-0.50     1       0.00      1.00
0.50-0.60     0          -         -
0.60-0.70     0          -         -
0.70-0.80     0          -         -
0.80-0.90    27       0.80      0.81
0.90-1.00    12       0.90      1.00

replies 40, 0 with no usable confidence; right 35 of 40, mean stated 0.81
ECE 0.064   Brier 0.130

answer if      answered  accuracy
conf >= 0.00       40      0.88
conf >= 0.80       39      0.87
conf >= 0.85       12      1.00
conf >= 0.90       12      1.00
conf >= 0.95        1      1.00
```

No dev, o número declarado parece útil. As respostas declaradas com 0,9 acertaram todas as vezes, 12
de 12, e as declaradas com 0,8 acertaram 0,81 das vezes. Responda quando a confiança for pelo menos
0,85, e você responde 12 mensagens de 40 **com acurácia 1,00**, e manda 28 para uma pessoa.

Agora ponha esse limiar contra o conjunto mais difícil, que ele nunca viu:

```
ana@lab:~/triage$ pl run prompts/v9-confidence.txt cases/holdout.jsonl --out runs/v9-holdout.jsonl
30 calls, prompt c31bed19, llama3.2:3b, written to runs/v9-holdout.jsonl
ana@lab:~/triage$ python3 calibrate.py runs/v9-holdout.jsonl --thresholds
stated         n  mean said  accuracy
0.00-0.50     0          -         -
0.50-0.60     0          -         -
0.60-0.70     0          -         -
0.70-0.80     0          -         -
0.80-0.90    19       0.80      0.58
0.90-1.00    11       0.90      0.55

replies 30, 0 with no usable confidence; right 17 of 30, mean stated 0.84
ECE 0.270   Brier 0.322

answer if      answered  accuracy
conf >= 0.00       30      0.57
conf >= 0.80       30      0.57
conf >= 0.85       11      0.55
conf >= 0.90       11      0.55
conf >= 0.95        0         -
```

A mesma regra responde 11 mensagens de 30 e acerta **0,55** delas. Responder tudo acerta 0,57. Neste
conjunto as respostas declaradas com 0,9 acertaram menos que as declaradas com 0,8, e um limiar que
era perfeito no dev é pior que limiar nenhum. Nada no modelo ou no limiar mudou. As mensagens
mudaram: o holdout tem as mensagens mais difíceis, e nelas o modelo escreveu 0,9 por motivos que não
tinham nada a ver com acertar.

## O que o limiar fez

No dev, uma confiança que mal separava certas de erradas em setenta mensagens pareceu um filtro
perfeito em quarenta, porque doze respostas por acaso estavam certas. No holdout o mesmo filtro não
fez nada de útil. É a diferença da aula 11 de novo, dev contra holdout, em outro número: **um limiar
escolhido num conjunto é o melhor caso para aquele conjunto**, e o número que quer dizer alguma
coisa é o de um conjunto onde ele não foi escolhido.

Então as regras para uma confiança declarada são as regras para qualquer outra saída:

- **Meça-a contra rótulos que uma pessoa deu**, com uma tabela de confiabilidade, ECE e Brier, nas
  mensagens que você vai de fato receber.
- **Compare-a com dizer a taxa de base toda vez.** Se uma constante a supera no Brier, como aqui,
  o número não carrega informação nenhuma pela qual encaminhar.
- **Escolha o limiar num conjunto e relate-o em outro.** O número do conjunto onde você escolheu é um
  melhor caso.
- **Meça de novo quando qualquer coisa mudar**: o prompt, o modelo, o tipo de mensagem que chega. Uma
  calibração é uma propriedade dos três juntos.

**Uma confiança declarada é uma característica a ser medida, nunca uma probabilidade em que
confiar.**

## O curso

Esta foi a última aula. Cada uma rodou o mesmo prompt sobre as mesmas mensagens e perguntou se uma
mudança se sustentava, numa contagem que poderia ter dado o contrário. Uma confiança é mais uma
afirmação que um modelo faz sobre a própria resposta, e recebe o que toda afirmação deste curso
recebeu: um conjunto de teste, os rótulos de uma pessoa, e um número que você calculou em vez de um
que lhe disseram.
