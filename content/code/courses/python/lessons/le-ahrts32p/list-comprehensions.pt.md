---
title: `[f(x) for x in xs if p(x)]`
version: 1
---

```python
com_desconto = [preco * 0.9 for preco in precos if preco > 100]
```

Seis linhas de laço numa, e a primeira coisa que ela diz é **o que está sendo construído**.

## Lendo

A ordem em que se escreve não é a ordem em que roda:

```
[  preco * 0.9        for preco in precos      if preco > 100  ]
   o que guardar      de onde vem              quais
```

A execução vai da direita para a esquerda: pegue cada preço, teste, e se passar, avalie a expressão.
A leitura vai da esquerda para a direita, que é o que a torna legível.

## As formas

```python
[x * 2 for x in xs]                  # mapear
[x for x in xs if x > 0]             # filtrar
[x * 2 for x in xs if x > 0]         # os dois
[y for linha in grade for y in linha]  # achatar — os laços na ordem em que você os escreveria
```

**A aninhada é a única que surpreende.** As cláusulas `for` se leem da esquerda para a direita
exatamente como comandos `for` aninhados, que é o oposto do que a maioria supõe.

## Quando ela deixa de ser mais clara

```python
# três condições e uma expressão condicional — isto é um laço
[transformar(x) if ok(x) else alternativa(x) for x in xs if a(x) and b(x)]
```

Duas regras que se sustentam:

**Se não couber numa linha, é um laço.** Não "quebre a linha" — a quebra é o sinal.

**Se você quiser fazer qualquer coisa além de construir um valor, é um laço.** Uma compreensão não
registra em log, não dá `break`, não atribui a nada fora de si. Isso é uma qualidade — é por isso que
dá para confiar no que uma delas faz numa olhada — e é também a fronteira.

## Para o que ela não serve

```python
[print(x) for x in xs]      # não
```

Isso constrói uma lista de `None` e a joga fora, pelo efeito colateral. Escreva o laço; tem o mesmo
comprimento e diz o que quer dizer.
