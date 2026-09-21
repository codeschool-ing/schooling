---
title: Um interpretador lê o seu arquivo, uma linha por vez
version: 1
---

Você escreve um arquivo. Um programa chamado **interpretador** lê esse arquivo e faz o que ele diz.
É esse o arranjo inteiro, e o nome do interpretador do Python é `python3`.

Algumas linguagens fazem diferente. C e Go são **compiladas**: um programa à parte transforma o seu
arquivo em instruções de máquina uma vez, e o que você distribui é o resultado. Python é
**interpretada**: não existe resultado à parte, e o `python3` lê o seu arquivo toda vez que ele roda.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 215\" role=\"img\" aria-label=\"Uma linguagem compilada transforma o seu arquivo num programa de máquina uma vez, com um compilador no meio, e o que roda depois é esse programa. Python não tem resultado à parte: o interpretador lê o seu arquivo toda vez que o programa roda.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"20\" y=\"20\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">compilada — C, Go</text> <rect x=\"20\" y=\"30\" width=\"144.5\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"92.25\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o seu arquivo</text> <rect x=\"198.5\" y=\"30\" width=\"144.5\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"270.75\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um compilador</text> <path d=\"M170.5 52 L192.5 52\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"377\" y=\"30\" width=\"144.5\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"449.25\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um programa de máquina</text> <path d=\"M349 52 L371 52\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"555.5\" y=\"30\" width=\"144.5\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"627.75\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">ele roda</text> <path d=\"M527.5 52 L549.5 52\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"20\" y=\"110\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">interpretada — Python</text> <rect x=\"20\" y=\"120\" width=\"186.667\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"113.333\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o seu arquivo</text> <rect x=\"266.667\" y=\"120\" width=\"186.667\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o python3 lê</text> <path d=\"M212.667 142 L260.667 142\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"513.333\" y=\"120\" width=\"186.667\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"606.667\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">ele roda</text> <path d=\"M459.333 142 L507.333 142\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">A caixa do meio da linha de cima é a que o Python não tem.</text> </svg>", "caption": "A linha de cima acontece uma vez. A linha do Python acontece a cada execução, e é isso que interpretada quer dizer."}
```

## O que isso compra

**Dá para rodar um programa pela metade.** O interpretador lê até o ponto onde quebra e avisa, o que
significa descobrir a linha 4 sem precisar deixar a linha 40 correta antes. Numa linguagem compilada
nada roda enquanto tudo não compilar.

**E dá para conversar com ele direto**, que é a próxima seção.

## O que custa

**Velocidade.** Um laço que soma dez milhões de números leva cerca de um segundo em Python e cerca
de dez milissegundos em C. Isso soa fatal e não é, por um motivo que vale entender agora:

> O Python que você vai escrever para dados passa quase todo o tempo dentro de bibliotecas que não
> são escritas em Python. `pandas` e `numpy` são C por baixo. O seu código é a camada fina que diz o
> que fazer; a aritmética acontece em outro lugar, rápido.

A aula 20 é onde isso fica preciso. Por ora: Python é lenta para aritmética e quase nunca é ela que
deixa o seu programa lento.

**E os erros chegam tarde.** Um nome escrito errado num ramo que ninguém tomou é um problema que se
encontra em produção em vez de na compilação. É esse o buraco de que as aulas 14 a 16 tratam —
anotações e um verificador que as lê, que é o aviso prévio de um compilador aparafusado de volta por
escolha.

## Onde ela roda de fato

O mesmo arquivo roda em Linux, macOS e Windows, porque o que muda é o interpretador e não o arquivo.
É uma promessa real e tem uma borda famosa — caminhos, que a aula 9 resolve com `pathlib`
exatamente por isso.
