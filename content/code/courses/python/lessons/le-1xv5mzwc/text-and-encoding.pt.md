---
title: Bytes em disco, texto em memória, e a linha entre os dois
version: 1
---

Um arquivo guarda bytes. Uma string do Python guarda caracteres. Uma CODIFICAÇÃO é a tabela que diz
quais bytes significam quais caracteres, e o `open` precisa saber qual é.

```python
open(caminho, encoding="utf-8")
```

**Escreva isso toda vez.** Sem isso o Python usa o padrão da plataforma — UTF-8 na maioria das
máquinas hoje, e não em todas, e não em todo ambiente. O defeito que vem disso é da pior forma que
existe: funciona no seu laptop e falha no servidor, num arquivo que não mudou.

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
open(caminho, encoding="utf-8", errors="replace")     # bytes ruins viram
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
