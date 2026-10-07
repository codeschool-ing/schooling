---
title: O laço, e quem decide o que acontece nele
version: 2
---

É tentador imaginar um agente como um modelo que recebeu as chaves: ele decide o que fazer, e faz.
O modelo decide o que **pedir**. **Todo o resto é decidido pelo programa que roda o laço**: quais
ferramentas existem, quais delas esta tarefa pode usar, quantas voltas o laço pode dar e o que conta
como terminado. Quatro execuções, cada uma terminando de um jeito, mostram onde ficam essas
decisões.

## Uma ferramenta que não existe

Três das quatro execuções abaixo reproduzem turnos de um arquivo, para que cada regra apareça
sozinha; cada arquivo traz as linhas `model>` que a execução imprime, um bloco por turno, separados
por `---`, e o do tempo começa com uma nota `#` dizendo qual era a pergunta. Um modelo pode pedir
qualquer coisa a que consiga dar nome, inclusive uma ferramenta que ninguém construiu. Aqui o turno
pede a previsão do tempo:

```
ana@lab:~/pe$ agent runs/weather.txt
tools allowed: calculator, reviews, search, today
step 1
  model> Action: weather[São Paulo]
  tool>  error: there is no tool called weather
step 2
  model> Answer: I cannot check the weather from here, so I cannot say.
done: an answer after 2 steps
```

O `agent` não tem ferramenta `weather`, então não executou nada e **devolveu um erro que o modelo
consegue ler**: não há ferramenta chamada weather. O turno seguinte usa isso e diz, com honestidade,
que não tem como conferir. Um laço que ignorasse o pedido desconhecido, ou devolvesse um resultado
vazio, deixaria o modelo preencher o silêncio com uma previsão provável (lição 5). Um erro claro é
informação, e o modelo consegue agir com base nele.

## Uma ferramenta que não é permitida

O `--allow` substitui a lista de ferramentas que uma tarefa pode usar. O padrão são as quatro que só leem
alguma coisa: `calculator`, `reviews`, `search` e `today`. A mesma encomenda de bolos, com só a
calculadora permitida:

```
ana@lab:~/pe$ agent runs/order.txt --allow calculator
tools allowed: calculator
step 1
  model> Action: today[]
  tool>  refused: today is not allowed in this task
step 2
  model> Action: calculator[3 * 42.50]
  tool>  127.5
step 3
  model> Answer: Tomorrow is Saturday 3 October. Three cakes cost R$ 127.50.
done: an answer after 3 steps
```

O pedido da data foi **recusado pelo programa**, e a calculadora rodou mesmo assim. A recusa não
depende de o modelo concordar com nada: `today` não estava na lista, então não rodou.

Agora leia a resposta. Ela ainda diz "Saturday 3 October", porque os turnos foram reproduzidos
acontecesse o que acontecesse. **Um modelo de verdade, no passo 3, não teria data nenhuma na frente
dele**, só a recusa. Eis o que um fez, com a mesma lista de permissões:

```
ana@lab:~/pe$ agent --live "Bruno wants three whole cakes at R\$ 42.50 each, to collect tomorrow. What day is tomorrow, and what is the total?" --allow calculator
tools allowed: calculator
step 1
  model> Action: today[] 
  model> Action: calculator[3 * 42.50]
  tool>  refused: today is not allowed in this task
step 2
  model> Action: calculator[42.50 * 3]
  tool>  127.5
step 3
  model> Answer: You will collect three whole cakes at R$ 127.50 each tomorrow.
done: an answer after 3 steps
```

Ele pediu a data e foi recusado; pediu a calculadora e recebeu 127.5; e respondeu. A resposta não
cita dia nenhum, o que é honesto, já que ele não tinha um, e não diz que não conseguiu achar, o que
é menos. Ela também diz que os bolos custam R$ 127.50 **cada**: o número certo, preso à coisa errada.
A lista de permissões controlou o que o agente podia fazer, e não fez nada para tornar a resposta
verdadeira. As duas coisas ainda precisam ser conferidas, por meios diferentes.

O `agent` tem uma quinta ferramenta, `send_email`, que muda algo fora da conversa e nunca está na
lista padrão. A lição 7 mostra por que uma ferramenta assim é tratada de outro jeito.

## Uma execução que chega ao limite

O `--max-steps` é o número de passos que o laço reproduz antes de desistir. Com limite de um:

```
ana@lab:~/pe$ agent runs/order.txt --max-steps 1
tools allowed: calculator, reviews, search, today
step 1
  model> Action: today[]
  tool>  Friday 2 October 2026
stopped: 1 step and no answer
```

Um passo, uma chamada de ferramenta e nenhuma resposta: **a execução é informada como parada, não
como respondida**. O limite existe porque um modelo pode continuar pedindo, com uma busca um pouco
diferente a cada vez ou a mesma chamada de novo, e cada vez custa tokens (lição 3). Alguém precisa
decidir quantas voltas uma tarefa vale, e o programa é onde essa decisão pode ser imposta.

A mesma coisa acontece quando os turnos do modelo acabam antes de um `Answer:`. Este arquivo tem duas
ações e nada depois delas:

```
ana@lab:~/pe$ agent runs/unfinished.txt
tools allowed: calculator, reviews, search, today
step 1
  model> Action: today[]
  tool>  Friday 2 October 2026
step 2
  model> Action: calculator[3 * 42.50]
  tool>  127.5
stopped: 2 steps and no answer
```

`stopped: 2 steps and no answer`. O laço conta os passos que de fato rodaram, e nunca transforma
"nenhuma resposta" numa resposta por conta própria.

## Por que os limites ficam no programa

Cada decisão acima poderia ter sido escrita como uma frase no prompt: "use só a calculadora", "pare
depois de um passo", "não invente ferramentas". Frases assim ajudam o modelo a se comportar bem, e o
programa não depende delas. **Um prompt é um pedido ao modelo; uma checagem no programa é um fato
sobre o que pode acontecer**, seja lá do que o modelo tenha sido convencido pelo texto na frente
dele. A lição 7 trata do texto que faz o convencimento, e a lição 29, de como um modelo decide qual
ferramenta pedir em seguida.
