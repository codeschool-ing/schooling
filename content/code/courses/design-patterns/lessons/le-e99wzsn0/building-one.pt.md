---
title: "Construindo um: uma thread e uma fila"
version: 1
---

**Um ator cabe em vinte linhas de Python: uma `queue.Queue` como caixa de correio, uma thread que
tira dela uma mensagem de cada vez, e um método que a thread chama para cada mensagem.** Tudo o que as
bibliotecas acrescentam, de schedulers a clusters, fica em volta desse laço. Escrever o laço você
mesmo uma vez torna concretas as regras da seção anterior, e mostra de onde vem cada garantia.

O exemplo é a estante da seção 02 de novo, reconstruída como ator. Os dois balcões continuam rodando
em duas threads no mesmo instante, e a pausa entre verificar e agir continua lá.

```schooling-example
{"language": "python", "file": "actor.py", "parts": [
 {"code": "# actor.py\nimport queue\nimport threading\nimport time\nfrom dataclasses import dataclass\n\n_STOP = object()", "note": "`_STOP` é um objeto privado que nunca se confunde com uma mensagem de verdade, porque nada fora deste arquivo consegue fazer outro igual."},
 {"code": "\n\nclass Actor:\n    def __init__(self):\n        self._mailbox: queue.Queue = queue.Queue()\n        self._thread = threading.Thread(target=self._run)\n        self._thread.start()\n\n    def tell(self, message) -> None:\n        self._mailbox.put(message)\n\n    def stop(self) -> None:\n        self._mailbox.put(_STOP)\n        self._thread.join()", "note": "O construtor cria a caixa de correio e inicia a thread. `tell` é a única entrada: põe uma mensagem na fila e retorna na hora, sem esperar o ator lê-la. `stop` manda `_STOP` e espera a thread terminar o que já está na fila."},
 {"code": "\n    def _run(self) -> None:\n        while (message := self._mailbox.get()) is not _STOP:\n            self.receive(message)\n\n    def receive(self, message) -> None:\n        raise NotImplementedError", "note": "O laço. `queue.Queue.get` bloqueia até chegar uma mensagem, e a próxima só é tirada depois que `receive` retornou, que é todo o \"uma mensagem de cada vez\". Uma subclasse escreve `receive` e mais nada."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Lend:\n    title: str\n    desk: str\n\n\n@dataclass(frozen=True)\nclass GiveBack:\n    title: str\n\n\n@dataclass(frozen=True)\nclass Report:\n    pass", "note": "Mensagens são dataclasses congeladas: valores que não podem mudar depois de enviados."},
 {"code": "\n\nclass Shelf(Actor):\n    def __init__(self, copies: dict[str, int]):\n        self._copies = dict(copies)\n        self._lent = self._refused = 0\n        super().__init__()\n\n    def receive(self, message) -> None:\n        match message:\n            case Lend(title=title):\n                if self._copies.get(title, 0) > 0:\n                    time.sleep(0.01)\n                    self._copies[title] -= 1\n                    self._lent += 1\n                    print(f\"{title}: lent, {self._copies[title]} left\")\n                else:\n                    self._refused += 1\n                    print(f\"{title}: refused, none left\")\n            case GiveBack(title=title):\n                self._copies[title] += 1\n                print(f\"{title}: back, {self._copies[title]} left\")\n            case Report():\n                print(f\"lent {self._lent}, refused {self._refused}, shelf {self._copies}\")", "note": "O estado da estante é definido antes de `super().__init__()` iniciar a thread, então a thread nunca vê um ator montado pela metade. O `match` escolhe o caso pela classe da mensagem. O `time.sleep` é a mesma pausa encenada do `shared.py`."},
 {"code": "\n\nif __name__ == \"__main__\":\n    shelf = Shelf({\"Iracema\": 1})\n    desks = [threading.Thread(target=shelf.tell, args=(Lend(\"Iracema\", name),))\n             for name in (\"north desk\", \"south desk\")]\n    for d in desks:\n        d.start()\n    for d in desks:\n        d.join()\n    shelf.tell(GiveBack(\"Iracema\"))\n    shelf.tell(Report())\n    shelf.stop()", "note": "Duas threads de balcão mandam mensagem para a estante no mesmo instante. Depois que as duas enviaram, a thread principal devolve um exemplar e pede um relatório, depois para a estante."}
]}
```

