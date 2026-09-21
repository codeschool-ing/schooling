---
title: O que desliga, e o que não desliga
version: 1
---

```python
from typing import Any

def tratar(carga: Any) -> None:
    carga.qualquer_coisa()    # nenhuma reclamação
    carga + 1                 # nenhuma reclamação
    carga[0]                  # nenhuma reclamação
```

`Any` quer dizer **pare de conferir este valor**. Tudo é permitido nele, e tudo a que ele é
passado é permitido.

## `object` mantém o verificador ligado

```python
def tratar(carga: object) -> None:
    carga.qualquer_coisa()    # erro: "object" has no attribute "qualquer_coisa"
```

`object` é o topo da hierarquia de classes: todo valor É um, então qualquer coisa dá para passar —
e quase nada dá para fazer com ele até você estreitar.

```python
    if isinstance(carga, dict):
        carga["chave"]        # aqui tudo bem
```

**O `object` diz "eu aceito qualquer coisa e vou conferir antes de usar".** O `Any` diz "eu aceito
qualquer coisa e você faz o que quiser". O primeiro é quase sempre o que alguém quis dizer.

## Por que o `Any` se espalha

```python
dados: Any = json.load(f)
linhas = dados["linhas"]      # linhas é Any
primeira = linhas[0]          # Any
nome = primeira["nome"]       # Any — e três funções depois, ainda Any
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
