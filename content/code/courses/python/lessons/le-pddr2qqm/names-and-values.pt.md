---
title: Um nome é um rótulo num valor, não uma caixa
version: 1
---

```python
x = 5
```

Leia como *o nome `x` agora se refere ao valor 5*, e não *a caixa chamada `x` agora contém 5*. A
diferença é invisível com números e vira a história inteira na aula 3.

## Reatribuir

```python
x = 5
x = "cinco"
```

Perfeitamente legal. O nome deixa de se referir ao número e passa a se referir à string. Python tem
**tipagem dinâmica**: valores têm tipo, nomes não.

Isso é liberdade e é também corda. Um nome que guarda um número num ramo e uma string em outro é um
nome sobre o qual ninguém consegue raciocinar, e é exatamente para isso que servem as anotações da
aula 14.

## Dois nomes, um valor

```python
a = [1, 2, 3]
b = a
b.append(4)
print(a)
```
```
[1, 2, 3, 4]
```

`b = a` não copiou nada. Os dois nomes se referem à mesma lista, e mudá-la por um aparece pelo outro.
`id(a) == id(b)` é `True` — o `id` é a identidade do próprio valor.

**Com números e strings você nunca vai reparar**, porque eles não podem ser alterados no lugar. Com
listas e dicionários é a seção `copying` da aula 3, e é a surpresa mais comum da linguagem.

## Nomear

`snake_case`, minúsculas, e um nome que diga o que a coisa é. Letras, dígitos e sublinhados; sem
começar com dígito.

**Não dá para usar uma palavra-chave** — `class`, `import`, `from`, `is`, `in`, `lambda` e umas
trinta outras. `list = [1, 2]` não é palavra-chave e é legal, e continua sendo um erro: você acabou
de perder a capacidade de chamar `list()` no resto daquele escopo. O linter da aula 17 aponta
exatamente isso.

## Apagar

`del x` remove o nome. O valor vai embora quando nada mais se refere a ele, e isso é assunto do
interpretador e não seu.
