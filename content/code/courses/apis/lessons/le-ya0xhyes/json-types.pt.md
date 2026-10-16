---
title: O que o JSON tem, e o que falta nele
version: 1
---

**O JSON tem seis tipos de valor e nenhum outro:** objeto, array, string, número, `true` ou `false`,
e `null`. Não há data, não há dinheiro, não há dados binários, e não há diferença entre um número
inteiro e uma fração. Tudo o que uma API envia e não é um desses seis é uma convenção, e uma
convenção só se sustenta se o contrato a escrever.

A imagem comum é que os números do JSON vêm em dois tipos, inteiros e de ponto flutuante, como na
maioria das linguagens de programação. Não vêm. A gramática tem um número só, e **no que ele se
transforma é decidido por quem o lê.** Os mesmos dois valores, lidos por dois parsers:

```
ana@api:~$ echo '[3990, 3990.0]' | jq -c .
[3990,3990.0]
ana@api:~$ echo '[3990, 3990.0]' | jq -c 'map(. + 0)'
[3990,3990]
ana@api:~$ python3 -c 'import json; print(json.loads("[3990, 3990.0]"))'
[3990, 3990.0]
```

O `jq` mantém `3990.0` como foi escrito enquanto só o repassa, e o transforma em `3990` no momento
em que faz uma conta com ele. O Python mantém os dois separados, um `int` e um `float`. Nenhum está
errado, porque o JSON nunca disse o que eles eram.

## Números que mudam no caminho

O JSON não põe limite no tamanho de um número. Quem lê põe. O JavaScript, e muitos leitores escritos
em outras linguagens, transformam todo número JSON num double de ponto flutuante de 64 bits, que
guarda exatamente todo número inteiro só até 2^53. Dali em diante, alguns inteiros não têm um double
próprio e são arredondados para um vizinho:

```
ana@api:~$ echo '{"id": 9007199254740993}' | jq .id
9007199254740993
ana@api:~$ echo '{"id": 9007199254740993}' | jq '.id + 0'
9007199254740992
ana@api:~$ python3 -c 'print(2**53, float(9007199254740993))'
9007199254740992 9007199254740992.0
```

O id era `9007199254740993`, um a mais que 2^53. O `jq` o imprimiu intacto enquanto só o repassava;
no momento em que o tratou como número, ele virou `9007199254740992`, e o mesmo aconteceu com o
`float` do Python. O Node não está instalado nesta máquina, então o JavaScript não roda aqui, mas os
números dele são os mesmos doubles, e o `JSON.parse` dele dá o mesmo `...992`. **Um cliente escrito
em JavaScript recebe um id diferente do que você enviou, sem erro nenhum.** A API do Twitter passou
exatamente por isso quando os ids dos tweets passaram de 2^53, e acrescentou um campo `id_str`
levando cada id de novo, como string.

Então um id que pode passar de 2^53 viaja como string. Os ids do shelf são números de linha
pequenos e continuam números; a decisão é do contrato, e é tomada uma vez, para todos os ids.

## Dinheiro nunca é float

Um float guarda a maioria das frações decimais de forma aproximada, e o erro aparece assim que você
multiplica. Três exemplares de um livro a 39,90:

```
ana@api:~$ jq -n '39.90 * 3'
119.69999999999999
ana@api:~$ python3 -c 'print(39.90 * 3, 3990 * 3)'
119.69999999999999 11970
```

Tanto o `jq` quanto o Python imprimem `119.69999999999999`, porque 39,90 não tem representação
binária exata. O arredondamento esconde isso numa conta e não na seguinte, e um total com um centavo
de diferença é um chamado no suporte. **Dinheiro viaja como um número inteiro da menor unidade da
moeda, com a moeda ao lado**: `3990` e `"BRL"`. A multiplicação fica exata, `11970`. A moeda não é
opcional, porque `3990` sozinho não diz se são reais ou euros, e nem toda moeda tem duas casas
decimais: o iene japonês não tem nenhuma.

## Datas são strings por acordo

O JSON não tem data, então uma data é uma string, e a string só é data porque os dois lados
combinaram:

```
ana@api:~$ echo '{"published": "1899-01-01"}' | jq '.published | type'
"string"
```

Para o `jq`, e para qualquer parser, `"1899-01-01"` é texto. Que texto conta como data, e o que ele
significa, é o assunto da próxima seção.

| você quer enviar | o JSON oferece | o que o contrato diz |
|---|---|---|
| uma contagem, um ano, um id pequeno | um número | um inteiro, e quem lê o mantém inteiro |
| um id que pode passar de 2^53 | um número que pode ser arredondado | uma string |
| uma quantia de dinheiro | um número que pode virar double | inteiro na menor unidade, mais um código de moeda |
| uma data ou um horário | nada | uma string em RFC 3339, com deslocamento |
| sim ou não | `true` e `false` | um booleano, nunca a string `"true"` |
| dados binários, como uma capa | nada | um link para eles, ou base64 numa string |
