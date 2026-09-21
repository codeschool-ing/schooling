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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Os nomes a e b são duas setas apontando para uma lista só. Acrescentar por qualquer um dos nomes muda a única lista a que os dois se referem, porque a atribuição b = a não copiou nada.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"24\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">dois nomes</text> <rect x=\"24\" y=\"32\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"84\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\">a</text> <rect x=\"24\" y=\"96\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"84\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\">b</text> <path d=\"M150 52 L322 74\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <path d=\"M150 116 L322 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"448\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">uma lista, num endereço só</text> <rect x=\"328\" y=\"32\" width=\"240\" height=\"104\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"448\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\">[1, 2, 3, 4]</text> <text x=\"360\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Uma tabela de um milhão de linhas é entregue assim a uma função, sem ser copiada.</text> <text x=\"360\" y=\"185\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">É surpresa exatamente uma vez, e depois disso é ferramenta.</text> </svg>", "caption": "Uma atribuição entre nomes move uma seta. Ela nunca duplica aquilo para onde a seta aponta."}
```

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
