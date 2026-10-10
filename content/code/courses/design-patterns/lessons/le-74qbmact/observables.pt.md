---
title: "Observables: um fluxo em que você se inscreve"
version: 1
---

**Um observable é a descrição de uma fonte de valores que não faz nada até alguém se inscrever.**
Inscrever-se entrega a ele três callbacks: um para cada valor, um para um erro, um para o fim. Dali
em diante o observable empurra, e quem se inscreveu só reage. Todo o resto de uma biblioteca como
RxJS ou Reactor é construído sobre esse arranjo.

A primeira imagem de costume é uma lista que vai enchendo com o tempo. Ela chega perto e engana num
ponto: uma lista existe antes de você olhar para ela, e um observable não. Até `subscribe` ser
chamado não há fluxo nenhum, só as instruções para fazer um. O programa abaixo mostra isso com um
print antes da primeira inscrição.

Há também uma regra sobre a ordem dos sinais, e é ela que separa um observable do observer da lição
6. Pode vir qualquer número de valores, e depois **no máximo um fim: um erro ou uma conclusão, nunca
os dois, e nada depois dele**. Escrita como padrão, `on_next* (on_error | on_complete)?`. A regra
quer dizer que quem se inscreveu pode confiar que `on_complete` é definitivo, e a classe abaixo
mantém a regra para todo produtor em vez de confiar que cada um se lembre dela.

```schooling-example
{"language": "python", "file": "observable.py", "parts": [
 {"code": "# observable.py\nfrom typing import Callable\n\n\nclass Sink:\n    def __init__(self, on_next, on_error, on_complete):\n        self._next, self._error, self._complete = on_next, on_error, on_complete\n        self.closed = False\n\n    def on_next(self, value) -> None:\n        if not self.closed:\n            self._next(value)\n\n    def on_error(self, err: Exception) -> None:\n        if not self.closed:\n            self.closed = True\n            self._error(err)\n\n    def on_complete(self) -> None:\n        if not self.closed:\n            self.closed = True\n            self._complete()", "note": "Um `Sink` é onde o produtor escreve. Ele embrulha os três callbacks de quem se inscreveu e mantém a regra sobre o fim: depois que `closed` é marcado, todo sinal posterior é ignorado."},
 {"code": "\n\ndef _ignore() -> None:\n    pass\n\n\ndef _raise(err: Exception) -> None:\n    raise err", "note": "Se quem se inscreve não passa um tratador de erro, o erro é lançado de novo em vez de descartado. Um fluxo que falhou não pode parecer um fluxo que veio vazio."},
 {"code": "\n\nclass Observable:\n    def __init__(self, producer: Callable[[Sink], None]):\n        self._producer = producer\n\n    def subscribe(self, on_next, on_error=_raise, on_complete=_ignore) -> Sink:\n        sink = Sink(on_next, on_error, on_complete)\n        try:\n            self._producer(sink)\n        except Exception as err:\n            sink.on_error(err)\n        return sink", "note": "Um `Observable` guarda um produtor, uma função que recebe um sink. `subscribe` cria o sink, roda o produtor e transforma qualquer coisa que o produtor lance em `on_error`."},
 {"code": "\n    def pipe(self, *operators) -> \"Observable\":\n        result = self\n        for operator in operators:\n            result = operator(result)\n        return result", "note": "`pipe` aplica operadores em ordem, cada um transformando um observable em outro. A seção 04 escreve os três primeiros."},
 {"code": "\n\ndef of(*values) -> Observable:\n    def produce(sink: Sink) -> None:\n        for value in values:\n            sink.on_next(value)\n        sink.on_complete()\n    return Observable(produce)", "note": "`of` cria um observable a partir de valores fixos: um valor para cada um, e depois o fim."},
 {"code": "\n\nif __name__ == \"__main__\":\n    returns = of(\"Dom Casmurro\", \"Vidas Secas\", \"Iracema\")\n    print(\"built; nothing has happened yet\")\n    returns.subscribe(lambda t: print(\"next:\", t),\n                      on_complete=lambda: print(\"complete\"))", "note": "A demonstração constrói um fluxo e se inscreve nele uma vez."},
 {"code": "\n    def careless(sink: Sink) -> None:\n        sink.on_next(\"Iracema\")\n        sink.on_complete()\n        sink.on_next(\"O Cortiço\")\n\n    def broken(sink: Sink) -> None:\n        sink.on_next(\"Memórias Póstumas\")\n        raise OSError(\"the barcode reader went away\")\n\n    Observable(careless).subscribe(lambda t: print(\"next:\", t),\n                                   on_complete=lambda: print(\"complete\"))\n    Observable(broken).subscribe(lambda t: print(\"next:\", t),\n                                 on_error=lambda e: print(\"error:\", e))", "note": "Um produtor que quebra a regra mandando um valor depois do fim, e um produtor que lança uma exceção no meio. Nenhum dos dois chega a quem se inscreveu como algo diferente de um fluxo bem formado."}
]}
```

