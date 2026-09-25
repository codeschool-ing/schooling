---
title: Entre os seus programas e o hardware
version: 1
---

**Um sistema operacional é o programa que opera o computador para os outros programas.** Um
navegador, uma planilha e um terminal querem, cada um, o processador, um pouco de memória, o disco,
a tela e a rede, tudo ao mesmo tempo. Se cada um falasse sozinho com o hardware, eles escreveriam
por cima da memória uns dos outros, gravariam no disco ao mesmo tempo e brigariam pela tela. O
sistema operacional fica no meio e os faz esperar a vez.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Três camadas. Em cima, os programas: um navegador, uma planilha, um terminal. No meio, o sistema operacional, cujo kernel gerencia processos, memória, dispositivos e arquivos. Embaixo, o hardware: processador, RAM, disco, e a tela, o teclado e a rede. Os programas só chegam ao hardware pedindo ao kernel, por chamadas de sistema como abrir, ler, escrever, iniciar e parar.\"><defs><marker id=\"ly-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">programas</text><rect x=\"20\" y=\"36\" width=\"210\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">navegador</text><rect x=\"250\" y=\"36\" width=\"210\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"355\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">planilha</text><rect x=\"480\" y=\"36\" width=\"210\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"585\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">terminal</text><path d=\"M125 80 L125 118\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><path d=\"M355 80 L355 118\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><path d=\"M585 80 L585 118\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><text x=\"690\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">chamadas de sistema: abrir, ler, escrever, iniciar, parar</text><rect x=\"20\" y=\"122\" width=\"680\" height=\"100\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">sistema operacional</text><text x=\"34\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">kernel</text><rect x=\"100\" y=\"176\" width=\"136\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"168\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">processos</text><rect x=\"250\" y=\"176\" width=\"136\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"318\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">memória</text><rect x=\"400\" y=\"176\" width=\"136\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"468\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">dispositivos</text><rect x=\"550\" y=\"176\" width=\"136\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"618\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">arquivos</text><path d=\"M168 212 L168 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><path d=\"M318 212 L318 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><path d=\"M468 212 L468 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><path d=\"M618 212 L618 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><text x=\"20\" y=\"250\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">hardware</text><rect x=\"100\" y=\"262\" width=\"136\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"168\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">processador</text><rect x=\"250\" y=\"262\" width=\"136\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"318\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">RAM</text><rect x=\"400\" y=\"262\" width=\"136\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"468\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">disco</text><rect x=\"550\" y=\"262\" width=\"136\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"618\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tela, teclado, rede</text></svg>", "caption": "Nenhum programa mexe no hardware diretamente. Ele pede ao kernel, e o kernel decide.", "same": ["hardware", "terminal", "RAM"]}
```

A parte que faz esse papel de juiz é o **kernel**. Ele é o primeiro programa carregado quando o
computador liga e o último a parar, e é o único programa com permissão para mexer diretamente no
hardware. Todo o resto, inclusive as partes do sistema que você vê, pede ao kernel o que precisa
por meio de **chamadas de sistema**: abra este arquivo, leia dele, inicie aquele programa, me dê
mais memória. A seção 06 vê um programa fazendo exatamente isso.

## Do que ele cuida

- **Processos**: todo programa em execução, quais existem, qual roda em seguida.
- **Memória**: quem fica com qual parte da RAM, e o que acontece quando ela não basta.
- **Dispositivos**: discos, teclados, telas, impressoras e placas de rede, cada um por meio de um
  **driver**.
- **Arquivos**: transformar um disco cheio de blocos numerados em pastas e nomes.

Ele também controla os **usuários** e o que cada um pode fazer, que é o assunto das aulas 9 e 10.

## Três sistemas, uma ideia

| | Windows | Linux | macOS |
|---|---|---|---|
| kernel | Windows NT | Linux | XNU |
| origem | Microsoft, 1993 | Linus Torvalds, 1991 | Apple, sobre código Unix (BSD) |
| onde você encontra | a maioria dos computadores de escritório | a maioria dos servidores, celulares Android | computadores da Apple |
| quem distribui | Microsoft | várias *distribuições* (aula 6) | Apple |

O Linux sozinho é só o kernel. O que as pessoas instalam é uma **distribuição**, o kernel mais os
programas em volta dele, e existem muitas. Windows e macOS vêm, cada um, de uma empresa só, inteiros.

No escritório, os três estão em uso ao mesmo tempo, e isso é normal. O trabalho da Ana não é
preferir um deles. É reconhecer a mesma ideia por trás de três telas diferentes, e isso começa pelos
processos.
