---
title: `None` é um valor, e `is None` é como se pergunta
version: 1
---

`None` é o valor que significa *não há valor*. É um objeto de verdade, existe exatamente um dele, e
o tipo dele é `NoneType`.

## De onde ele vem

**Uma função sem `return` devolve ele.** É de longe a forma mais comum de encontrá-lo:

```python
>>> resultado = print("olá")
olá
>>> resultado is None
True
```

O `print` faz o trabalho dele e não devolve nada, então `resultado` é `None`. Um método que altera
uma lista no lugar — `sort`, `append`, `reverse` — faz o mesmo, o que produz o clássico:

```python
>>> nomes = ["b", "a"]
>>> nomes = nomes.sort()      # nomes agora é None
```

O `sort` ordenou a lista e devolveu `None`, e a atribuição jogou a lista fora. O `sorted(nomes)`
devolve uma lista nova; o `nomes.sort()` é chamado pelo efeito e não se atribui.

## Perguntando

```python
if valor is None:
if valor is not None:
```

**`is` e não `==`.** O `is` pergunta se é o mesmo objeto, e só existe um `None`, então isto é exato e
rápido. `== None` em geral funciona e pode ser subvertido por uma classe que define `__eq__` mal — a
aula 6 mostra como. A convenção é `is`, em todo lugar, e o linter da aula 17 vai dizer isso.

## Como argumento padrão

```python
def saudar(nome, saudacao=None):
    if saudacao is None:
        saudacao = "Olá"
```

Parece o caminho longo e é o certo. A aula 3 tem a seção sobre por que `saudacao=[]` é um defeito que
cresce entre chamadas, e o `None` é o conserto exatamente disso.

## Ele não é zero, vazio nem falso

`None` é falso, o que significa que `if not valor` é `True` para `None`, `0`, `""` e `[]` igualmente.
Quando a diferença importa — e para um valor que veio de um arquivo ou de uma API em geral importa —
pergunte `is None`.
