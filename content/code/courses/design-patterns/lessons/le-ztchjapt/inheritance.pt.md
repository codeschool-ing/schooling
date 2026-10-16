---
title: "Herança: uma classe definida como mudança de outra"
version: 1
---

**Herança diz que uma classe é outra classe com algumas diferenças.** O filho recebe todos os campos
e métodos do pai e pode acrescentar ou substituir. É o recurso que a maioria dos cursos ensina
primeiro e aquele que este curso vai passar a lição 2 dizendo para você usar por último, então vale
ver exatamente o que ele faz antes de qualquer discussão.

A biblioteca empresta mais do que livros. Um livro sai por 14 dias, um filme em DVD por 7, e uma
obra de referência não sai. Os três compartilham quase tudo: um título, uma cota de estante, um
jeito de dizer quanto dura o empréstimo. A herança põe a parte comum num lugar só.

```schooling-example
{"language": "python", "file": "items.py", "parts": [
 {"code": "# items.py\nclass Item:\n    loan_days = 14\n\n    def __init__(self, title: str, shelf: str):\n        self.title = title\n        self.shelf = shelf\n\n    def describe(self) -> str:\n        return f\"{self.title} [{self.shelf}], {self.loan_days} days\"", "note": "O pai guarda o que todo item tem. `loan_days` é um atributo de classe: um valor compartilhado por todas as instâncias, até um filho dizer outra coisa."},
 {"code": "\n\nclass Book(Item):\n    pass", "note": "`Book(Item)` se lê como *um Book é um Item*. Com o corpo vazio, é um `Item` com outro nome, o que basta para o `isinstance` distinguir os dois."},
 {"code": "\n\nclass Film(Item):\n    loan_days = 7\n\n    def __init__(self, title: str, shelf: str, minutes: int):\n        super().__init__(title, shelf)\n        self.minutes = minutes\n\n    def describe(self) -> str:\n        return super().describe() + f\", {self.minutes} min\"", "note": "Um filme muda um valor, acrescenta um campo e estende um método. `super()` é a versão do pai, então o filho acrescenta à descrição em vez de reescrevê-la."},
 {"code": "\n\nclass ReferenceBook(Item):\n    loan_days = 0\n\n    def describe(self) -> str:\n        return f\"{self.title} [{self.shelf}], reading room only\"", "note": "Este substitui `describe` por inteiro. Guarde-o: a lição 3 o usa para mostrar o que dá errado quando um filho não consegue cumprir uma promessa que o pai fez."},
 {"code": "\n\nif __name__ == \"__main__\":\n    shelf = [\n        Book(\"Grande Sertão: Veredas\", \"869.3 ROS\"),\n        Film(\"Central do Brasil\", \"DVD 791 SAL\", 113),\n        ReferenceBook(\"Aurélio\", \"R 469.3 FER\"),\n    ]\n    for item in shelf:\n        print(item.describe())\n    print(isinstance(shelf[1], Item), isinstance(shelf[1], Book))\n    print([cls.__name__ for cls in Film.__mro__])"}
]}
```

```
ana@laptop:~/patterns/oo$ python3 items.py
Grande Sertão: Veredas [869.3 ROS], 14 days
Central do Brasil [DVD 791 SAL], 7 days, 113 min
Aurélio [R 469.3 FER], reading room only
True False
['Film', 'Item', 'object']
```

A última linha é a **ordem de resolução de métodos**: quando `describe` é chamado num filme, o Python
procura em `Film`, depois em `Item`, depois em `object`, e roda o primeiro que encontrar. Toda
linguagem com herança tem essa busca; Java e C# percorrem a mesma cadeia do filho para o pai. O
Python também permite que uma classe tenha vários pais, e aí a ordem é calculada por uma regra
chamada C3 — é para mostrar isso, quando importa, que `__mro__` existe.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 290\" role=\"img\" data-fig=\"l01-items\" aria-label=\"Um diagrama de classes de items.py. Item, no alto, tem os campos title, shelf e loan_days e o método describe. Três classes apontam para ele com pontas de seta vazadas, o que quer dizer que cada uma é um Item: Book não acrescenta nada; Film põe loan_days em 7, acrescenta minutes e sobrescreve describe; ReferenceBook põe loan_days em 0 e sobrescreve describe. Uma chamada a describe num Film procura primeiro em Film, depois em Item, depois em object.\"><rect x=\"260.0\" y=\"14.0\" width=\"180.0\" height=\"96.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"25.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Item</text><path d=\"M260.0 36.5 L440.0 36.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"268.0\" y=\"47.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">title: str</text><text x=\"268.0\" y=\"62.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shelf: str</text><text x=\"268.0\" y=\"76.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">loan_days = 14</text><path d=\"M260.0 88.0 L440.0 88.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"268.0\" y=\"99.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">describe()</text><rect x=\"40.0\" y=\"170.0\" width=\"180.0\" height=\"22.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><path d=\"M130.0 170.0 L130.0 145.0 L350.0 145.0 L350.0 110.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M350.0 110.5 L357.0 122.5 L343.0 122.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--panel)\"></path><text x=\"130.0\" y=\"208.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">não muda nada</text><rect x=\"260.0\" y=\"170.0\" width=\"180.0\" height=\"82.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Film</text><path d=\"M260.0 192.5 L440.0 192.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"268.0\" y=\"203.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">loan_days = 7</text><text x=\"268.0\" y=\"218.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">minutes: int</text><path d=\"M260.0 229.5 L440.0 229.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"268.0\" y=\"240.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">describe()</text><path d=\"M350.0 170.0 L350.0 145.0 L350.0 145.0 L350.0 110.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M350.0 110.5 L357.0 122.5 L343.0 122.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--panel)\"></path><text x=\"350.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">acrescenta e estende</text><rect x=\"480.0\" y=\"170.0\" width=\"180.0\" height=\"67.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ReferenceBook</text><path d=\"M480.0 192.5 L660.0 192.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"488.0\" y=\"203.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">loan_days = 0</text><path d=\"M480.0 215.0 L660.0 215.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"488.0\" y=\"226.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">describe()</text><path d=\"M570.0 170.0 L570.0 145.0 L350.0 145.0 L350.0 110.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M350.0 110.5 L357.0 122.5 L343.0 122.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--panel)\"></path><text x=\"570.0\" y=\"253.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">substitui describe</text><text x=\"560.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ponta vazada: &quot;é um&quot;</text></svg>", "caption": "Três filhos de um pai. Cada um herda os campos e o método, e dois deles mudam o que describe faz."}
```

## O que a herança acopla

Um filho depende de mais coisas do pai do que dos métodos públicos. `Film.describe` chama
`super().describe()` e conta com o que ele devolve; `Film.__init__` conta com o construtor do pai
recebendo exatamente um título e uma cota. Mude qualquer um dos dois em `Item` e todo filho é
afetado, inclusive filhos escritos por gente que nunca contou a você que eles existiam. **Esse é o
custo: o interior do pai vira parte do contrato do filho.** A lição 2 chama isso de classe base
frágil e mede a velocidade com que cresce.

O Go não tem herança nenhuma, de propósito. Ele embute uma struct em outra, o que dá à de fora os
métodos da de dentro e nada mais; não existe `super`, e a struct de dentro nunca chama de volta a de
fora. O `class … extends` do JavaScript é herança sobre protótipos e se comporta como a do Python em
tudo o que esta lição mostra.