```
ana@laptop:~/patterns/actors$ python3 actor.py
Iracema: lent, 0 left
Iracema: refused, none left
Iracema: back, 1 left
lent 1, refused 1, shelf {'Iracema': 1}
```

Um empréstimo, uma recusa, e a estante de volta a um exemplar depois da devolução. **A pausa que
quebrou o `shared.py` não muda nada aqui**, porque nenhum outro código consegue rodar o
verificar-e-agir enquanto a estante dorme no meio dele: o segundo *Lend* está esperando na caixa de
correio. Qual balcão ficou com o livro depende de qual `tell` chegou primeiro à fila, e o programa não
imprime o nome do balcão por esse motivo. As quatro linhas acima são as mesmas em toda execução.

## De onde vem cada garantia

| garantia | o que a fornece |
|---|---|
| uma mensagem de cada vez | uma única thread roda `_run`, e `_run` chama `receive` num laço |
| estado privado | só `receive` toca `_copies`, e `receive` só roda na thread do ator |
| remetentes nunca esperam | `tell` é um `put` numa fila sem limite |
| ordem de um mesmo remetente | `queue.Queue` é a primeira a entrar, a primeira a sair |
| `put` seguro de muitas threads | `queue.Queue` trava internamente, que é o trabalho dela |

A terceira linha tem um custo que você viu na lição 16: uma caixa de correio sem limite é uma fila sem
limite. Uma estante que trata dez mensagens por segundo e recebe cinquenta vai acumular até a memória
acabar. A caixa de correio padrão do Akka não tem limite pelo mesmo motivo que esta, conveniência, e o
Akka oferece uma caixa com limite para os atores que precisam de backpressure; aqui seria
`queue.Queue(maxsize=n)`. O Erlang deixa a caixa de correio sem limite e espera que você projete de
modo que ela não encha.

A segunda linha é uma promessa que o Python não consegue impor. Nada impede o código da thread
principal de ler `shelf._copies`, e se ele fizesse isso com o ator rodando estaria de volta ao mundo
da seção 02. O Erlang impõe a regra dando a cada processo a própria memória. Na JVM, o Akka entrega a
quem envia um `ActorRef` em vez do objeto do ator, então não há referência aos campos para usar mal. A
seção 07 faz a mesma coisa aqui com um processo separado.

## Ordem entre remetentes

A quarta linha diz *de um mesmo remetente*. Se o balcão norte manda *Lend* e depois *GiveBack*, a
estante os recebe nessa ordem. Se o balcão norte manda *Lend* e o balcão sul manda *GiveBack* ao mesmo
tempo, qualquer um pode chegar primeiro, e o modelo de atores não promete nada sobre qual. Um projeto
que precisa das mensagens de dois remetentes numa ordem específica tem de fazer um esperar pelo outro,
o que na prática quer dizer perguntar, o assunto da próxima seção.

## Um ator ou muitos

A estante aqui guarda todos os títulos. Uma biblioteca movimentada poderia ter um ator por título, ou
por filial, e essa escolha é a versão em atores de escolher o escopo de um lock. Um ator só é simples e
vira uma fila em que todo mundo espera; um por título espalha a carga e torna mais difícil uma
pergunta sobre dois títulos ao mesmo tempo, porque nenhum ator conhece os dois. Os agregados da lição
12 enfrentam a mesma decisão para transações, e serve a mesma regra prática: trace a fronteira em
volta do que precisa ser consistente junto, e de nada mais.
