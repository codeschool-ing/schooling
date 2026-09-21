---
title: Um verificador lê o programa e não executa nada dele
version: 1
---

```python
taxas = {"BRL": 1.0, "USD": 5.4}

def achar(codigo: str) -> float | None:
    return taxas.get(codigo)

def total(valor: float, codigo: str) -> float:
    return valor * achar(codigo)
```

```sh
a.py:7: error: Unsupported operand types for * ("float" and "None")  [operator]
a.py:7: note: Right operand is of type "float | None"
```

**Nada executou.** Nenhum arquivo foi aberto, nenhum `total` foi chamado, nenhum teste existia. O
verificador leu as anotações, seguiu `achar` até o seu `return`, viu que `dict.get` responde
`None` quando a chave não está lá, e olhou o que a linha 7 faz com o resultado.

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
def media(valores: list[float]) -> float:
    return sum(valores) * len(valores)
```

Correto em todo tipo e errado do único jeito que importa. Um verificador não tem opinião sobre `*`
contra `/`, sobre a fórmula estar ao contrário, nem sobre o arquivo ser o arquivo errado.

**Um verificador não é um teste.** Ele diz que as peças encaixam; não diz nada sobre a coisa que
elas montam ser a coisa que você queria. A aula 16 é a outra metade, e nenhuma das duas substitui
a outra.

## E aquele sobre o qual ele é honesto

```python
linha = {"cidade": "Recife", "codigo": "BR"}
print(linha["ciidade"])
```

```sh
Success: no issues found in 1 source file
```

Um `dict[str, str]` comum aceita qualquer string como chave, então o erro de digitação é uma
expressão válida que levanta `KeyError` em tempo de execução. **O verificador só sabe o que os
tipos lhe contaram** — e o `TypedDict` da aula 14 é como você conta, que é quando a mesma linha
vira `TypedDict "Row" has no key "citty"` com um `Did you mean "city"?` embaixo.
