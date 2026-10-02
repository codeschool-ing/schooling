---
title: Usando uma confiança declarada
version: 1
---

Uma confiança vale ser coletada se ajuda a decidir o que fazer com uma resposta. O uso comum é um
limiar: **responder automaticamente acima dele e mandar o resto para uma pessoa**. Subir o limiar
responde menos mensagens e, se a confiança quer dizer alguma coisa, acerta uma parte maior delas. A
troca se chama cobertura contra acurácia.

O `pl calibrate --thresholds` imprime essa troca para alguns limiares. O jeito de usá-lo é escolher
num conjunto e conferir em outro que não teve papel nenhum na escolha. Aqui, escolha no conjunto
dev:

```
ana@lab:~/triage$ pl run prompts/v9-confidence.txt cases/dev.jsonl --out runs/v9-dev.jsonl
40 calls, prompt c31bed19, written to runs/v9-dev.jsonl
ana@lab:~/triage$ pl calibrate runs/v9-dev.jsonl --thresholds
stated         n  mean said  accuracy
0.50-0.60    0          -         -
0.60-0.70    0          -         -
0.70-0.80    1       0.70      0.00
0.80-0.90   14       0.85      1.00
0.90-1.00   25       0.97      1.00

replies 40, right 39, mean stated confidence 0.92
ECE 0.092   Brier 0.022

answer if  answered  accuracy
conf >= 0.00     40      0.97
conf >= 0.80     39      1.00
conf >= 0.85     34      1.00
conf >= 0.90     25      1.00
conf >= 0.95     21      1.00
```

No dev, o substituto parece **pouco confiante**: respostas declaradas em torno de 0,85 acertaram
todas as vezes. A única resposta errada foi declarada com 0,70, e um limiar de 0,80 a remove.
Responda quando a confiança for pelo menos 0,80, e você responde 39 mensagens de 40 com acurácia
de 1,00.

Agora aplique esse limiar ao conjunto mais difícil, que ele nunca viu:

```
ana@lab:~/triage$ pl run prompts/v9-confidence.txt cases/holdout.jsonl --out runs/v9-holdout.jsonl
30 calls, prompt c31bed19, written to runs/v9-holdout.jsonl
ana@lab:~/triage$ pl calibrate runs/v9-holdout.jsonl --thresholds
stated         n  mean said  accuracy
0.50-0.60    0          -         -
0.60-0.70    2       0.69      0.00
0.70-0.80    6       0.74      0.33
0.80-0.90   13       0.85      0.62
0.90-1.00    9       0.96      0.78

replies 30, right 17, mean stated confidence 0.85
ECE 0.282   Brier 0.295

answer if  answered  accuracy
conf >= 0.00     30      0.57
conf >= 0.80     22      0.68
conf >= 0.85     16      0.75
conf >= 0.90      9      0.78
conf >= 0.95      7      0.86
```

A mesma regra responde 22 mensagens de 30 e acerta **0,68** delas. Neste conjunto o substituto é
confiante demais em todas as faixas, e o ECE dele é 0,282 contra 0,092 no dev. Nada no modelo ou no
limiar mudou. As mensagens mudaram: o holdout guarda as mensagens mais difíceis, muitas com evidência
para dois rótulos como `h04`, e é exatamente aí que a regra do substituto declara uma confiança que a
resposta não mereceu.

## O que o limiar ainda fez

Ele ajudou. No holdout, responder tudo dá 0,57; responder com 0,80 ou mais dá 0,68, e as oito
mensagens que ele segurou foram para uma pessoa. Uma confiança mal calibrada ainda consegue ordenar
as respostas de um jeito útil, e é essa ordem que um limiar usa. O que ela não consegue é cumprir a
acurácia que prometeu no conjunto em que foi escolhida.

Então as regras para uma confiança declarada são as regras de qualquer outra saída:

- **Meça contra rótulos que uma pessoa deu**, com tabela de confiabilidade, ECE e Brier, nas
  mensagens que você vai de fato receber.
- **Escolha o limiar num conjunto e relate-o em outro.** O número do conjunto em que você escolheu
  é o melhor caso.
- **Meça de novo quando algo mudar**: o prompt, o modelo, o tipo de mensagem que chega. Uma
  calibração é uma propriedade dos três juntos.

**Uma confiança declarada é uma característica a medir, nunca uma probabilidade em que confiar.**

## O curso

Esta foi a última aula. Cada uma delas rodou o mesmo prompt nas mesmas mensagens e perguntou se uma
mudança se sustentava, numa contagem que podia ter saído ao contrário. Uma confiança é mais uma
afirmação que um modelo faz sobre a própria resposta, e recebe o que toda afirmação recebeu neste
curso: um conjunto de teste, os rótulos de uma pessoa e um número que você calculou, e não um que lhe
disseram.
