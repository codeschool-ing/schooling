---
title: A árvore, e por que um caminho é o único nome real de um arquivo
version: 1
---

O armazenamento de um computador é arranjado como uma **árvore**: uma raiz, pastas dentro de
pastas, e arquivos nas pontas dos ramos. Cada arquivo fica em exatamente um lugar dessa árvore, e
a linha que desce da raiz até ele se chama **caminho**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Uma árvore de pastas desenhada como uma lista indentada unida por linhas. A partir da raiz, uma pasta chamada home, dentro dela uma pasta chamada ana marcada como onde você está, dentro dessa uma pasta chamada documents com um arquivo chamado taxes-2025.pdf, e ao lado uma pasta downloads e uma pasta etc que não estão no caminho. À direita o mesmo arquivo é escrito de dois jeitos: o caminho inteiro desde a raiz, e o caminho curto desde onde você está.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Um arquivo, um lugar, e dois jeitos de dizer onde</text><path d=\"M54 60 L54 82 L64 82\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M82 90 L82 112 L92 112\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M110 120 L110 142 L120 142\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M138 150 L138 172 L148 172\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M110 120 L110 202 L120 202\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M54 60 L54 232 L64 232\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"40\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">/</text><text x=\"68\" y=\"82\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">home/</text><text x=\"96\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">ana/</text><text x=\"124\" y=\"142\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">documents/</text><text x=\"152\" y=\"172\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">taxes-2025.pdf</text><text x=\"124\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">downloads/</text><text x=\"68\" y=\"232\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">etc/</text><path d=\"M168 112 L186 112 M180 107 L186 112 L180 117\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><text x=\"194\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">você está aqui</text><text x=\"380\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o mesmo arquivo, nomeado duas vezes</text><text x=\"380\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a partir da raiz</text><text x=\"380\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/home/ana/documents/taxes-2025.pdf</text><text x=\"380\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a partir de onde você está</text><text x=\"380\" y=\"174\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">documents/taxes-2025.pdf</text><path d=\"M380 204 L700 204\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"380\" y=\"226\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Uma barra na frente é a diferença inteira.</text><text x=\"380\" y=\"246\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Sem ela o nome não significa nada</text><text x=\"380\" y=\"266\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">até você dizer onde está.</text><text x=\"24\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Todo outro jeito de alcançar um arquivo — um atalho, uma lista de recentes, uma busca — é apelido disto.</text></svg>", "caption": "Um caminho é o endereço do arquivo. Um atalho é o bilhete de alguém sobre onde o endereço ficava."}
```

## Absoluto e relativo

Um caminho que parte da raiz é **absoluto**: ele significa a mesma coisa digitado em qualquer
lugar, por qualquer pessoa, a qualquer hora. Um caminho que não parte é **relativo**, e só
significa algo depois de se saber onde você está.

Os dois são úteis e falham de jeitos diferentes. Um caminho absoluto quebra quando o arquivo
muda de lugar; um relativo quebra quando *você* muda. Um link dentro de um documento para
`images/diagram.png` continua funcionando quando a pasta inteira é copiada para outro lugar, e a
versão absoluta não — e é por isso que caminhos relativos são o que documentos e páginas web
usam.

Duas abreviações aparecem em todo lugar e valem ser conhecidas:

- **`.`** significa *aqui*, a pasta em que você está.
- **`..`** significa *a pasta acima desta*. Então `../downloads` é irmã de onde você está.

## Windows e todo o resto

Eles desenham a mesma árvore com pontuação diferente, e uma diferença real por baixo.

| | Windows | macOS e Linux |
|---|---|---|
| separador | `\` barra invertida | `/` barra |
| o topo | uma árvore por disco: `C:\`, `D:\` | uma árvore, `/`, com os discos presos dentro dela |
| a pasta pessoal | `C:\Users\ana` | `/home/ana` ou `/Users/ana` |
| maiúsculas nos nomes | `Report.pdf` e `report.pdf` são o mesmo arquivo | são dois arquivos |

**A última linha é a que morde.** Um projeto que funciona numa máquina e falha em outra com
*arquivo não encontrado*, com o arquivo visivelmente ali, é quase sempre uma letra maiúscula. É
também por isso que tudo destinado a um servidor web é escrito em minúsculas por hábito.

A diferença da letra de disco importa menos do que parece. O Windows também consegue montar um
disco dentro de uma pasta; isso só não é o padrão.

## O que uma pasta de fato é

Uma pasta não é um recipiente do jeito que uma caixa é. Ela é **um arquivo que guarda uma lista
de nomes e onde cada um está no disco.** É por isso que mover um arquivo dentro do mesmo disco é
instantâneo independentemente do tamanho — nada se move, uma lista perde uma entrada e outra
ganha — e por isso que movê-lo para outro disco demora o mesmo que copiar.

Isso também explica algo que as pessoas acham estranho: **um arquivo pode estar aberto e sendo
lido enquanto o nome dele é mudado**, porque o nome e o conteúdo são duas coisas diferentes em
dois lugares diferentes.
