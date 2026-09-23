---
title: O que desliga, e o que não desliga
version: 2
---

```python
from typing import Any

def handle(payload: Any) -> None:
    payload.anything()        # no complaint
    payload + 1               # no complaint
    payload[0]                # no complaint
```

`Any` quer dizer **pare de conferir este valor**. Tudo é permitido nele, e tudo a que ele é
passado é permitido.

## `object` mantém o verificador ligado

```python
def handle(payload: object) -> None:
    payload.anything()        # error: "object" has no attribute "anything"
```

`object` é o topo da hierarquia de classes: todo valor É um, então qualquer coisa dá para passar —
e quase nada dá para fazer com ele até você estreitar.

```python
    if isinstance(payload, dict):
        payload["key"]        # fine here
```

**O `object` diz "eu aceito qualquer coisa e vou conferir antes de usar".** O `Any` diz "eu aceito
qualquer coisa e você faz o que quiser". O primeiro é quase sempre o que alguém quis dizer.

## Por que o `Any` se espalha

```python
data: Any = json.load(f)
rows = data["rows"]           # rows is Any
first = rows[0]               # Any
name = first["name"]          # Any — and three functions later, still Any
```

Um `Any` escorre por tudo que ele toca, e a conferência para em todo lugar que ele alcança. É por
isso que um `Any` merece um comentário: ele não é uma decisão local.

## Onde o `Any` está certo

- dado cuja forma varia de verdade e é validado na fronteira
- o `*args, **kwargs` de um decorador, antes de você partir para as anotações difíceis
- a lacuna num arquivo que você está anotando aos poucos

## E o que um verificador faz sem anotação nenhuma

Um parâmetro sem anotação é tratado como `Any` por padrão. Então um arquivo sem anotações não está
"sem conferência porque está errado" — ele está sem conferência porque nada foi afirmado. A aula 15
tem o ajuste que torna isso um erro.
