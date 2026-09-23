---
title: Um verificador lê o programa e não executa nada dele
version: 2
---

```python
rates = {"BRL": 1.0, "USD": 5.4}

def find(code: str) -> float | None:
    return rates.get(code)

def total(amount: float, code: str) -> float:
    return amount * find(code)
```

```sh
a.py:7: error: Unsupported operand types for * ("float" and "None")  [operator]
a.py:7: note: Right operand is of type "float | None"
```

**Nada executou.** Nenhum arquivo foi aberto, nenhum `total` foi chamado, nenhum teste existia. O
verificador leu as anotações, seguiu `find` até o seu `return`, viu que `dict.get` responde
`None` quando a chave não está lá, e olhou o que a linha 7 faz com o resultado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 248\" role=\"img\" aria-label=\"O verificador lê as anotações e segue as chamadas: dict.get responde None quando a chave não está lá, então achar pode devolver None, então multiplicar pelo resultado dela pode multiplicar por None. O erro é relatado sem o programa nunca ter rodado.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <defs><marker id=\"ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs> <rect x=\"20\" y=\"26\" width=\"440\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"240\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">taxas.get(codigo) responde None quando a chave não está lá</text> <rect x=\"20\" y=\"72\" width=\"440\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"240\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">então find(code) pode devolver None</text> <path d=\"M240 62 L240 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <rect x=\"20\" y=\"118\" width=\"440\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"240\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">então amount * find(code) pode multiplicar por None</text> <path d=\"M240 108 L240 114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <rect x=\"20\" y=\"164\" width=\"440\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"240\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">error: Unsupported operand types for * (&quot;float&quot; and &quot;None&quot;)</text> <path d=\"M240 154 L240 160\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"592\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">o que de fato executou</text> <text x=\"592\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nenhum arquivo foi aberto</text> <text x=\"592\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">total() nunca foi chamada</text> <text x=\"592\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nenhum teste existia</text> </svg>", "caption": "Um teste acha o que você pensou em tentar. Um verificador segue cada chamada, inclusive o ramo que ninguém tomou."}
```

## O que isso acha que um teste não acharia

Um teste acha o que você pensou em tentar. Um verificador segue toda chamada do programa,
inclusive a ramificação que ninguém tomou e o chamador no arquivo que você não estava olhando.

```sh
error: Argument 1 to "totals" has incompatible type "list[str]"; expected "list[int]"  [arg-type]
error: Incompatible return value type (got "int", expected "str")  [return-value]
error: Item "None" of "Row | None" has no attribute "city"  [union-attr]
error: "Point" has no attribute "z"  [attr-defined]
error: Name "sendmail" is not defined  [name-defined]
error: Missing positional argument "name" in call to "greet"  [call-arg]
```

Cada um desses é um programa que importa sem queixa e levanta em algum momento no futuro. Os dois
últimos nem precisam de anotação — um nome escrito errado e uma chamada com a quantidade errada de
argumentos são achados num arquivo sem tipo nenhum dentro.

## O que ele não acha

```python
def average(values: list[float]) -> float:
    return sum(values) * len(values)
```

Correto em todo tipo e errado do único jeito que importa. Um verificador não tem opinião sobre `*`
contra `/`, sobre a fórmula estar ao contrário, nem sobre o arquivo ser o arquivo errado.

**Um verificador não é um teste.** Ele diz que as peças encaixam; não diz nada sobre a coisa que
elas montam ser a coisa que você queria. A aula 16 é a outra metade, e nenhuma das duas substitui
a outra.

## E aquele sobre o qual ele é honesto

```python
row = {"city": "Recife", "code": "BR"}
print(row["citty"])
```

```sh
Success: no issues found in 1 source file
```

Um `dict[str, str]` comum aceita qualquer string como chave, então o erro de digitação é uma
expressão válida que levanta `KeyError` em tempo de execução. **O verificador só sabe o que os
tipos lhe contaram** — e o `TypedDict` da aula 14 é como você conta, que é quando a mesma linha
vira `TypedDict "Row" has no key "citty"` com um `Did you mean "city"?` embaixo.
