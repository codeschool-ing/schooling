---
title: O `sys.path`, e o arquivo que você chamou de `random.py`
version: 1
---

```python
import sys
sys.path
# ['', '/usr/lib/python3.12', '/usr/lib/python3/dist-packages', ...]
```

Um import percorre essa lista em ordem e pega a primeira coincidência. A primeira entrada é o
diretório do script que está rodando — que é esta seção inteira.

## O sombreamento

```
$ ls
random.py      meu_jogo.py
```

`meu_jogo.py` diz `import random`. O Python olha o diretório atual primeiro, encontra o SEU
`random.py`, e importa aquele. Aí `random.choice(...)` levanta `AttributeError: module 'random' has
no attribute 'choice'` — nomeando uma função que certamente existe, num módulo que certamente está
instalado.

**O erro está dizendo a verdade sobre o arquivo errado.** `random.__file__` imprime de onde o
módulo de fato veio, e é o único comando que resolve isto em cinco segundos.

Os nomes que as pessoas tomam por acidente são os óbvios: `random.py`, `json.py`, `email.py`,
`test.py`, `string.py`, `types.py`. É também por isso que o `__pycache__` importa aqui — um `.pyc`
velho do seu módulo sombreador sobrevive ao arquivo que você apagou.

## O que mais está no caminho

Os site packages — onde o `pip install` põe as coisas — e a biblioteca padrão. Você não edita o
`sys.path` em código comum: acrescentar a ele no topo de um arquivo para alcançar um módulo um
diretório acima é o arranjo que funciona na sua máquina e em nenhuma outra.

As respostas suportadas são um pacote com `__init__.py`, rodar com `python -m`, e — para qualquer
coisa de verdade — instalar o seu projeto, que é o que a aula 18 cobre.

## De onde ele veio

```python
import json
json.__file__          # /usr/lib/python3.12/json/__init__.py
```

Três perguntas são respondidas por essa linha: ele é meu ou da biblioteca, é a versão que eu penso,
e ele está instalado. **Recorra a ela assim que um import fizer algo surpreendente.**
