---
title: A dúzia que carrega o trabalho
version: 2
---

Cada um destes devolve uma string **nova**. Nenhum altera aquela em que foi chamado.

## Limpando

```python
>>> "  ada  ".strip()
'ada'
>>> "ada.csv".removesuffix(".csv")
'ada'
```

O `strip` tira espaços dos dois lados; `lstrip` e `rstrip` tiram de um lado cada. Com um argumento
ele remove aqueles *caracteres*, e não aquela string:

```python
>>> "report.csv".strip(".csv")
'report'
>>> "discos.csv".strip(".csv")
'disco'
```

O primeiro é coincidência. `strip(".csv")` quer dizer *remova qualquer um entre `.`, `c`, `s`, `v`
das duas pontas, enquanto eles continuarem aparecendo* — e `discos` termina em `s`, então o `s` vai
junto. **Use `removesuffix` quando você quer dizer sufixo**, que é para isso que ele existe.

## Separando e juntando

```python
>>> "a,b,c".split(",")
['a', 'b', 'c']
>>> ",".join(["a", "b", "c"])
'a,b,c'
```

O `split` sem argumento separa em qualquer sequência de espaços e descarta os vazios, que é quase
sempre o que se quer para uma linha de texto.

**O `join` é chamado no separador**, o que parece de trás para frente até deixar de parecer. E é
também o jeito certo de montar uma string com muitas partes — a seção acima disse por quê.

## Perguntando

```python
>>> "report.csv".endswith(".csv")
True
>>> "ada" in "ada lovelace"
True
>>> "ada lovelace".find("love")
4
```

`startswith` e `endswith` aceitam uma tupla quando você quer vários:
`name.endswith((".csv", ".tsv"))`.

**O `find` devolve `-1` quando não achou** e o `index` levanta erro. Use `in` quando você só quer
saber.

## Mudando

```python
>>> "2026-09-21".replace("-", "/")
'2026/09/21'
>>> "Ada".lower(), "Ada".upper()
('ada', 'ADA')
```

O `replace` aceita uma contagem como terceiro argumento. O `casefold()` é o `lower()` para comparar
texto em línguas onde minúscula não basta, e é o certo para uma comparação que ignora caixa.

## A tabela que vale guardar

| | |
|---|---|
| `strip` `lstrip` `rstrip` | espaços das pontas |
| `split` `join` | separar, e juntar de volta |
| `replace` | um trecho por outro |
| `lower` `upper` `title` `casefold` | caixa |
| `startswith` `endswith` `find` `count` | perguntar |
| `removeprefix` `removesuffix` | quando você quer dizer prefixo ou sufixo |
| `zfill` `ljust` `rjust` | preenchimento, quando não há uma especificação de formato à mão |
| `isdigit` `isalpha` `isspace` | o que os caracteres são |

`dir("")` lista o resto, e `help(str.partition)` explica qualquer um deles sem sair do prompt.
