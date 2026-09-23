---
title: Suas classes, um apelido, e uma forma para o JSON
version: 2
---

## Uma classe é um tipo

```python
class Student: ...

def enrol(student: Student) -> None: ...
```

Não há o que declarar. Toda classe que você escreve serve como anotação, e uma subclasse é aceita
onde o pai é pedido.

## Um apelido, para a forma que você repete

```python
Row = dict[str, str]
Rows = list[Row]

def load(path: Path) -> Rows: ...
```

Uma atribuição comum. Ela encurta a assinatura e dá à forma um nome que quem lê reconhece — e
mudar a forma é então uma linha.

`type Rows = list[Row]` é a sintaxe da 3.12 para a mesma coisa, com a vantagem de ser
inequivocamente um tipo e não um valor.

## `NewType`, quando duas coisas da mesma forma não podem se misturar

```python
from typing import NewType

UserId = NewType("UserId", int)
OrderId = NewType("OrderId", int)

def load_user(uid: UserId) -> User: ...
load_user(OrderId(7))        # the checker refuses
```

Os dois são inteiros em tempo de execução e nenhum custa nada. O que isso compra é que passar o
errado é um erro — que é o defeito invisível de todo outro jeito.

## `TypedDict`, para o JSON da aula 9

```python
from typing import TypedDict

class Row(TypedDict):
    name: str
    city: str
    score: int

def parse(data: dict) -> list[Row]: ...
```

Ele é um dicionário em tempo de execução — o mesmo `{"name": ...}` que você já tem — e um
verificador sabe quais chaves existem e o que cada uma guarda. O `row["ctiy"]` vira um erro em
vez de um `KeyError` em produção.

`total=False` torna toda chave opcional; `NotRequired[str]` marca uma.

**Esta é a anotação para dado que você analisou**, e é a que paga o esforço mais rápido em
qualquer coisa que saiu de um arquivo.
