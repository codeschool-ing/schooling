---
title: A f-string, e o que vem depois dos dois pontos
version: 1
---

```python
nome = "Ada"
print(f"Olá, {nome}")
```
```
Olá, Ada
```

Um `f` antes da aspa, e chaves em volta de **qualquer expressão** — não só de um nome:

```python
>>> f"{2 + 2}"
'4'
>>> f"{nome.upper()}"
'ADA'
```

## `=` para depurar

```python
>>> total = 41
>>> f"{total=}"
'total=41'
```

O nome e o valor, com um caractere. É o idioma de depuração por `print` no Python moderno e vale a
memória muscular.

## A especificação de formato

Depois de dois pontos dentro das chaves, você diz **como**:

```python
>>> f"{3.14159:.2f}"
'3.14'
>>> f"{1234567:,}"
'1,234,567'
>>> f"{0.734:.1%}"
'73.4%'
>>> f"{42:>8}"
'      42'
>>> f"{42:08}"
'00000042'
```

| | |
|---|---|
| `.2f` | duas casas decimais, fixas |
| `,` ou `_` | separador de milhar |
| `%` | como porcentagem, e multiplica por 100 |
| `>` `<` `^` | à direita, à esquerda, ao centro, numa largura |
| `0` | preencher com zeros |
| `e` | científica |
| `b` `o` `x` | binário, octal, hexadecimal |

**A largura pode ser uma variável**: `f"{nome:>{w}}"`.

## Chaves que você quer manter

Dobre: `f"{{literal}}"` imprime `{literal}`.

## Os dois jeitos mais antigos

Você vai encontrar os dois em código que não escreveu.

```python
"Olá, {}".format(nome)     # .format, do Python 2.6
"Olá, %s" % nome           # %, desde o começo
```

Os dois continuam funcionando. Nenhum dos dois vale ser escrito agora, com uma exceção honesta:
chamadas de log usam a forma `%` de propósito, para a formatação ser pulada quando a mensagem não
vai ser emitida.

## O que uma f-string não é

Ela não é um modelo que você guarda e preenche depois — é avaliada onde está escrita. E ela **não**
é como se monta SQL, um comando de shell ou HTML. O `sql-databases` tem uma seção sobre exatamente
o buraco que uma f-string abre ali, e a resposta é um parâmetro, toda vez.
