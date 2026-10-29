---
title: "CLS: se a página fica parada"
version: 1
---

**O Cumulative Layout Shift mede quanto conteúdo visível se mexeu, sem a pessoa causar isso, ao longo
da vida da página.** É a métrica do botão que se mexeu bem na hora em que alguém o tocou, e do
parágrafo que pulou uma linha para baixo enquanto alguém o lia. Um deslocamento causado pela pessoa,
como abrir um menu que ela tocou, não conta: qualquer coisa a até meio segundo de uma interação é
perdoada.

## Como um deslocamento recebe nota

Cada deslocamento recebe uma nota de duas frações multiplicadas:

- **impacto**: quanto da janela o conteúdo que se mexeu cobria, antes e depois do movimento juntos;
- **distância**: quanto ele se moveu, como fração do lado maior da janela.

Um conteúdo que cobre metade da janela e desce um décimo dela tira por volta de 0,05. O mesmo
movimento cobrindo a janela inteira tira por volta de 0,1. Então **o mesmo deslocamento tira nota
maior numa tela pequena**, onde o conteúdo que se mexe cobre mais da janela e a distância é uma parte
maior dela. A seção "Um deslocamento de layout, criado e removido" mede com uma janela do tamanho de
um celular por isso.

Os deslocamentos são agrupados em **janelas**: deslocamentos a menos de um segundo um do outro entram
na mesma janela, e uma janela dura no máximo cinco segundos. O CLS é a nota da pior janela, então uma
página que carrega com uma única rajada de movimento é julgada por essa rajada, por mais tempo que
fique aberta depois.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Deslocamentos de layout ao longo de uma linha do tempo, cada um desenhado como uma barra cuja altura é a sua nota. Deslocamentos a menos de um segundo um do outro pertencem à mesma janela, e uma janela dura no máximo cinco segundos. Duas janelas estão desenhadas; o CLS é o total da pior.\"><line x1=\"40\" y1=\"140\" x2=\"690\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"690.0,140.0 682.6,143.1 682.6,136.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"690\" y=\"158\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">segundos</text><rect x=\"71.0\" y=\"110\" width=\"10\" height=\"30\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"101.0\" y=\"122\" width=\"10\" height=\"18\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"143.0\" y=\"100\" width=\"10\" height=\"40\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"419.0\" y=\"118\" width=\"10\" height=\"22\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"455.0\" y=\"128\" width=\"10\" height=\"12\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"64.0\" y=\"40\" width=\"102.0\" height=\"105\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"115.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">janela 1: a pior</text><rect x=\"412.0\" y=\"60\" width=\"66.0\" height=\"85\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"445.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">janela 2</text><text x=\"40\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"160\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"280\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"400\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"520\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8</text><text x=\"640\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"280\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mais de um segundo sem deslocamento fecha uma janela</text></svg>", "caption": "O CLS é a pior rajada de movimento, não a soma de todo deslocamento que a página já fez."}
```

**O limite é 0,1 para bom e 0,25 para ruim.** As causas comuns são todas coisas que chegam tarde e
ocupam um espaço que ninguém guardou para elas: uma imagem sem largura e altura (aula 7), uma fonte
que troca para um tamanho diferente (aula 7), um anúncio, e, no planner, um aviso.
