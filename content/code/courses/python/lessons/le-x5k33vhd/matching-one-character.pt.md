---
title: Que caractere, e as classes que valem decorar
version: 1
---

A maior parte dos caracteres casa consigo mesma. `cat` casa `cat`. Os interessantes são o resto.

## O ponto

`.` casa qualquer caractere menos uma quebra de linha. Essa exceção importa quando você trabalha
linha a linha e surpreende quem não trabalha — o `re.DOTALL` a desliga.

## Classes

```
[aeiou]      qualquer um desses
[a-z]        qualquer minúscula
[a-zA-Z0-9]  uma letra ou um dígito
[^0-9]       qualquer coisa que NÃO seja dígito
```

Colchetes são um conjunto de caracteres, e UM deles casa. O `^` no COMEÇO de uma classe a nega; em
qualquer outro lugar ele é um `^` literal.

## As abreviações

| abreviação | quer dizer | negação |
| --- | --- | --- |
| `\d` | um dígito | `\D` |
| `\w` | uma letra, dígito ou sublinhado | `\W` |
| `\s` | um espaço, tabulação ou quebra | `\S` |

O `\w` inclui letras acentuadas no Python 3 por padrão, que é o certo para `ção` e surpreende quem
esperava ASCII. O `re.ASCII` o estreita.

## Escapar, dentro e fora

```python
r"\."          # um ponto literal
r"[.]"         # também um ponto literal — dentro de uma classe quase tudo é literal
r"[\d.]"       # um dígito ou um ponto
r"[a\-z]"      # a, um hífen, ou z — o escape torna o hífen literal
```

**Dentro de uma classe quase nada é especial**, e é por isso que `[.]` não precisa de barra. As
exceções são `]`, `\`, o `^` no começo, e o `-` entre dois caracteres — e pôr o hífen primeiro ou
por último evita a questão inteira: `[-a-z]`.

## `re.escape`

```python
padrao = re.escape(entrada_do_usuario)
```

Quando o texto vem de outro lugar, todo caractere nele precisa ser tomado ao pé da letra. O
`re.escape` faz isso, e escrever as barras à mão é como um ponto no nome de alguém vira um
curinga.
