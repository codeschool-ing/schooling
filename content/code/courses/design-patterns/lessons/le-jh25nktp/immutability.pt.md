---
title: "Imutabilidade: valores que não mudam pelas suas costas"
version: 1
---

**A objeção comum a dados imutáveis é que desperdiçam memória copiando. O motivo comum para querê-los
é um bug que a cópia teria evitado.** Um objeto que pode ser mudado pode ser mudado por qualquer um
que tenha uma referência a ele, e num programa de qualquer tamanho mais de uma coisa tem a
referência. Todo lugar que guarda o objeto passa a ver a mudança, querendo ou não.

## O bug, e a cura

Uma renovação soma 14 dias a um empréstimo. Escrita como mutação, ela edita o empréstimo no lugar.
Escrita como valor, ela devolve um empréstimo novo e deixa o antigo em paz:

```schooling-example
{"language": "python", "file": "frozen.py", "parts": [
 {"code": "# frozen.py\nfrom dataclasses import FrozenInstanceError, dataclass, replace\nfrom datetime import date, timedelta", "note": "`replace` e `FrozenInstanceError` vêm os dois de `dataclasses`."},
 {"code": "\n\nclass MutableLoan:\n    def __init__(self, title: str, due: date):\n        self.title = title\n        self.due = due\n\n\ndef renew_in_place(loan: MutableLoan) -> None:\n    loan.due += timedelta(days=14)", "note": "Uma classe comum e uma função que a edita. Nada em nenhuma das duas parece errado."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Loan:\n    title: str\n    due: date\n\n\ndef renewed(loan: Loan) -> Loan:\n    return replace(loan, due=loan.due + timedelta(days=14))", "note": "`frozen=True` transforma a atribuição a um campo em erro. `replace` monta uma instância nova com os campos que você nomeia trocados e o resto copiado."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Member:\n    name: str\n    titles: list[str]", "note": "Congelada também, mas guardando uma lista. A demonstração abaixo mostra o que isso significa."},
 {"code": "\n\nif __name__ == \"__main__\":\n    first = MutableLoan(\"Dom Casmurro\", date(2026, 3, 16))\n    history = [first]\n    renew_in_place(first)\n    print(\"history, mutable:\", history[0].due)", "note": "O histórico devia registrar o empréstimo como era. Ele guarda uma referência, não uma cópia, então a renovação reescreveu o histórico."},
 {"code": "\n    loan = Loan(\"Dom Casmurro\", date(2026, 3, 16))\n    history = [loan]\n    new = renewed(loan)\n    print(\"history, frozen:\", history[0].due, \"| renewed:\", new.due)\n    try:\n        loan.due = date(2026, 4, 30)\n    except FrozenInstanceError as err:\n        print(\"refused:\", err)", "note": "Os mesmos passos com um empréstimo congelado. O histórico mantém a data antiga, a renovação é um valor separado, e uma tentativa de editar o antigo é recusada."},
 {"code": "\n    bia = Member(\"Bia\", [\"Iracema\"])\n    bia.titles.append(\"Dom Casmurro\")\n    print(\"frozen, but the list inside is not:\", bia.titles)", "note": "Congelar impede `bia.titles = ...`. Não impede que a lista seja mudada por `append`."}
]}
```

```
ana@laptop:~/patterns/functional$ python3 frozen.py
history, mutable: 2026-03-30
history, frozen: 2026-03-16 | renewed: 2026-03-30
refused: cannot assign to field 'due'
frozen, but the list inside is not: ['Iracema', 'Dom Casmurro']
```

**Com o empréstimo mutável, o histórico diz que o livro vencia em 30 de março, o que nunca foi
verdade no momento do registro.** Nada lançou erro; o programa simplesmente guarda um registro
falso. Com o empréstimo congelado, o histórico mantém 16 de março, a renovação é um valor novo com
30 de março, e `loan.due = ...` para com `cannot assign to field 'due'`.

## Rasa, não profunda

A última linha da saída é a armadilha. `frozen=True` protege os campos do objeto, então `bia.titles`
não pode apontar para outra lista. A lista em si é uma lista mutável comum, e `append` a muda. Um
objeto congelado só é tão imutável quanto os valores que guarda.

A correção é guardar valores imutáveis até o fundo: uma `tuple` em vez de uma `list`, um
`frozenset` em vez de um `set`, e outras dataclasses congeladas em vez de objetos comuns.
`titles: tuple[str, ...]` faria de `bia.titles.append` um `AttributeError`, e acrescentar um título
seria `replace(bia, titles=bia.titles + ("Dom Casmurro",))`, mais um valor novo.

## A cópia é um custo?

`replace` copia os campos, não os objetos a que eles se referem: o empréstimo novo compartilha a
string `title` com o antigo. Para registros de uma dúzia de campos isso é desprezível perto de uma
chamada ao banco. Onde não é, em coleções grandes mudadas com frequência, as linguagens funcionais
usam **estruturas de dados persistentes**, que compartilham a maior parte da estrutura entre
versões, de modo que uma versão nova de um mapa de um milhão de elementos custa um punhado de nós
novos. A biblioteca padrão do Python não tem nenhuma; `tuple` e `frozenset` são copiados inteiros.
Isso é motivo para guardar a imutabilidade para os valores do domínio, os empréstimos, membros e
dinheiro das lições 12 e 14, e não para cada buffer do programa.

O que a imutabilidade compra em troca é a garantia de que nenhuma outra parte do programa consegue
mudar um valor que você está segurando. Bugs de apelido como o do histórico acima não acontecem, um
valor pode ser compartilhado entre threads sem trava, e um valor pode ser chave de dicionário ou
membro de conjunto porque o hash nunca muda. Uma dataclass congelada ganha um `__hash__` por esse
motivo, e uma comum não.
