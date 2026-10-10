---
title: "Substituição de Liskov: filhos cumprem as promessas dos pais"
version: 1
---

**O princípio da substituição de Liskov diz que um código escrito contra um tipo pai precisa
continuar funcionando, sem saber disso, quando recebe qualquer filho desse tipo.** Barbara Liskov o
enunciou numa palestra em 1987 e, com Jeannette Wing, em 1994, deu a ele a forma precisa usada
hoje. É a regra que torna o polimorfismo seguro: o código da lição 1 que chamava `deliver` sem
perguntar que canal tinha estava contando com ela.

O mal-entendido comum é achar que substituição é questão de tipos. Se o filho tem todos os métodos
do pai, com os mesmos nomes e os mesmos argumentos, o compilador fica satisfeito, e em Python nada é
verificado. **Um filho pode bater perfeitamente com a assinatura do pai e ainda assim quebrar todo
mundo que o chama**, porque aquilo em que quem chama confia é o comportamento: o que um método
aceita, o que promete devolver, o que continua verdadeiro sobre o objeto.

## Uma promessa numa docstring

Os itens da lição 1, reduzidos ao que esta seção precisa, e com a promessa de `lend` escrita:

```schooling-example
{"language": "python", "file": "items.py", "parts": [
 {"code": "# items.py\nfrom datetime import date, timedelta\n\n\nclass Item:\n    loan_days = 14\n\n    def __init__(self, title: str):\n        self.title = title\n\n    def lend(self, on: date) -> date:\n        \"\"\"Lend the item on a day and return its due date, which is later.\"\"\"\n        return on + timedelta(days=self.loan_days)", "note": "O contrato do pai: qualquer dia é aceito, e a data devolvida é posterior a ele. Quem chama vai escrever código que se apoia nas duas metades."},
 {"code": "\n\nclass Book(Item):\n    pass\n\n\nclass Film(Item):\n    loan_days = 7", "note": "Dois filhos que cumprem a promessa: um livro por 14 dias, um filme por 7."},
 {"code": "\n\nclass ReferenceBook(Item):\n    def lend(self, on: date) -> date:\n        raise ValueError(f\"{self.title!r} is for the reading room only\")", "note": "Mesmo nome, mesmo argumento, mesmo tipo de retorno declarado. Um verificador de tipos aceita. Ele não cumpre a promessa: se recusa a emprestar."},
 {"code": "\n\ndef check_out(items: list[Item], on: date) -> None:\n    for item in items:\n        print(f\"{item.title:<22} due {item.lend(on)}\")", "note": "Um código escrito contra `Item`, como seria o do balcão. Ele nunca ouviu falar de livros de referência."},
 {"code": "\n\nif __name__ == \"__main__\":\n    check_out([Book(\"Dom Casmurro\"), Film(\"Central do Brasil\"), ReferenceBook(\"Aurélio\")],\n              date(2026, 3, 2))"}
]}
```

```
ana@laptop:~/patterns/solid-1$ python3 items.py
Dom Casmurro           due 2026-03-16
Central do Brasil      due 2026-03-09
Traceback (most recent call last):
  File "/home/ana/patterns/solid-1/items.py", line 35, in <module>
    check_out([Book("Dom Casmurro"), Film("Central do Brasil"), ReferenceBook("Aurélio")],
  File "/home/ana/patterns/solid-1/items.py", line 31, in check_out
    print(f"{item.title:<22} due {item.lend(on)}")
                                  ^^^^^^^^^^^^^
  File "/home/ana/patterns/solid-1/items.py", line 26, in lend
    raise ValueError(f"{self.title!r} is for the reading room only")
ValueError: 'Aurélio' is for the reading room only
```

`check_out` está correto: ele faz o que o tipo `Item` diz que pode ser feito. A falha está em
`ReferenceBook`, que diz ser um `Item` e não é um no sentido de que quem chama precisa. A reação
habitual é consertar quem chama, com um `isinstance(item, ReferenceBook)` antes de `lend`. Esse
teste é o sintoma. Toda função que empresta qualquer coisa passa a precisar dele, e todo filho novo
que recusa alguma coisa precisa de outro.

