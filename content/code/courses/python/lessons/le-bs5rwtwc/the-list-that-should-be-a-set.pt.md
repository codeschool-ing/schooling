---
title: O conserto mais comum que existe
version: 2
---

```python
blocked = load_blocked_ids()      # a list of 3,000 ids
for order in orders:              # 20,000 orders
    if order.customer_id in blocked:
        continue
    ...
```

**Vinte mil caminhadas por uma lista de três mil itens.** Sessenta milhões de comparações, para
uma checagem que se lê como uma operação.

```python
blocked = set(load_blocked_ids())
```

Uma palavra, uma linha, e o laço agora são vinte mil buscas por hash.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"O custo de perguntar se um nome ausente está numa lista dobra cada vez que a lista dobra, de noventa microssegundos com dez mil para quase dois milissegundos com duzentos mil. A mesma pergunta a um conjunto fica em cerca de quarenta e sete nanossegundos em todos os tamanhos.\"> <text x=\"20\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">x in list, em microssegundos</text> <rect x=\"90\" y=\"164.413\" width=\"96\" height=\"5.58749\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\"></rect> <text x=\"138\" y=\"150.413\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">91.7</text> <text x=\"138\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10 000</text> <rect x=\"90\" y=\"224\" width=\"96\" height=\"2\" rx=\"0\" fill=\"var(--phosphor)\"></rect> <rect x=\"240\" y=\"143.909\" width=\"96\" height=\"26.0912\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\"></rect> <text x=\"288\" y=\"129.909\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">428.2</text> <text x=\"288\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">50 000</text> <rect x=\"240\" y=\"224\" width=\"96\" height=\"2\" rx=\"0\" fill=\"var(--phosphor)\"></rect> <rect x=\"390\" y=\"115.21\" width=\"96\" height=\"54.7903\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\"></rect> <text x=\"438\" y=\"101.21\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">899.2</text> <text x=\"438\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">100 000</text> <rect x=\"390\" y=\"224\" width=\"96\" height=\"2\" rx=\"0\" fill=\"var(--phosphor)\"></rect> <rect x=\"540\" y=\"50\" width=\"96\" height=\"120\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\"></rect> <text x=\"588\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">1969.4</text> <text x=\"588\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">200 000</text> <rect x=\"540\" y=\"224\" width=\"96\" height=\"2\" rx=\"0\" fill=\"var(--phosphor)\"></rect> <text x=\"20\" y=\"214\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">x in set, em todos os tamanhos</text> <text x=\"360\" y=\"252\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">quarenta e sete nanossegundos, e não se move: quarenta mil vezes menor que a barra acima dele</text> </svg>", "caption": "Medido com o timeit numa máquina. As barras do conjunto não estão faltando — estão desenhadas na mesma escala, e nessa escala elas são um fio."}
```

## Quanto isso vale

```sh
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
valid_codes = ["BRL", "USD", "EUR", ...]      # built once
...
for row in rows:
    if row["code"] in valid_codes:            # searched n times
```

Se uma coleção só é perguntada "isto está em você", ela deveria ser um set. Se é perguntada "qual
é o valor disto", deveria ser um dict.

## Quando não importa

```python
if method in ("GET", "POST", "HEAD"):
```

Três itens, e a tupla ganha em memória e em velocidade porque construir um set custa mais que
caminhar por três elementos. **O ponto de virada é pequeno** — algo abaixo de uns dez itens para
valores simples — e abaixo dele a tupla também é mais fácil de ler.

A regra é sobre o tamanho da coleção e a quantidade de vezes que ela é buscada, e os dois têm de
ser grandes antes de isso importar.

## E o que não é um conserto

```python
if x in set(items):          # the set is built every time
```

Construir um set é `O(n)`, então fazê-lo dentro do laço custa exatamente o que a caminhada
custava, mais a alocação. A economia inteira está em construí-lo **uma vez, do lado de fora**.
