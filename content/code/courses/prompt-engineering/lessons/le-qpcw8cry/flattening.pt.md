---
title: Dividir as notas por um número
version: 1
---

A temperatura costuma ser descrita como um botão de criatividade: aumente e o modelo fica mais
imaginativo, diminua e ele fica mais cuidadoso. Essa imagem serve para o uso e erra no que se mexe.
**A temperatura não muda nada do que o modelo sabe. Ela remodela as probabilidades que o modelo
deu, logo antes de uma palavra ser sorteada delas.** As palavras continuam as mesmas; só mudam as
frações que cada uma recebe.

A lição 1 mostrou o `toylm next`, que imprime as probabilidades do próprio modelo. O `toylm dist`
imprime a mesma tabela depois de aplicados os controles de amostragem, então você vê de onde um
sorteio sairia de fato. Na temperatura 1 nada muda:

```
ana@lab:~/pe$ toylm dist "the coffee is" --temperature 1
context: trigram after 'coffee is'
  hot       59.3%  ########################
  strong    18.5%  #######
  ready     11.1%  ####
  cold       7.4%  ###
  bitter     3.7%  #
```

Com metade da temperatura, a primeira colocada se distancia:

```
ana@lab:~/pe$ toylm dist "the coffee is" --temperature 0.5
context: trigram after 'coffee is'
  hot       86.8%  ###################################
  strong     8.5%  ###
  ready      3.1%  #
  cold       1.4%  #
  bitter     0.3%  
```

Com o dobro, o pelotão se aproxima:

```
ana@lab:~/pe$ toylm dist "the coffee is" --temperature 2
context: trigram after 'coffee is'
  hot       38.5%  ###############
  strong    21.5%  #########
  ready     16.7%  #######
  cold      13.6%  #####
  bitter     9.6%  ####
```

As três tabelas têm as mesmas cinco palavras na mesma ordem. **A classificação nunca muda; mudam as
distâncias entre as posições.** Em 0,5, `hot` fica com 86,8% e `bitter` cai para 0,3%, uma
palavra que sairia umas três vezes em mil sorteios. Em 2, `bitter` tem 9,6%, mais ou menos um
sorteio em dez.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Três gráficos de barras da próxima palavra depois de the coffee is. Na temperatura 0,5: hot 86,8 por cento, strong 8,5, ready 3,1, cold 1,4, bitter 0,3. Na temperatura 1: hot 59,3, strong 18,5, ready 11,1, cold 7,4, bitter 3,7. Na temperatura 2: hot 38,5, strong 21,5, ready 16,7, cold 13,6, bitter 9,6.\"><rect x=\"10\" y=\"10\" width=\"225\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"122\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">--temperature 0.5</text><text x=\"122\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mais pontuda</text><text x=\"22\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hot</text><rect x=\"74\" y=\"72\" width=\"95.5\" height=\"14\" fill=\"var(--phosphor)\"></rect><text x=\"175.48000000000002\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">86.8%</text><text x=\"22\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">strong</text><rect x=\"74\" y=\"102\" width=\"9.3\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"89.35\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8.5%</text><text x=\"22\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ready</text><rect x=\"74\" y=\"132\" width=\"3.4\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"83.41\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3.1%</text><text x=\"22\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cold</text><rect x=\"74\" y=\"162\" width=\"1.5\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"81.54\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.4%</text><text x=\"22\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bitter</text><rect x=\"74\" y=\"192\" width=\"1\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"80.33\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.3%</text><rect x=\"247\" y=\"10\" width=\"225\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"359\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">--temperature 1</text><text x=\"359\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">as frações do próprio modelo</text><text x=\"259\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hot</text><rect x=\"311\" y=\"72\" width=\"65.2\" height=\"14\" fill=\"var(--phosphor)\"></rect><text x=\"382.23\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">59.3%</text><text x=\"259\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">strong</text><rect x=\"311\" y=\"102\" width=\"20.4\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"337.35\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18.5%</text><text x=\"259\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ready</text><rect x=\"311\" y=\"132\" width=\"12.2\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"329.21\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">11.1%</text><text x=\"259\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cold</text><rect x=\"311\" y=\"162\" width=\"8.1\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"325.14\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7.4%</text><text x=\"259\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bitter</text><rect x=\"311\" y=\"192\" width=\"4.1\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"321.07\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3.7%</text><rect x=\"484\" y=\"10\" width=\"225\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"596\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">--temperature 2</text><text x=\"596\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mais achatada</text><text x=\"496\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hot</text><rect x=\"548\" y=\"72\" width=\"42.4\" height=\"14\" fill=\"var(--phosphor)\"></rect><text x=\"596.35\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">38.5%</text><text x=\"496\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">strong</text><rect x=\"548\" y=\"102\" width=\"23.6\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"577.65\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">21.5%</text><text x=\"496\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ready</text><rect x=\"548\" y=\"132\" width=\"18.4\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"572.37\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16.7%</text><text x=\"496\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cold</text><rect x=\"548\" y=\"162\" width=\"15.0\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"568.96\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">13.6%</text><text x=\"496\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bitter</text><rect x=\"548\" y=\"192\" width=\"10.6\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"564.56\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">9.6%</text></svg>", "caption": "As mesmas cinco palavras depois de “the coffee is” em três temperaturas, tiradas das três tabelas acima. A ordem nunca muda; muda a distância entre a primeira palavra e as outras."}
```

## O que o número faz

Um modelo não calcula porcentagens primeiro. Ele calcula uma nota para cada palavra, chamada
**logit**, e as porcentagens saem dessas notas por um passo fixo: elevar *e* a cada nota e dividir
pelo total, para que as frações somem 100%. A temperatura entra no meio. **Cada nota é dividida pela
temperatura antes de as porcentagens serem calculadas.**

Dividir por um número menor que 1 aumenta todas as notas, e as diferenças entre elas junto, então a
fração da palavra do topo cresce. Dividir por um número maior que 1 encolhe as diferenças, e as
frações andam na direção de ficarem iguais. Nas tabelas acima, `hot` era 3,2 vezes mais provável
que `strong` na temperatura 1 (59,3% contra 18,5%). Em 0,5 é umas dez vezes mais provável (86,8%
contra 8,5%), porque cortar a temperatura pela metade eleva essa razão ao quadrado.

O `toylm` faz exatamente isso. As notas dele são os logaritmos das contagens, e a função que aplica
os controles as divide pela temperatura antes de transformá-las de volta em frações. As notas de
um modelo grande vêm dos pesos em vez de contagens, e a divisão é a mesma.

## Os dois extremos

Há dois valores nas pontas, e vale conhecer os dois porque os dois são usados.

- Conforme a temperatura cai para 0, a fração da palavra do topo vai para 100%. No 0 em si a
  divisão não existe, então as implementações tratam o caso como uma regra à parte: pegar a
  palavra do topo. Esse é o assunto da próxima seção.
- Conforme a temperatura sobe, toda palavra que tinha alguma nota vai para uma fração igual. Uma
  palavra a que o modelo deu 0,3% ganha tantos sorteios quanto a que recebeu 86,8%.

**Nenhum dos extremos acrescenta uma palavra que o modelo não pontuou.** O `toylm` nunca vai dizer
`sweet` depois de `coffee is`, em temperatura nenhuma, porque `sweet` nunca veio depois dessas duas
palavras no arquivo dele. Um modelo grande dá nota a todos os tokens do vocabulário, então numa
temperatura alta os raros e estranhos ganham uma chance de verdade, e é daí que vem o disparate.
