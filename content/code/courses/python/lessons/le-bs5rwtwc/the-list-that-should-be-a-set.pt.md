---
title: O conserto mais comum que existe
version: 1
---

```python
bloqueados = carregar_bloqueados()   # uma lista de 3.000 ids
for pedido in pedidos:               # 20.000 pedidos
    if pedido.cliente_id in bloqueados:
        continue
    ...
```

**Vinte mil caminhadas por uma lista de três mil itens.** Sessenta milhões de comparações, para
uma checagem que se lê como uma operação.

```python
bloqueados = set(carregar_bloqueados())
```

Uma palavra, uma linha, e o laço agora são vinte mil buscas por hash.

## Quanto isso vale

```text
$ python -m timeit -s "data = list(range(100_000))" "99_999 in data"
500 loops, best of 5: 866 usec per loop

$ python -m timeit -s "data = set(range(100_000))"  "99_999 in data"
10000000 loops, best of 5: 34.6 nsec per loop
```

**Vinte e cinco mil vezes**, nesta máquina, neste tamanho. A razão cresce com `n`, porque um lado
é `O(n)` e o outro é `O(1)`.

## Como reconhecer

Procure um `in` contra uma coleção **dentro de um laço**. É esse o padrão inteiro. O sinal é que a
coleção é construída uma vez e nunca mudada:

```python
codigos_validos = ["BRL", "USD", "EUR", ...]   # construída uma vez
...
for linha in linhas:
    if linha["codigo"] in codigos_validos:     # buscada n vezes
```

Se uma coleção só é perguntada "isto está em você", ela deveria ser um set. Se é perguntada "qual
é o valor disto", deveria ser um dict.

## Quando não importa

```python
if metodo in ("GET", "POST", "HEAD"):
```

Três itens, e a tupla ganha em memória e em velocidade porque construir um set custa mais que
caminhar por três elementos. **O ponto de virada é pequeno** — algo abaixo de uns dez itens para
valores simples — e abaixo dele a tupla também é mais fácil de ler.

A regra é sobre o tamanho da coleção e a quantidade de vezes que ela é buscada, e os dois têm de
ser grandes antes de isso importar.

## E o que não é um conserto

```python
if x in set(itens):          # o set é construído toda vez
```

Construir um set é `O(n)`, então fazê-lo dentro do laço custa exatamente o que a caminhada
custava, mais a alocação. A economia inteira está em construí-lo **uma vez, do lado de fora**.
