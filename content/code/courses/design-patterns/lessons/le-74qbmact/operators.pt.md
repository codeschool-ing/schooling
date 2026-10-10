---
title: "Operadores: um pipeline que cada valor percorre sozinho"
version: 1
---

**Um operador é uma função que recebe um observable e devolve um novo.** Quando alguém se inscreve no
novo, ele se inscreve no antigo, e cada valor que passa é transformado, retido ou somado no caminho.
Uma cadeia de operadores é um pipeline, e o valor que entra percorre o comprimento inteiro antes de o
próximo entrar. Essa última propriedade é o que diferencia um pipeline sobre um fluxo dos mesmos
passos sobre uma lista.

O engano comum é achar que `pipe` executa alguma coisa. Não executa: `pipe` só embrulha uma descrição
em outra. **Nada anda até alguém se inscrever no último observable da cadeia**, e aí as inscrições
correm rio acima, do fim da cadeia de volta à fonte, antes de o primeiro valor descer.

Aqui estão três operadores, escritos sobre o `observable.py` da seção 03, no mesmo diretório:

```schooling-example
{"language": "python", "file": "operators.py", "parts": [
 {"code": "# operators.py\nfrom observable import Observable, Sink", "note": "O import traz as duas classes da seção 03."},
 {"code": "\n\ndef map_(fn):\n    def operator(source: Observable) -> Observable:\n        def produce(sink: Sink) -> None:\n            source.subscribe(lambda v: sink.on_next(fn(v)), sink.on_error, sink.on_complete)\n        return Observable(produce)\n    return operator", "note": "`map_` transforma cada valor. O produtor dele se inscreve na fonte com um callback que aplica `fn` e repassa o resultado; erros e conclusão passam direto. O sublinhado deixa o `map` do próprio Python utilizável."},
 {"code": "\n\ndef filter_(keep):\n    def operator(source: Observable) -> Observable:\n        def produce(sink: Sink) -> None:\n            def forward(v) -> None:\n                if keep(v):\n                    sink.on_next(v)\n            source.subscribe(forward, sink.on_error, sink.on_complete)\n        return Observable(produce)\n    return operator", "note": "`filter_` só deixa passar um valor quando `keep` concorda. Um valor retido simplesmente não é repassado: não fica buraco no fluxo, nem `None`."},
 {"code": "\n\ndef scan(fn, seed):\n    def operator(source: Observable) -> Observable:\n        def produce(sink: Sink) -> None:\n            total = seed\n\n            def forward(v) -> None:\n                nonlocal total\n                total = fn(total, v)\n                sink.on_next(total)\n            source.subscribe(forward, sink.on_error, sink.on_complete)\n        return Observable(produce)\n    return operator", "note": "`scan` mantém um total acumulado e o emite depois de cada valor. O `total` dele é criado quando alguém se inscreve, então dois inscritos ganham cada um seu próprio total a partir da semente."},
 {"code": "\n\nif __name__ == \"__main__\":\n    returns = [(\"Dom Casmurro\", 0), (\"Vidas Secas\", 3), (\"Iracema\", 0), (\"O Cortiço\", 5)]\n\n    def produce(sink: Sink) -> None:\n        for title, days_late in returns:\n            print(f\"source: {title}, {days_late} days late\")\n            sink.on_next((title, days_late))\n        sink.on_complete()", "note": "A fonte imprime cada devolução antes de empurrá-la, então a saída mostra quando cada valor entra no pipeline."},
 {"code": "\n    fines = Observable(produce).pipe(\n        filter_(lambda r: r[1] > 0),\n        map_(lambda r: r[1] * 50),\n        scan(lambda total, cents: total + cents, 0),\n    )\n    fines.subscribe(lambda total: print(f\"  fines so far: {total} cents\"),\n                    on_complete=lambda: print(\"day closed\"))", "note": "Só as devoluções atrasadas, dias convertidos em centavos a 50 por dia, e uma soma acumulada. Ler a cadeia de cima para baixo é ler o que acontece com cada valor."}
]}
```

```
ana@laptop:~/patterns/reactive$ python3 operators.py
source: Dom Casmurro, 0 days late
source: Vidas Secas, 3 days late
  fines so far: 150 cents
source: Iracema, 0 days late
source: O Cortiço, 5 days late
  fines so far: 400 cents
day closed
```

