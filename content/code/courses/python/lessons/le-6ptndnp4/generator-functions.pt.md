---
title: O `yield`, e a função que pausa
version: 1
---

```python
def contagem(n):
    while n > 0:
        yield n
        n -= 1

for i in contagem(3):
    print(i)          # 3, 2, 1
```

Uma função com um `yield` em qualquer lugar dela é uma FUNÇÃO GERADORA. Chamá-la não roda nada do
corpo: ela devolve um objeto gerador. Cada `next` roda o corpo até o próximo `yield`, devolve
aquele valor, e **pausa ali** — com o `n` e todos os outros locais ainda vivos.

## O que ela substitui

```python
class Contagem:                      # a mesma coisa, à mão
    def __init__(self, n): self.n = n
    def __iter__(self): return self
    def __next__(self):
        if self.n <= 0: raise StopIteration
        self.n -= 1
        return self.n + 1
```

Oito linhas contra três, e as oito têm onde pôr um defeito. **Qualquer coisa que você escreveria
como classe guardando uma posição é um gerador em vez disso**, e a última seção desta aula escreve
uma dos dois jeitos de propósito.

## `return` dentro de um gerador

```python
def ate_a_linha_vazia(linhas):
    for linha in linhas:
        if not linha.strip():
            return            # encerra — nenhum valor volta
        yield linha
```

Um `return` pelado encerra o gerador, o que levanta `StopIteration` para quem chama. Um `return
valor` define o atributo `value` da exceção, que quase nada lê — então trate o `return` como
"pare" e dê `yield` em tudo que você pretende entregar.

## Repassar de outro gerador

```python
def os_dois(a, b):
    yield from a
    yield from b
```

O `yield from` entrega a outro iterável até ele se esgotar. É o mesmo que um laço `for` com um
`yield` dentro, e é mais curto e mais rápido.

## O caso a observar

```python
def carregado():
    linhas = caro()           # isto NÃO roda na hora da chamada
    for l in linhas:
        yield l
```

Nada no corpo acontece até o primeiro `next`. Esse é o ponto inteiro, e é uma surpresa quando a
linha cara estava ali para falhar cedo — um gerador que nunca é iterado nunca roda, e nunca
levanta erro.
