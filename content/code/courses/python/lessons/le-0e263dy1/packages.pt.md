---
title: Um diretório de módulos, e os dois tipos de import
version: 1
---

```
relatorio/
    __init__.py
    carregar.py
    formatar.py
```

Um pacote é um diretório. `import relatorio.carregar` funciona porque o diretório tem um
`__init__.py` — e desde o Python 3.3 ele em geral funciona sem um também, que é uma mudança que
causa confusão em vez de tirá-la. **Escreva o `__init__.py`.** Um arquivo vazio é a coisa mais
clara que você pode dizer.

## Para que serve o `__init__.py`

Ele roda quando o pacote é importado pela primeira vez. Dois usos honestos:

```python
# relatorio/__init__.py
from .carregar import carregar_linhas    # reexportar, e quem chama escreve relatorio.carregar_linhas
__version__ = "1.2.0"
```

Qualquer coisa mais longa que isso é trabalho acontecendo na importação, que é o problema da seção
anterior um nível acima.

## Absoluto e relativo

```python
from relatorio.carregar import carregar_linhas   # absoluto
from .carregar import carregar_linhas            # relativo — o pacote em que este arquivo está
from ..comum import utils                        # um nível acima
```

**Absoluto dentro de um projeto, relativo dentro de um pacote feito para ser movido ou
renomeado.** A regra que importa mais: um import relativo só funciona quando o arquivo está sendo
importado COMO PARTE DE um pacote. Rode `python relatorio/carregar.py` direto e `from .algo import
x` levanta erro — o arquivo foi rodado, então ele não está num pacote, e o ponto não tem a que se
referir.

Esse erro — `attempted relative import with no known parent package` — quer dizer exatamente isso,
e o conserto é `python -m relatorio.carregar`.

## O import circular

```python
# a.py
import b
# b.py
import a
```

Cada um está meio construído quando o outro o lê, e a falha é um `AttributeError` sobre um nome que
claramente existe. Quase sempre é sinal de que algo pertence a um terceiro módulo que os dois
importam — ou de que os dois eram um módulo só desde o começo.
