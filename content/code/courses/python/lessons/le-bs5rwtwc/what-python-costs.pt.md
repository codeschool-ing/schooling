---
title: A tabela que vale conhecer
version: 2
---

| operação | custo | medido em n = 100.000 |
| --- | --- | --- |
| `data[i]` | O(1) | 13 ns |
| `data.append(x)` | O(1) | 19 ns |
| `data.pop()` | O(1) | 26 ns |
| `data.insert(0, x)` | **O(n)** | 32.527 ns |
| `data.pop(0)` | **O(n)** | 13.247 ns |
| `x in list` | **O(n)** | 885.901 ns |
| `x in set` | O(1) | 69 ns |
| `x in dict` | O(1) | 44 ns |

Tudo medido com `timeit` numa máquina. **As razões são o ponto**, não os nanossegundos.

## Por que `in` numa lista é uma caminhada

Uma lista é uma sequência de posições. Nada nela diz onde um valor está, então `x in data`
compara `x` com cada elemento até achar um — `n` comparações no pior caso, e é isso que são os
`885.901` nanossegundos acima.

## Por que `in` num set é um passo

Um set guarda cada valor numa posição calculada **a partir do próprio valor** — o hash dele.
Perguntar se `x` está lá é calcular `hash(x)`, ir àquela posição e olhar. O tamanho do set não
entra na conta.

Um dict é a mesma maquinaria com um valor preso, que é por que `x in dict` e `d[x]` são os dois
`O(1)`.

## O que isso custa a você

```python
{"a": 1}        # a dict of one
[("a", 1)]      # a list of one
```

O set e o dict usam mais memória por elemento e precisam que as chaves sejam **hasheáveis** —
então strings, números e tuplas sim, listas e dicionários não. Eles também perdem garantias de
ordem do tipo que uma lista dá, ainda que os dois preservem ordem de inserção no Python moderno.

É essa a troca inteira, e quase sempre vale a pena fazer.

## `insert(0, …)` e `pop(0)`

```python
data.insert(0, x)     # everything after it shifts up one slot
```

Uma lista é contígua, então pôr algo na frente move todo outro elemento. Em cem mil itens isso dá
32 microssegundos contra os 19 nanossegundos do `append` — **cerca de mil e setecentas vezes** — e
a próxima seção é o que usar no lugar.

## Strings, e uma regra que é meio lenda

```python
s = ""
for word in words:
    s += word
```

```python
s = "".join(words)
```

```sh
+= over 10,000 words   0.515 ms       join over 10,000   0.077 ms
+= over 20,000 words   1.023 ms       join over 20,000   0.148 ms
+= over 40,000 words   2.046 ms       join over 40,000   0.298 ms
```

Strings são imutáveis, então o que se costuma contar é que `s += word` copia tudo a cada vez e
o laço é `O(n²)`. **Medido, ele é linear** — dobre as palavras, dobre o tempo — porque o CPython
tem uma otimização que faz a string crescer no lugar quando nada mais se refere a ela.

O `join` ainda é cerca de sete vezes mais rápido, e ainda é o que escrever: a otimização é do
CPython e não da linguagem, e ela deixa de valer no momento em que outra coisa segura uma
referência a `s`. Mas o motivo é "é para isso que o `join` serve", e não um quadrático que você
consegue medir.
