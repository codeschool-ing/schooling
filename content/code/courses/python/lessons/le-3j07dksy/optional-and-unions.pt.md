---
title: `X | None`, e a união que é sintoma
version: 1
---

```python
def achar(codigo: str) -> Taxa | None:
    ...
```

**A anotação mais útil da aula.** Ela diz que a função às vezes não acha nada, e um verificador
então aponta toda chamada que usou o resultado sem perguntar.

## A grafia antiga

```python
Optional[Taxa]        # do typing — a mesma coisa
Union[int, str]       # do typing — agora int | str
```

`Optional[X]` quer dizer `X | None` e nunca quis dizer "este argumento pode ser omitido", que é o
que o nome sugere e o que todo mundo supõe uma vez. A forma com `|` é a de escrever agora.

## Estreitar

```python
taxa = achar(codigo)
if taxa is None:
    return 0.0
return total * taxa          # aqui o verificador sabe que é uma Taxa
```

Um verificador segue o `if` e sabe que `taxa` não pode ser `None` abaixo dele. É isso que torna a
anotação útil em vez de irritante: você confere uma vez, e o resto da função fica limpo.

Um `if taxa is not None:` e um `return` antecipado fazem o mesmo, que é a cláusula de guarda da
aula 4 se pagando de novo.

## Um padrão `None`

```python
def conectar(timeout: int | None = None) -> None:
    if timeout is None:
        timeout = 30
```

A anotação é `int | None` e o padrão é `None`. Escrever `timeout: int = None` é um escorregão
comum, e um verificador recusa.

## Quando uma união é sintoma de projeto

```python
def carregar(fonte: str | Path | bytes | IO) -> list[dict]: ...
```

Quatro coisas, e o corpo precisa se ramificar sobre qual chegou. **Duas costuma estar bem; quatro
em geral é uma função que deveria ser duas funções**, ou uma que recebe algo estreito e um
chamador que converte.

A exceção honesta é uma fronteira — um analisador, um adaptador, a coisa que encontra o mundo lá
fora. Esse é o único lugar em que aceitar várias formas é o trabalho.
