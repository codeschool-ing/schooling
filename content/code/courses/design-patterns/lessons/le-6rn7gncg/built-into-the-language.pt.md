---
title: Quando a linguagem já tem o padrão
version: 1
---

**Vários padrões GoF existem porque o C++ e o Smalltalk de 1994 não tinham um recurso, e numa
linguagem que tem o recurso o padrão encolhe para uma linha ou desaparece.** A própria introdução do
livro diz que a escolha da linguagem molda o que conta como padrão. Um padrão é um contorno com nome,
e um contorno deixa de ser necessário quando a linguagem faz o trabalho.

Peter Norvig disse isso sem rodeios em 1996, numa palestra chamada *Design Patterns in Dynamic
Languages*. Olhando para Lisp e Dylan, ele concluiu que 16 dos 23 padrões eram invisíveis ou mais
simples ali, porque essas linguagens tinham funções de primeira classe, classes que são elas mesmas
objetos, e macros. O Python tem as duas primeiras, e o JavaScript também, e em boa parte o Go e o
Java moderno.

## Quatro padrões numa dúzia de linhas

As mesmas ideias das seções anteriores, escritas com o que o Python oferece.

```schooling-example
{"language": "python", "file": "vanish.py", "parts": [
 {"code": "# vanish.py\nfrom functools import cache, partial\n\nrequests = [(\"Bia\", 1, 4), (\"Caio\", 2, 0), (\"Duda\", 3, 1)]\n\n\ndef fewest_loans(request):\n    member, placed, held = request\n    return (held, placed)\n\n\nprint(\"queue:\", [member for member, *_ in sorted(requests, key=fewest_loans)])", "note": "Strategy: a regra é uma função, passada para uma função que recebe regras. `sorted` e o seu `key` sempre foram o padrão strategy."},
 {"code": "\nlisteners = [lambda title: print(f\"  alert: {title} is in\"),\n             lambda title: print(f\"  count: one more return, {title}\")]\nfor listen in listeners:\n    listen(\"Vidas Secas\")", "note": "Observer: uma lista de chamáveis. Qualquer função com os argumentos certos é um ouvinte, sem interface para declarar."},
 {"code": "\nshelf = {\"Dom Casmurro\"}\nhistory = []\n\n\ndef lend(title):\n    shelf.remove(title)\n    history.append(partial(shelf.add, title))\n\n\nlend(\"Dom Casmurro\")\nprint(\"after lending:\", shelf)\nhistory.pop()()\nprint(\"after undo:\", shelf)", "note": "Command: o desfazer é uma função guardada para depois. `partial` captura a chamada e o seu argumento, que era tudo o que `Lend.undo` fazia."},
 {"code": "\nlookups = 0\n\n\n@cache\ndef lookup(isbn):\n    global lookups\n    lookups += 1\n    return f\"book {isbn}\"\n\n\nfor isbn in [\"012-3\", \"014-7\", \"012-3\", \"012-3\"]:\n    lookup(isbn)\nprint(\"asked 4 times, looked up\", lookups)", "note": "Decorator e proxy ao mesmo tempo: `@cache` embrulha `lookup` numa função com a mesma assinatura que responde ela mesma às chamadas repetidas, como `CachingCatalogue`."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 vanish.py
queue: ['Caio', 'Duda', 'Bia']
  alert: Vidas Secas is in
  count: one more return, Vidas Secas
after lending: set()
after undo: {'Dom Casmurro'}
asked 4 times, looked up 2
```

As outras seções da lição já mostraram mais três desses. A factory era um dicionário de classes, o
que funciona porque uma classe Python é um objeto que se guarda e se chama. O singleton era um
módulo. O iterator era um gerador.

## O que sobra depois da linguagem

| padrão | o que o absorve em Python | em Java, Go, TypeScript |
|---|---|---|
| Strategy | uma função passada como argumento | lambdas (Java 8 em diante), valores `func`, funções |
| Command | uma closure ou `partial` | uma lambda ou `Runnable`; uma `func`; uma closure |
| Observer | uma lista de chamáveis | lambdas ouvintes; canais ou fatias de `func`; emissores de eventos |
| Iterator | `for`, geradores, `yield` | `for` aprimorado; range sobre funções (Go 1.23); `function*` |
| Decorator (de uma função) | sintaxe `@`, `functools.wraps` | embrulhos; middleware HTTP como `func(h) h`; decorators (TS 5.0) |
| Singleton | um objeto no nível do módulo | um `enum`; uma variável de pacote; um export de módulo |
| Factory | um dicionário de classes | um mapa de funções construtoras nas três |
| Visitor | `match` com padrões de classe (3.10 em diante) | padrões em `switch` (Java 21); type switch; uniões discriminadas |

**O que sobrevive é a ideia, não as classes.** Uma função passada a `sorted` continua sendo uma
strategy: a decisão continua separada do código que a usa, e tudo o que foi dito sobre quando isso
compensa continua valendo. Saber o nome permite ver o projeto numa linha de Python, e explicar a um
colega de Java por que ela não precisa de interface.

Alguns padrões sobrevivem com a estrutura intacta. Um decorator de um objeto com vários métodos,
como uma política de multa que também precisasse se descrever, precisa de uma classe; o `@` só
embrulha funções isoladas. State, facade, adapter e builder tratam de como as responsabilidades se
dividem, não de um recurso que falta, e ficam bem parecidos em qualquer linguagem. **Os padrões que
desaparecem são os de passar comportamento de um lado para outro; os de onde ficam as fronteiras
permanecem.** A lição 15 retoma o primeiro grupo pelo lado funcional, onde passar comportamento de um
lado para outro é o programa inteiro.
