---
title: Construir uma busca uma vez, em vez de procurar repetidamente
version: 1
---

```python
for pedido in pedidos:                    # 5.000 pedidos
    for cliente in clientes:              # 5.000 clientes
        if cliente["id"] == pedido["cliente_id"]:
            out.append((cliente["nome"], pedido["centavos"]))
            break
```

```python
por_id = {c["id"]: c for c in clientes}   # uma passagem, construída uma vez
out = [(por_id[p["cliente_id"]]["nome"], p["centavos"]) for p in pedidos]
```

```sh
lento    0,5485s   5000 linhas
rápido   0,0030s   5000 linhas
mesma resposta: True
```

**O(n²) virando O(n), por uma linha.** Medido em cinco mil de cada; em vinte mil a distância é
quinhentas vezes, que é a demonstração no fim desta aula.

## Por que funciona

O laço de dentro é uma busca, e uma busca é o que um dict faz num passo. Construir o índice é uma
passagem sobre os clientes — `O(n)` — e aí cada consulta é `O(1)`, então o todo é `O(n + m)` em
vez de `O(n × m)`.

Você paga uma passagem e alguma memória. Você economiza uma passagem por linha.

## As formas que servem

```python
por_id = {c["id"]: c for c in clientes}              # um valor por chave
```

```python
from collections import defaultdict
por_pais = defaultdict(list)
for c in clientes:
    por_pais[c["pais"]].append(c)                    # muitos valores por chave
```

```python
from collections import Counter
contagens = Counter(p["pais"] for p in pedidos)      # só a contagem
```

O `defaultdict(list)` é o de agrupar e ele aparece o tempo todo — é `sort | uniq` sem o sort, e o
`groupby` da próxima aula é a mesma ideia sobre uma tabela.

## Onde construí-lo

**Fora de todo laço que o usa**, e uma vez por programa em vez de uma vez por chamada:

```python
def relatorio(pedidos, clientes):
    por_id = {c["id"]: c for c in clientes}    # uma vez
    for p in pedidos:
        ...
```

Construí-lo dentro do laço é o mesmo engano do `set(itens)` dentro de uma condição: o índice é
`O(n)` para construir, então construí-lo `n` vezes é o `O(n²)` que você estava removendo.

## E o limite honesto

Isso funciona quando você busca as coisas **por uma chave exata**. Uma busca por "qualquer cliente
cujo nome comece com estas letras", ou "o valor mais próximo", é outro problema — `bisect` sobre
uma lista ordenada para faixas, e um índice de verdade ou um banco para qualquer coisa maior.
