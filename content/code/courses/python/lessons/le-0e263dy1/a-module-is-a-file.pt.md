---
title: Um módulo é um arquivo, e um import é uma busca
version: 1
---

```python
import math
math.sqrt(16)
```

`math` é um arquivo chamado `math.py` — ou, no caso deste, algo embutido no interpretador. O
`import` o encontra, o roda uma vez, e liga o nome `math` ao resultado.

## As quatro formas

```python
import math                      # math.sqrt
from math import sqrt            # sqrt
from math import sqrt, pi        # os dois nomes
import numpy as np               # um apelido
```

**`import modulo` é o padrão**, porque `math.sqrt(x)` diz de onde o `sqrt` veio e `sqrt(x)` não
diz. Num arquivo de trezentas linhas, essa é a diferença entre ler e procurar.

O `from … import` ganha o lugar dele quando o nome é usado o tempo todo e não é ambíguo — `from
pathlib import Path`, `from collections import Counter`. Um apelido é para um nome longo usado
muito, e os apelidos que as pessoas usam são convenções: `np`, `pd`, `plt`. **Não invente um
novo.**

## O `import *`

```python
from math import *       # não
```

Todo nome público, no seu arquivo, sem nada dizendo isso. Duas coisas acontecem então e nenhuma é
barulhenta: um nome seu é silenciosamente substituído, e quem lê a linha duzentos não descobre de
onde veio o `gamma`.

O único lugar em que ele se defende é uma sessão interativa, onde não existe linha duzentos.

## O módulo roda uma vez

```python
# config.py
print("carregando config")
AJUSTES = ler_ajustes()
```

O primeiro `import config` roda o arquivo. Todo import posterior — de qualquer outro módulo —
recebe o mesmo objeto já carregado, e o print acontece uma vez. É por isso que o nível de topo de
um módulo é um bom lugar para uma constante e um mau lugar para trabalho com efeito.

## Importar não copia

```python
from config import AJUSTES      # o mesmo dicionário, com outro nome
```

O `b = a` da aula 3, atravessando a fronteira de um arquivo. Mudá-lo por um nome muda para todo
módulo que o importou — o que de vez em quando é o que um registro quer, e em geral é uma
surpresa.
