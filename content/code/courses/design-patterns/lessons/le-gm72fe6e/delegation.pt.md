---
title: "Delegação: guardar um objeto em vez de ser um"
version: 1
---

**Delegação é composição posta para trabalhar: um objeto guarda outro e repassa chamadas a ele,
acrescentando no caminho o que precisa.** A prateleira que conta, da primeira seção, escrita desse
jeito guarda um `Shelf` em vez de ser um. Ela sobrevive às duas versões de `shelf.py`, por um motivo
que vale ver com precisão.

Às vezes se descreve a delegação como herança feita à mão, a mesma coisa com mais digitação. A
digitação é real. A igualdade não: um objeto guardado chama os próprios métodos em si mesmo, nunca
no objeto que o guarda, então a chamada a `self` que quebrou o `CountingShelf` não tem como chegar
ao invólucro.

```schooling-example
{"language": "python", "file": "counted.py", "parts": [
 {"code": "# counted.py\nfrom shelf import Shelf\n\n\nclass CountedShelf:\n    def __init__(self, shelf: Shelf):\n        self._shelf = shelf\n        self.added = 0", "note": "Sem classe pai. A prateleira é entregue de fora e guardada num campo, como o canal do membro na lição 1."},
 {"code": "\n    def add(self, title: str) -> None:\n        self.added += 1\n        self._shelf.add(title)\n\n    def add_all(self, titles: list[str]) -> None:\n        self.added += len(titles)\n        self._shelf.add_all(titles)", "note": "Cada método conta e depois repassa. Quando o `add_all` da prateleira de dentro chama `self.add`, o `self` dele é o `Shelf` de dentro, então o contador não é tocado uma segunda vez."},
 {"code": "\n    def __len__(self) -> int:\n        return len(self._shelf)", "note": "Todo método que o invólucro oferece tem de ser escrito, inclusive os que ele não muda em nada. Esse é o preço."},
 {"code": "\n\nif __name__ == \"__main__\":\n    shelf = CountedShelf(Shelf())\n    shelf.add(\"Dom Casmurro\")\n    shelf.add_all([\"Vidas Secas\", \"Iracema\", \"O Cortiço\"])\n    print(\"on the shelf:\", len(shelf))\n    print(\"counted:     \", shelf.added)\n    print(\"is a Shelf?  \", isinstance(shelf, Shelf))", "note": "Os mesmos quatro títulos de antes, e mais uma pergunta no fim."}
]}
```

O seu `shelf.py` é a segunda versão, a que estende a lista. Rode:

```
ana@laptop:~/patterns/composition$ python3 counted.py
on the shelf: 4
counted:      4
is a Shelf?   False
```

Agora ponha de volta o primeiro `shelf.py`, aquele cujo `add_all` faz um laço sobre `add`, e rode de
novo:

```
ana@laptop:~/patterns/composition$ python3 counted.py
on the shelf: 4
counted:      4
is a Shelf?   False
```

Quatro nas duas vezes. **O invólucro depende do que os métodos de `Shelf` fazem, nunca de como
fazem**, que é exatamente a dependência que o autor de `Shelf` consegue ver e respeitar.

## O que a delegação custa

A última linha de cada execução é o primeiro custo. Um `CountedShelf` não é um `Shelf`, então um
código que testa `isinstance(x, Shelf)`, ou um método Java declarado para receber um `Shelf`, o
recusa. A cura é depender de uma descrição dos métodos em vez de uma classe: um `Protocol` em
Python, uma `interface` em Java, Go e TypeScript, que é como funcionava o `Channel` da lição 1. A
lição 4 transforma isso em princípio.

O segundo custo é o repasse. Um invólucro em volta de uma classe com vinte métodos precisa de vinte
métodos de uma linha, dezenove dos quais não acrescentam nada. O Python oferece um atalho, e ele é
uma armadilha:

```python
class CountedShelf:
    def __getattr__(self, name):
        return getattr(self._shelf, name)
```

`__getattr__` é chamado para qualquer atributo que o invólucro não tenha, então todo método de
`Shelf` é repassado sem ser escrito. (Menos `len()`, na verdade: o Python procura métodos especiais
na classe e nunca por `__getattr__`, então `__len__` continua tendo de ser escrito.) Funciona hoje.
No dia em que `Shelf` ganhar um `add_many`, o invólucro o repassa em silêncio e sem contar, e o
relatório volta a errar, sem que nada em `counted.py` tenha mudado. **Repassar tudo automaticamente
traz de volta o acoplamento que a delegação devia remover**, um método novo de cada vez. Escreva o
repasse, e deixe que um método novo do objeto de dentro seja algo que o invólucro decide oferecer.

## A mesma ideia nas outras três linguagens

| linguagem | como um invólucro repassa | o que acontece quando o tipo de dentro ganha um método |
|---|---|---|
| Python | um método por chamada repassada, ou `__getattr__` | escrito à mão: nada; `__getattr__`: repassado em silêncio |
| Java | um método por chamada, muitas vezes gerado pela IDE | nada, até alguém escrever o método |
| Go | embutir a struct: `type CountedShelf struct { *Shelf; added int }` | promovido automaticamente, como com `__getattr__` |
| TypeScript | um método por chamada | nada, até alguém escrever o método |

O embutimento do Go merece uma frase à parte. Ele promove os métodos do tipo de dentro para o de
fora, então poupa a digitação, e o `AddAll` de dentro continua chamando o `Add` de dentro, então a
contagem dupla não acontece. Mas ele tem a mesma fraqueza do `__getattr__`: um método acrescentado a
`Shelf` aparece em `CountedShelf` sem ninguém ter escolhido. Kotlin tem uma palavra-chave para a
mesma ideia, `class CountedShelf(s: Shelf) : Shelf by s`, que repassa tudo e deixa você sobrescrever
o que muda.

## A delegação não serve só para invólucros

`CountedShelf` mantém a interface do que guarda, e isso faz dele um invólucro; a lição 6 chama esse
formato de decorator. Com mais frequência, um objeto delega a partes que têm interfaces próprias: um
empréstimo pede um número à sua regra de multa, um membro pede ao seu canal que entregue. O
mecanismo é o mesmo, e é ele que a próxima seção usa para mudar o comportamento de um empréstimo com
o programa rodando.
