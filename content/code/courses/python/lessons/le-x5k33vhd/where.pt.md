---
title: Âncoras, e as duas funções que não são a mesma
version: 1
---

```
^      o começo da string (ou de uma linha, com re.MULTILINE)
$      o fim da string (ou de uma linha)
\b     uma fronteira de palavra
\A \Z  o começo e o fim da STRING, diga o MULTILINE o que disser
```

## O `\b`

```python
re.search(r"\bcat\b", "the cat sat")      # casa
re.search(r"\bcat\b", "concatenate")      # não casa
```

Uma fronteira de palavra é o lugar entre um `\w` e um não-`\w`. É o que transforma "contém" em
"contém como palavra", e é a âncora mais útil que existe.

## `match` contra `search`

```python
re.match(r"\d+", "abc 123")       # None  — ancorado no começo
re.search(r"\d+", "abc 123")      # '123' — em qualquer lugar
re.fullmatch(r"\d+", "123 ")      # None  — precisa cobrir a string inteira
```

**O `match` é ancorado no começo e o `search` não é.** Essa é a diferença inteira, e é a confusão
mais comum do módulo — um `re.match(r"error", linha)` procurando um nível no meio de uma linha não
acha nada e não diz nada.

O `match` NÃO é ancorado no fim: `re.match(r"\d+", "123abc")` casa sem reclamar. O `fullmatch` é o
que exige a string inteira, e é o que você quer para validar um campo.

## O `$` e a quebra de linha final

```python
re.search(r"\d$", "42\n")        # casa
```

O `$` casa no fim da string E logo antes de uma quebra de linha final. Isso é conveniente ao ler
linhas e surpreendente ao validar — o `\Z` é a versão estrita, e o `fullmatch` evita a questão.

## `re.MULTILINE`

```python
re.findall(r"^ERROR.*", texto, re.MULTILINE)
```

Faz o `^` e o `$` significarem o começo e o fim de cada LINHA em vez dos da string inteira. Sem
isso, um padrão ancorado com `^` acha no máximo uma coincidência numa string de várias linhas — o
que se lê como o padrão estar errado.
