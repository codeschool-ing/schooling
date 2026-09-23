---
title: Bytes em disco, texto em memória, e a linha entre os dois
version: 2
---

Um arquivo guarda bytes. Uma string do Python guarda caracteres. Uma CODIFICAÇÃO é a tabela que diz
quais bytes significam quais caracteres, e o `open` precisa saber qual é.

```python
open(path, encoding="utf-8")
```

**Escreva isso toda vez.** Sem isso o Python usa o padrão da plataforma — UTF-8 na maioria das
máquinas hoje, e não em todas, e não em todo ambiente. O defeito que vem disso é da pior forma que
existe: funciona no seu laptop e falha no servidor, num arquivo que não mudou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"Uma mesma sequência de bytes lida com duas codificações diferentes. Decodificada como UTF-8 é a palavra café; decodificada como Latin-1 é cafÃ©. Nada falha — a tabela errada simplesmente produz outros caracteres.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"360\" y=\"20\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">um arquivo guarda bytes; uma string guarda caracteres</text> <rect x=\"20\" y=\"62\" width=\"250\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"145\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">b&quot;caf\\xc3\\xa9&quot;</text> <rect x=\"420\" y=\"34\" width=\"250\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"545\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;café&quot;</text> <rect x=\"420\" y=\"96\" width=\"250\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"545\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;cafÃ©&quot;</text> <path d=\"M276 76 L414 56\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <path d=\"M276 96 L414 114\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"345\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">.decode(&quot;utf-8&quot;)</text> <text x=\"345\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">.decode(&quot;latin-1&quot;)</text> <text x=\"360\" y=\"186\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">É por isso que a codificação é escrita toda vez: sem ela o Python pega o padrão da plataforma,</text> <text x=\"360\" y=\"203\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">que é UTF-8 no seu laptop e outra coisa na máquina que roda aquilo.</text> </svg>", "caption": "A codificação não é um ajuste do arquivo. É a tabela que você leva até ele, e a errada se lê perfeitamente bem."}
```

## `UnicodeDecodeError`, lido direito

```
UnicodeDecodeError: 'utf-8' codec can't decode byte 0xe7 in position 14: invalid continuation byte
```

Quatro fatos numa linha. O codec que ele TENTOU (`utf-8`), o byte que ele encontrou (`0xe7`), onde
(posição 14), e por que aquilo não podia fazer parte de um caractere UTF-8.

`0xe7` sozinho é `ç` em Latin-1, que é a resposta comum: **o arquivo não é UTF-8**, e ele
provavelmente é `latin-1` ou `cp1252` de uma planilha do Windows. `encoding="latin-1"` o lê, e o
conserto certo em geral é converter o arquivo uma vez em vez de carregar a codificação por aí.

## O que o `errors=` faz, e quando

```python
open(path, encoding="utf-8", errors="replace")     # bad bytes become
```

Ele impede o erro e perde o dado. Isso está certo para um log que você está filtrando e errado para
qualquer coisa que você vai gravar de volta — um `errors="replace"` num pipeline quer dizer um nome
virando `Jo o` em silêncio no meio do caminho.

## O BOM

Um arquivo escrito pelo Bloco de Notas ou pelo Excel pode começar com três bytes invisíveis
anunciando "isto é UTF-8". Com `encoding="utf-8"` eles chegam como um caractere no começo do seu
primeiro campo, e o sintoma é um cabeçalho chamado `"﻿name"` que compara diferente de
`"name"`.

**`encoding="utf-8-sig"` o come se ele estiver lá e é inofensivo se não estiver**, o que o torna a
escolha certa para qualquer coisa que uma pessoa exportou de uma planilha.

## Quebras de linha

O modo texto traduz `\r\n` para `\n` na entrada. É o que você quer para texto, e é exatamente o que
o `csv` pede para desligar com `newline=""` — a razão está naquela seção.
