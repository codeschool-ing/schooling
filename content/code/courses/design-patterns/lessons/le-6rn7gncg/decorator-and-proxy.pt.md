---
title: "Decorator e proxy: a mesma interface, embrulhada"
version: 1
---

**Um decorator embrulha um objeto em outro com a mesma interface e acrescenta comportamento no
caminho; um proxy embrulha um objeto em outro com a mesma interface e controla o acesso a ele.** Na
estrutura eles são idênticos: uma classe que implementa o protocolo, guarda uma instância do
protocolo e repassa as chamadas a ela. O que os separa é a intenção, e a intenção é o que o nome diz
a quem lê.

Um aviso antes do código. A sintaxe `@decorator` do Python, a linha acima de uma função, é outra
coisa que compartilha o nome. As duas são parentes, e a última seção de leitura desta lição mostra
como, mas o decorator do GoF é sobre objetos e funciona igual em qualquer linguagem.

## Um decorator: empilhando regras numa multa

A biblioteca cobra 50 centavos por dia. Estudantes têm dois dias de tolerância e um teto de dez
reais. Algum outro grupo pode ter o teto sem a tolerância. Escrito como subclasses, isso é uma
classe por combinação, a multiplicação que a lição 2 mediu. Escrito como decorators, cada regra é
uma classe pequena, e elas se empilham.

```schooling-example
{"language": "python", "file": "decorator.py", "parts": [
 {"code": "# decorator.py\nfrom typing import Protocol\n\n\nclass FinePolicy(Protocol):\n    def fine(self, days_late: int) -> int: ...", "note": "Um método é o protocolo inteiro: quanto se deve por tantos dias de atraso."},
 {"code": "\n\nclass DailyFine:\n    def __init__(self, cents_per_day: int):\n        self._rate = cents_per_day\n\n    def fine(self, days_late: int) -> int:\n        return max(days_late, 0) * self._rate", "note": "A política simples. Todo o resto é construído em cima dela."},
 {"code": "\n\nclass GraceDays:\n    def __init__(self, inner: FinePolicy, days: int):\n        self._inner, self._days = inner, days\n\n    def fine(self, days_late: int) -> int:\n        return self._inner.fine(days_late - self._days)\n\n\nclass Capped:\n    def __init__(self, inner: FinePolicy, cap: int):\n        self._inner, self._cap = inner, cap\n\n    def fine(self, days_late: int) -> int:\n        return min(self._inner.fine(days_late), self._cap)", "note": "Dois decorators. Cada um guarda outra política, muda o que entra ou o que sai e repassa o resto. Nenhum dos dois sabe o que está embrulhando."},
 {"code": "\n\nif __name__ == \"__main__\":\n    plain = DailyFine(50)\n    student = Capped(GraceDays(DailyFine(50), days=2), cap=1000)\n    for days in (1, 3, 10, 40):\n        print(f\"{days:>2} day(s) late: plain {plain.fine(days):>4}, student {student.fine(days):>4}\")", "note": "A política de estudante são três objetos aninhados. Trocar a ordem, ou tirar uma camada, é uma mudança nesta linha e em nenhuma classe."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 decorator.py
 1 day(s) late: plain   50, student    0
 3 day(s) late: plain  150, student   50
10 day(s) late: plain  500, student  400
40 day(s) late: plain 2000, student 1000
```