```
ana@laptop:~/patterns/reactive$ python3 observable.py
built; nothing has happened yet
next: Dom Casmurro
next: Vidas Secas
next: Iracema
complete
next: Iracema
complete
next: Memórias Póstumas
error: the barcode reader went away
```

`built; nothing has happened yet` vem primeiro porque `of(...)` só criou um objeto. Os três títulos
e o `complete` aparecem dentro da chamada a `subscribe`. O produtor descuidado chamou
`on_next("O Cortiço")` depois de concluir, e esse título não está em lugar nenhum da saída: o sink já
tinha fechado. O produtor quebrado entregou um título e depois lançou uma exceção, e quem se inscreveu
recebeu o erro como um sinal, com a mensagem do fluxo, em vez de um traceback vindo de algum lugar
dentro do código de outra pessoa.

## O que os três callbacks compram

Compare com o balcão da seção 02. Os ouvintes dele tinham um callback cada e nenhum jeito de saber
que o dia tinha acabado ou que o leitor tinha falhado. Com um observable, as duas coisas são valores
no fluxo, entregues do mesmo jeito que um título. **O fim de um fluxo e a falha de um fluxo fazem
parte do fluxo**, então o código mais abaixo pode reagir a eles em ordem: fechar o relatório do dia
quando as devoluções terminam, mostrar um alerta quando falham.

Isso pesa mais onde um laço teria cuidado deles de graça. Um `for` sobre um gerador termina quando o
gerador retorna, e uma exceção dentro do gerador aparece no laço. O push tira o laço, então esses dois
sinais precisam de um lugar para ir, e `on_complete` e `on_error` são esse lugar.

## Síncrono, de propósito

Todo produtor desta lição roda dentro de `subscribe`, na thread de quem chamou, e é assim que as
bibliotecas de verdade se comportam também, a não ser que você peça um scheduler. O `of(1, 2, 3)` do
RxJS entrega os três valores antes de `subscribe` retornar. Push não implica thread: a fonte decide
quando um valor anda, e aqui ela decide *na hora*. Quando a fonte é um timer, um socket ou um leitor
de código de barras, os valores chegam depois, e o código de quem se inscreveu é o mesmo.

## O que a classe deixa de fora

Observables de verdade também devolvem um jeito de *cancelar a inscrição*, para quem se inscreveu
poder parar uma fonte que senão rodaria para sempre: um timer, um fluxo de cliques. O nosso devolve o
sink, cujo campo `closed` um produtor poderia consultar, e nada nesta lição precisa de mais. As
bibliotecas acrescentam schedulers, cancelamento ao longo de uma cadeia inteira e dezenas de jeitos
de construir uma fonte a partir de um timer, de um evento ou de uma promise. A forma continua a de
cima: um produtor, um sink com três métodos e a regra sobre o fim.
