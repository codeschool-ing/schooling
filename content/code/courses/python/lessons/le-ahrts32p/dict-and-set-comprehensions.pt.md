---
title: A mesma forma com chaves, e a que não é nenhuma das duas
version: 2
---

## Dicionário

```python
by_id = {p["id"]: p for p in people}
lengths = {word: len(word) for word in words}
```

Chave e valor separados por dois pontos, e o resto é idêntico. **Esta é a compreensão mais útil de
todas em trabalho com dados**: ela transforma uma lista num índice, uma vez, e toda busca seguinte
vira um passo em vez de um percurso — que é o argumento da aula 3 e a medida da aula 20.

Invertendo um:

```python
by_name = {v: k for k, v in by_id.items()}
```

O que só é seguro quando os valores são únicos, porque uma repetição sobrescreve em silêncio.

## Conjunto

```python
seen = {p["city"] for p in people}
```

Chaves sem dois pontos, e as duplicatas colapsam. O caso vazio continua sendo `set()`.

## Expressão geradora

```python
total = sum(price for price in prices if price > 100)
```

Parênteses, e **nada é construído**. Ela produz um valor por vez conforme o `sum` pede, o que
significa que nenhuma lista de um milhão de números existe em memória em momento algum.

Quando a chamada já tem parênteses, o par extra é dispensável — `sum(x for x in xs)` em vez de
`sum((x for x in xs))`.

A aula 11 é onde isto vira o assunto inteiro. Duas regras até lá:

**Use uma expressão geradora quando ela alimenta direto algo que a consome** — `sum`, `max`, `any`,
`all`, `"".join`.

**Use uma compreensão de lista quando você precisa da lista** — para iterar duas vezes, indexar,
guardar. Um gerador se esgota depois de uma passada e a segunda passada silenciosamente não recebe
nada.

## `any` e `all`

```python
if any(p["city"] == "Porto" for p in people):
if all(score >= 50 for score in scores):
```

Os dois têm curto-circuito: o `any` para no primeiro verdadeiro, o `all` no primeiro falso. Junto com
uma expressão geradora eles substituem um laço com bandeira, que é um padrão que vale reconhecer no
instante em que você se pega escrevendo `achou = False`.
