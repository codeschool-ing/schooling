---
title: Memória, e o que acontece quando ela acaba
version: 1
---

**A RAM é onde os programas em execução guardam aquilo em que estão trabalhando.** Ela é rápida, é
bem menor que o disco e é esvaziada toda vez que o computador desliga. O kernel decide quem fica com
qual parte dela:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dois processos, o navegador e a planilha, veem cada um a sua própria faixa de endereços começando do zero. O kernel mapeia pedaços de cada faixa para lugares na RAM física, intercalados, e alguns pedaços da planilha para o disco, no swap ou no pagefile. Nenhum processo consegue ver os pedaços do outro.\"><defs><marker id=\"sp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o navegador vê</text><rect x=\"20\" y=\"34\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><rect x=\"20\" y=\"74\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4096</text><rect x=\"20\" y=\"114\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8192</text><rect x=\"20\" y=\"154\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12288</text><text x=\"560\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a planilha vê</text><rect x=\"560\" y=\"34\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><rect x=\"560\" y=\"74\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4096</text><rect x=\"560\" y=\"114\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8192</text><rect x=\"560\" y=\"154\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12288</text><text x=\"20\" y=\"214\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">endereços próprios, a partir de 0</text><text x=\"290\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">RAM física</text><rect x=\"290\" y=\"34\" width=\"140\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"290\" y=\"58\" width=\"140\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"290\" y=\"82\" width=\"140\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"290\" y=\"106\" width=\"140\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"290\" y=\"130\" width=\"140\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"290\" y=\"154\" width=\"140\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"290\" y=\"178\" width=\"140\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"290\" y=\"236\" width=\"140\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">disco (swap / pagefile)</text><path d=\"M162 49 C220 49 240 44 286 44\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah)\"></path><path d=\"M162 89 C220 89 240 92 286 92\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah)\"></path><path d=\"M162 129 C220 129 240 140 286 140\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah)\"></path><path d=\"M162 169 C220 169 240 188 286 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah)\"></path><path d=\"M558 49 C500 49 480 68 434 68\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah)\"></path><path d=\"M558 89 C500 89 480 116 434 116\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah)\"></path><path d=\"M558 129 C500 129 480 164 434 164\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah)\"></path><path d=\"M558 169 C500 169 480 248 434 248\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah)\" stroke-dasharray=\"4 3\"></path></svg>", "caption": "Cada processo acredita ter uma memória particular começando no zero. O kernel guarda o mapa de verdade, e pode mandar pedaços parados para o disco."}
```

Cada processo vê os próprios endereços, começando do zero, e não consegue ver os de ninguém mais.
Isso é a **memória virtual**: o kernel guarda um mapa dos endereços de cada processo para lugares de
verdade na RAM. É por isso que um programa travando não derruba os outros junto, e que um programa
não consegue simplesmente ler a senha que outro está guardando.

## Lendo os números

```
ana@server:~/office$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       638Mi        13Gi        12Mi       2.2Gi        15Gi
Swap:             0B          0B          0B
```

Leia da direita para a esquerda, porque a coluna que importa é a última:

- **total**: a RAM da máquina, 15 GiB aqui.
- **used**: ocupada por processos.
- **buff/cache**: arquivos que o kernel manteve na RAM porque foram lidos há pouco. Não é
  desperdício; lê-los de novo é instantâneo. E é devolvida no momento em que um programa precisa.
- **available**: o que um programa novo conseguiria agora, cache incluído. **Este é o número para
  olhar.** Uma máquina com pouca memória *free* e bastante *available* está saudável.

## Quando ela acaba

Quando os programas querem mais RAM do que existe, o kernel move para o disco pedaços que ninguém
está usando no momento, e os traz de volta quando são necessários. Essa área do disco é o **swap**
no Linux, o **pagefile** (`pagefile.sys`) no Windows e os **arquivos de swap** no macOS. Windows e
macOS também comprimem a memória antes de recorrer ao disco.

Isso mantém a máquina funcionando, e é lento: um disco é milhares de vezes mais lento que a RAM. Um
computador sem memória fica lento de um jeito característico. O mouse se mexe, mas cada janela leva
segundos para responder, e a luz do disco fica acesa. É o *esperar outra coisa* da seção anterior, e
a cura de costume é menos programas abertos, ou mais RAM.

Este servidor mostra `Swap: 0B`: não tem nenhum configurado, então não consegue fazer isso. Quando é
o caso, o último recurso do kernel é parar um processo para liberar memória, no Linux por um
mecanismo chamado **OOM killer** (*out of memory*, sem memória).

O equivalente do `free` no Windows é a aba *Desempenho* do Gerenciador de Tarefas, e no macOS é a aba
*Memória* do Monitor de Atividade. Os dois mostram a mesma ideia: em uso, em cache e comprimida.
