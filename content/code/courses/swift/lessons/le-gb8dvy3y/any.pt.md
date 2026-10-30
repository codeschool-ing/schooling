---
title: any, e quanto custa a caixa
version: 1
---

A lição 8 pôs cursos e sessões num array como `[any Describable]`, e a seção 06 mandou o caso misto
para cá. **`any Protocolo` é um existencial: um valor cujo tipo concreto é decidido enquanto o
programa roda, guardado numa caixa que também lembra qual é esse tipo.** `some` é um tipo que quem
chama não conhece; `any` é uma caixa que pode guardar um tipo diferente a cada vez.

## A caixa tem tamanho

A caixa é real, e o `MemoryLayout` a mede:

```swift
// Box.swift
protocol Describable { var title: String { get } }
struct Course: Describable { var title: String; var lessons: Int }
struct StudySession: Describable { var title: String; var minutes: Int }

print(MemoryLayout<Int>.size, MemoryLayout<String>.size)
print(MemoryLayout<Course>.size, MemoryLayout<StudySession>.size)
print(MemoryLayout<any Describable>.size)

let mixed: [any Describable] = [Course(title: "Swift", lessons: 20),
                                StudySession(title: "Optionals", minutes: 45)]
for item in mixed { print(item.title) }
```

```
ana@vm:~/sw/l09$ swift Box.swift
8 16
24 24
40
Swift
Optionals
```

Um `Int` tem 8 bytes e uma `String` 16, então cada struct tem 24. Um `any Describable` tem **40
bytes**, guarde o que guardar: um espaço de três palavras para o valor, uma palavra dizendo que tipo
está dentro e uma apontando para a tabela de conformidade desse tipo, da lição 8, que é como
`item.title` acha a propriedade certa. Um valor grande demais para o espaço é guardado em outro lugar,
e o espaço guarda um ponteiro para ele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l09-box\" aria-label=\"Dois arrays lado a lado. À esquerda, [Course]: três células de 24 bytes cada, cada uma um Course, uma depois da outra. À direita, [any Describable]: duas células de 40 bytes cada. Cada célula se divide num espaço de 24 bytes para o valor, uma palavra dizendo que tipo está dentro e uma palavra apontando para a tabela de conformidade desse tipo. A primeira caixa guarda um Course, a segunda uma StudySession.\"><text x=\"130\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">[Course]</text><text x=\"130\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um tipo, conhecido na compilação</text><rect x=\"40\" y=\"70\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Course</text><text x=\"130\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24 B</text><rect x=\"40\" y=\"132\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Course</text><text x=\"130\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24 B</text><rect x=\"40\" y=\"194\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Course</text><text x=\"130\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24 B</text><text x=\"500\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">[any Describable]</text><text x=\"500\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma caixa por elemento, o tipo lido na execução</text><rect x=\"300\" y=\"70\" width=\"400\" height=\"72\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"310\" y=\"80\" width=\"190\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"405\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Course</text><text x=\"405\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">valor, 24 bytes</text><rect x=\"510\" y=\"80\" width=\"80\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">que tipo</text><rect x=\"600\" y=\"80\" width=\"90\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"645\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tabela</text><text x=\"645\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">de conformidade</text><rect x=\"300\" y=\"160\" width=\"400\" height=\"72\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"310\" y=\"170\" width=\"190\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"405\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">StudySession</text><text x=\"405\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">valor, 24 bytes</text><rect x=\"510\" y=\"170\" width=\"80\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">que tipo</text><rect x=\"600\" y=\"170\" width=\"90\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"645\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tabela</text><text x=\"645\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">de conformidade</text><text x=\"500\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">40 B × 2</text></svg>", "caption": "Um array de uma struct guarda as próprias structs. Um array de any guarda uma caixa de 40 bytes por elemento: espaço para o valor, e duas palavras que dizem o que ele é e onde estão os métodos."}
```

## O que um any não consegue fazer

A caixa esconde o tipo, e com ele tudo o que depende do tipo. O `Describable` da lição 8 não tem tipo
associado, então nada se perdeu. O `Store` da seção 05 tem um, e um repositório dentro de uma caixa
não sabe mais o que aceita:

```swift
// AnyStore.swift
protocol Store {
    associatedtype Item
    var all: [Item] { get }
    mutating func add(_ item: Item)
}

struct Minutes: Store {
    var all: [Int] = []
    mutating func add(_ item: Int) { all.append(item) }
}

var store: any Store = Minutes()
print(store.all)
store.add(30)
```

```
ana@vm:~/sw/l09$ swiftc AnyStore.swift -o anystore
AnyStore.swift:15:1: error: member 'add' cannot be used on value of type 'any Store'; consider using a generic constraint instead [#ExistentialMemberAccess]
13 | var store: any Store = Minutes()
14 | print(store.all)
15 | store.add(30)
   | `- error: member 'add' cannot be used on value of type 'any Store'; consider using a generic constraint instead [#ExistentialMemberAccess]
16 | 

[#ExistentialMemberAccess]: <https://docs.swift.org/compiler/documentation/diagnostics/existential-member-access-limitations>
```

A linha 14, que lê `all`, foi aceita: só a linha 15 tem erro. Acrescentar é recusado, porque nada
impede `store` de guardar um repositório de strings naquele momento, e a mensagem sugere o que fazer
no lugar: **uma restrição genérica**, como o `fill<S: Store>` da seção 05, que mantém o tipo conhecido.

## Escolhendo entre os dois

| você tem | escreva |
|---|---|
| um tipo que quem chama não precisa nomear | `some Protocolo` |
| um parâmetro que aceita qualquer tipo que conforma | `some Protocolo`, ou uma restrição `<T: Protocolo>` |
| valores de tipos diferentes numa coleção, ou uma propriedade armazenada cujo tipo muda | `any Protocolo` |

**Comece com `some`, e escreva `any` quando os valores forem mesmo misturados.** `any` não é errado, e
a lista mista do planner é exatamente o caso dele; é uma caixa com uma consulta a cada chamada, e um
genérico que conhece o tipo não tem nenhuma das duas. O Swift 6 pede que você escreva a palavra `any`
por isso, para o custo ficar visível onde é pago. Código de antes dessa regra escrevia
`[Describable]`, que ainda compila hoje, e a lição 15 é onde os modos de linguagem que apertam regras
como esta são explicados.
