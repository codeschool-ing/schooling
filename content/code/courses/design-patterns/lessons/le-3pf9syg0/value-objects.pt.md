---
title: "Objetos de valor: iguais quando os valores são iguais"
version: 1
---

**Um objeto de valor é definido inteiramente pelos seus valores: dois deles com os mesmos valores
são intercambiáveis, e nenhum deles muda nunca.** Cinquenta centavos são cinquenta centavos;
ninguém pergunta *quais* cinquenta centavos. Uma data, um ISBN, um endereço e uma quantia de
dinheiro são valores. Quando um valor precisa ser diferente, você cria outro, do mesmo jeito que
`3 + 1` não muda o 3.

A ideia errada é achar que um tipo primitivo resolve. Uma quantia é um `int`, uma moeda é uma `str`,
uma multa é `days * 50`. Aí as regras do dinheiro moram em todo lugar onde o dinheiro é tocado: uma
função esquece a moeda, outra aceita `0.5`, uma terceira soma euros com reais porque os dois são
inteiros. Cada regra do valor se repete pelo código e não é imposta em lugar nenhum. **Um objeto de
valor é o lugar onde essas regras moram, uma vez.** A lição 14 chama a versão primitiva de cheiro,
a *obsessão por primitivos*.

A lição 1 guardava dinheiro como centavos inteiros num `int`, o que estava certo para uma classe.
Agora o dinheiro aparece em multas, em pagamentos e no limite para pegar emprestado, então ganha um
tipo:

```schooling-example
{"language": "python", "file": "money.py", "parts": [
 {"code": "# money.py\nfrom dataclasses import dataclass, replace\n\n\n@dataclass(frozen=True)\nclass Money:\n    cents: int\n    currency: str = \"BRL\"", "note": "`frozen=True` deixa todo campo somente leitura depois da construção, e o `__eq__` gerado compara os campos. Essas duas linhas são quase tudo o que um objeto de valor é."},
 {"code": "\n    def __post_init__(self) -> None:\n        if not isinstance(self.cents, int):\n            raise TypeError(f\"cents must be an int, not {type(self.cents).__name__}\")", "note": "Um objeto de valor se recusa a existir num estado sem sentido. Meio centavo é um desses estados."},
 {"code": "\n    def __add__(self, other: \"Money\") -> \"Money\":\n        if other.currency != self.currency:\n            raise ValueError(f\"cannot add {other.currency} to {self.currency}\")\n        return Money(self.cents + other.cents, self.currency)\n\n    def __sub__(self, other: \"Money\") -> \"Money\":\n        return self + Money(-other.cents, other.currency)\n\n    def times(self, n: int) -> \"Money\":\n        return Money(self.cents * n, self.currency)", "note": "A aritmética devolve um novo `Money` e nunca muda `self`. Somar duas moedas é recusado aqui, uma vez, em vez de em toda função que soma multas."},
 {"code": "\n    def __str__(self) -> str:\n        return f\"{self.currency} {self.cents // 100}.{self.cents % 100:02d}\""},
 {"code": "\n\nif __name__ == \"__main__\":\n    daily = Money(50)\n    fine = daily.times(3) + Money(25)\n    print(fine, \"|\", fine == Money(175), \"|\", fine is Money(175))\n    print(replace(fine, cents=0))\n    try:\n        fine.cents = 0\n    except AttributeError as err:\n        print(\"refused:\", type(err).__name__, err)\n    for bad in (lambda: fine + Money(100, \"EUR\"), lambda: Money(0.5)):\n        try:\n            bad()\n        except (ValueError, TypeError) as err:\n            print(\"refused:\", err)", "note": "A multa de três dias mais 25 centavos, comparada com um `Money` criado à parte; depois as três recusas."}
]}
```

```
ana@laptop:~/patterns/ddd-tactical$ python3 money.py
BRL 1.75 | True | False
BRL 0.00
refused: FrozenInstanceError cannot assign to field 'cents'
refused: cannot add EUR to BRL
refused: cents must be an int, not float
```

Três dias a 50 centavos mais 25 dão `BRL 1.75`, e isso é igual a um `Money(175)` criado à parte: o
primeiro `True`. Não é o mesmo objeto, o `False` depois dele, e isso não importa para um valor.
`replace` cria uma cópia alterada, aqui com zero centavos, e deixa o original em paz. Escrever num
campo é recusado com `FrozenInstanceError`, somar euros a reais é recusado, e meio centavo também.

## O que a imutabilidade compra

Um valor imutável pode ser compartilhado sem medo. O `FINE_LIMIT` da próxima seção é um único
`Money(1000)` com que todo sócio se compara; se algum código pudesse pôr o `cents` dele em 0, todo
sócio passaria do limite de uma vez. Como ele é congelado, ninguém consegue, e ninguém precisa fazer
uma cópia defensiva antes de passá-lo adiante.

Ela também simplifica o trabalho da entidade. O `owed` de um sócio é um `Money`. Para somar uma
multa, o sócio o substitui por `owed + fine`: uma atribuição, num método do sócio, e nada mais
consegue mudar a quantia pelas costas dele.

| linguagem | um objeto de valor |
|---|---|
| Python | `@dataclass(frozen=True)`, ou uma `NamedTuple` |
| Java | um `record`, cujos campos são final e cujo `equals` os compara |
| Go | uma struct pequena passada por valor, com campos não exportados e métodos que devolvem structs novas |
| TypeScript | uma classe com campos `readonly`, ou `Object.freeze`; `===` continua comparando referências, então acrescente um método `equals` |

O TypeScript é o desajeitado: `readonly` impede escritas em tempo de compilação, mas dois valores
iguais continuam sendo duas referências diferentes para o `===`. Um método `equals(other)`, usado de
propósito, é a resposta usual.

## Entidade ou valor?

O mesmo conceito pode ser um ou outro, dependendo do contexto, o que é a lição 11 de novo. No
empréstimo, um exemplar de *Vidas Secas* é uma entidade: o exemplar `C-0107` está com Bia e o
`C-0108` está na estante, e eles não são intercambiáveis. Nas aquisições, os dois exemplares de um
pedido são uma quantidade, 2, e ninguém liga para qual é qual até eles chegarem. Pergunte se alguém
se importaria de receber um igual no lugar. Se não, faça dele um valor.
