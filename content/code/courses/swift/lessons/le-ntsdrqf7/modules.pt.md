---
title: O módulo é a fronteira que conta
version: 1
---

Um **módulo** é uma unidade de código compilada junta e importada pelo nome: a biblioteca padrão é o
módulo `Swift`, os frameworks da Apple são módulos chamados `Foundation` e `SwiftUI`, e cada target
de um pacote Swift é um módulo próprio. **O nível padrão, `internal`, para na borda do módulo.** A
seção 02 nunca encontrou essa borda, porque os dois arquivos foram para um programa só. Esta seção
divide o planner em dois módulos e vê a borda aparecer.

A lição 19 trata de pacotes a fundo. Por ora, um pacote é um diretório com um `Package.swift` que o
descreve e um diretório `Sources` com um subdiretório por módulo. Este tem dois: uma biblioteca,
`PlannerCore`, que guarda os tipos do planner, e um executável, `plan`, que os usa.

```swift
// swift-tools-version: 6.2
// Package.swift
import PackageDescription

let package = Package(
    name: "planner",
    products: [
        .library(name: "PlannerCore", targets: ["PlannerCore"]),
    ],
    targets: [
        .target(name: "PlannerCore"),
        .executableTarget(name: "plan", dependencies: ["PlannerCore"]),
    ]
)
```

O único arquivo da biblioteca declara uma semana sem marcar nada:

```swift
// Sources/PlannerCore/Week.swift
struct Week {
    var minutes: [Int] = []
    var total: Int { minutes.reduce(0, +) }
}
```

e o executável importa a biblioteca e a usa:

```swift
// Sources/plan/main.swift
import PlannerCore

var week = Week()
week.minutes.append(45)
print(week.total)
```

O `swift build` compila todo módulo do pacote. Quando um build falha, ele imprime, antes do erro, o
comando inteiro que deu ao compilador, uma linha de cerca de 2.500 caracteres. **Toda transcrição de
pacote neste curso passa a saída pelo `grep -v frontend`**, que tira essa linha e a linha que a
anuncia, e mantém todo o resto:

```
ana@vm:~/sw/l17/planner$ swift build 2>&1 | grep -v frontend
Building for debugging...
[Pre-planning 1 / 95]
[Constructing 1 / 192]
[25 / 37] PlannerCore
error: SwiftCompile normal x86_64 failed with a nonzero exit code. Command line:     cd /home/ana/sw/l17
    
/home/ana/sw/l17/planner/Sources/plan/main.swift:4:12: error: cannot find 'Week' in scope
2 | import PlannerCore
3 | 
4 | var week = Week()
  |            `- error: cannot find 'Week' in scope
5 | week.minutes.append(45)
6 | print(week.total)
error: Build failed
```

**`cannot find 'Week' in scope`, num arquivo que importa o módulo onde `Week` mora.** `Week` é
`internal`, então fora do `PlannerCore` ele simplesmente não existe; o compilador não consegue nem
dizer que está escondido, porque de dentro do `plan` não há nada para ver. As linhas entre colchetes
antes do erro são o progresso do build, e os números mudam de uma execução para outra.

## public, e o inicializador que ninguém escreveu

Marque a struct e os dois membros como `public`:

```swift
// Sources/PlannerCore/Week.swift
public struct Week {
    public var minutes: [Int] = []
    public var total: Int { minutes.reduce(0, +) }
}
```

```
ana@vm:~/sw/l17/planner$ swift build 2>&1 | grep -v frontend
Building for debugging...
[Using on-disk description]
[6 / 13] PlannerCore
error: SwiftCompile normal x86_64 failed with a nonzero exit code. Command line:     cd /home/ana/sw/l17
    
/home/ana/sw/l17/planner/Sources/plan/main.swift:4:12: error: 'Week' initializer is inaccessible due to 'internal' protection level
2 | import PlannerCore
3 | 
4 | var week = Week()
  |            `- error: 'Week' initializer is inaccessible due to 'internal' protection level
5 | week.minutes.append(45)
6 | print(week.total)

PlannerCore.Week.init:2:10: note: 'init()' declared here
1 | struct Week {
2 | internal init()}
  |          `- note: 'init()' declared here
3 | 
error: Build failed
```

O tipo agora está visível, e outra coisa não está. **O inicializador membro a membro de uma struct,
o que o Swift escreve por você, é `internal`**, seja qual for a marcação da struct. A nota mostra
isso: o compilador imprime a declaração que gerou, `internal init()`, num arquivo que não existe,
com o nome do tipo. A regra é proposital: tornar um tipo público não deve publicar junto um jeito de
construí-lo que você nunca escreveu e talvez queira mudar. **Um tipo público que outros módulos
criam precisa de um `init` público escrito à mão:**

```swift
// Sources/PlannerCore/Week.swift
public struct Week {
    public var minutes: [Int] = []
    public var total: Int { minutes.reduce(0, +) }

    public init() {}
}
```

```
ana@vm:~/sw/l17/planner$ swift build 2>&1 | grep -v frontend
Building for debugging...
[Using on-disk description]
[7 / 14] plan-product
[10 / 16] PlannerCore
[14 / 17] plan-product
[18 / 18] plan-product
Build complete! (3.57 secs)
ana@vm:~/sw/l17/planner$ .build/debug/plan
45
```

O build deu certo, e `.build/debug/plan` é onde o `swift build` deixa o executável.

## O que public custa

Tudo marcado `public` é uma promessa a todo módulo que importa o seu. Dentro do módulo você pode
renomear `minutes` e corrigir cada uso no mesmo commit; fora, o código de outra pessoa depende do
nome, e renomeá-lo quebra um build que você não vê. **Então `public` se decide membro a membro, não
tipo a tipo**, e o padrão `internal` do compilador é o ponto de partida seguro: uma biblioteca
publica só aquilo em que alguém escreveu `public`.

É também por isso que o mesmo planner, compilado como um módulo só dentro de um app, não precisa de
nenhuma dessas palavras: o código de um app é todo `internal`, todo num módulo, e ninguém o importa.
Os níveis de acesso começam a importar no primeiro `import` do seu próprio código, o que no app de
iOS do `ios-apps` acontece assim que o modelo vai para um pacote próprio.
