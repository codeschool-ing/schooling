---
title: "Quente e frio: o fluxo começa quando você se inscreve?"
version: 1
---

**Um observable frio recomeça a fonte para cada inscrito; um quente já está rodando, e quem se
inscreve recebe o que acontecer depois que entrou.** Todo observable desta lição até aqui era frio:
inscrever-se chamava o produtor, e o produtor começava do primeiro valor. O balcão de devoluções em
si é quente. Os livros voltam esteja alguém ouvindo ou não, e uma atendente que começa o turno às dez
perdeu as devoluções das nove.

Os dois tipos parecem idênticos por fora. Os dois têm `subscribe`, os dois empurram valores e os dois
terminam. A diferença é onde a fonte mora: dentro da inscrição, feita de novo para cada inscrito, ou
fora dela, compartilhada por todos.

Um observable quente precisa de uma classe nova. Um `Subject` é as duas pontas ao mesmo tempo: tem
`subscribe`, como qualquer observable, e tem `on_next` e `on_complete`, para o código dono dele poder
empurrar valores para dentro. É o observer da lição 6 de novo, com a regra sobre o fim acrescentada.

```schooling-example
{"language": "python", "file": "hot_cold.py", "parts": [
 {"code": "# hot_cold.py\nfrom observable import Observable, Sink\n\n\ndef catalogue() -> Observable:\n    def produce(sink: Sink) -> None:\n        print(\"  (reading the catalogue from the start)\")\n        for title in [\"Dom Casmurro\", \"Vidas Secas\", \"Iracema\"]:\n            sink.on_next(title)\n        sink.on_complete()\n    return Observable(produce)", "note": "Uma fonte fria. O print mostra cada vez que o produtor começa, o que acontece uma vez por inscrição."},
 {"code": "\n\nclass Subject(Observable):\n    def __init__(self):\n        self._sinks: list[Sink] = []\n        super().__init__(self._sinks.append)\n\n    def on_next(self, value) -> None:\n        for sink in list(self._sinks):\n            sink.on_next(value)\n\n    def on_complete(self) -> None:\n        for sink in list(self._sinks):\n            sink.on_complete()", "note": "O produtor do subject é o método `append` da própria lista. Inscrever-se cria um sink e o acrescenta; nada é empurrado até alguém chamar `on_next`."},
 {"code": "\n\nif __name__ == \"__main__\":\n    print(\"cold: each subscriber gets its own run\")\n    titles = catalogue()\n    titles.subscribe(lambda t: print(\"  Ana sees\", t))\n    titles.subscribe(lambda t: print(\"  Bia sees\", t))", "note": "Duas inscrições no catálogo frio."},
 {"code": "\n    print(\"hot: one run, shared by whoever is listening\")\n    desk = Subject()\n    desk.subscribe(lambda t: print(\"  Ana sees\", t))\n    desk.on_next(\"Dom Casmurro\")\n    desk.subscribe(lambda t: print(\"  Bia sees\", t))\n    desk.on_next(\"Vidas Secas\")\n    desk.on_next(\"Iracema\")\n    desk.on_complete()", "note": "Duas inscrições no balcão quente, e a segunda chega depois do primeiro livro."}
]}
```

```
ana@laptop:~/patterns/reactive$ python3 hot_cold.py
cold: each subscriber gets its own run
  (reading the catalogue from the start)
  Ana sees Dom Casmurro
  Ana sees Vidas Secas
  Ana sees Iracema
  (reading the catalogue from the start)
  Bia sees Dom Casmurro
  Bia sees Vidas Secas
  Bia sees Iracema
hot: one run, shared by whoever is listening
  Ana sees Dom Casmurro
  Ana sees Vidas Secas
  Bia sees Vidas Secas
  Ana sees Iracema
  Bia sees Iracema
```

A metade fria lê o catálogo duas vezes, e cada leitora vê os três títulos desde o começo. Na metade
quente, Ana estava ouvindo quando *Dom Casmurro* voltou e Bia não, então a primeira linha de Bia é
*Vidas Secas*. **Nada repete o título para ela: um fluxo quente não lembra o que já mandou.**

## Que tipo é uma fonte

A pergunta é se os valores existem independentemente de quem se inscreve.

| frio: cada inscrito dá a partida | quente: roda de qualquer jeito |
|---|---|
| ler um arquivo | um leitor de código de barras no balcão |
| uma consulta ao banco de dados | cliques de mouse e teclas |
| uma requisição HTTP | cotações de uma bolsa |
| `of(...)` e um timer iniciado por `subscribe` | um `Subject` em que alguém empurra valores |

**Um observable frio é uma receita e um quente é uma transmissão.** Nenhum é melhor. Eles respondem a
perguntas diferentes: "me dê o catálogo" quer todos os títulos desde o começo, toda vez, e "me avise
quando um livro voltar" só faz sentido de agora em diante.

## O bug que cada tipo produz

O tipo frio surpreende quem se inscreve duas vezes. Num template Angular, escrever o mesmo observable
HTTP em dois lugares faz duas inscrições, e o servidor recebe duas requisições idênticas. Em
`hot_cold.py` o exemplo é a linha *reading the catalogue from the start*, impressa uma vez por
leitora. A resposta das bibliotecas é um operador, `share` no RxJS, que se inscreve na fonte fria uma
vez e repassa cada valor para todos os inscritos dele: uma fonte fria que virou quente.

O tipo quente surpreende quem se inscreve tarde. Uma tela que se inscreve no balcão depois da primeira
devolução não mostra nada sobre ela, e nada no fluxo diz que um valor passou. Quando quem chega tarde
precisa do passado, as bibliotecas oferecem subjects que lembram. O `ReplaySubject` do RxJS guarda os
últimos *n* valores e os manda para cada recém-chegado, e o `BehaviorSubject` guarda só o mais
recente e exige um para começar, o que combina com um valor que sempre tem um estado atual, como o
número de exemplares de *Iracema* na estante.

## Um subject é uma porta aberta

O nosso `Subject` deixa qualquer código que o tenha nas mãos chamar `on_next`. Isso é cômodo numa
demonstração e perigoso num programa: todo mundo que o tem pode empurrar valores em que todos os
inscritos vão acreditar. A disciplina comum é manter o subject privado à classe dona da fonte e
entregar a todos os outros o lado só de leitura, um `Observable`. No RxJS isso é
`subject.asObservable()`; no Python desta lição, uma property devolvendo
`Observable(lambda sink: desk.subscribe(sink.on_next, sink.on_error, sink.on_complete))` faria o
mesmo. É o encapsulamento da lição 1 aplicado a um fluxo: o produtor guarda para si o direito de
produzir.
