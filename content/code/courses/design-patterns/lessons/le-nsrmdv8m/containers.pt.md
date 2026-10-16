---
title: "Contêineres: a ligação feita por uma máquina"
version: 1
---

**Um contêiner de injeção de dependência é uma raiz de composição que descobre a ligação por você:
você registra que classe atende cada necessidade, e ele constrói um objeto lendo o que o
construtor pede.** Spring, Guice, o contêiner embutido do .NET, NestJS e Angular têm um no centro.
Nenhum deles é mágico, e o jeito mais rápido de parar de tratá-los como mágica é construir um.

## Trinta linhas de contêiner

```schooling-example
{"language": "python", "file": "container.py", "parts": [
 {"code": "# container.py\nimport inspect\nfrom typing import get_type_hints\n\n\nclass Container:\n    def __init__(self):\n        self._providers = {}\n        self._shared = {}", "note": "Duas tabelas: como construir cada coisa, e as coisas já construídas que devem ser compartilhadas."},
 {"code": "\n    def register(self, key, provider, shared=False):\n        self._providers[key] = (provider, shared)", "note": "Uma chave costuma ser um protocolo, como `Notifier`. O provedor é uma classe a construir ou uma função a chamar. `shared=True` quer dizer uma instância durante a vida inteira do contêiner."},
 {"code": "\n    def resolve(self, key):\n        if key in self._shared:\n            return self._shared[key]\n        if key not in self._providers:\n            raise LookupError(f\"nothing registered for {key.__name__}\")\n        provider, shared = self._providers[key]\n        obj = self._build(provider)\n        if shared:\n            self._shared[key] = obj\n        return obj", "note": "Resolver devolve a instância compartilhada se houver uma, recusa uma chave que ninguém registrou e, fora isso, constrói."},
 {"code": "\n    def _build(self, provider):\n        if not inspect.isclass(provider):\n            return provider()\n        hints = get_type_hints(provider.__init__)\n        hints.pop(\"return\", None)\n        args = {name: self.resolve(kind) for name, kind in hints.items()}\n        return provider(**args)", "note": "O truque que todo contêiner faz. Ele lê as anotações de tipo de `__init__` e resolve cada uma antes de chamar o construtor. Isso se chama autowiring."}
]}
```

O `wired.py` pede ao contêiner um `OverdueNotices` sem nunca dizer como fazer um. Depois mostra os
dois tempos de vida e o que acontece quando falta um registro.

```schooling-example
{"language": "python", "file": "wired.py", "parts": [
 {"code": "# wired.py\nfrom datetime import date\n\nfrom container import Container\nfrom overdue import (Clock, FixedClock, ListedLoans, Loan, LoanStore, Notifier,\n                     OverdueNotices, PrintNotifier)", "note": "A mesma tarefa e os mesmos protocolos de antes. O contêiner precisa dos protocolos como chaves."},
 {"code": "\n\ndef configure(c: Container) -> None:\n    c.register(LoanStore, lambda: ListedLoans([\n        Loan(\"Bia\", \"Dom Casmurro\", date(2026, 3, 16))]))\n    c.register(Notifier, PrintNotifier, shared=True)\n    c.register(Clock, lambda: FixedClock(date(2026, 3, 20)))\n    c.register(OverdueNotices, OverdueNotices)", "note": "O registro substitui o `build` da raiz de composição. `ListedLoans` e `FixedClock` precisam de valores que um contêiner não tem como adivinhar, então são registrados como funções."},
 {"code": "\n\nif __name__ == \"__main__\":\n    c = Container()\n    configure(c)\n    notices = c.resolve(OverdueNotices)\n    print(\"sent:\", notices.send_all())\n    print(\"same notifier:\", c.resolve(Notifier) is c.resolve(Notifier))\n    print(\"same clock:\", c.resolve(Clock) is c.resolve(Clock))", "note": "Um único `resolve` constrói quatro objetos: o contêiner lê `loans`, `notifier` e `clock` no construtor e resolve cada um."},
 {"code": "\n    bare = Container()\n    bare.register(LoanStore, lambda: ListedLoans([]))\n    bare.register(Notifier, PrintNotifier)\n    bare.register(OverdueNotices, OverdueNotices)\n    try:\n        bare.resolve(OverdueNotices)\n    except LookupError as err:\n        print(\"refused:\", err)", "note": "Um segundo contêiner, sem relógio registrado. O construtor de `OverdueNotices` diz que precisa de um, então o contêiner recusa no `resolve`, antes de qualquer aviso sair."}
]}
```

```
ana@laptop:~/patterns/injection$ python3 wired.py
to Bia: 'Dom Casmurro' is 4 days late, fine 200 cents
sent: 1
same notifier: True
same clock: False
refused: nothing registered for Clock
```

O notificador foi registrado como compartilhado, então os dois pedidos receberam o mesmo objeto; o
relógio não foi, então cada pedido construiu um novo. Essa é a ideia inteira de um **tempo de
vida**. Contêineres de verdade acrescentam um terceiro, uma instância por requisição web, que é o
motivo de eles existirem em frameworks web.

## Quando um contêiner vale a pena

Compare as duas raízes desta lição. O `build` de `main.py` é código comum: dá para lê-lo, percorrê-lo
num depurador, e um nome escrito errado é um erro antes de o programa fazer qualquer coisa. O
`configure` é mais curto, mas a ligação agora acontece dentro de `_build`, e um registro que falta só
é descoberto quando algo é resolvido. **Um contêiner troca código que você lê por código que você
configura, e a troca só compensa quando a ligação é grande ou repetitiva.**

Ela compensa num framework que constrói centenas de objetos por requisição e precisa dar a cada
requisição a sua própria sessão de banco de dados. Não compensa num script, numa ferramenta de linha
de comando ou num serviço de vinte classes, que é a maior parte do código Python. A comunidade
Python costuma ligar as peças à mão por esse motivo; o `Depends` do FastAPI é a exceção mais
conhecida, e é um contêiner por requisição disfarçado.

| linguagem | o que se costuma usar | o hábito comum |
|---|---|---|
| Java | Spring, Guice, Dagger (ligação gerada na compilação) | um contêiner em quase toda aplicação |
| TypeScript | NestJS e Angular, cada um com o seu; InversifyJS | um contêiner sempre que o framework tem um |
| Go | o `wire` do Google (gera a ligação que você escreveria), o `fx` da Uber | ligação à mão no `main` |
| Python | o `Depends` do FastAPI; existem pacotes, mas raramente fazem falta | ligação à mão no `main` |

Dagger e `wire` merecem uma segunda olhada: eles escrevem a raiz de composição como código comum na
hora do build, então a ligação é verificada antes de o programa rodar. É a conveniência do contêiner
sem o seu custo principal.