## As regras, enunciadas com precisão

A formulação de Liskov e Wing divide a promessa em partes que um revisor consegue verificar uma de
cada vez:

| regra | o que significa para um filho | `ReferenceBook` |
|---|---|---|
| pré-condições não podem ficar mais fortes | aceita pelo menos tudo o que o pai aceita | quebra: o pai empresta em qualquer dia, o filho em nenhum |
| pós-condições não podem ficar mais fracas | garante pelo menos tudo o que o pai garante | nunca chega a um retorno |
| invariantes se mantêm | o que é sempre verdade sobre o pai continua verdade | — |
| regra do histórico | não permite mudanças de estado que o pai proíbe | — |

Um filho pode ir no sentido contrário à vontade: aceitar **mais** que o pai, ou prometer **mais**.
Um `Film` que aceitasse uma data no passado, ou garantisse um vencimento que nunca cai num domingo,
continuaria sendo um `Item` perfeitamente bom.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l03-contract\" aria-label=\"Dois painéis sobre a promessa de Item.lend. À esquerda, o que um método aceita: o pai aceita qualquer dia, desenhado como uma caixa; uma caixa tracejada em volta mostra que um filho pode aceitar mais. ReferenceBook não aceita dia nenhum, desenhado como uma caixa vazia dentro da do pai, o que quebra a regra. À direita, o que um método devolve: o pai promete um dia posterior, desenhado como uma caixa; uma caixa menor dentro dela mostra que um filho pode prometer mais, como nunca um domingo. Laptop devolve o mesmo dia, desenhado como um ponto fora da caixa do pai, o que quebra a regra.\"><text x=\"175.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o que lend aceita</text><rect x=\"20.0\" y=\"34.0\" width=\"310.0\" height=\"230.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"175.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">um filho pode aceitar mais</text><rect x=\"55.0\" y=\"70.0\" width=\"240.0\" height=\"170.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Item: qualquer dia</text><rect x=\"115.0\" y=\"150.0\" width=\"120.0\" height=\"46.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"175.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">ReferenceBook</text><text x=\"175.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">nenhum dia: quebra</text><text x=\"175.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pré-condições: nunca mais fortes</text><path d=\"M360.0 20.0 L360.0 290.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"540.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o que lend devolve</text><rect x=\"400.0\" y=\"50.0\" width=\"280.0\" height=\"190.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Item: um dia posterior</text><rect x=\"450.0\" y=\"110.0\" width=\"180.0\" height=\"60.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"540.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">um filho pode prometer mais:</text><text x=\"540.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">nunca um domingo</text><circle cx=\"540.0\" cy=\"258.0\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"552.0\" y=\"258.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">Laptop: o mesmo dia, fora</text><text x=\"540.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pós-condições: nunca mais fracas</text></svg>", "caption": "Um filho pode aceitar mais que o pai e prometer mais. Não pode aceitar menos, como ReferenceBook, nem prometer menos, como Laptop."}
```

## O que o princípio diz sobre o conserto

A conclusão honesta é que um livro de referência não é um item emprestável, e a hierarquia dizia
que era. A lição 1 marcou isso dando a ele `loan_days = 0`, o que parece inofensivo e é a mesma
violação numa forma mais discreta, como mostra a próxima seção. O conserto é parar de afirmar isso:
um `Item` com título e estante, e o empréstimo como uma capacidade separada que só alguns itens têm.
Dividir o que um objeto afirma nas partes de que cada cliente precisa é o primeiro princípio da
lição 4.

Em toda linguagem a verificação fica com pessoas e com testes. O compilador do Java verifica que
`lend` tem a assinatura certa e nada sobre o que ele faz; as interfaces do Go, os tipos do
TypeScript e os protocolos do Python são iguais. A próxima seção mostra a ferramenta que verifica
comportamento: um conjunto de testes, escrito para o pai, rodado contra cada filho.
