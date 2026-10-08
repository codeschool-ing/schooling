---
title: Por que uma imagem, e não uma cópia dos arquivos
version: 1
---

A aula 12 deixou em aberto uma pergunta que nenhum log responde: **quais arquivos estavam nos 612 MB** que saíram
do servidor de arquivos. A resposta está no disco do servidor, no que havia lá naquela noite, no que foi lido, e
no que foi apagado depois. Obtê-la é perícia, e a perícia começa com uma regra que parece exagerada e não é:
**ninguém examina o original.**

Uma **imagem forense** é uma cópia de um disco **bit a bit**: todo setor, do primeiro ao último, seja usado por um
arquivo ou não. Essa é a diferença para copiar os arquivos:

| | copiar os arquivos | uma imagem forense |
|---|---|---|
| **arquivos que existem** | sim | sim |
| **arquivos apagados** cujos dados ainda estão no disco | não | sim |
| **espaço livre**, e as sobras que há nele | não | sim |
| **metadados do sistema de arquivos**: horários, donos, o journal | em parte, e a cópia muda alguns | sim, intactos |
| **dá para provar que é idêntica** ao original | não | sim, pelo hash |

A última linha é o ponto. Um hash do disco inteiro tirado antes da cópia, e o mesmo hash da imagem depois dela,
provam que a imagem é o disco, até o último byte. **Toda análise então acontece numa cópia da imagem**, e quem
duvidar de um achado pode fazer a própria cópia a partir da imagem guardada, conferir o hash e olhar por conta
própria.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Da esquerda para a direita: o disco original, lido através de um bloqueador de escrita, é copiado para uma imagem; uma cópia de trabalho é feita a partir da imagem. O mesmo hash SHA-256 aparece embaixo do disco, da imagem e da cópia de trabalho. O original e a imagem são guardados e nunca analisados; toda análise acontece na cópia de trabalho.\"><rect x=\"10\" y=\"30\" width=\"160\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">disco original</text><text x=\"90.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">guardado, lacrado</text><rect x=\"190\" y=\"30\" width=\"160\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">bloqueador de escrita</text><text x=\"270.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só lê</text><rect x=\"370\" y=\"30\" width=\"160\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">imagem</text><text x=\"450.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">guardada, nunca aberta</text><rect x=\"550\" y=\"30\" width=\"160\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cópia de trabalho</text><text x=\"630.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a aula 17 abre esta</text><path d=\"M170 60 L190 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M190 60 L182.0 56.0 L182.0 64.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M350 60 L370 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M370 60 L362.0 56.0 L362.0 64.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M530 60 L550 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M550 60 L542.0 56.0 L542.0 64.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"90\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">mesmo SHA-256</text><text x=\"450\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">mesmo SHA-256</text><text x=\"630\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">mesmo SHA-256</text><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o mesmo hash em cada passo é o que faz da cópia uma evidência</text></svg>", "caption": "Um hash, três cópias. A análise só toca a última."}
```

Há dois jeitos de gerar a imagem de um servidor. Uma aquisição **a frio** desliga o servidor e gera a imagem do
disco a partir de outra máquina; nada no disco muda durante a cópia, e a memória se perde, por isso a aula 13
coleta o estado volátil antes e a aula 17 captura a memória. Uma aquisição **a quente** gera a imagem com o
servidor ligado, e ela vira o retrato de um alvo em movimento: ainda valiosa, e documentada como tal. Para uma
máquina virtual, um snapshot do arquivo de disco dela é o caminho comum, e as mesmas regras de hash valem.
