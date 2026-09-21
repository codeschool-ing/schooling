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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Um import percorre a lista de caminhos em ordem e pega a primeira coincidência. A primeira entrada é o diretório do script que está rodando, então um arquivo seu chamado random.py é achado antes de a biblioteca padrão sequer ser consultada.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"56\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">import random percorre esta lista, nesta ordem</text> <rect x=\"56\" y=\"34\" width=\"300\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"206\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o diretório do script que está rodando</text> <text x=\"380\" y=\"54\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">e o seu está aqui: random.py</text> <rect x=\"56\" y=\"86\" width=\"300\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"206\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">/usr/lib/python3.12</text> <text x=\"380\" y=\"106\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o de verdade está aqui, e nunca é consultado</text> <rect x=\"56\" y=\"138\" width=\"300\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"206\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">/usr/lib/python3/dist-packages</text> <path d=\"M34 190 L34 42\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"26\" y=\"208\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">a primeira coincidência vence, e o percurso para</text> <text x=\"360\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">random.__file__ imprime de onde o módulo realmente veio.</text> <text x=\"360\" y=\"249\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">É o único comando que resolve isso em cinco segundos.</text> </svg>", "caption": "Não há nada errado com a maquinaria. O import achou um random.py — só não era o que você queria."}
```

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
