---
title: Escrever uma frase uma palavra por vez
version: 1
---

Uma probabilidade para a próxima palavra ainda não é uma frase. **A geração é um laço em volta
desse passo**: dar nota à próxima palavra, escolher uma, juntá-la ao fim do texto e dar notas de novo
com o texto mais longo. Ela para quando o modelo escolhe a palavra que significa "acabou", ou quando
chega a um limite que alguém definiu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um laço. O texto até aqui, the café opens at, entra no modelo. O modelo dá uma probabilidade para cada próxima palavra: seven 75 por cento, eight 25 por cento. Uma é escolhida, seven, e ela é juntada ao texto, que volta ao modelo para o próximo passo.\"><defs><marker id=\"gen-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o texto até aqui</text><text x=\"105\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">the café opens at</text><path d=\"M190 75 L238 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gen-ah)\"></path><rect x=\"240\" y=\"40\" width=\"110\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"295\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o modelo</text><path d=\"M350 75 L398 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gen-ah)\"></path><rect x=\"400\" y=\"20\" width=\"180\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"490\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma probabilidade para cada palavra</text><text x=\"430\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">seven</text><rect x=\"475\" y=\"59\" width=\"75\" height=\"14\" fill=\"var(--phosphor)\"></rect><text x=\"555\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">75%</text><text x=\"430\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">eight</text><rect x=\"475\" y=\"89\" width=\"25\" height=\"14\" fill=\"var(--phosphor)\"></rect><text x=\"505\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">25%</text><path d=\"M580 75 L618 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gen-ah)\"></path><rect x=\"620\" y=\"40\" width=\"85\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"662\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">escolhe uma</text><text x=\"662\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">seven</text><path d=\"M662 110 L662 200 L105 200 L105 112\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gen-ah)\"></path><text x=\"383\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">junta ao texto e pergunta de novo</text><text x=\"383\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">the café opens at seven</text></svg>", "caption": "Um passo da geração. O modelo nunca escreve uma frase: ele pontua a próxima palavra, uma palavra é escolhida e o texto mais longo volta a entrar."}
```

O `toylm generate` roda esse laço. Com `--temperature 0` ele sempre escolhe a palavra de nota mais
alta, que é a regra mais simples que existe:

```
ana@lab:~/pe$ toylm generate "the café opens at" --temperature 0
seven.
-- finish: end, prompt 4 tokens, output 2 tokens
```

Saíram duas palavras, `seven` e o ponto final, e então o modelo escolheu o fim. Dá para ver o
segundo passo sozinho dando a ele o texto mais longo:

```
ana@lab:~/pe$ toylm next "the café opens at seven"
context: trigram after 'at seven'
  .        100.0%  ########################################
```

A última linha do `generate` é a contabilidade que toda API de modelo devolve de alguma forma: **por
que ele parou**, e quantos tokens entraram e saíram. `end` quer dizer que o modelo escolheu parar. A
lição 15 trata do outro motivo, um limite, e a lição 3 de por que uma contagem de tokens é o que você
paga.

## O que o modelo consegue ver

O `toylm` olha as duas últimas palavras e nada mais, e isso aparece no que ele escreve:

```
ana@lab:~/pe$ toylm next "the cat sat on the"
context: trigram after 'on the'
  chair     50.0%  ####################
  mat       33.3%  #############
  counter   16.7%  #######
ana@lab:~/pe$ toylm generate "the cat sat on the" --temperature 0
chair by the window.
-- finish: end, prompt 5 tokens, output 5 tokens
```

O arquivo com que ele aprendeu diz `the cat sat on the mat` duas vezes. Também diz `the cat sleeps
on the chair` três vezes, e **quando o `toylm` chega em `on the`, a palavra `sat` já saiu de
vista**. Então a cadeira ganha, três contra dois, e a frase sobre o gato sentado termina na cadeira
onde o gato dorme.

A janela de um modelo grande é enorme em comparação, e ele falha do mesmo jeito na borda dela: um
texto que ficou fora da janela, ou que está enterrado no meio de uma janela muito longa, não tem voz
no que vem a seguir. A lição 4 trata dessa janela.

## Escolher nem sempre é pegar a palavra do topo

Pegar sempre a nota mais alta dá o mesmo texto toda vez, e não é o que os assistentes de chat fazem
por padrão. Eles **sorteiam** uma palavra, em proporção às notas: `hot` sai mais ou menos seis vezes
em dez, `bitter` mais ou menos uma vez em vinte e sete. Cinco sorteios, cada um começando de uma
semente aleatória diferente:

```
ana@lab:~/pe$ toylm generate "the coffee is" --samples 5
[seed 1] hot.
[seed 2] cold and the cat wakes.
[seed 3] hot.
[seed 4] hot.
[seed 5] strong.
```

Três dos cinco são a resposta provável e dois não, que é mais ou menos o que 59,3% prevê. O segundo
merece ser lido duas vezes. **`the coffee is cold and the cat wakes` (o café está frio e o gato
acorda) é gramatical, cada par de palavras dela aparece no arquivo**, e nada no arquivo diz isso. O
modelo escreveu uma frase fluente sem nenhum fato por trás, porque fluência é o que ele foi feito
para produzir.

Essa linha é a semente de três lições adiante. A lição 13 controla o quanto o sorteio é ousado, a
lição 14 corta as palavras improváveis antes do sorteio, e a lição 5 explica por que uma resposta
fluente e uma resposta correta são coisas diferentes.

## De continuar texto a responder perguntas

O `toylm` continua texto. Um assistente de chat parece fazer outra coisa: ele responde. A distância
é menor do que parece. **Uma conversa também é um texto**, com as vezes de cada um marcadas: quem
falou, e o que disse. O modelo recebe esse texto e precisa do próximo pedaço, que é a vez do
assistente.

O que faz desse próximo pedaço uma resposta útil, e não outra pergunta no mesmo estilo, é mais
treinamento depois do primeiro. O modelo é treinado de novo com muitas conversas em que a vez do
assistente é uma boa resposta, e depois ajustado com o julgamento de pessoas sobre quais respostas
eram melhores. Depois disso, **a continuação mais provável de uma pergunta é uma resposta a ela**. O
mecanismo não mudou; o que mudou foi o que ele aprendeu a achar provável.
