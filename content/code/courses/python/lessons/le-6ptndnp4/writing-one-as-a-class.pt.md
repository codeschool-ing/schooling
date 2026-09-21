---
title: A mesma coisa, escrita duas vezes
version: 1
---

O gerador, de antes:

```python
def contagem(n):
    while n > 0:
        yield n
        n -= 1
```

A mesma coisa como classe:

```python
class Contagem:
    def __init__(self, n):
        self.n = n

    def __iter__(self):
        return self

    def __next__(self):
        if self.n <= 0:
            raise StopIteration
        self.n -= 1
        return self.n + 1
```

## O que a classe mostra

**O `self.n` é o estado, e a versão com `yield` guarda o mesmo estado numa variável local.** Essa é
a coisa inteira que um gerador faz: o frame da função — os locais dela, a posição dela no corpo —
é mantido vivo entre as chamadas, e o `__next__` é gerado para você.

O `return self` no `__iter__` é o que torna o objeto usável num laço `for`, e é também por que este
objeto, como todo iterador, se esgota depois de uma passada.

## Por que a versão com `yield` vence

- três linhas contra nove
- o estado fica onde você o procuraria, no corpo
- o laço é escrito como laço em vez de virado do avesso numa máquina de estados
- não há um `+ 1` para errar, e acima há

A versão com classe tem uma forma de defeito que o gerador não tem: o `__next__` precisa
reconstruir, em toda chamada, onde ele estava — e no momento em que há dois laços ou uma condição
no meio, essa reconstrução é a parte difícil.

## Quando uma classe ESTÁ certa

```python
class Linhas:
    def __init__(self, caminho): self.caminho = caminho
    def __iter__(self):
        with open(self.caminho, encoding="utf-8") as f:
            yield from f
```

Um ITERÁVEL — `__iter__` novo a cada vez, e assim dá para percorrer duas vezes — com um gerador
dentro dele. Essa é a forma para algo reaproveitável apoiado numa fonte que dá para reabrir, e é o
único lugar em que as duas ideias ficam melhor juntas que separadas.

**Note o que não há aqui: nenhum `__next__`.** O `__iter__` é uma função geradora, então cada
chamada devolve um gerador novo, e o objeto em si nunca se esgota.
