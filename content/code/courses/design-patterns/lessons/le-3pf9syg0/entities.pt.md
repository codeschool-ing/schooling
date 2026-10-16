---
title: "Entidades: a mesma coisa ao longo do tempo"
version: 1
---

**Uma entidade é um objeto definido pela identidade, e não pelos atributos: ela continua sendo a
mesma coisa enquanto tudo nela muda.** Uma sócia da biblioteca muda o telefone, o endereço e até o
nome, e continua sendo a sócia que está com três livros. O que a mantém a mesma é um identificador
que a biblioteca lhe deu e que nunca muda. A lição 11 traçou as linhas estratégicas; esta lição
preenche um contexto, o empréstimo, com os padrões táticos que Evans descreveu, começando por este.

A ideia errada é achar que dois objetos são o mesmo quando os campos são iguais. Para pessoas,
exemplares e empréstimos isso é falso nos dois sentidos. Duas sócias chamadas Ana Souza, com o
mesmo telefone porque moram na mesma casa, são duas sócias. Uma sócia com todos os campos editados é
uma sócia só. Um código que compara entidades pelos campos um dia vai fundir duas pessoas ou dividir
uma, e nenhum dos dois erros levanta exceção.

Trabalhe no diretório desta lição:

```sh
mkdir -p ~/patterns/ddd-tactical
cd ~/patterns/ddd-tactical
```

```schooling-example
{"language": "python", "file": "entities.py", "parts": [
 {"code": "# entities.py\nclass Member:\n    def __init__(self, member_id: str, name: str, phone: str):\n        self.id = member_id\n        self.name = name\n        self.phone = phone", "note": "Um sócio nasce com um id, e o id é a única coisa nele que nunca muda. Nome e telefone são atributos: verdadeiros hoje, editáveis amanhã."},
 {"code": "\n    def __eq__(self, other: object) -> bool:\n        return isinstance(other, Member) and other.id == self.id\n\n    def __hash__(self) -> int:\n        return hash(self.id)\n\n    def __repr__(self) -> str:\n        return f\"Member({self.id}, {self.name!r})\"", "note": "A igualdade, e o hash que precisa concordar com ela, olham o id e nada mais. O padrão do Python compararia os endereços dos objetos na memória, o que quebra na primeira vez que o mesmo sócio for carregado duas vezes."},
 {"code": "\n\nif __name__ == \"__main__\":\n    ana = Member(\"m-014\", \"Ana Souza\", \"+55 11 5550-0114\")\n    other_ana = Member(\"m-203\", \"Ana Souza\", \"+55 11 5550-0114\")\n    print(ana == other_ana, \"- same name and phone, different members\")\n\n    before = Member(\"m-014\", \"Ana Souza\", \"+55 11 5550-0114\")\n    ana.name = \"Ana Souza Lima\"\n    ana.phone = \"+55 11 5550-0199\"\n    print(ana == before, \"- every field changed, same member\")\n    print(len({ana, before, other_ana}), \"members in the set\")", "note": "Dois sócios com o mesmo nome e telefone, e depois um sócio cujos atributos mudam todos."}
]}
```

```
ana@laptop:~/patterns/ddd-tactical$ python3 entities.py
False - same name and phone, different members
True - every field changed, same member
2 members in the set
```

As duas Anas são sócias diferentes, e o conjunto conta duas sócias entre três objetos, porque `ana`
e `before` são uma sócia vista em dois momentos. **O id carrega a identidade, e os atributos são só
o que é verdade sobre a sócia hoje.**

## De onde vem o id

Uma entidade precisa do id desde o momento em que existe, o que descarta a resposta cômoda de deixar
o banco atribuir um no insert: até a linha ser gravada, o objeto não tem identidade e não pode ser
comparado, posto num conjunto nem referido por outro agregado. Três escolhas comuns:

| origem | exemplo | troca |
|---|---|---|
| o domínio já tem um | um número de carteirinha, um ISBN, um CPF | tem significado, mas pertence a outra pessoa e pode estar errado ou mudar |
| gerado pela aplicação | `uuid.uuid4()`, ou um código curto como `m-014` | disponível na hora, sem significado, nunca muda |
| uma sequência do banco | `INSERT ... RETURNING id` | curto, mas o objeto fica sem id até ser salvo |

A biblioteca usa os próprios números de carteirinha, `m-` seguido de dígitos, emitidos quando o
sócio se associa. O número aparece para o sócio e é digitado no balcão, então precisa ser curto; ele
é seguro como identidade porque a biblioteca o emite e nunca o reemite.

## Na sua linguagem

O Python compara objetos pela identidade na memória, a menos que a classe diga o contrário, e é por
isso que `entities.py` escreve `__eq__` e `__hash__`. As outras três linguagens têm a mesma escolha
a fazer, com a própria sintaxe:

| linguagem | igualdade pelo id |
|---|---|
| Java | sobrescrever `equals` e `hashCode` para usar o id; um `record` compararia todos os campos, o que é certo para um objeto de valor e errado aqui |
| Go | comparar `a.ID == b.ID` explicitamente; `==` em duas structs compara todos os campos, e em dois ponteiros compara endereços |
| TypeScript | comparar `a.id === b.id`; `===` em dois objetos compara referências, e não há operador para sobrescrever |

O `record` do Java e a igualdade de structs do Go são os padrões que comparam campos, e os dois são
exatamente o que a próxima seção quer para outro tipo de objeto.
