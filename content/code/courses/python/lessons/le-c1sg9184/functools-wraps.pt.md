---
title: O nome que o wrapper comeu
version: 2
---

```python
@timed
def load_rows(path):
    """Read the rows from a CSV."""

load_rows.__name__      # 'wrapper'
load_rows.__doc__       # None
help(load_rows)         # describes the wrapper
```

O nome `load_rows` agora se refere ao wrapper, e a identidade do próprio wrapper é o que
tudo enxerga. **Isso não é cosmético** — é toda linha de log, todo quadro de traceback, e toda
documentação, para toda função que você decorou.

## O conserto

```python
import functools

def timed(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        ...
    return wrapper
```

Uma linha. Ela copia `__name__`, `__doc__`, `__module__`, `__qualname__` e `__dict__` da função
envolvida para o wrapper, e define `__wrapped__` para a original continuar alcançável.

## O que continua quebrado sem ela

- uma linha de log que diz `wrapper` nove vezes e não diz qual
- o `help()` e a dica do editor descrevendo a maquinaria
- o `doctest` da aula 16 não achando docstring nenhuma
- um framework de testes que coleta por nome achando nove funções chamadas `wrapper`
- o `pickle` falhando na função decorada, que é uma tarde estranha

## O que o `wraps` NÃO conserta

A assinatura, para qualquer coisa que a inspecione a fundo. O `inspect.signature` segue o
`__wrapped__` e acerta; algumas ferramentas antigas não seguem, e veem `(*args, **kwargs)`.

**Esse é o limite honesto**, e raramente é o que morde. O nome e a docstring são o que morde.

## Escreva toda vez

Não existe caso em que um decorador fique melhor sem ela. Ponha o `@functools.wraps(func)` na
função de dentro enquanto digita, antes do corpo, e ela nunca é a coisa que você está depurando.
