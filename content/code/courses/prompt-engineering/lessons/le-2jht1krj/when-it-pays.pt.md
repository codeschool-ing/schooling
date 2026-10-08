---
title: O modelo como propositor e juiz, e quando compensa
version: 2
---

O `tot` propõe e julga com aritmética exata. No método como foi publicado, e no artigo que o
apresentou com este mesmo quebra-cabeça, **um modelo de linguagem faz os dois trabalhos, e um
programa comum em volta dele faz a busca**: guarda a lista de estados, decide qual expandir, conta
os níveis e para. O modelo é chamado muitas vezes, uma para cada proposta e uma para cada
julgamento.

## Dois prompts

O propositor recebe o pedido de próximos passos possíveis a partir de um estado. O juiz é
consultado sobre um estado por vez. Eis um prompt de avaliação para o estado que o `tot` manteve no
nível 1, com `4 13 19` sobrando, salvo como `~/pe/prompts/judge.txt` e mandado ao modelo local:

```
ana@lab:~/pe$ cat prompts/judge.txt
Numbers left: 4 13 19
Goal: make 24 using each number exactly once, with + - * /.
Try a few combinations, then give your verdict on the last line:
sure (you found a way), likely (it looks reachable), or impossible (every attempt is far off).
ana@lab:~/pe$ ask - --temperature 0 < prompts/judge.txt
Let's try a few combinations:

1. (13 + 4) * 19 = 217 (not 24)
2. (19 - 4) * 13 = 221 (not 24)
3. (19 + 4) * 13 = 247 (not 24)
4. (19 + 13) * 4 = 208 (not 24)
5. (19 - 13) * 4 = 6 (not 24)
6. (19 + 13) / 4 = 8 (not 24)
7. (19 - 4) / 13 = 1.38 (not 24)
8. (13 + 4) / 19 = 0.74 (not 24)
9. (19 + 4) / 13 = 2.46 (not 24)
10. (19 - 4) / 13 = 1.38 (not 24)
11. (13 + 4) * 19 / 13 = 24 (yes!)

Verdict: sure (I found a way)
-- llama3.2:3b, finish: stop, prompt 88 tokens, output 236 tokens
```

`4 13 19` consegue dar 24: o `tot` achou no nível 2, `19 - 13 = 6`, depois `4 * 6`. O modelo testou
exatamente essa combinação na linha 5 e escreveu `(19 - 13) * 4 = 6`. Depois, na linha 11, escreveu
`(13 + 4) * 19 / 13 = 24`, que usa o 13 duas vezes e dá 24,85, e com base nisso disse **sure**. O
veredito está certo, e o motivo dele é falso. Um julgamento feito desse jeito podia muito bem ter dito impossível, e podado o ramo que resolve o quebra-cabeça. **É aí que a busca erra quando tem um modelo dentro**: não na busca,
que é só contabilidade, mas num julgamento que ninguém confere.

Um estado sem caminho até 24, `1 1 2`, mostra o outro risco. O mesmo prompt, com um limite de 150
tokens:

```
ana@lab:~/pe$ sed "s/4 13 19/1 1 2/" prompts/judge.txt > prompts/judge-dead.txt
ana@lab:~/pe$ ask - --temperature 0 --max-tokens 150 < prompts/judge-dead.txt
Let's try a few combinations:

1. (1 + 2) * 1 = 3 (not enough)
2. (1 + 1) * 2 = 4 (not enough)
3. (1 + 2) - 1 = 2 (not enough)
4. (1 + 1) - 2 = 0 (not enough)
5. (1 + 2) / 1 = 3 (not enough)
6. (1 + 1) / 2 = 1.5 (not enough)
7. (1 + 2) * (1 + 1) = 6 (not enough)
8. (1 + 2) * (1
-- llama3.2:3b, finish: length, prompt 88 tokens, output 150 tokens
```

Ele foi cortado no meio da lista, em 150 tokens, e ainda não tinha chegado a um veredito. Um juiz que passa pelas combinações uma a uma pode custar muitas vezes o que um julgamento deveria, e é para isso que serve o limite da lição
15.

É por isso que a largura da seção anterior importa com um modelo e não com o `tot`, e por isso que as
implementações costumam perguntar ao juiz várias vezes por estado e combinar os vereditos: a
votação da lição 27, aplicada a um passo, com os limites da lição 27.

## Quantas chamadas uma resposta exige

Conte na captura da seção anterior. Suponha que um modelo tivesse julgado cada estado diferente que o
`tot` propôs: 36 no nível 1, 47 no nível 2 e 7 no nível 3. **São 90 chamadas para julgar, mais as
chamadas que propuseram os passos, para uma resposta a um quebra-cabeça.** Uma
cadeia de pensamento teria sido uma chamada. Cada uma dessas chamadas é curta, e muitas podem
rodar em paralelo, mas a conta cobra todas.

Isso faz da árvore de pensamentos, de longe, a técnica mais cara desta parte do curso, e o custo é
a primeira coisa a pesar.

## Quando vale a pena

O método compensa em problemas com duas propriedades juntas.

**Os estados intermediários podem ser julgados.** Depois de um passo do jogo do 24 dá para fazer
uma pergunta com sentido: o 24 ainda é alcançável a partir destes três números? Uma palavra
cruzada pela metade, um plano com três de seis passos escolhidos, uma demonstração com dois lemas
prontos: cada estado parcial pode ser conferido contra as restrições. Onde uma resposta parcial não
pode ser julgada, como o primeiro parágrafo de uma resposta a um cliente, a árvore não tem por onde
podar e vira autoconsistência com passos a mais.

**Há becos sem saída, e um passo inicial pode levar a um.** Na captura, 29 dos 36 primeiros passos
nunca chegariam a 24. Uma cadeia única que escolhesse um deles gastaria todos os passos seguintes
à toa. Problemas em que todo caminho leva a algo sensato, como resumir, ou responder a uma pergunta
a partir de uma página do manual, não ganham nada explorando alternativas.

## As três lado a lado

| | cadeia de pensamento (lição 26) | autoconsistência (lição 27) | árvore de pensamentos |
|---|---|---|---|
| caminhos | um | vários, independentes | vários, ramificando de passos comuns |
| quando os caminhos são comparados | nunca | no fim, pela resposta final | a cada passo, por um julgamento |
| um beco sem saída | é seguido até o fim | perde na votação, se for raro | é descartado quando é julgado |
| chamadas por resposta | uma | uma por amostra | uma por proposta e por julgamento |

**Use a técnica mais barata que funcione no seu problema.** A cadeia de pensamento é o padrão para
qualquer coisa com passos intermediários. Uma votação entre várias cadeias serve para respostas que
dão para comparar, quando uma errada sai cara. Uma árvore é só para um problema que é uma busca, com
estados que você consegue julgar e becos sem saída de que precisa sair cedo. A lição 29
acrescenta a peça que falta, um modelo que chama ferramentas entre os seus passos.
