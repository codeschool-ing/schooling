---
title: O cifrão, a segunda face de um wrapper
version: 1
---

O `$minutes` da view do SwiftUI da seção 02 não é outra variável que alguém declarou. **Um wrapper pode
oferecer um segundo valor, o `projectedValue`, e o compilador o nomeia com um `$`** na frente da
propriedade. O que esse valor é depende inteiramente do wrapper: o `@State` do SwiftUI projeta um
`Binding`, uma alça pela qual outra view lê e escreve, que é como o `Stepper` muda `minutes`. O nosso
pode projetar qualquer coisa útil.

O planner gostaria de saber quando um valor foi limitado, para poder avisar a estudante que 900
minutos é mais do que uma sessão comporta. O wrapper é o único código que sabe, então ele guarda essa
informação e a projeta:

```swift
// Projected.swift
@propertyWrapper
struct Clamped {
    private var value: Int
    private(set) var projectedValue = false
    let range: ClosedRange<Int>

    init(wrappedValue: Int, _ range: ClosedRange<Int>) {
        self.range = range
        self.value = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }

    var wrappedValue: Int {
        get { value }
        set {
            value = min(max(newValue, range.lowerBound), range.upperBound)
            projectedValue = value != newValue
        }
    }
}

struct StudySession {
    @Clamped(0...600) var minutes = 45
}

var session = StudySession()
for typed in [90, 900, 600] {
    session.minutes = typed
    if session.$minutes {
        print("\(typed) is too long: kept \(session.minutes)")
    } else {
        print("\(typed) minutes")
    }
}
```

```
ana@vm:~/sw/l16$ swift Projected.swift
90 minutes
900 is too long: kept 600
600 minutes
```

**`session.$minutes` é um `Bool`**, porque o `projectedValue` é um. O compilador transformou
`$minutes` em `_minutes.projectedValue`, do mesmo jeito que transforma `minutes` em
`_minutes.wrappedValue`. O 600 que veio por último foi aceito como estava, então a marca voltou a
`false`: ela descreve a escrita mais recente, não a história.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l16-wrapper\" aria-label=\"À esquerda, a única linha que você escreve: @Clamped(0...600) var minutes. Setas levam a três declarações geradas à direita: uma propriedade armazenada privada _minutes com o wrapper Clamped, um minutes computado cujo getter e setter vão para _minutes.wrappedValue, e $minutes, que lê _minutes.projectedValue.\"><defs><marker id=\"l16-wrap-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o que você escreve</text><rect x=\"20\" y=\"38\" width=\"270\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"155\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">@Clamped(0...600) var minutes</text><text x=\"400\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o que o compilador gera</text><rect x=\"400\" y=\"38\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">private var _minutes: Clamped</text><text x=\"550\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o próprio wrapper, escondido</text><path d=\"M290 55 C340 55 350 60 398 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-wrap-ah)\"></path><rect x=\"400\" y=\"98\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">var minutes: Int</text><text x=\"550\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">get/set → _minutes.wrappedValue</text><path d=\"M290 55 C340 55 350 120 398 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-wrap-ah)\"></path><rect x=\"400\" y=\"158\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">var $minutes: Bool</text><text x=\"550\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">get → _minutes.projectedValue</text><path d=\"M290 55 C340 55 350 180 398 180\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-wrap-ah)\"></path><text x=\"155\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ler minutes</text><text x=\"155\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">= chamar o getter</text><text x=\"155\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ler $minutes</text><text x=\"155\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">= perguntar ao wrapper</text><text x=\"360\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--amber)\">uma linha entra, três declarações saem</text></svg>", "caption": "Um property wrapper expandido: o armazenamento é o wrapper, a propriedade passa pelo wrappedValue, e o nome com cifrão pelo projectedValue."}
```

O `private(set)` no `projectedValue` quer dizer que quem chama pode lê-lo e só o wrapper pode mudá-lo.
Um chamador que pudesse definir "foi limitado" como quisesse faria a marca não significar nada.

## Lendo o wrapper de outra pessoa

Quando você encontra um `@` que não conhece, três perguntas descobrem o que ele faz, e as respostas
estão na declaração do wrapper, não no lugar em que você o usa:

| pergunta | onde olhar |
|---|---|
| o que ler a propriedade faz? | o getter do `wrappedValue` |
| o que escrever nela faz? | o setter do `wrappedValue`, se houver |
| o que `$nome` dá? | o tipo do `projectedValue`, se houver |

Para o SwiftUI as respostas estão na documentação da Apple, e o `ios-apps` faz essas perguntas ao
`@State`, ao `@Binding` e ao `@Environment`, um de cada vez. O mecanismo por baixo de cada um é o que
você acabou de escrever.
