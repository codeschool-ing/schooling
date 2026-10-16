---
title: O service locator, e o que ele esconde
version: 1
---

**Um service locator é um registro global ao qual uma classe pede os colaboradores quando precisa
deles, e ele se parece tanto com injeção que costuma ser confundido com ela.** Os dois mantêm `new
SmtpNotifier()` fora da tarefa. A diferença é a direção: com injeção o objeto recebe o que precisa, e
com um locator o objeto vai buscar. Essa inversão desfaz a maior parte do que as seções anteriores
compraram.

O contêiner da seção anterior pode ser usado dos dois jeitos. Entregue à raiz de composição e
consultado uma vez, na inicialização, para obter o objeto do topo, ele é uma ferramenta de ligação.
Importado em toda classe e consultado de dentro dos métodos, ele é um service locator, diga a
documentação o que disser.

## Uma tarefa que vai buscar

```schooling-example
{"language": "python", "file": "locator.py", "parts": [
 {"code": "# locator.py\nfrom datetime import date\n\nfrom overdue import ListedLoans, Loan, PrintNotifier\n\n\nclass Services:\n    _registry = {}\n\n    @classmethod\n    def provide(cls, key: str, service) -> None:\n        cls._registry[key] = service\n\n    @classmethod\n    def get(cls, key: str):\n        return cls._registry[key]", "note": "O registro é uma classe com um dicionário e dois métodos. Ser global é o objetivo: qualquer código, em qualquer lugar, alcança o registro."},
 {"code": "\n\nclass LocatedNotices:\n    DAILY_FINE = 50  # cents\n\n    def send_all(self) -> int:\n        sent = 0\n        for loan in Services.get(\"loans\").open_loans():\n            late = (Services.get(\"clock\").today() - loan.due).days\n            if late > 0:\n                Services.get(\"notifier\").send(\n                    loan.member, f\"'{loan.title}' is {late} days late\")\n                sent += 1\n        return sent", "note": "O construtor da tarefa não recebe nada. As três dependências continuam lá; elas só foram parar dentro do método, onde apenas quem ler cada linha vai encontrá-las."},
 {"code": "\n\nif __name__ == \"__main__\":\n    Services.provide(\"loans\", ListedLoans([\n        Loan(\"Bia\", \"Dom Casmurro\", date(2026, 3, 16))]))\n    Services.provide(\"notifier\", PrintNotifier())\n    notices = LocatedNotices()\n    print(\"built:\", type(notices).__name__)\n    notices.send_all()", "note": "A preparação registra dois serviços e esquece o relógio. Construir a tarefa funciona mesmo assim, porque nada em `LocatedNotices()` diz que um relógio é necessário."}
]}
```

```
ana@laptop:~/patterns/injection$ python3 locator.py
built: LocatedNotices
Traceback (most recent call last):
  File "/home/ana/patterns/injection/locator.py", line 39, in <module>
    notices.send_all()
  File "/home/ana/patterns/injection/locator.py", line 25, in send_all
    late = (Services.get("clock").today() - loan.due).days
            ^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/patterns/injection/locator.py", line 16, in get
    return cls._registry[key]
           ~~~~~~~~~~~~~^^^^^
KeyError: 'clock'
```

