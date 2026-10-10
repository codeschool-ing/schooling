---
title: O balde de fichas
version: 1
---

**Um balde de fichas (*token bucket*) dá a cada cliente um balde que guarda até um número fixo de
fichas e é reabastecido a uma taxa fixa.** Cada requisição leva uma ficha, e uma requisição que
encontra o balde vazio é recusada. Dois números o descrevem, e eles dizem duas coisas diferentes:

| número | no plano free do `limits.py` | o que ele decide |
|---|---|---|
| **capacidade** | 10 fichas | a maior rajada que um cliente pode mandar de uma vez, depois de ficar quieto |
| **taxa de reposição** | 1 ficha por segundo | o ritmo que um cliente pode manter para sempre |

A divisão importa porque um cliente de verdade é irregular: uma página carrega e pede seis coisas de uma
vez, depois nada por um minuto. Uma janela fixa de uma requisição por segundo recusaria cinco das seis,
enquanto um balde de dez reabastecido a uma por segundo aceita as seis e ainda segura qualquer cliente
em uma por segundo, na média.

## Nada dispara

A imagem errada é a de um temporizador em algum lugar pingando uma ficha no balde de cada cliente uma
vez por segundo. Com um milhão de clientes, são um milhão de temporizadores. Nada dispara: o balde
guarda **quantas fichas tinha e quando olhou pela última vez**, e quando chega uma requisição ele soma o
que o tempo decorrido vale, até a capacidade. Um cliente que ficou quieto por uma hora recebe dez fichas
de volta, não 3.600, porque o balde estava cheio depois de dez segundos.

A mesma conta responde à pergunta que um cliente recusado faz. Com 0,2 ficha no balde e uma requisição
que custa uma, os 0,8 que faltam chegam em 0,8 segundo a uma por segundo, e o `Retry-After` leva
segundos inteiros, então diz `1`.

Vinte e quatro requisições, quatro por segundo, contra um balde novo do plano free. A execução e o
programa que a enviou estão na seção "Uma rajada contra ele"; desenhadas, com as fichas que o servidor
informou depois de cada requisição:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 260\" role=\"img\" aria-label=\"Vinte e quatro requisições, quatro por segundo, contra um balde de dez reabastecido a uma por segundo. As fichas restantes caem de 9 a 0 nos primeiros três segundos, com toda requisição aceita; depois, uma em cada quatro é aceita, uma por segundo. 15 das 24 foram aceitas.\"><line x1=\"80\" y1=\"200\" x2=\"660\" y2=\"200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"80\" y1=\"70\" x2=\"660\" y2=\"70\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><text x=\"660\" y=\"61\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">capacidade 10</text><text x=\"72\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"72\" y=\"135\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"72\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"20\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fichas</text><text x=\"20\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">restantes</text><rect x=\"84.0\" y=\"83\" width=\"12\" height=\"117\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"85.0\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"107.8\" y=\"96\" width=\"12\" height=\"104\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"108.8\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"131.5\" y=\"109\" width=\"12\" height=\"91\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"132.5\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"155.2\" y=\"122\" width=\"12\" height=\"78\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"156.2\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"179.0\" y=\"135\" width=\"12\" height=\"65\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"180.0\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"202.8\" y=\"135\" width=\"12\" height=\"65\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"203.8\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"226.5\" y=\"148\" width=\"12\" height=\"52\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"227.5\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"250.2\" y=\"161\" width=\"12\" height=\"39\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"251.2\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"274.0\" y=\"174\" width=\"12\" height=\"26\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"275.0\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"297.8\" y=\"174\" width=\"12\" height=\"26\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"298.8\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"321.5\" y=\"187\" width=\"12\" height=\"13\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"322.5\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"347.2\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"370.9\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"394.7\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"418.4\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"442.2\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"465.9\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"489.7\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"513.5\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"537.2\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"561.0\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"584.7\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"608.4\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"632.2\" y=\"206\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"90\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><text x=\"185\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1 s</text><text x=\"280\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2 s</text><text x=\"375\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3 s</text><text x=\"470\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4 s</text><text x=\"565\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5 s</text><text x=\"660\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6 s</text><text x=\"223.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">a rajada guardada</text><text x=\"517.5\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">depois uma por segundo: a taxa de reposição</text><rect x=\"90\" y=\"240\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"108\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aceita</text><rect x=\"200\" y=\"240\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"218\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">recusada</text></svg>", "caption": "A capacidade pagou a rajada; a taxa de reposição decidiu o resto. 15 de 24 aceitas."}
```

As primeiras requisições são pagas com as dez fichas guardadas, enquanto a reposição soma um quarto de
ficha entre uma e outra, e é por isso que a contagem cai menos de uma por requisição. Com o balde
vazio, o cliente que manda quatro por segundo consegue passar uma delas a cada segundo, que é a taxa de
reposição. **A capacidade pagou a rajada; a taxa decidiu tudo depois dela.**

Uma requisição não precisa custar uma ficha. O `limits.py` cobra cinco por uma busca, que é como um
único limite cobre endpoints de custos muito diferentes; a seção sobre cotas e custos mede isso.

## O balde furado, o espelho dele

O **balde furado** (*leaky bucket*) é a mesma imagem virada ao contrário. As requisições entram no
balde, e ele esvazia a uma taxa fixa; uma requisição que chega com o balde cheio é recusada. Usado só
para decidir entre aceitar e recusar, é o balde de fichas contado pela outra ponta, e aceita as mesmas
requisições.

O outro jeito de usá-lo é como **fila**: as requisições aceitas esperam no balde e são repassadas na
taxa de vazão, então uma rajada sai do outro lado espaçada por igual, mais lenta mas não recusada. Isso
suaviza o que chega à aplicação ao preço de atraso, e é o que um proxy na frente da API costuma fazer.
O Nginx descreve a própria limitação de requisições como um balde furado, e o `servers-cache`, o
próximo curso, a configura.

| | balde de fichas | balde furado como fila |
|---|---|---|
| uma rajada dentro da capacidade | passa na hora | espera, e sai na taxa de vazão |
| o que um cliente acima do limite vê | `429` | atraso primeiro, depois `429` quando a fila enche |
| estado por cliente | fichas e uma hora | uma fila de requisições esperando |
