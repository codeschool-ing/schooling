---
title: Propriedades lazy
version: 1
---

Alguns valores são caros de construir e talvez nunca sejam necessários: o resumo de um histórico
longo, um arquivo interpretado, um formatador. **Uma propriedade `lazy` é armazenada, mas o valor
inicial é calculado na primeira vez que é lida, e nunca mais.** Até lá a instância não carrega valor
nenhum para ela:

```swift
// Lazy.swift
struct Report {
    let sessions: [Int]
    lazy var summary: String = {
        print("building the summary")
        return "\(sessions.count) sessions, \(sessions.reduce(0, +)) minutes"
    }()
}
var report = Report(sessions: [45, 30, 60])
print("report made")
print(report.summary)
print(report.summary)
```

```
ana@vm:~/sw/l06$ swift Lazy.swift
report made
building the summary
3 sessions, 135 minutes
3 sessions, 135 minutes
```

O valor inicial é uma closure chamada na hora, `{ … }()`, que é o jeito comum de escrever um valor
inicial que precisa de várias linhas. **"building the summary" foi impresso uma vez**, na primeira
leitura e depois de "report made", e a segunda leitura encontrou a string guardada. Um valor inicial
lazy pode usar as outras propriedades da instância, `sessions` aqui, o que um valor padrão comum não
pode, porque quando alguém lê uma propriedade lazy a instância já existe.

## Ler muda a instância

A primeira leitura de uma propriedade lazy guarda um valor, o que é uma mudança. Para uma struct, uma
mudança precisa de um `var`, e então uma propriedade lazy não pode ser lida por um `let`:

```swift
// LazyLet.swift
struct Report {
    let sessions: [Int]
    lazy var summary: String = "\(sessions.count) sessions"
}
let report = Report(sessions: [45, 30])
print(report.summary)
```

```
ana@vm:~/sw/l06$ swiftc LazyLet.swift -o lazylet
LazyLet.swift:7:14: error: cannot use mutating getter on immutable value: 'report' is a 'let' constant
4 |     lazy var summary: String = "\(sessions.count) sessions"
5 | }
6 | let report = Report(sessions: [45, 30])
  | `- note: change 'let' to 'var' to make it mutable
7 | print(report.summary)
  |              `- error: cannot use mutating getter on immutable value: 'report' is a 'let' constant
8 | 
```

"Mutating getter" é o nome que o compilador dá a uma leitura que escreve. Essa é a exceção que a
seção 02 prometeu: **`lazy` funciona livremente numa classe e numa struct só por um `var`**, o que a
torna bem mais comum em classes. É também por isso que uma propriedade lazy é sempre `var`, nunca
`let`.

## Que tipo roda código, e quando

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l06-kinds\" aria-label=\"Uma tabela desenhada como grade. Linhas: propriedades armazenadas, computadas, observadas, lazy e estáticas. Colunas: o que acontece na inicialização, numa leitura e numa escrita. Armazenada: guarda o valor, devolve, guarda. Computada: nada, roda o get, roda o set. Observada: guarda sem rodar os observadores, devolve, roda willSet, guarda e roda didSet. Lazy: nada, constrói o valor na primeira leitura, guarda. Estática: nada por instância, inicializada uma vez para o tipo no primeiro uso, guarda.\"><text x=\"80.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">tipo</text><text x=\"235.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">na inicialização</text><text x=\"410.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">na leitura</text><text x=\"595.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">na escrita</text><rect x=\"23\" y=\"40\" width=\"114\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">stored</text><rect x=\"143\" y=\"40\" width=\"184\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"235.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">guarda o valor</text><rect x=\"333\" y=\"40\" width=\"154\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">devolve</text><rect x=\"493\" y=\"40\" width=\"204\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">guarda</text><rect x=\"23\" y=\"80\" width=\"114\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">computed</text><rect x=\"143\" y=\"80\" width=\"184\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"235.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nada</text><rect x=\"333\" y=\"80\" width=\"154\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">roda o get</text><rect x=\"493\" y=\"80\" width=\"204\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">roda o set</text><rect x=\"23\" y=\"120\" width=\"114\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">observed</text><rect x=\"143\" y=\"120\" width=\"184\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"235.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">guarda, sem observador</text><rect x=\"333\" y=\"120\" width=\"154\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">devolve</text><rect x=\"493\" y=\"120\" width=\"204\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">willSet, guarda, didSet</text><rect x=\"23\" y=\"160\" width=\"114\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lazy</text><rect x=\"143\" y=\"160\" width=\"184\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"235.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nada</text><rect x=\"333\" y=\"160\" width=\"154\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1ª leitura: constrói</text><rect x=\"493\" y=\"160\" width=\"204\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">guarda</text><rect x=\"23\" y=\"200\" width=\"114\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">static</text><rect x=\"143\" y=\"200\" width=\"184\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"235.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nada por instância</text><rect x=\"333\" y=\"200\" width=\"154\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1º uso: inicializa</text><rect x=\"493\" y=\"200\" width=\"204\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">guarda</text></svg>", "caption": "Os mesmos três momentos para cada tipo de propriedade. As caixas em âmbar são onde roda código seu."}
```

Uma propriedade lazy é calculada uma vez e depois se comporta como uma armazenada; uma propriedade
computada roda a cada leitura; uma propriedade observada roda a cada escrita depois da
inicialização. Escolher entre elas é escolher quando o código roda.
