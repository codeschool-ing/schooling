---
title: A mesma coisa, escrita duas vezes
version: 2
---

O gerador, de antes:

```python
def countdown(n):
    while n > 0:
        yield n
        n -= 1
```

A mesma coisa como classe:

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "class Countdown:\n    def __init__(self, n):\n        self.n = n",
      "note": "**O `self.n` é o estado.** O gerador guarda o mesmo número na variável local `n`."
    },
    {
      "code": "    def __iter__(self):\n        return self",
      "note": "O `return self` é o que deixa um laço `for` usar o objeto, e é também por que o objeto, como todo iterador, se esgota depois de uma passada."
    },
    {
      "code": "    def __next__(self):\n        if self.n <= 0:\n            raise StopIteration",
      "note": "**O fim precisa ser anunciado.** O gerador para ao sair do `while`; a classe levanta o `StopIteration` ela mesma."
    },
    {
      "code": "        self.n -= 1\n        return self.n + 1",
      "note": "**Primeiro desce um, depois devolve o valor de antes do passo.** Esse é o `+ 1` de que o gerador nunca precisou."
    }
  ]
}
```

## O que a classe mostra

**Tudo o que a classe escreve por extenso, o gerador ganha de graça.** O frame dele — os locais,
a posição no corpo — é mantido vivo entre as chamadas, e o `__next__` é gerado para você.

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
class Rows:
    def __init__(self, path): self.path = path
    def __iter__(self):
        with open(self.path, encoding="utf-8") as f:
            yield from f
```

Um ITERÁVEL — `__iter__` novo a cada vez, e assim dá para percorrer duas vezes — com um gerador
dentro dele. Essa é a forma para algo reaproveitável apoiado numa fonte que dá para reabrir, e é o
único lugar em que as duas ideias ficam melhor juntas que separadas.

**Note o que não há aqui: nenhum `__next__`.** O `__iter__` é uma função geradora, então cada
chamada devolve um gerador novo, e o objeto em si nunca se esgota.
