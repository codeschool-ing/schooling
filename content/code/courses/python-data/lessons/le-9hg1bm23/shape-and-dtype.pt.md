---
title: Formato, dtype, e os jeitos de criar um array
version: 1
---

**Todo array responde às mesmas poucas perguntas sobre si**, e lê-las é a primeira coisa a fazer
com um array que você não criou. Eis um pequeno, com um significado: o número de docas em cada uma
de cinco estações, feito a partir de uma lista:

```python
docks = np.array([14, 20, 12, 17, 10])
docks.ndim, docks.shape, docks.size, docks.dtype, docks.itemsize
```
```
(1, (5,), 5, dtype('int64'), 8)
```

| atributo | diz |
|---|---|
| `ndim` | quantos eixos: 1 para uma fileira de números, 2 para uma tabela |
| `shape` | o comprimento de cada eixo, como tupla: `(5,)` são cinco números num eixo |
| `size` | quantos elementos ao todo |
| `dtype` | o tipo que todos os elementos têm |
| `itemsize` | quantos bytes ocupa um elemento |

**`(5,)` com a vírgula é uma tupla de um**, e a diferença entre `(5,)` e `(5, 1)` é o assunto da
aula 6. O NumPy escolheu `int64` porque todos os valores eram inteiros; um ponto decimal em
qualquer lugar e o array inteiro vira float:

```python
np.array([14, 20, 12.5]).dtype, np.array([14, "20"]).dtype
```
```
(dtype('float64'), dtype('<U21'))
```

O segundo é um aviso. Uma lista com uma string virou um array de **strings**, `<U21`: Unicode
little-endian, até 21 caracteres cada, e nenhuma aritmética funciona nele. O NumPy não recusa uma
lista misturada; ele acha um tipo que caiba tudo, e para números misturados com texto esse tipo é
texto.

## Criando arrays sem lista

A maioria dos arrays não é digitada. Os construtores que você vai usar todo dia:

```python
np.zeros(3), np.ones((2, 3), dtype=int), np.arange(0, 24, 6), np.linspace(0, 1, 5)
```
```
(array([0., 0., 0.]),
 array([[1, 1, 1],
        [1, 1, 1]]),
 array([ 0,  6, 12, 18]),
 array([0.  , 0.25, 0.5 , 0.75, 1.  ]))
```

- `np.zeros` e `np.ones` recebem um formato, e criam floats se não forem instruídos ao contrário.
- `np.arange` é o `range` dos arrays: início, fim e passo, com o fim de fora.
- `np.linspace` recebe um início, um fim e **quantos pontos**, e inclui o fim. Para passos
  fracionários é o mais seguro, porque o `arange` com passo float pode produzir um elemento a mais
  ou a menos do que você espera quando o passo não divide o intervalo exatamente em binário.

Um array bidimensional é uma tabela, com as linhas primeiro:

```python
hours = np.arange(24).reshape(4, 6)
hours
```
```
array([[ 0,  1,  2,  3,  4,  5],
       [ 6,  7,  8,  9, 10, 11],
       [12, 13, 14, 15, 16, 17],
       [18, 19, 20, 21, 22, 23]])
```

`reshape(4, 6)` lê os 24 números em quatro linhas de seis. Os números não são movidos nem copiados,
o que é o assunto das duas últimas seções, e o produto do novo formato tem de ser igual ao tamanho
antigo:

```python
np.arange(24).reshape(5, 5)
```
```
ValueError: cannot reshape array of size 24 into shape (5,5)
```
