---
title: Escolher uma sequência de parada
version: 1
---

Uma sequência de parada parece algo seguro de acrescentar: ela só termina o texto mais cedo. O
problema está no *mais cedo*. **Uma parada dispara no texto, onde quer que ele apareça, inclusive
dentro de uma resposta que você queria inteira.** Escolher uma é escolher um texto que marca o fim e
nunca aparece antes dele.

## Uma parada dentro de uma resposta legítima

Alguém preocupado com o `toylm` seguindo em frente com `and the cat sleeps and the cat...` (lição 15) poderia
recorrer a `and` como parada. Em outro prompt, isso quebra uma resposta correta:

```
ana@lab:~/pe$ toylm generate "the menu has" --temperature 0 --stop and
soup, bread
-- finish: stop, prompt 3 tokens, output 4 tokens
```

O cardápio tem sopa, pão **e** bolo, e a parada tirou o bolo. O motivo de término diz `stop`, que
parece um fim normal. Isso é mais difícil de notar que `length`, porque uma parada existe para
terminar o texto.

Uma parada é comparada como texto, não como palavra. No `toylm` é um teste simples de substring
sobre o que já foi escrito, então uma parada curta pode disparar dentro de uma palavra maior:

```
ana@lab:~/pe$ toylm generate "the coffee is" --seed 2
cold and the cat wakes.
-- finish: end, prompt 3 tokens, output 6 tokens
ana@lab:~/pe$ toylm generate "the coffee is" --seed 2 --stop at
cold and the c
-- finish: stop, prompt 3 tokens, output 4 tokens
```

`at` está dentro de `cat`, então a resposta foi cortada no meio de uma palavra. As APIs de modelo
também comparam sequências de parada com o texto gerado, e os detalhes, como onde cortar uma
coincidência que atravessa dois tokens, são do provedor. **Quanto mais longa e distinta a parada,
menor a chance de ela aparecer por acaso.**

## O texto da parada não está na saída

Em todas as execuções com parada desta lição, o texto da parada some: `yes.` e não `yes. question`, `is there cake?`
e não `is there cake? answer`. Esse é o comportamento habitual das APIs de modelo também, e tem uma
consequência: **se o seu programa precisa do marcador, acrescente-o você mesmo.** A contagem de
saída ainda inclui o token que disparou a parada. Na execução do café, o `toylm` informou 3 tokens
de saída para os dois mostrados (`yes` e o ponto final), porque escreveu `question` antes de a
conferência tirá-lo.

## Paradas para marcadores de turno

Texto em formato de conversa é o caso comum. Uma transcrição em que cada turno começa com um rótulo,
como `question :` e `answer :`, ou `User:` e `Assistant:`, tem uma parada natural: o rótulo que
começa o turno do outro lado. Aqui o `toylm` é chamado a escrever uma pergunta, e sem parada ele
escreve também a resposta:

```
ana@lab:~/pe$ toylm generate "question :"
is there cake? answer: at six.
-- finish: end, prompt 2 tokens, output 9 tokens
```

Parar no rótulo do próximo turno mantém só o turno que você pediu:

```
ana@lab:~/pe$ toylm generate "question :" --stop answer
is there cake?
-- finish: stop, prompt 2 tokens, output 5 tokens
```

Um modelo que escreve o turno do outro lado está pondo palavras na boca de outra pessoa. Num programa,
esse turno inventado pode ser lido como se o usuário a tivesse dito. Uma parada no rótulo do próximo
turno é uma proteção barata contra isso.

APIs de chat que recebem uma lista de mensagens marcam os turnos com tokens próprios, e terminam o
turno do assistente sem você escrever parada nenhuma. As sequências de parada importam mais quando o
texto que você manda é texto puro com os seus próprios marcadores, e em templates em que um
prompt traz muitos exemplos (lição 21).

## Várias paradas de uma vez

As APIs que aceitam sequências de parada costumam aceitar uma lista curta, e a geração termina na
que aparecer primeiro. No `toylm`, o `--stop` pode ser repetido:

```
ana@lab:~/pe$ toylm generate "question : when does the café open ? answer :" --stop question --stop answer
yes.
-- finish: stop, prompt 10 tokens, output 3 tokens
```

Aqui `question` chegou primeiro. Com as duas ajustadas, uma resposta que começa uma nova pergunta ou
um novo rótulo de resposta é cortada nesse ponto. Cada provedor limita quantas paradas uma
requisição pode levar e qual o tamanho de cada uma; a referência da API diz o que a sua permite.

**Escolha paradas que marquem o fim da unidade que você quer, que não possam aparecer dentro dela, e
teste-as em respostas reais** antes de confiar nelas. Uma parada que você nunca viu disparar não foi
testada, e uma parada que dispara dentro das respostas vai parecer, no motivo de término, igualzinha
a uma que funciona.
