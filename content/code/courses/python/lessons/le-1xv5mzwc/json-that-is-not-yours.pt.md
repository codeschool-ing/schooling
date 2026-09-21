---
title: A chave que estava lá ontem
version: 1
---

A documentação dizia que todo registro tem um `address` com uma `city` dentro. Aí um deles não tem,
e `registro["address"]["city"]` levanta erro trezentas linhas adiante.

## O `get`, com um padrão

```python
cidade = registro.get("address", {}).get("city", "")
```

A forma da aula 3, e o dicionário vazio do meio é o que mantém o segundo `get` válido. Não é
elegante e não levanta erro.

**Decida o que ausente SIGNIFICA antes de escrever o padrão.** Uma string vazia que vai para um
relatório como célula em branco está bem; uma string vazia que vira chave de banco é um defeito que
você acabou de escrever.

## `null` não é ausente

```python
{"city": null}      → registro["city"] é None
{}                  → registro["city"] levanta erro
```

Duas situações diferentes, e o `get` com padrão só pega a segunda. `registro.get("city") or ""` pega
as duas — e também transforma `0` e `False` em `""`, que é a armadilha daquele idioma.

```python
valor = registro.get("city")
if valor is None:
    valor = ""
```

Mais longo, e quer dizer exatamente o que diz.

## O tipo que você não esperava

```python
dados = json.load(f)
for linha in dados:       # dados é um dict, e não uma lista
    linha["name"]         # linha é uma CHAVE — uma string
```

Iterar um dicionário dá chaves, então isto falha com um `TypeError` sobre índices de string, três
linhas longe do problema de verdade. **Confira a forma na fronteira:**

```python
if not isinstance(dados, list):
    raise ValueError(f"{caminho}: esperava uma lista de registros, veio {type(dados).__name__}")
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
