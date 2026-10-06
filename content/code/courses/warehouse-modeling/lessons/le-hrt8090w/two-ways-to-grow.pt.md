---
title: Para cima ou para os lados
version: 1
---

Um banco lento demais, ou cheio demais, tem dois jeitos de crescer.

**Escala vertical** (scale up): uma máquina maior. Mais núcleos para trabalhar em paralelo, mais memória
para guardar o que está em uso, discos mais rápidos. O software não muda, os dados não se movem, e toda
consulta que funcionava antes funciona do mesmo jeito, mais rápido.

**Escala horizontal** (scale out): mais máquinas. Os dados são divididos entre elas, cada máquina
trabalha na sua parte, e os resultados são combinados. Aumentar a capacidade significa acrescentar uma
máquina, e em princípio não há limite para quantas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois jeitos de crescer. À esquerda, escalar verticalmente: uma máquina trocada por uma maior, com mais núcleos e memória, os dados sem sair do lugar. À direita, escalar horizontalmente: quatro máquinas, cada uma com um quarto dos dados e trabalhando no seu quarto, com um coordenador juntando as respostas.\"><defs><marker id=\"ah-up-or-out\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">vertical: uma máquina maior</text><text x=\"530\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">horizontal: mais máquinas</text><line x1=\"350\" y1=\"40\" x2=\"350\" y2=\"240\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></line><rect x=\"30\" y=\"110\" width=\"90\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"75\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4 núcleos</text><text x=\"75\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">16 GB</text><line x1=\"125\" y1=\"145\" x2=\"175\" y2=\"145\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-up-or-out)\"></line><rect x=\"180\" y=\"60\" width=\"140\" height=\"170\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"250\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">64 núcleos</text><text x=\"250\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">512 GB</text><text x=\"250\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">todos os dados</text><rect x=\"470\" y=\"50\" width=\"120\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">coordenador</text><line x1=\"530\" y1=\"86\" x2=\"410\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"375\" y=\"150\" width=\"70\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"410\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nó</text><text x=\"410\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">¼</text><line x1=\"530\" y1=\"86\" x2=\"492\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"457\" y=\"150\" width=\"70\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"492\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nó</text><text x=\"492\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">¼</text><line x1=\"530\" y1=\"86\" x2=\"574\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"539\" y=\"150\" width=\"70\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"574\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nó</text><text x=\"574\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">¼</text><line x1=\"530\" y1=\"86\" x2=\"656\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"621\" y=\"150\" width=\"70\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"656\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nó</text><text x=\"656\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">¼</text></svg>", "caption": "Escalar verticalmente troca a máquina; escalar horizontalmente divide os dados entre máquinas.", "same": ["16 GB", "512 GB"]}
```

O laboratório é uma máquina:

```
ana@lab:~/wh$ nproc
4
ana@lab:~/wh$ free -m | head -2
               total        used        free      shared  buff/cache   available
Mem:           16094        1359       11197         348        4182       14734
```

Quatro núcleos e 16 GB de memória. O warehouse da Ana, inteiro, é um arquivo de cerca de 46 MB. **Para
um negócio deste tamanho, escalar verticalmente não é uma decisão que alguém precise tomar ainda.** Essa é a
situação mais comum que existe: um servidor moderno guarda centenas de gigabytes em memória e tem
dezenas de núcleos, mais que o warehouse inteiro da maioria das empresas.

A lição 1 prometeu um número para "pequeno". Aqui está, como regra prática e não como lei: **se os dados
que uma consulta típica lê cabem na memória de uma máquina, uma máquina é a resposta mais simples.** O
resto desta lição é o que muda quando não cabem.
