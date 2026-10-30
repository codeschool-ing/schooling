---
title: Uma dependência do GitHub
version: 1
---

O `plan` lê os argumentos à mão e ignora o que não for número. Uma ferramenta de linha de comando de
verdade tem opções, uma página de `--help` e erros que dizem o que estava errado, e fazer isso bem é
um projeto à parte. **A Apple publica um como pacote, o `swift-argument-parser`**, e depender dele
são duas linhas do manifesto.

```swift
// swift-tools-version: 6.2
// Package.swift
import PackageDescription

let package = Package(
    name: "planner",
    products: [
        .library(name: "PlannerCore", targets: ["PlannerCore"]),
        .executable(name: "plan", targets: ["plan"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.0"),
    ],
    targets: [
        .target(name: "PlannerCore"),
        .executableTarget(
            name: "plan",
            dependencies: [
                "PlannerCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ]
)
```

A lista `dependencies` do topo diz **que pacotes** buscar, pelo endereço do repositório git e pelas
versões aceitáveis. A `dependencies` do próprio target diz **que produtos deles** este módulo usa: um
pacote pode oferecer vários, e o `ArgumentParser` é o que este target importa. As duas listas são
separadas porque respondem a perguntas diferentes, e esquecer a segunda é o motivo de sempre do
`no such module 'ArgumentParser'`.

`from: "1.6.0"` quer dizer **1.6.0 ou qualquer coisa posterior antes de 2.0.0**. A seção 05 trata do
que essa faixa promete e de como ela é fixada.

## O programa, reescrito

```schooling-example
{"language": "swift", "file": "Sources/plan/Plan.swift", "parts": [
{"code": "import ArgumentParser\nimport PlannerCore", "note": "Dois imports: o produto da dependência e a própria biblioteca do pacote."},
{"code": "@main\nstruct Plan: ParsableCommand {\n    static let configuration = CommandConfiguration(\n        abstract: \"Add up a week of study sessions.\"\n    )", "note": "O comando é um tipo que se conforma a `ParsableCommand`, marcado com `@main` como na seção 02. O `abstract` vira a primeira linha da página de ajuda."},
{"code": "    @Option(help: \"Minutes the week should reach.\")\n    var goal = 300\n\n    @Argument(help: \"The minutes of each session.\")\n    var minutes: [Int]", "note": "Cada entrada é uma propriedade com um property wrapper da aula 16. `@Option` é um `--goal` com nome, e com seu padrão; `@Argument` é posicional, e um `[Int]` junta todo número dado. O parser converte cada palavra para o tipo da propriedade, ou a recusa."},
{"code": "    func run() {\n        var week = Week(goal: goal)\n        for session in minutes {\n            week.add(session)\n        }\n        print(\"\\(week.total) of \\(week.goal) minutes\")\n    }\n}", "note": "O `run()` é chamado depois que tudo foi lido, com todas as propriedades já preenchidas."}
]}
```

O programa sai do `main.swift`, porque um target com um tipo `@main` não pode ter os dois. **O
`swift package resolve` busca a dependência** sem compilar nada, o que separa o download da
compilação:

```
ana@vm:~/sw/l19/planner$ rm Sources/plan/main.swift
ana@vm:~/sw/l19/planner$ swift package resolve
Fetching https://github.com/apple/swift-argument-parser
[1/19320] Fetching swift-argument-parser
Fetched https://github.com/apple/swift-argument-parser (1.39s)
Computing version for https://github.com/apple/swift-argument-parser
Computed https://github.com/apple/swift-argument-parser at 1.8.2 (1.67s)
Creating working copy for https://github.com/apple/swift-argument-parser
Working copy of https://github.com/apple/swift-argument-parser resolved at 1.8.2
```

O SwiftPM clonou o repositório, olhou as tags e escolheu a versão mais nova que `from: "1.6.0"`
permite: **1.8.2**. A cópia de trabalho é um checkout dessa tag, guardado sob o `.build`. O primeiro
build também compila a dependência, e por isso é mais lento que qualquer build só do planner:

```
ana@vm:~/sw/l19/planner$ swift build 2>&1 | tail -1
Build complete! (7.66 secs)
ana@vm:~/sw/l19/planner$ .build/debug/plan 45 30 60
135 of 300 minutes
ana@vm:~/sw/l19/planner$ .build/debug/plan --goal 120 45 30 60
135 of 120 minutes
ana@vm:~/sw/l19/planner$ .build/debug/plan --help
OVERVIEW: Add up a week of study sessions.

USAGE: plan [--goal <goal>] <minutes> ...

ARGUMENTS:
  <minutes>               The minutes of each session.

OPTIONS:
  --goal <goal>           Minutes the week should reach. (default: 300)
  -h, --help              Show help information.

ana@vm:~/sw/l19/planner$ .build/debug/plan 45 forty; echo $?
Error: The value 'forty' is invalid for '<minutes>'
Help:  <minutes>  The minutes of each session.
Usage: plan [--goal <goal>] <minutes> ...
  See 'plan --help' for more information.
64
```

O parser fez três trabalhos que ninguém escreveu: converteu três palavras num `[Int]`, escreveu uma
página de ajuda a partir dos nomes das propriedades e das strings `help:`, e recusou `forty` com uma
mensagem que nomeia o argumento. Depois saiu com **64**, o status convencional para um comando
usado errado, para que um script que chama o `plan` distinga um erro de digitação de uma quebra.

## Quanto custa uma dependência

**Toda dependência é código que você não escreveu e que vai compilar, distribuir e atualizar.** O
`swift-argument-parser` é uma razoável: vem da Apple, é pequeno, não tem dependências próprias e
substitui um trabalho fácil de errar. A pergunta a fazer a qualquer outra é a mesma lista: quem a
mantém, quanto ela traz junto, e quanto custaria trocá-la. O `swift package show-dependencies` da
seção 05 responde à segunda num relance.
