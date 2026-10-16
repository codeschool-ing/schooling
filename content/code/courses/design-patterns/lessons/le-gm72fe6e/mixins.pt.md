---
title: "Mixins: herança usada para partes"
version: 1
---

**Um mixin é uma classe pequena que nunca é usada sozinha e existe para ser herdada junto com
outras, para acrescentar uma capacidade.** É a ideia da composição, uma classe feita de partes,
entregue pelo mecanismo da herança. O Python dá suporte direto a isso, porque uma classe pode ter
vários pais, e herda tanto a conveniência quanto o acoplamento escondido da primeira seção.

Às vezes os mixins são apresentados como a resposta à explosão de classes: em vez de
`BookStudentSms`, herdar `Book`, `Student` e `Sms` juntos. Isso continua exigindo uma classe
declarada por combinação, já que `class X(A, B, C)` é uma classe que alguém escreve. O que um mixin
faz bem é mais estreito: acrescentar a mesma capacidade pequena e independente a muitas classes que,
fora isso, não têm nada em comum.

## Quatro mixins e três classes

```schooling-example
{"language": "python", "file": "mixins.py", "parts": [
 {"code": "# mixins.py\nimport json\n\n\nclass AsDictMixin:\n    def as_dict(self) -> dict:\n        return {k: v for k, v in vars(self).items() if not k.startswith(\"_\")}", "note": "Uma capacidade: os campos públicos do objeto como um dicionário. Não tem `__init__` nem estado, e é isso que o torna seguro para misturar em qualquer coisa."},
 {"code": "\n\nclass JsonMixin:\n    def to_json(self) -> str:\n        return json.dumps(self.as_dict(), ensure_ascii=False)", "note": "Este chama `self.as_dict()`, um método que ele não define. Ele supõe, em silêncio, que outro mixin vai estar lá."},
 {"code": "\n\nclass ShelfLabelMixin:\n    def label(self) -> str:\n        return f\"{self.shelf} | {self.title}\"\n\n\nclass BarcodeLabelMixin:\n    def label(self) -> str:\n        return f\"*{self.code}*\"", "note": "Dois jeitos de imprimir uma etiqueta, os dois chamados `label`, os dois buscando campos que a classe hospedeira deveria ter."},
 {"code": "\n\nclass Book(JsonMixin, AsDictMixin, ShelfLabelMixin, BarcodeLabelMixin):\n    def __init__(self, title: str, shelf: str, code: str):\n        self.title = title\n        self.shelf = shelf\n        self.code = code\n\n\nclass Film(JsonMixin, AsDictMixin, BarcodeLabelMixin, ShelfLabelMixin):\n    def __init__(self, title: str, shelf: str, code: str):\n        self.title = title\n        self.shelf = shelf\n        self.code = code", "note": "Os mesmos quatro mixins nas duas classes. A única diferença é a ordem dos dois últimos entre os parênteses."},
 {"code": "\n\nclass Member(JsonMixin):\n    def __init__(self, name: str):\n        self.name = name", "note": "Um membro que queria JSON e pegou o mixin com esse nome."},
 {"code": "\n\nif __name__ == \"__main__\":\n    book = Book(\"Iracema\", \"869.3 ALE\", \"B-0042\")\n    film = Film(\"Cidade de Deus\", \"DVD 791 MEI\", \"F-0007\")\n    print(book.to_json())\n    print(book.label())\n    print(film.label())\n    print([cls.__name__ for cls in Film.__mro__])\n    try:\n        Member(\"Bia\").to_json()\n    except AttributeError as caught:\n        print(caught)"}
]}
```

```
ana@laptop:~/patterns/composition$ python3 mixins.py
{"title": "Iracema", "shelf": "869.3 ALE", "code": "B-0042"}
869.3 ALE | Iracema
*F-0007*
['Film', 'JsonMixin', 'AsDictMixin', 'BarcodeLabelMixin', 'ShelfLabelMixin', 'object']
'Member' object has no attribute 'as_dict'
```

A primeira linha é o mixin funcionando como prometido: `Book` ganhou JSON de graça. As três linhas
seguintes são os custos.

**A ordem dos pais é comportamento.** `Book` e `Film` herdam as mesmas quatro classes, e uma imprime
uma etiqueta de estante enquanto a outra imprime um código de barras. O Python percorre a ordem de
resolução de métodos e roda o primeiro `label` que encontra; a quarta linha mostra essa ordem para
`Film`, com `BarcodeLabelMixin` antes de `ShelfLabelMixin`. Nada avisou que havia dois métodos com o
mesmo nome. Reordene os pais de uma classe para deixá-los arrumados e você mudou o que ela faz.

**Um mixin pode depender de outro sem dizer.** `Member` pegou `JsonMixin` e levou um
`AttributeError` na primeira vez em que foi usado, porque `to_json` precisa de `as_dict`, de um
mixin de que `Member` nunca ouviu falar. É a classe base frágil de novo, agora entre irmãos: um pai
depende de um método que só outro pai fornece.

## A mesma ideia nas outras três linguagens

| linguagem | como uma classe ganha um mixin | dois mixins com o mesmo método |
|---|---|---|
| Python | listá-lo entre os pais | vence o que vem antes na ordem de resolução de métodos, em silêncio |
| Java | uma `interface` com métodos `default` | erro de compilação até a classe sobrescrever o método |
| Go | embutir duas structs | erro de compilação, *ambiguous selector*, quando o método é chamado |
| TypeScript | uma função que devolve `class extends Base` | vence o aplicado por último, em silêncio |

Java e Go recusam a ambiguidade, então o conflito de `mixins.py` não compilaria lá. Python e
TypeScript a resolvem por uma regra, e a regra é correta e fácil de esquecer.

## Quando um mixin tem o tamanho certo

Os mixins da própria biblioteca padrão mostram como é o tipo seguro. `collections.abc.Mapping` dá a
uma classe `get`, `keys`, `items` e `__contains__` assim que ela escreve `__getitem__`, `__iter__` e
`__len__`, e **a documentação lista esses três como o que o mixin exige**. As chamadas que ele faz a
`self` são o contrato, como `Notice.body` na seção anterior.

Então um mixin é razoável quando não tem estado, acrescenta métodos que nenhum outro pai vai
definir, e diz de quais métodos ou campos da classe hospedeira depende. Quando ele precisa de estado
próprio, ou quando dois mixins começam a saber um do outro, eles querem ser objetos que a classe
guarda. Um `Labeller` num campo não liga para a ordem dos pais, e a falta de um falha quando o
objeto é criado, e não quando um método é chamado pela primeira vez.
