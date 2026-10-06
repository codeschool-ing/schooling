---
title: Fake
version: 1
---

Um **fake** é uma implementação que funciona de verdade, mas pega um atalho que a produção não pode
pegar: guarda dados em memória em vez de num banco, grava arquivos numa pasta temporária em vez de
num armazenamento na nuvem, ou entrega e-mail numa lista em vez de num servidor SMTP. Ao contrário
de um stub, tem comportamento real. Pergunte duas vezes e ele lembra da primeira.

O fake do `shipquote` fica no lugar da tabela onde os pedidos são guardados:

```python
class FakeOrders:
    """Orders kept in a list: the real table's behaviour, without the table."""

    def __init__(self):
        self.rows = []

    def add(self, email, cents):
        self.rows.append((email, cents))
        return len(self.rows)
```

Guarda as linhas numa lista e distribui ids a partir de 1, como um `INTEGER PRIMARY KEY` faria. Isso
basta para `place`, que só precisa de `add` para guardar um pedido e devolver o id. O teste da
recusa da seção 03 lê `orders.rows` depois para conferir que nada foi guardado, e um stub não
ofereceria isso, porque um stub não guarda nada.

## Por que um fake, e não a tabela real

A tabela real funcionaria: os testes de integração da aula 1 já usam SQLite num diretório
temporário. Mas `place` é sobre a ordem de duas ações, guardar e depois avisar, e sobre a regra de
que uma recusa não faz nenhuma das duas. Nada disso depende de SQL. Um fake mantém esses testes na
camada rápida e os deixa independentes de um esquema que eles não exercitam.

**Um fake é código, e código pode estar errado.** Se `FakeOrders.add` devolvesse ids a partir de 0,
os testes que o usam passariam enquanto a produção se comportaria diferente. A defesa é a mesma que
a seção 10 aplica aos stubs: **rodar os mesmos testes contra o fake e contra a implementação real**,
para que os dois fiquem de acordo por outra coisa que não a memória. Para um store, isso quer dizer
um pequeno conjunto de testes, parametrizado sobre os dois, perguntando o que toda implementação
precisa fazer: um pedido adicionado pode ser achado, o primeiro id é 1, dois pedidos recebem dois
ids.

## Fakes que vale conhecer

Alguns fakes são tão comuns que viraram produto:

| colaborador real | fake conhecido |
|---|---|
| um servidor SMTP | um servidor local que guarda as mensagens para inspeção (MailHog, Mailpit) |
| armazenamento de objetos na nuvem | um servidor local que fala a mesma API (MinIO para S3) |
| um banco relacional | o mesmo motor num contêiner, subido a cada execução |
| o relógio | um objeto relógio que o teste avança à mão |

A última linha volta na aula 3: a regra de despacho do `shipquote` depende da hora, e um teste que
depende do relógio real passa ou falha conforme a hora do dia.
