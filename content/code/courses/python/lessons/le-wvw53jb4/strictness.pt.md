---
title: O padrão que passa quase tudo
version: 1
---

```python
def somar(a, b):
    return a + b

somar("x", 3)
```

```text
Success: no issues found in 1 source file
```

**Uma primeira passagem que não diz nada em geral quer dizer que nada foi verificado.** Uma função
sem anotação não é um erro para o `mypy` — é uma função sobre a qual ele não tem opinião, e toda
chamada a ela é uma chamada que ele não consegue julgar.

A reação honesta a uma primeira passagem limpa numa base sem anotações não é alívio.

## O que ele verifica assim mesmo

```python
somar(1, 2, 3)
```

```text
error: Too many arguments for "add"  [call-arg]
```

Aridade, nomes e importações são estruturais: uma chamada com três argumentos para uma função que
recebe dois está errada sejam quais forem os tipos. Então mesmo no seu mais frouxo o verificador
não está fazendo nada.

## `--strict`, e o que ele liga

```sh
mypy --strict app/
```

```text
error: Function is missing a type annotation  [no-untyped-def]
error: Call to untyped function "add" in typed context  [no-untyped-call]
error: Returning Any from function declared to return "dict[Any, Any]"  [no-any-return]
error: Missing type parameters for generic type "dict"  [type-arg]
```

`--strict` não é um modo separado. É um atalho para uma lista de flags, e as quatro que mudam o seu
dia valem ser conhecidas pelo nome:

- **`disallow_untyped_defs`** — toda função precisa de anotação. É esta que transforma uma base
  silenciosa numa base barulhenta.
- **`disallow_untyped_calls`** — uma função anotada não pode chamar uma sem anotação. É isto que
  impede a metade verificada de se apoiar caladamente na metade não verificada.
- **`warn_return_any`** — uma função declarada como devolvendo `dict` não pode simplesmente
  devolver o que o `json.load` lhe deu. `Any` é como um tipo se perde sem ninguém reparar.
- **`disallow_any_generics`** — escreva `dict[str, int]`, não um `dict` pelado.

As demais são menores: `warn_redundant_casts`, `warn_unused_ignores`, `strict_equality`,
`no_implicit_reexport`, e mais algumas.

## `check_untyped_defs`, que é a interessante

```python
def total(itens):
    n: int = "zero"
    return n
```

```text
note: By default the bodies of untyped functions are not checked,
      consider using --check-untyped-defs  [annotation-unchecked]
```

O `mypy` lê a *assinatura* de uma função sem anotação e pula o *corpo* inteiro. Ligar isto
verifica dentro desses corpos sem exigir as assinaturas antes — **então ela acha coisas no primeiro
dia e não pede anotação a ninguém**, o que faz dela a flag mais barata de ligar numa base inteira.
