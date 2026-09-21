---
title: Uma tabela como um objeto
version: 1
---

```python
total = 0
for linha in linhas:                    # uma lista de dicts
    if linha["pais"] == "BR":
        total += linha["centavos"]
```

```python
total = df.loc[df["pais"] == "BR", "centavos"].sum()
```

**Um DataFrame é uma tabela sobre a qual você fala como um todo.** Uma coluna é um objeto que você
compara, multiplica, filtra e agrupa, e o resultado de comparar uma é outra coluna — de booleanos
— que é o que a segunda linha está fazendo.

## O que custa fazer um laço no lugar

```python
df["centavos"] * df["taxa"]                             # vetorizado
df.apply(lambda l: l["centavos"] * l["taxa"], axis=1)   # uma chamada Python por linha
[l["centavos"] * l["taxa"] for _, l in df.iterrows()]   # um Series montado por linha
```

```text
500.000 linhas
  iterrows   11,200 s
  apply       2,771 s
  vetorizado  0,002 s
```

**Cinco mil vezes**, medido. A operação de coluna roda em código compilado sobre um bloco contíguo
de memória; o `iterrows` monta um objeto `Series` para cada linha antes de você tocá-la.

O `apply(axis=1)` parece o jeito pandas de fazer isso e não é — é uma chamada de função Python por
linha com a construção do objeto ainda lá.

## Os dois tipos

```python
df["centavos"]                # um Series  — uma coluna, com um índice
df[["cliente","centavos"]]    # um DataFrame — duas colunas
```

Um **Series** é uma coluna: valores mais um índice. Um **DataFrame** é um dict de Series
compartilhando um índice. Quase tudo o que você faz devolve um dos dois, e saber qual você tem na
mão explica a maior parte das mensagens de erro.

## O índice

```text
   id cliente pais    centavos
3   4   diego   US     23000.0
6   7  gisele   US     15000.0
```

Depois de filtrar, as linhas mantêm os rótulos **originais** — 3 e 6, não 0 e 1. O índice não é
uma posição, e essa é a surpresa mais comum do pandas. A seção sobre `loc` e `iloc` é exatamente
sobre isso.

## Quando não usar

Cem linhas lidas uma vez. Um fluxo que você processa e descarta. Qualquer coisa em que a resposta
seja uma passagem só e os dados não caibam numa tabela. O `pandas` custa uma dependência, alguma
memória e uma curva de aprendizado, e abaixo de alguns milhares de linhas uma lista de dicts está
honestamente bem.
