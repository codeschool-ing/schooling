---
title: Prompt escrito, prompt tuning, fine-tuning
version: 1
---

É fácil ler os três como degraus de uma escada, em que o trabalho sério começa com um prompt e
depois passa para o treino. Eles se leem melhor como três lugares onde pôr a mudança, cada um com seu
preço. **A pergunta não é qual é o mais avançado, e sim em quais números você tem permissão de
mexer.**

| | prompt escrito | prompt tuning | fine-tuning (lição 9) |
|---|---|---|---|
| o que muda | o texto enviado em cada requisição | alguns vetores aprendidos na frente da entrada | os pesos do modelo, ou parte deles |
| o que fica fixo | o modelo | o modelo | a base de onde você partiu |
| do que você precisa | acesso ao modelo, por chat ou API | os pesos, um conjunto de treino e hardware para treinar | um conjunto de treino, e os pesos ou um serviço de treino do provedor |
| quanto custa | os tokens do prompt, em toda requisição (lição 3) | uma rodada de treino, depois quase nada por requisição | uma rodada de treino, e muitas vezes um preço maior por requisição para um modelo próprio |
| uma pessoa consegue ler | **sim** | não: são vetores | não: são pesos |
| passar para outro modelo | reescrever e testar de novo | treinar de novo do zero | treinar de novo do zero |
| em quanto tempo dá para mudar | minutos | uma nova rodada de treino | uma nova rodada de treino |

Leia as colunas de cima para baixo e uma diferença salta aos olhos: **só o prompt escrito pode ser
lido, e mudado, por alguém sem um conjunto de treino.** Quase tudo o que este curso ensinou, de
papéis a exemplos ao ReAct, mora na primeira coluna.

## Por que a maioria nunca faz isso

Se você usa um modelo por uma API hospedada, no momento em que este curso foi escrito (2026), você
envia texto e recebe texto. Você não tem os pesos, então a segunda coluna está fechada para você:
não existe campo na requisição onde caiba um vetor. O fine-tuning só chega até você onde um provedor
o oferece como serviço, nos modelos que ele escolhe, e a lição 9 pesou quando isso vale a pena.

Então o prompt tuning é de quem roda um modelo por conta própria, em geral um modelo de pesos
abertos no próprio hardware. Para essas pessoas ele tem uma vantagem real sobre o fine-tuning: uma
única cópia congelada do modelo atende muitas tarefas, cada uma com seu soft prompt pequeno trocado
a cada requisição, onde o fine-tuning exigiria um conjunto de pesos separado por tarefa.

## Por que ainda vale conhecer

Duas coisas valem mesmo que você nunca treine um vetor.

Primeiro, ele mostra com clareza que **as palavras de um prompt só importam pelo que fazem ao
modelo**. O melhor soft prompt não é uma frase, e uma pessoa nunca o escreveria. Os prompts escritos
que funcionam melhor para um modelo podem ser estranhos do mesmo jeito, e é por isso que a lição 31
deixa um programa procurá-los em vez de confiar no que se lê melhor.

Segundo, ele dá nome a uma afirmação que você vai encontrar em descrições de produto: um modelo
"ajustado" para uma tarefa. Pergunte qual coluna é. Uma instrução escrita nova, um conjunto de
vetores aprendidos e pesos alterados são três coisas diferentes, e só a primeira pode ser examinada
lendo.
