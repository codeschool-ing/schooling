---
title: O bloco é do tamanho da coisa que pode falhar
version: 1
---

```python
try:
    porta = int(bruto)
except ValueError:
    porta = 5432
```

O `try` segura a coisa que pode falhar. O `except` nomeia a classe e diz o que fazer. É a
construção inteira.

## Mantenha o `try` pequeno

```python
try:                              # NÃO
    linhas = carregar(caminho)
    total = sum(l["valor"] for l in linhas)
    relatar(total)
except KeyError:
    ...
```

Três coisas na rede e uma delas é a que você queria. O `KeyError` que você esperava era de
`l["valor"]`; o que você acabou de capturar pode ser de dentro do `relatar`, três arquivos adiante
— e você nunca vai saber, porque o tratamento é o mesmo.

**Ponha o `try` em volta da linha que falha**, e de nada mais.

## Vários tipos

```python
except FileNotFoundError:
    ...
except PermissionError:
    ...
except OSError as e:          # qualquer outra coisa do sistema de arquivos
    ...
```

As cláusulas são tentadas em ordem e a PRIMEIRA que casa vence, então as específicas vêm antes. Uma
classe base acima de uma subclasse faz da cláusula da subclasse código morto, e o Python não vai
avisar.

## `as e`, e o que fazer com ele

```python
except ValueError as e:
    raise ValueError(f"{caminho}: a porta precisa ser um número, não {bruto!r}") from e
```

Capturar uma falha para dizer algo melhor sobre ela é uma das duas boas razões para capturar. A
outra é ter uma alternativa — um padrão, um segundo servidor, uma linha a pular.

**"Porque pode falhar" não é uma razão.** Se o tratamento não sabe o que fazer, o código acima
talvez saiba, e o traceback certamente sabe.

## O tratamento que esconde o defeito

```python
except Exception:
    pass          # as duas linhas mais caras deste curso
```

Um `pass` num tratamento quer dizer: algo deu errado, e eu decidi que ninguém precisa saber. Se uma
falha é mesmo segura de ignorar, o tratamento diz isso num comentário e nomeia a classe — e esse
comentário é o que quem lê precisa seis meses depois.
