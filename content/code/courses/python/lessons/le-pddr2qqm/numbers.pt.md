---
title: `int` não tem teto; `float` não guarda um terço
version: 1
---

Dois tipos numéricos carregam quase tudo.

## `int`

Números inteiros, positivos ou negativos, **sem limite superior**:

```python
>>> 2 ** 100
1267650600228229401496703205376
```

Não é truque. O Python faz o inteiro crescer conforme precisa, o que significa nenhum estouro e
nenhum tipo `long` para lembrar. O custo é velocidade, e não é um custo que você vá encontrar neste
curso.

## `float`

Decimais, guardados do jeito que toda linguagem guarda — em binário, com 53 bits de precisão. O que
leva à única coisa que todo mundo precisa ouvir uma vez:

```python
>>> 0.1 + 0.2
0.30000000000000004
```

**Isso não é defeito do Python.** Um décimo não pode ser escrito exatamente em binário, do mesmo
jeito que um terço não pode ser escrito exatamente em decimal. O valor guardado fica levemente
diferente, e somar dois valores levemente diferentes mostra o erro.

Duas consequências:

**Nunca compare floats com `==`.** `0.1 + 0.2 == 0.3` é `False`. Compare com uma tolerância, ou use
`math.isclose`, que a aula 7 cobre.

**Nunca guarde dinheiro num float.** O `Decimal` da biblioteca padrão é exato para isso, e a
plataforma em que você está lendo isto guarda todo preço como um número inteiro de centavos pelo
mesmo motivo.

## Os operadores

| | | |
|---|---|---|
| `+` `-` `*` | como se espera | |
| `/` | divisão verdadeira, **sempre um float** | `4 / 2` é `2.0` |
| `//` | divisão inteira, a parte cheia | `7 // 2` é `3` |
| `%` | resto | `7 % 2` é `1` |
| `**` | potência | `2 ** 10` é `1024` |

**`//` e `%` arredondam para menos infinito**, o que vale saber antes de surpreender:

```python
>>> -7 // 2
-4
>>> -7 % 2
1
```

Não `-3` e `-1`. A regra que o Python mantém é `a == (a // b) * b + a % b`, e o resto fica com o
sinal do divisor. Para um divisor positivo o resto nunca é negativo, que é exatamente o que se quer
ao percorrer uma lista em ciclo.

## Misturando os dois

Qualquer aritmética que toque um float produz um float. `2 + 2.0` é `4.0`, e `4 / 2` é `2.0` mesmo
com os dois lados inteiros. Para ter um inteiro de volta, `//` ou `int()` — e o `int()` trunca em
direção ao zero em vez de arredondar, que é o que o `round()` faz.