O objeto foi construído e anunciado. A falha veio depois, do meio do laço, como um `KeyError` que
cita uma string. Neste programa as duas coisas estão a poucas linhas de distância; num serviço, a
distância vai da implantação até o primeiro empréstimo atrasado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l05-locator\" aria-label=\"Duas versões do mesmo trabalho lado a lado. À esquerda, injetado: OverdueNotices tem um construtor que recebe loans, notifier e clock, e três caixas, LoanStore, Notifier e Clock, mandam cada uma uma seta para dentro dele, com o rótulo entregues, visíveis na assinatura. À direita, localizado: LocatedNotices tem um construtor que não recebe nada; uma seta vai dele até um registro Services, e do registro até três chaves, loans, notifier e clock. A chave clock aparece tracejada em âmbar com o rótulo nunca fornecido, descoberto só quando send_all roda.\"><defs><marker id=\"l05-locator-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"175.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">injetado</text><rect x=\"55.0\" y=\"34.0\" width=\"240.0\" height=\"57.3\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175.0\" y=\"44.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.0\" font-weight=\"600\" fill=\"var(--paper)\">OverdueNotices</text><path d=\"M55.0 55.8 L295.0 55.8\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"63.0\" y=\"66.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">__init__(loans, notifier, clock)</text><text x=\"63.0\" y=\"80.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">send_all()</text><rect x=\"30.0\" y=\"163.0\" width=\"90.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">LoanStore</text><path d=\"M75.0 163.0 L75.0 93.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-locator-dp-ah-paper-dim)\"></path><rect x=\"130.0\" y=\"163.0\" width=\"90.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Notifier</text><path d=\"M175.0 163.0 L175.0 93.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-locator-dp-ah-paper-dim)\"></path><rect x=\"230.0\" y=\"163.0\" width=\"90.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Clock</text><path d=\"M275.0 163.0 L275.0 93.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-locator-dp-ah-paper-dim)\"></path><text x=\"175.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">entregues, visíveis na assinatura</text><path d=\"M360.0 12.0 L360.0 258.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"545.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">localizado</text><rect x=\"425.0\" y=\"34.0\" width=\"240.0\" height=\"57.3\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"545.0\" y=\"44.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.0\" font-weight=\"600\" fill=\"var(--paper)\">LocatedNotices</text><path d=\"M425.0 55.8 L665.0 55.8\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"433.0\" y=\"66.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">__init__()</text><text x=\"433.0\" y=\"80.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">send_all()</text><rect x=\"485.0\" y=\"112.0\" width=\"120.0\" height=\"43.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"545.0\" y=\"122.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.0\" font-weight=\"600\" fill=\"var(--paper)\">Services</text><path d=\"M485.0 133.8 L605.0 133.8\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"493.0\" y=\"144.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">get(key)</text><path d=\"M545.0 91.3 L545.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-locator-dp-ah-paper-dim)\"></path><text x=\"555.0\" y=\"103.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">de dentro de send_all</text><rect x=\"400.0\" y=\"184.0\" width=\"80.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"440.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">loans</text><path d=\"M545.0 155.6 L545.0 165.6 L440.0 165.6 L440.0 182.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l05-locator-dp-ah-paper-dim)\"></path><rect x=\"500.0\" y=\"184.0\" width=\"80.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">notifier</text><path d=\"M545.0 155.6 L545.0 165.6 L540.0 165.6 L540.0 182.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l05-locator-dp-ah-paper-dim)\"></path><rect x=\"600.0\" y=\"184.0\" width=\"80.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"640.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">clock</text><path d=\"M545.0 155.6 L545.0 165.6 L640.0 165.6 L640.0 182.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l05-locator-dp-ah-paper-dim)\"></path><text x=\"640.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">nunca fornecido:</text><text x=\"640.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">descoberto quando send_all roda</text></svg>", "caption": "As mesmas três dependências, declaradas à esquerda e buscadas à direita. Só a da esquerda pode ser verificada antes de o trabalho rodar."}
```

## Três coisas que ele esconde

**O construtor deixa de dizer a verdade.** `OverdueNotices(loans, notifier, clock)` lista o que
precisa; `LocatedNotices()` afirma não precisar de nada. Para saber o que ela usa de fato, você lê
cada método, e cada método que cada um deles chama, porque qualquer um pode chamar `Services.get`.

**Um serviço que falta é descoberto tarde.** O contêiner da seção anterior recusou no `resolve`,
antes de sair um único aviso, porque o construtor declarava o relógio. O locator só descobriu dentro
do laço. Com injeção, o próprio Python faz a conferência: construa `OverdueNotices` com dois
argumentos e ele falha nessa linha.

**Os testes compartilham estado global.** Um teste fornece um notificador falso, e o teste seguinte,
que esqueceu de fornecer o seu, usa em silêncio o falso do anterior. Os testes então passam ou falham
conforme a ordem em que rodam, o tipo de falha que custa uma tarde.

## Onde ele aparece de qualquer jeito

Locators não são raros. O `getSystemService(...)` do Android é um; buscar
`app.config` ou um objeto global `settings` lá do fundo de um tratador de requisição também é.
Logging é o caso que quase todo mundo aceita: `logging.getLogger(__name__)` é uma chamada de locator
em quase todo arquivo Python, e passar um logger para cada construtor é um preço que poucas equipes
pagam.

Então a regra é mais estreita do que "nunca". **Um locator é tolerável para serviços transversais
que não mudam nenhum comportamento que interesse a um teste, e errado para os colaboradores que
decidem o que o código faz.** Um notificador, um repositório e um relógio decidem o que
`OverdueNotices` faz. O lugar deles é no construtor, onde o próximo leitor e o teste os veem.
