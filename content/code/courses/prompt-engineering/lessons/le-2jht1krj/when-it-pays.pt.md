---
title: O modelo como propositor e juiz, e quando compensa
version: 1
---

O `tot` propõe e julga com aritmética exata. No método como foi publicado, e no artigo que o
apresentou com este mesmo quebra-cabeça, **um modelo de linguagem faz os dois trabalhos, e um
programa comum em volta dele faz a busca**: guarda a lista de estados, decide qual expandir, conta
os níveis e para. O modelo é chamado muitas vezes, uma para cada proposta e uma para cada
julgamento.

## Dois prompts

O propositor recebe o pedido de próximos passos possíveis a partir de um estado. O juiz é
consultado sobre um estado por vez. Este é um prompt de avaliação que o curso escreveu como
exemplo; ele não foi executado, já que a bancada não tem modelo:

```
Numbers left: 4 13 19
Goal: make 24 using each number exactly once, with + - * /.
Try a few combinations, then give your verdict on the last line:
sure (you found a way), likely (it looks reachable), or impossible (every attempt is far off).
```

E a ilustração do curso para uma resposta:

```localised
19 - 13 = 6, e 4 * 6 = 24.
Veredito: sure
```

Aqui o juiz por acaso achou uma solução, então `sure` é fácil. A maioria dos estados é mais
difícil: o juiz tenta algumas combinações, não acha nada que funcione de cara, e tem de chutar
entre `likely` e `impossible`. **Esse chute é onde a busca pode dar errado**, e é por isso que a
largura da seção anterior importa com um modelo e não com o `tot`. Implementações muitas vezes
consultam o juiz várias vezes por estado e combinam os vereditos, que é a votação da lição 27
aplicada a um passo.

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