Com dez dias, o estudante deve por oito, 400 centavos. Com quarenta dias, a política simples chega a
2000 e a do estudante para no teto de 1000.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l06-decorator\" aria-label=\"Três caixas aninhadas: Capped com teto de 1000 por fora, GraceDays com 2 dias dentro dela e DailyFine a 50 centavos no meio. Uma chamada fine(40) entra na caixa de fora e é repassada sem mudança como 40; GraceDays repassa 40 menos 2, que dá 38; DailyFine calcula 38 vezes 50, que dá 1900. Na volta, GraceDays devolve 1900 sem mudança e Capped devolve o menor entre 1900 e 1000, que é 1000.\"><defs><marker id=\"l06-decorator-dp-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l06-decorator-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40.0\" y=\"46.0\" width=\"640.0\" height=\"190.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"54.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Capped(cap=1000)</text><rect x=\"140.0\" y=\"82.0\" width=\"440.0\" height=\"136.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"154.0\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">GraceDays(days=2)</text><rect x=\"240.0\" y=\"120.0\" width=\"240.0\" height=\"78.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"320.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">DailyFine(50)</text><text x=\"320.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">38 × 50 = 1900</text><text x=\"372.0\" y=\"24.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">fine(40)</text><path d=\"M380.0 14.0 L380.0 44.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decorator-dp-ah-paper-dim)\"></path><text x=\"372.0\" y=\"66.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">40</text><path d=\"M380.0 50.0 L380.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decorator-dp-ah-paper-dim)\"></path><text x=\"372.0\" y=\"103.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">40 − 2 = 38</text><path d=\"M380.0 86.0 L380.0 118.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decorator-dp-ah-paper-dim)\"></path><path d=\"M460.0 118.0 L460.0 86.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decorator-dp-ah-amber)\"></path><text x=\"468.0\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1900</text><path d=\"M460.0 80.0 L460.0 50.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decorator-dp-ah-amber)\"></path><text x=\"468.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1900</text><path d=\"M460.0 44.0 L460.0 14.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decorator-dp-ah-amber)\"></path><text x=\"468.0\" y=\"24.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">min(1900, 1000) = 1000</text></svg>", "caption": "student.fine(40), acompanhada pela pilha. Cada camada muda o que entra ou o que sai, e não sabe nada das outras."}
```

**A ordem importa numa pilha de decorators.** `GraceDays(Capped(DailyFine(50), 1000), 2)` põe o teto
dentro da tolerância, o que por acaso dá os mesmos números aqui; um decorator que dividisse a multa
pela metade não comutaria com o teto. A ordem do aninhamento faz parte da regra, e está escrita numa
linha onde um revisor a vê.

## Um proxy: o mesmo catálogo, consultado menos vezes

O catálogo nacional da seção do adapter é lento e limita quantas vezes pode ser consultado. O balcão
procura os mesmos poucos livros o dia todo. Um proxy de cache responde ele mesmo às perguntas
repetidas e só deixa passar as novas.

```schooling-example
{"language": "python", "file": "proxy.py", "parts": [
 {"code": "# proxy.py\nfrom adapter import Book, Catalogue, OpenShelfCatalogue, OpenShelfClient", "note": "O proxy embrulha o adapter de `adapter.py`, então esse arquivo precisa estar no mesmo diretório."},
 {"code": "\n\nclass CachingCatalogue:\n    def __init__(self, inner: Catalogue):\n        self._inner = inner\n        self._cache: dict[str, Book | None] = {}\n        self.asked_inner = 0\n\n    def find(self, isbn: str) -> Book | None:\n        if isbn not in self._cache:\n            self.asked_inner += 1\n            self._cache[isbn] = self._inner.find(isbn)\n        return self._cache[isbn]", "note": "Ele é um `Catalogue`, guarda um `Catalogue` e decide quando o de verdade é consultado. Um erro de cache passa adiante e é lembrado; um acerto nunca sai do proxy."},
 {"code": "\n\nif __name__ == \"__main__\":\n    catalogue = CachingCatalogue(OpenShelfCatalogue(OpenShelfClient()))\n    requests = [\"978-65-5555-012-3\", \"978-65-5555-014-7\", \"978-65-5555-012-3\",\n                \"978-65-5555-012-3\", \"978-65-5555-099-9\", \"978-65-5555-099-9\"]\n    for isbn in requests:\n        book = catalogue.find(isbn)\n        print(isbn, \"->\", book.title if book else \"not found\")\n    print(f\"{len(requests)} requests, the service was asked {catalogue.asked_inner} times\")", "note": "Seis pedidos para três ISBNs diferentes. Quem chama não distingue uma resposta do cache de uma nova."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 proxy.py
978-65-5555-012-3 -> Vidas Secas
978-65-5555-014-7 -> Dom Casmurro
978-65-5555-012-3 -> Vidas Secas
978-65-5555-012-3 -> Vidas Secas
978-65-5555-099-9 -> not found
978-65-5555-099-9 -> not found
6 requests, the service was asked 3 times
```

O proxy lembra também o "não encontrado", e isso é uma decisão, não um acidente: um livro que o
serviço não conhece hoje pode ser acrescentado amanhã, e este cache nunca mais perguntaria. Um cache
de verdade guardaria cada resposta por um tempo limitado. Esse é um problema do cache, não do padrão;
o padrão só diz onde a decisão mora.

## Os tipos de proxy

Cache é um dos motivos para controlar o acesso. O livro lista outros, e você já encontrou a maioria
sem o nome. Um **proxy remoto** representa um objeto em outro processo: o stub de cliente que uma
ferramenta de gRPC ou RMI gera é um. Um **proxy virtual** adia a criação de algo caro até ser usado,
que é o que um ORM faz quando `loan.member` carrega o membro do banco só quando você o toca. Um
**proxy de proteção** confere a permissão antes de repassar, como uma visão somente leitura do
registro entregue ao código de relatórios.

| | decorator | proxy |
|---|---|---|
| acrescenta ou controla | acrescenta comportamento | controla o acesso |
| quem monta o embrulho | em geral quem chama, escolhendo uma pilha | em geral um framework ou a raiz de composição |
| quem chama sabe | muitas vezes, foi ele que escolheu as camadas | em geral não, de propósito |
| nesta lição | `GraceDays`, `Capped` | `CachingCatalogue` |

O `java.io` do Java é o decorator de livro-texto: `new BufferedReader(new InputStreamReader(stream))`
empilha comportamento sobre um stream. Os embrulhos de `io.Reader` do Go, como `bufio.NewReader(r)`,
são a mesma ideia com uma interface que o tipo satisfaz sem declarar.
