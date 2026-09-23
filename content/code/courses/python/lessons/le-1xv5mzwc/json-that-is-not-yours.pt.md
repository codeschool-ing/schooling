---
title: A chave que estava lá ontem
version: 2
---

A documentação dizia que todo registro tem um `address` com uma `city` dentro. Aí um deles não tem,
e `record["address"]["city"]` levanta erro trezentas linhas adiante.

## O `get`, com um padrão

```python
city = record.get("address", {}).get("city", "")
```

A forma da aula 3, e o dicionário vazio do meio é o que mantém o segundo `get` válido. Não é
elegante e não levanta erro.

**Decida o que ausente SIGNIFICA antes de escrever o padrão.** Uma string vazia que vai para um
relatório como célula em branco está bem; uma string vazia que vira chave de banco é um defeito que
você acabou de escrever.

## `null` não é ausente

```python
{"city": null}      → record["city"] is None
{}                  → record["city"] raises
```

Duas situações diferentes, e o `get` com padrão só pega a segunda. `record.get("city") or ""` pega
as duas — e também transforma `0` e `False` em `""`, que é a armadilha daquele idioma.

```python
value = record.get("city")
if value is None:
    value = ""
```

Mais longo, e quer dizer exatamente o que diz.

## O tipo que você não esperava

```python
data = json.load(f)
for row in data:          # data is a dict, not a list
    row["name"]           # row is a KEY — a string
```

Iterar um dicionário dá chaves, então isto falha com um `TypeError` sobre índices de string, três
linhas longe do problema de verdade. **Confira a forma na fronteira:**

```python
if not isinstance(data, list):
    raise ValueError(f"{path}: expected a list of records, got {type(data).__name__}")
```

Uma linha, na borda, e toda falha posterior é sobre o dado em vez de sobre a forma.

## Números que são strings

`{"score": "91"}` é JSON válido e uma string no Python. `sum` sobre isso levanta erro, `sorted`
ordena como texto — `"100" < "91"` — e nenhum dos dois diz a palavra "string". Converta na
fronteira, e nomeie a linha quando falhar.

## A regra

**Leia como se eles tivessem feito o que a documentação diz, e trate como se não tivessem.** O erro
que você levanta deveria nomear o arquivo, a linha e o campo — porque quando isto disparar você vai
estar olhando a exportação de outra pessoa, e mais nada no programa sabe de onde ela veio.
