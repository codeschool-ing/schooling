---
title: Debug e release
version: 1
---

Todo build até aqui foi um build de **debug**: compilado rápido, sem otimização e com verificações
que ajudam enquanto você trabalha. Um build de **release**, `swift build -c release`, é o que você
distribui: o otimizador reescreve o código para rodar mais rápido, e algumas das verificações somem.
**Os dois não são o mesmo programa**, e a diferença que morde não é a velocidade.

## assert, que só o debug mantém

A biblioteca do planner decide que uma sessão precisa durar pelo menos um minuto, e diz isso com
`assert`:

```swift
// Sources/PlannerCore/Week.swift
public struct Week {
    public private(set) var minutes: [Int] = []
    public let goal: Int

    public init(goal: Int = 300) {
        self.goal = goal
    }

    public mutating func add(_ session: Int) {
        assert(session > 0, "a session lasts at least a minute")
        minutes.append(session)
    }

    public var total: Int { minutes.reduce(0, +) }
}
```

```
ana@vm:~/sw/l19/planner$ swift build 2>&1 | tail -1
Build complete! (5.83 secs)
ana@vm:~/sw/l19/planner$ .build/debug/plan 45 0 2>&1 | head -3
PlannerCore/Week.swift:11: Assertion failed: a session lasts at least a minute

*** Signal 4: Backtracing from 0x7fc8b6909fbf... done ***
```

O build de debug parou na asserção e disse o arquivo, a linha e a mensagem, antes do relatório de
quebra que a lição 1 conheceu; o `head -3` guarda o começo dele. Agora o build de release, do mesmo
fonte:

```
ana@vm:~/sw/l19/planner$ swift build -c release 2>&1 | tail -1
Build complete! (23.62 secs)
ana@vm:~/sw/l19/planner$ .build/release/plan 45 0
45 of 300 minutes
```

**O build de release não verificou, e imprimiu um total que inclui uma sessão de zero minutos.** O
`assert` é uma verificação para o programador: não custa nada no release porque não está lá. Para
uma condição que precisa valer também no programa distribuído, o Swift tem o `precondition`, que
fica nos builds de release, e o `fatalError`, que sempre para. A regra prática é sobre quem errou:
**`assert` para as suposições do seu próprio código, `precondition` para o que um chamador passa.**
Uma semana que recebe zero de uma linha de comando é do segundo tipo, e este `assert` é a ferramenta
errada para ela, o que vale um exercício no fim da lição.

O release também levou mais tempo para compilar: 23,6 segundos, contra 5,8 do build de debug antes
dele. A comparação não é bem justa, e saber disso também vale: o build de debug tinha só um arquivo
alterado para compilar, enquanto o primeiro build de release compilou tudo, a dependência inclusive,
e gastou o tempo extra otimizando.

## Tamanho e velocidade

```
ana@vm:~/sw/l19/planner$ ls -l .build/debug/plan .build/release/plan
-rwxr-xr-x 1 ana ana 5167944 Oct 30 16:00 .build/debug/plan
-rwxr-xr-x 1 ana ana 3618736 Oct 30 16:00 .build/release/plan
```

O executável de release é cerca de 30% menor, porque o otimizador removeu código que conseguiu provar
que não é usado, e o build de debug guarda informação extra para o depurador. Depois, o mesmo
trabalho em cada um: o `seq 1 3000` produz os números de 1 a 3000, e o `$(…)` os passa ao `plan` como
três mil argumentos:

```
ana@vm:~/sw/l19/planner$ time .build/debug/plan $(seq 1 3000)
4501500 of 300 minutes

real	0m2.261s
user	0m2.229s
sys	0m0.011s
ana@vm:~/sw/l19/planner$ time .build/release/plan $(seq 1 3000)
4501500 of 300 minutes

real	0m0.238s
user	0m0.226s
sys	0m0.008s
```

**Cerca de 2,3 segundos contra 0,24**, os mesmos argumentos, o mesmo resultado. Quase tudo é o parser
de argumentos conferindo três mil palavras, e no debug toda chamada de função e toda verificação de
limites roda exatamente como escrita. Aqui o release foi cerca de nove vezes mais rápido, e a razão
muda de um programa para outro; o ponto é que a velocidade de um build de debug diz pouco sobre o que
uma estudante vai sentir, e **uma medida de tempo tirada de um build de debug nunca deve ser
citada**.

## Quando compilar cada um

Trabalhe e teste em debug: compila mais rápido, mantém o `assert`, e uma quebra nele aponta uma
linha. O `swift test` compila em debug por padrão por esses motivos. Compile em release para medir
velocidade e para distribuir, e rode o programa distribuído pelo menos uma vez antes de ele sair,
porque código que se comporta diferente depois de otimizado é raro e real, e o `assert` acima é o
jeito mais comum de isso acontecer.
