---
title: O que o swift package init cria
version: 1
---

As lições 17 e 18 usaram pacotes e falaram pouco deles. Um **pacote** é um diretório com um
`Package.swift` no topo, o **manifesto**, e os arquivos-fonte nos lugares que o manifesto espera. É a
unidade que o Swift compila, testa e compartilha: toda biblioteca que você vai acrescentar a um
projeto chega como um, e o app de iOS do `ios-apps` também guarda o modelo num. O **Swift Package
Manager**, SwiftPM para encurtar, é a parte do toolchain que lê manifestos, e responde ao `swift
build`, ao `swift test`, ao `swift run` e ao `swift package`.

O jeito mais rápido de ver o formato é pedir ao SwiftPM um pacote vazio:

```
ana@vm:~/sw/l19/hello$ swift package init --type executable
Creating executable package: hello
Creating Package.swift
Creating .gitignore
Creating Sources
Creating Sources/hello/hello.swift
Creating Tests/
Creating Tests/helloTests/
Creating Tests/helloTests/helloTests.swift
ana@vm:~/sw/l19/hello$ find . -path ./.build -prune -o -type f -print | sort
./.gitignore
./Package.swift
./Sources/hello/hello.swift
./Tests/helloTests/helloTests.swift
```

O `swift package init` dá ao pacote o nome do diretório, a menos que se diga outro, e o `--type
executable` pede um programa em vez de uma biblioteca. Ele criou quatro arquivos. O `find` deixa de
fora o `.build`, para onde vai tudo o que o SwiftPM produz; o `.gitignore` já lista esse diretório,
porque nada nele pertence ao controle de versão.

## O manifesto é Swift

```
ana@vm:~/sw/l19/hello$ cat Package.swift
// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "hello",
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "hello",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .testTarget(
            name: "helloTests",
            dependencies: ["hello"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
    ]
)
```

**A primeira linha não é um comentário comum.** `// swift-tools-version: 6.4` é lido pelo SwiftPM
antes de tudo, e diz em que versão do formato de manifesto este arquivo está escrito. Um toolchain
mais antigo que 6.4 recusa o arquivo, e a seção 07 mostra que o número também decide o modo de
linguagem em que os targets são compilados. Abaixo dela, o manifesto é um programa Swift que importa
`PackageDescription` e constrói um valor, `package`, descrevendo o que há ali.

Dois **targets**: um executável chamado `hello`, cujos fontes estão em `Sources/hello`, e um target
de testes `helloTests` em `Tests/helloTests` que depende dele. Um target é um módulo, a unidade de
acesso da lição 17. Os `swiftSettings` ligam o `ApproachableConcurrency`, uma **funcionalidade
futura**: uma mudança na linguagem que um modo futuro tornará padrão, ligada mais cedo para este
target. O modelo do toolchain 6.4 a acrescenta a todo pacote novo; a lição 15 trata do que ela muda.

## O programa, e rodá-lo

O único arquivo do executável é o primeiro programa de sempre:

```
ana@vm:~/sw/l19/hello$ cat Sources/hello/hello.swift
// The Swift Programming Language
// https://docs.swift.org/swift-book

@main
struct hello {
    static func main() {
        print("Hello, world!")
    }
}
```

O `@main` marca o tipo cujo `main()` estático é onde o programa começa. É o segundo jeito de dizer
onde um programa começa, ao lado das instruções de nível superior no `main.swift` da lição 1: um
target tem um ou outro, e um arquivo chamado `main.swift` não pode conter também um tipo `@main`. O
`swift run` compila o pacote e roda o executável:

```
ana@vm:~/sw/l19/hello$ swift run 2>&1 | grep -v frontend
Building for debugging...
[Planning deferred tasks]
[18 / 22] hello-product
[19 / 22] hello-product
[23 / 23] hello-product
Build complete! (3.14 secs)
warning: safeExec: signal(32, SIG_DFL) failed: Invalid argument
warning: safeExec: signal(33, SIG_DFL) failed: Invalid argument
Hello, world!
```

O `swift run` compila primeiro, então as linhas de progresso e o `Build complete!` vêm antes da
saudação. **Os dois avisos de `safeExec` vêm do próprio `swift run`**, logo antes de passar a vez ao
programa: ele tenta devolver todo sinal ao padrão, e o Linux reserva os sinais 32 e 33 para a
biblioteca de threads, que recusa. Eles não dizem nada sobre o seu programa, e não aparecem quando
você roda o executável diretamente, como todas as outras seções desta lição fazem.
