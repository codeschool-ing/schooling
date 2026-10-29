---
title: O que a primeira pintura espera
version: 1
---

**Um navegador não pinta assim que o HTML chega.** Ele lê o HTML, descobre do que a página precisa, e
pinta quando tem as coisas sem as quais não deve pintar. A corrente do primeiro byte até a primeira
pintura se chama **caminho crítico de renderização**, e tudo nela é uma requisição que a pessoa espera
antes de ver qualquer coisa.

| no caminho | por que segura a pintura |
|---|---|
| **o HTML** | nada existe antes dele |
| **folhas de estilo no head** | uma página pintada sem o CSS seria desenhada duas vezes, a segunda de outro jeito, então o navegador espera toda folha de estilo antes |
| **scripts no head sem `defer`, `async` ou `type="module"`** | o navegador para de ler o HTML até um script desses ser baixado e rodado, porque ele pode escrever na página |
| **uma fonte, para o texto que a usa** | conforme o `font-display`, o texto não é desenhado até a fonte chegar, ou é desenhado duas vezes |

**Fora do caminho**: imagens, scripts com `defer`, `async` ou `type="module"`, que é o que o Vite escreve,
e o que um script busca depois. Eles ainda podem decidir o LCP, como o aviso do planner na aula 5, mas a
primeira pintura não espera por eles.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Requisições ao longo do tempo, enquanto uma página carrega. O HTML vem primeiro. A folha de estilo é pedida quando o HTML a cita, e a primeira pintura espera por ela. A fonte só é pedida depois que a folha de estilo chegou, e o texto que a usa espera pela fonte. O script módulo e a imagem são pedidos junto com a folha de estilo, e a primeira pintura não espera por nenhum dos dois.\"><text x=\"158\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o HTML</text><rect x=\"170\" y=\"30\" width=\"150\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"158\" y=\"72\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">folha de estilo</text><rect x=\"320\" y=\"62\" width=\"150\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"158\" y=\"104\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fonte</text><rect x=\"470\" y=\"94\" width=\"150\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"158\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">script módulo</text><rect x=\"320\" y=\"126\" width=\"194.99999999999997\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"158\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">imagem</text><rect x=\"320\" y=\"158\" width=\"240.0\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><line x1=\"470\" y1=\"22\" x2=\"470\" y2=\"196\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></line><text x=\"470\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">primeira pintura</text><line x1=\"620\" y1=\"22\" x2=\"620\" y2=\"196\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"620\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">texto na sua fonte</text><rect x=\"170\" y=\"228\" width=\"12\" height=\"12\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"188\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no caminho crítico</text><rect x=\"370\" y=\"228\" width=\"12\" height=\"12\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"388\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fora dele</text></svg>", "caption": "Cada degrau do caminho é uma ida e volta que a pessoa espera sem ver nada."}
```

## O que esta aula faz a respeito

O planner está para ganhar as duas coisas de que a maioria das páginas é feita: uma imagem e uma
tipografia. Cada uma começa como um projeto de verdade começa, com o arquivo que um designer entrega, e
cada uma é medida, diminuída e medida de novo:

- **a imagem** é a maior coisa de uma página, então costuma ser o LCP. O tamanho, o formato, as
  dimensões e a prioridade dela são quatro correções separadas, e o Lighthouse acha as quatro.
- **a fonte** está no caminho crítico do texto. O que acontece enquanto ela carrega é uma escolha, e as
  duas escolhas têm um custo que a pessoa vê.
- **a folha de estilo** está no caminho de tudo. A última correção a tira de lá.
