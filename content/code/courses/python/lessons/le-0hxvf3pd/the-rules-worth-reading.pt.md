---
title: Quatro achados que são defeitos e não arrumação
version: 1
---

A maior parte do que um linter relata é arrumação. Estes não são, e cada um já foi para produção.

## `B006` — um argumento padrão mutável

```python
def load_rates(path, cache={}):
    if path in cache:
        return cache[path]
    cache[path] = read(path)
    return cache[path]
```

```sh
>>> load("a.json"); load("b.json")
>>> load.__defaults__
({'a.json': {...}, 'b.json': {...}},)
```

**O dicionário é criado uma vez, quando o `def` roda.** Ele não é por chamada — está preso ao
objeto função e vive enquanto o processo viver. Escrito como um cache parece que funciona, e ele
nunca esvazia, e é compartilhado por todo chamador, inclusive os dos testes.

O conserto é `cache=None` e `if cache is None: cache = {}` dentro.

## `E722` — um `except` pelado

```python
try:
    data = json.load(f)
except:
    return {}
```

`except:` captura **`BaseException`**, que inclui `KeyboardInterrupt` e `SystemExit`. Então um
Ctrl-C dentro daquele bloco é engolido, e um `NameError` na linha acima vira um dicionário vazio
que o resto do programa trata como dado de verdade.

`except Exception:` é a versão que pelo menos deixa você parar o processo.
`except json.JSONDecodeError:` é a que você queria.

## `B023` — uma variável de laço capturada por um fechamento

```python
out = []
for i in range(3):
    out.append(lambda: i)
[f() for f in out]        # [2, 2, 2]
```

```sh
B023 Function definition does not bind loop variable `i`
```

Os fechamentos compartilham a variável, não o valor dela, e o laço terminou com ela em `2`. Isso
chega em código de verdade como uma lista de callbacks montada num laço que fazem todos o trabalho
do último.

O conserto é um argumento padrão — `lambda i=i: i` — que prende o valor na definição, e é o único
caso em que a coisa contra a qual o `B006` avisa é a ferramenta certa.

## `A002` — sombrear um embutido

```python
def summarise(rows, filter=None, id=None, type=None):
    ...
```

Menos dramático, e morde onde você não vê: dentro daquela função, `filter`, `id` e `type` são os
argumentos e os embutidos estão inalcançáveis. Uma linha acrescentada depois que chama `type(x)`
ganha um `TypeError` sobre `None` não ser chamável, numa função que não mudou.

## E os que são arrumação

`F401` import sem uso, `I001` imports fora de ordem, `SIM103` devolver uma comparação pelo caminho
longo, `UP` reescrevendo sintaxe velha. Vale consertar, vale o `--fix`, não vale uma conversa —
que é a distinção que esta seção existe para fazer.
