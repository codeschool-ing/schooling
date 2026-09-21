---
title: A indentação é o bloco
version: 1
---

```python
if nota >= 70:
    print("aprovado")
elif nota >= 50:
    print("limítrofe")
else:
    print("reprovado")
```

Dois pontos encerram cada linha de cabeçalho, e as linhas indentadas embaixo são o bloco. Não há
`end`, não há chaves, e mover uma linha quatro espaços muda a qual ramo ela pertence.

## `elif` em vez de um `if` aninhado

```python
if nota >= 70:
    ...
else:
    if nota >= 50:      # funciona, e deriva para a direita sem fim
        ...
```

O `elif` é uma palavra-chave para exatamente isso, e mantém plana uma cadeia de cinco condições.

**Os ramos são tentados em ordem e o primeiro que casa vence.** Então ordene do mais específico ao
menos: uma cadeia começando em `if nota >= 50` nunca chegaria ao caso do 70.

## A expressão condicional

```python
rotulo = "aprovado" if nota >= 70 else "reprovado"
```

Um valor ou o outro, numa expressão. Lê-se do meio para fora, o que exige um instante na primeira
vez. Use quando os dois lados forem curtos; use um `if` quando algum não for.

**Não existe o ternário `?:`** em Python, e foi isto que o substituiu.

## `match`, num parágrafo

O Python 3.10 acrescentou `match`/`case`, que vale reconhecer:

```python
match comando:
    case "start":
        ...
    case _:
        ...
```

Ele é bem mais que um `switch` — desestrutura formas — e uma cadeia de `elif` continua sendo a
resposta comum para comparar um valor com alguns poucos. Este curso não volta a usá-lo.

## Aninhamento, e a cláusula de guarda

```python
def enviar(usuario):
    if usuario is None:
        return
    if not usuario.verificado:
        return
    ...
```

Dois retornos cedo em vez de dois níveis de `if`. **Quanto mais fundo um bloco está, mais difícil é
saber o que é verdade dentro dele**, e tirar os casos impossíveis do caminho logo no topo mantém o
corpo num nível só. A aula 5 tem o `return`; esta forma vale conhecer agora, porque é como a maioria
das funções reais é escrita.
