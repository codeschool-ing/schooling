---
title: Temperatura
version: 1
---

**A temperatura divide cada pontuação antes do softmax.** Abaixo de 1 ela estica as distâncias entre
as pontuações, e a candidata do topo fica com mais probabilidade. Acima de 1 ela as encolhe, e a
cauda ganha mais. Estas são as mesmas oito pontuações em 0.2 e em 1.5:

```
ana@lab:~/triage$ pl sample --temperature 0.2
Your parcel is ___   temperature 0.2, top-k off, top-p 1, 1000 draws
  on         92.2%    914  #####################################
  delayed     7.6%     85  ###
  here        0.2%      1  
  lost        0.0%      0  
  ready       0.0%      0  
  wet         0.0%      0  
  singing     0.0%      0  
  purple      0.0%      0  
ana@lab:~/triage$ pl sample --temperature 1.5
Your parcel is ___   temperature 1.5, top-k off, top-p 1, 1000 draws
  on         35.3%    386  ##############
  delayed    25.3%    248  ##########
  here       15.9%    135  ######
  lost        9.9%     90  ####
  ready       8.7%     86  ###
  wet         3.4%     44  #
  singing     0.8%      7  
  purple      0.6%      4  
```

Em 0.2 a distância de meio ponto entre `on` e `delayed` vira uma distância de 2,5, e *e* elevado a
2,5 dá cerca de 12, que é a razão entre 92.2% e 7.6%. Cinco das oito palavras agora têm uma
probabilidade que arredonda para zero. Em 1.5 a mesma distância encolhe para um terço de ponto, e
`on` cai para 35.3%. **Achatar dá chance também ao absurdo**: `singing` e `purple` saíram 7 e 4
vezes em mil.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 272\" role=\"img\" aria-label=\"A probabilidade de cada uma de oito próximas palavras depois de &#x27;Your parcel is&#x27;, em duas temperaturas. Em 0.2: on 92,2%, delayed 7,6%, here 0,2%, o resto quase zero. Em 1.5: on 35,3%, delayed 25,3%, here 15,9%, lost 9,9%, ready 8,7%, wet 3,4%, singing 0,8%, purple 0,6%.\"><path d=\"M74 240 L700 240\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"68\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0%</text><text x=\"68\" y=\"145.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">50%</text><path d=\"M74 145.0 L700 145.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"68\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">100%</text><path d=\"M74 50.0 L700 50.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">probabilidade</text><rect x=\"90\" y=\"64.8308961109781\" width=\"22\" height=\"175.1691038890219\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"116\" y=\"172.9154293311659\" width=\"22\" height=\"67.08457066883409\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"114\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">on</text><rect x=\"166\" y=\"225.62124434832006\" width=\"22\" height=\"14.37875565167995\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"192\" y=\"191.93180465938033\" width=\"22\" height=\"48.06819534061967\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"190\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">delayed</text><rect x=\"242\" y=\"239.4\" width=\"22\" height=\"0.6\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"268\" y=\"209.85695935312424\" width=\"22\" height=\"30.143040646875765\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"266\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">here</text><rect x=\"318\" y=\"239.4\" width=\"22\" height=\"0.6\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"344\" y=\"221.09762821340212\" width=\"22\" height=\"18.90237178659787\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"342\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lost</text><rect x=\"394\" y=\"239.4\" width=\"22\" height=\"0.6\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"420\" y=\"223.45714854573936\" width=\"22\" height=\"16.542851454260628\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"418\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ready</text><rect x=\"470\" y=\"239.4\" width=\"22\" height=\"0.6\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"496\" y=\"233.49467716890442\" width=\"22\" height=\"6.505322831095588\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"494\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">wet</text><rect x=\"546\" y=\"239.4\" width=\"22\" height=\"0.6\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"572\" y=\"238.3958071403918\" width=\"22\" height=\"1.6041928596081882\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"570\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">singing</text><rect x=\"622\" y=\"239.4\" width=\"22\" height=\"0.6\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"648\" y=\"238.85054558789184\" width=\"22\" height=\"1.14945441210817\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"646\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">purple</text><rect x=\"420\" y=\"16\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"438\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">temperatura 0.2</text><rect x=\"570\" y=\"16\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"588\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">temperatura 1.5</text></svg>", "caption": "As mesmas oito pontuações, divididas por duas temperaturas. Em 0.2 quase todo sorteio é a palavra do topo; em 1.5 a cauda ganha chances reais, inclusive palavras sem sentido."}
```

Temperatura 0 não dá para calcular assim, já que nada se divide por zero, então ela é definida como
o limite: ficar sempre com a candidata do topo, sem sorteio nenhum. É o que o substituto faz em 0,
que é o padrão do `pl run`. O `pl sample` só aceita temperaturas acima de 0, porque mostra o
sorteio.

**O número é relativo às pontuações que ele divide.** No substituto as pontuações das categorias de
uma mensagem muitas vezes ficam a menos de um ponto umas das outras, então uma temperatura de 1 é
muita aleatoriedade ali. Em outro modelo, a mesma configuração não promete a mesma quantidade, e o
jeito de saber é medir na sua tarefa, como faz a última seção desta aula.
