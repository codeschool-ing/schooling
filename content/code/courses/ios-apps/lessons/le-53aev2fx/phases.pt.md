---
title: Fases, e a falha que o AsyncImage não informa
version: 1
---

**A forma curta tem um marcador e uma imagem, e nada para o terceiro caso.** Se o download falha, o
marcador fica, e a documentação da Apple acrescenta um detalhe que vale saber: quando o marcador é ele
mesmo uma `Image` que não carrega, o SwiftUI não mostra nada e não informa erro. Uma capa que nunca
chega fica então igual a uma que ainda está a caminho.

A forma completa entrega à closure um `AsyncImagePhase`, um enum com três cases: `empty` enquanto
carrega, `success` com uma `Image`, e `failure` com um `Error`. É o `Loadable` da aula 12 com outra
roupa, e é desenhado do mesmo jeito, com um `switch` que o compilador obriga a cobrir todo case. **Não
executado**:

```swift
// CourseCover.swift
import SwiftUI

struct CourseCover: View {
    let url: URL

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Cover not available")
            @unknown default:
                Color.clear
            }
        }
        .frame(width: 80, height: 80)
        .clipped()
    }
}
```

O `@unknown default` está ali porque `AsyncImagePhase` é um enum ao qual a Apple pode acrescentar um
case num iOS futuro. **Um `switch` sobre o enum de outra pessoa precisa dele, e um `switch` sobre o seu
próprio não deveria ter**, e é por isso que o `Loadable` da aula 12 não tinha: ali, um case novo deve
quebrar a compilação.

A falha desenha um símbolo e um rótulo para o VoiceOver. Uma capa é decoração ao lado do título de um
curso, então a falha dela é discreta; uma imagem que é o próprio conteúdo, um recibo ou um diagrama,
mereceria uma mensagem e um botão de tentar de novo, como o estado de erro da aula 12 tinha.

## Uma transação, para o momento em que ela aparece

O mesmo inicializador recebe uma `Transaction`, que é como uma imagem carregada aparece aos poucos em
vez de surgir de uma vez:

```swift
// CourseCover.swift, the fading version
AsyncImage(url: url, transaction: Transaction(animation: .easeIn(duration: 0.2))) { phase in
    // the same switch as above
}
```

A aula 11 trata de animação; o ponto aqui é só que a passagem de `empty` para `success` é uma mudança
de estado como qualquer outra, e pode ser animada como uma.
