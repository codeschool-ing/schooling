---
title: "Top-p: manter o bastante para chegar a p"
version: 1
---

O top-p, também chamado de **amostragem de núcleo** (*nucleus sampling*), fixa uma fração em vez de
uma contagem. **Ele mantém o menor conjunto de palavras do topo cujas frações somam pelo menos p, e
descarta tudo o que vem depois.** O conjunto mantido é o núcleo, e as frações que sobram são
renormalizadas como no top-k.

Com p igual a 0,8 depois de `the coffee is`:

```
ana@lab:~/pe$ toylm dist "the coffee is" --top-p 0.8
context: trigram after 'coffee is'
  hot       66.7%  ###########################
  strong    20.8%  ########
  ready     12.5%  #####
```

`hot` sozinha é 59,3%, abaixo de 80%. Somando `strong` chega a 77,8%, ainda abaixo. Somando `ready`
chega a 88,9%, e a contagem para aí. Três palavras ficam, e `cold` e `bitter` saem.

## Ele se adapta a quão seguro o modelo está

O mesmo p mantém um número diferente de palavras em lugares diferentes. Onde o modelo está quase
certo:

```
ana@lab:~/pe$ toylm next "the coffee is hot"
context: trigram after 'is hot'
  .         85.0%  ##################################
  and       15.0%  ######
ana@lab:~/pe$ toylm dist "the coffee is hot" --top-p 0.8
context: trigram after 'is hot'
  .        100.0%  ########################################
```

O ponto final tem 85% sozinho, o que já passa de 0,8, então o núcleo é uma palavra e `and` some.
Onde o modelo está dividido:

```
ana@lab:~/pe$ toylm next "and the"
context: trigram after 'and the'
  cat       35.3%  ##############
  coffee    23.5%  #########
  bread     17.6%  #######
  café      11.8%  #####
  terrace   11.8%  #####
ana@lab:~/pe$ toylm dist "and the" --top-p 0.8
context: trigram after 'and the'
  cat       40.0%  ################
  coffee    26.7%  ###########
  bread     20.0%  ########
  café      13.3%  #####
```

São precisas quatro palavras para passar de 80%: 35,3, 58,8, 76,4 e então 88,2. `café` e `terrace`
empataram em 11,8%, e o `toylm` mantém a empatada que vem primeiro na ordem alfabética, a mesma
regra que usa na temperatura 0.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três barras empilhadas com uma linha em 80 por cento. Depois de the coffee is hot: o ponto final tem 85 por cento e cruza a linha sozinho, então uma palavra fica e and, 15 por cento, é cortada. Depois de the coffee is: hot 59,3, strong 18,5 e ready 11,1 são necessárias para cruzar, então três ficam e cold e bitter são cortadas. Depois de and the: cat, coffee, bread e café são necessárias, então quatro ficam e terrace é cortada.\"><text x=\"140\" y=\"53\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">the coffee is hot</text><rect x=\"150\" y=\"40\" width=\"391.0\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"345.5\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"700\" fill=\"var(--paper)\">.</text><rect x=\"541.0\" y=\"40\" width=\"69.0\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 2\"></rect><text x=\"575.5\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and</text><text x=\"618\" y=\"53\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 palavra mantida</text><text x=\"140\" y=\"117\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">the coffee is</text><rect x=\"150\" y=\"104\" width=\"272.8\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"286.4\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">hot</text><rect x=\"422.8\" y=\"104\" width=\"85.1\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"465.3\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">strong</text><rect x=\"507.9\" y=\"104\" width=\"51.1\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"533.4\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ready</text><rect x=\"558.9\" y=\"104\" width=\"34.0\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 2\"></rect><text x=\"576.0\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cold</text><rect x=\"593.0\" y=\"104\" width=\"17.0\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 2\"></rect><text x=\"618\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3 palavras mantidas</text><text x=\"140\" y=\"181\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">and the</text><rect x=\"150\" y=\"168\" width=\"162.4\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"231.2\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">cat</text><rect x=\"312.4\" y=\"168\" width=\"108.1\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"366.4\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">coffee</text><rect x=\"420.5\" y=\"168\" width=\"81.0\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"461.0\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">bread</text><rect x=\"501.4\" y=\"168\" width=\"54.3\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"528.6\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">café</text><rect x=\"555.7\" y=\"168\" width=\"54.3\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 2\"></rect><text x=\"582.9\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">terrace</text><text x=\"618\" y=\"181\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4 palavras mantidas</text><path d=\"M518.0 26 L518.0 38\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M518.0 68 L518.0 102\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M518.0 132 L518.0 166\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M518.0 196 L518.0 222\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"518.0\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">p = 0.8</text><rect x=\"150\" y=\"232\" width=\"12\" height=\"10\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"168\" y=\"237\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mantidas</text><rect x=\"260\" y=\"232\" width=\"12\" height=\"10\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 2\"></rect><text x=\"278\" y=\"237\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cortadas</text></svg>", "caption": "Top-p em 0,8 em três contextos, tirado das tabelas desta seção. Cada barra são as frações do modelo postas uma após a outra; o núcleo é cada palavra até a que cruza a linha."}
```

**Quando o modelo está confiante, o top-p corta fundo; quando está em dúvida, o top-p deixa
espaço.** O top-k não faz nenhuma das duas coisas. Com k = 2 os mesmos dois contextos dão:

```
ana@lab:~/pe$ toylm dist "the coffee is hot" --top-k 2
context: trigram after 'is hot'
  .         85.0%  ##################################
  and       15.0%  ######
ana@lab:~/pe$ toylm dist "and the" --top-k 2
context: trigram after 'and the'
  cat       60.0%  ########################
  coffee    40.0%  ################
```

Depois de `is hot`, o top-k mantém `and`, uma palavra com 15% que o top-p tinha jogado fora. Depois
de `and the` ele descarta `bread` e `café`, que o top-p manteve. Uma contagem fixa é frouxa demais
no primeiro lugar e apertada demais no segundo, e a fração se ajusta sozinha.

O top-p não protege você de toda palavra estranha. Uma palavra dentro do núcleo ainda pode ser
errada para o seu propósito, e um p perto de 1 mantém quase a cauda inteira. Ele tira a cauda longa
de palavras improváveis em cada lugar, que é de onde vem a maior parte da saída estranha.
