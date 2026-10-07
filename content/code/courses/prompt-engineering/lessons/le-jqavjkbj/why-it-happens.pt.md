---
title: Provável não é o mesmo que verdadeiro
version: 2
---

A palavra "alucinação" faz parecer um defeito: algo no modelo dá errado de vez em quando, e ele
começa a ver coisas. **Uma alucinação é o modelo fazendo exatamente o que sempre faz, escrever a
continuação mais provável, num momento em que a continuação mais provável é falsa.** As respostas
certas e as inventadas saem do mesmo passo, e é por isso que o texto sozinho não diz qual das duas
você recebeu.

A lição 1 mostrou isso com uma frase, `the coffee is cold and the cat wakes`: cada par de
palavras dela veio do arquivo, e a frase inteira não veio de lugar nenhum. Mais duas perguntas ao
`toylm` mostram as duas formas comuns do problema.

## Várias respostas confiantes para uma pergunta

O café tem uma sopa do dia, e o arquivo de onde o `toylm` aprendeu menciona três. Pergunte cinco
vezes:

```
ana@lab:~/pe$ toylm generate "the soup of the day is" --samples 5
[seed 1] tomato. question: is the coffee is hot.
[seed 2] pumpkin.
[seed 3] tomato.
[seed 4] tomato.
[seed 5] lentil.
```

Tomate três vezes, abóbora uma, lentilha uma, e cada uma dita sem rodeios, sem nada que diga "não
tenho certeza". As notas explicam:

```
ana@lab:~/pe$ toylm next "the soup of the day is"
context: trigram after 'day is'
  tomato    50.0%  ####################
  lentil    25.0%  ##########
  pumpkin   25.0%  ##########
```

**Cada uma dessas respostas é provável, e nenhuma é sabida.** O arquivo diz qual foi a sopa em
vários dias; nada nele diz qual é a sopa hoje, e nada no modelo poderia dizer. Quando você pergunta
a um modelo grande sobre algo que muda, como um preço, a versão mais recente de uma biblioteca ou
quem ocupa um cargo, ele está na mesma posição. Ele consegue dizer o que era comum no texto de onde
aprendeu, escrito no presente.

## Uma resposta confiante a uma pergunta que ninguém respondeu

Agora pergunte sobre algo que o arquivo nunca menciona:

```
ana@lab:~/pe$ toylm next "the owner of the café is"
context: trigram after 'café is'
  full     100.0%  ########################################
ana@lab:~/pe$ grep -c owner corpus.txt
0
```

A palavra `owner` não aparece nenhuma vez no corpus, e o modelo dá à resposta uma nota de 100%.
Olhe a linha de contexto: a janela tinha `café is`, e no arquivo `café is` é sempre seguido de
`full`. **Os 100% medem quão consistente o arquivo é depois dessas duas palavras**, e não dizem
nada sobre a resposta ter a ver com donos. Um modelo grande vê a pergunta inteira, então não cairia
nesse buraco em particular. Ainda assim, ele produz uma resposta fluente pela mesma regra sempre que
a resposta honesta seria "nada do que li diz isso".

## As formas que isso toma nos modelos grandes

O mesmo mecanismo produz várias falhas conhecidas:

| o que você pede | o que pode voltar | por que é provável |
|---|---|---|
| um fato raro no texto de treino | um fato plausível sobre algo parecido | o padrão comum ganha do fato raro |
| um fato que mudou | o valor antigo, no presente | o valor antigo estava em muito mais texto |
| a resposta a uma pergunta com premissa falsa | uma resposta que aceita a premissa | texto que responde a uma pergunta é mais provável que texto que a contesta |
| uma fonte, um link, um número de página | **uma que tem o formato certo e não existe** | citações seguem um padrão, e o padrão é fácil de continuar |

A última linha é a que já envergonhou gente em público, porque uma citação inventada parece
exatamente uma de verdade. Peça uma ao modelo local:

```
ana@lab:~/pe$ ask "Is there research showing that coffee improves memory? Cite one study: authors, year, title, journal, volume and pages." --temperature 0
Yes, there is research showing that coffee can improve memory. Here's a study that supports this claim:

Cote, K. A., et al. (2012). "Caffeine and caffeine analogs: effects on cognition and mood." Journal of Psychopharmacology, 26(1), 15-25.

This study found that caffeine, a key component of coffee, improved alertness and cognitive performance, including memory, in a group of healthy adults. The researchers used a double-blind, placebo-controlled design to investigate the effects of caffeine on cognitive function, and found that caffeine improved performance on a memory task, particularly in the short-term memory domain.

Please note that individual results may vary, and more research is needed to fully understand the relationship between coffee consumption and memory.
-- llama3.2:3b, finish: stop, prompt 51 tokens, output 160 tokens
```

O Journal of Psychopharmacology existe. Uma busca por esse título, no dia em que esta lição foi
gravada, não achou artigo nenhum, e os autores, o volume e as páginas têm a cara comum de qualquer
referência ao lado deles. **Nada na resposta diz se ela foi inventada.** É esse o ponto: um modelo
produz a forma de uma citação com a mesma fluência com que produz a forma de uma frase, e a forma é
tudo o que você vê. O único jeito de saber é procurar, e é isso que a próxima seção manda fazer.

## Por que é difícil eliminar com treino

Os modelos por trás dos assistentes de chat recebem treino adicional para serem úteis (lição 1), e
uma resposta parece mais útil que "não sei". Quem os faz também os treina para admitir incerteza, e
os modelos melhoraram bastante nisso; o problema diminui e não desaparece, porque o modelo não tem
um depósito separado de fatos para consultar antes de escrever. **O que ele sabe e o que ele acha
provável são a mesma coisa dentro dele.** Por isso os remédios da próxima seção não pedem ao modelo
que se esforce mais. Eles mudam o que ele recebe, e conferem o que ele devolve.