*Vidas Secas*, com três dias de atraso, entra no pipeline e sai como `150` antes de a fonte imprimir
*Iracema*. *Iracema* está em dia, então o `filter_` a segura e não se imprime nada para ela depois da
linha da fonte. *O Cortiço*, com cinco dias de atraso, vira 250 centavos e o total acumulado vira
400. **Cada valor passou pela cadeia inteira antes de o próximo ser produzido.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 400\" role=\"img\" data-fig=\"l16-marbles\" aria-label=\"Um diagrama de bolinhas de operators.py. Quatro linhas do tempo horizontais, uma embaixo da outra, com o tempo correndo para a direita. A linha de cima, as devoluções, tem quatro bolinhas: Dom Casmurro com 0 dias de atraso, Vidas Secas 3, Iracema 0 e O Cortiço 5, e depois uma barra de conclusão. Abaixo, filter_ deixa passar só as atrasadas, então a segunda linha tem duas bolinhas, 3 e 5, nos mesmos instantes de antes. map_ as transforma em 150 e 250 centavos na terceira linha, e scan soma tudo em 150 e 400 na linha de baixo. Toda linha termina com a mesma barra de conclusão.\"><defs><marker id=\"l16-marbles-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">devoluções</text><path d=\"M140.0 50.0 L670.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-marbles-dp-ah-paper-dim)\"></path><path d=\"M620.0 36.0 L620.0 64.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"200.0\" cy=\"50.0\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"200.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">0</text><circle cx=\"320.0\" cy=\"50.0\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"320.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3</text><circle cx=\"440.0\" cy=\"50.0\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"440.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">0</text><circle cx=\"560.0\" cy=\"50.0\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"560.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">5</text><text x=\"20.0\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">só atrasadas</text><path d=\"M140.0 150.0 L670.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-marbles-dp-ah-paper-dim)\"></path><path d=\"M620.0 136.0 L620.0 164.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"320.0\" cy=\"150.0\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"320.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3</text><circle cx=\"560.0\" cy=\"150.0\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"560.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">5</text><text x=\"20.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">em centavos</text><path d=\"M140.0 250.0 L670.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-marbles-dp-ah-paper-dim)\"></path><path d=\"M620.0 236.0 L620.0 264.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"320.0\" cy=\"250.0\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"320.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">150</text><circle cx=\"560.0\" cy=\"250.0\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"560.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">250</text><text x=\"20.0\" y=\"350.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">total acumulado</text><path d=\"M140.0 350.0 L670.0 350.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-marbles-dp-ah-paper-dim)\"></path><path d=\"M620.0 336.0 L620.0 364.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"320.0\" cy=\"350.0\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"320.0\" y=\"350.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">150</text><circle cx=\"560.0\" cy=\"350.0\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"560.0\" y=\"350.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">400</text><text x=\"200.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Dom Casmurro</text><text x=\"320.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Vidas Secas</text><text x=\"440.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Iracema</text><text x=\"560.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">O Cortiço</text><rect x=\"265.0\" y=\"89.0\" width=\"230.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">filter_(days late &gt; 0)</text><rect x=\"265.0\" y=\"189.0\" width=\"230.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">map_(days × 50)</text><rect x=\"265.0\" y=\"289.0\" width=\"230.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">scan(+, seed 0)</text><text x=\"670.0\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">tempo →</text><text x=\"620.0\" y=\"382.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">fim</text></svg>", "caption": "Cada valor desce a cadeia inteira no instante em que chega. Um valor que o filter_ segura deixa um vão no tempo, não um None."}
```

## Por que não uma list comprehension

Com uma lista, os mesmos três passos seriam três passadas:

```python
late = [r for r in returns if r[1] > 0]
cents = [r[1] * 50 for r in late]
```

Isso funciona quando a lista está completa antes de você começar. Um fluxo nunca está: as devoluções
do dia chegam uma de cada vez e o dia pode não ter acabado. Uma versão baseada em listas precisa
esperar o fim antes de dizer qualquer coisa, e um fluxo de leituras de um balcão que abre toda manhã
não tem fim para esperar. O pipeline responde depois de cada valor, então uma tela mostrando as
multas do dia pode se atualizar no momento em que *Vidas Secas* é lido.

Uma cadeia de generator expressions, a prima preguiçosa das comprehensions da lição 15, parece quase
igual. Ela também anda um valor de cada vez, mas é movida pela outra ponta, por quem faz o laço sobre
ela. A cadeia de observables é movida pela ponta da fonte, por quem empurra. O mesmo pipeline, motor
oposto.

## Como a cadeia é montada e executada

`Observable(produce).pipe(a, b, c)` monta `c(b(a(source)))`: quatro objetos, cada um guardando uma
referência ao anterior. Inscrever-se no de fora inscreve o produtor de `c`, que se inscreve no
observable de `b`, que se inscreve no de `a`, que finalmente se inscreve na fonte. Só então a fonte
começa a empurrar, no callback de `a`, que chama o de `b`, que chama o de `c`, que chama o seu. Cada
valor é uma chamada de função aninhada, e a pilha de chamadas no momento em que
`fines so far: 150 cents` é impresso tem todos os operadores nela.

As bibliotecas trazem dezenas de operadores no mesmo molde. `debounce` espera um momento de silêncio
antes de repassar o último valor, `merge` intercala dois fluxos, `buffer` junta valores em listas por
quantidade ou por tempo, e `retry` se inscreve de novo depois de um erro. Cada um é uma função de
observable para observable, então cada um se compõe com os outros. A maioria tem poucas linhas a
mais que `scan`, porque lida com tempo e com mais de uma fonte.

## Onde a cadeia esconde um custo

Cada inscrição em `fines` monta a cadeia inteira de novo e roda a fonte de novo, porque a fonte aqui é
uma função que começa do início toda vez que é chamada. Para uma lista de quatro devoluções isso não
custa nada. Para uma fonte que consulta um banco de dados ou chama um serviço web, dois inscritos
querem dizer duas consultas. A próxima seção dá nome a esse comportamento e mostra o outro tipo de
fonte.
