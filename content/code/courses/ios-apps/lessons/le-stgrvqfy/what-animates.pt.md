---
title: O que anima, e o que só muda
version: 1
---

**O SwiftUI anima números.** Tudo o que se mexe na tela durante uma animação, uma largura, uma cor, uma
posição, um ângulo, é um valor que o SwiftUI sabe calcular a meio caminho entre dois outros. A
documentação da Apple para o protocolo `Animatable` descreve o mecanismo: quando um valor animável muda
dentro de uma mudança animada, o SwiftUI lê o valor antigo e o novo e interpola entre eles ao longo de
quadros sucessivos, gravando de volta cada valor interpolado a cada quadro. O que não pode ser calculado
a meio caminho não se mexe; muda, e no máximo esmaece. Nada nesta seção foi executado; a seção 04
calcula a própria interpolação.

## O body roda uma vez

Quando `fraction` vai de dois terços a um, o body da barra roda uma vez, com o valor novo, e devolve uma
barra cheia. Ele não roda 21 vezes no caminho. O que roda a cada quadro é a interpolação do próprio
SwiftUI das propriedades que ele sabe animar, `frame(width:)` aqui, da largura que desenhou para a
largura que agora tem de desenhar. É por isso que animação no SwiftUI custa pouco: a parte cara, o seu
body, rodou uma vez.

## Uma forma que não anima até alguém dizer como

Um anel de progresso em vez de uma barra é um `Shape` com uma fração dentro:

```swift
// ProgressRing.swift
import SwiftUI

struct ProgressRing: Shape {
    var fraction: Double

    var animatableData: Double {
        get { fraction }
        set { fraction = newValue }
    }

    func path(in rect: CGRect) -> Path {
        Path { path in
            path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                        radius: min(rect.width, rect.height) / 2,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 + 360 * fraction),
                        clockwise: false)
        }
    }
}
```

**Sem `animatableData`, o anel pula.** A documentação da Apple para `animatableData` diz que a
implementação padrão devolve `EmptyAnimatableData`, "o que quer dizer que nada é animado": o SwiftUI
pergunta à forma o que interpolar e ouve que nada, então desenha o anel antigo e depois o novo. As quatro
linhas de `animatableData` lhe entregam `fraction`, e a cada quadro o SwiftUI põe em `fraction` o
próximo valor interpolado e chama `path(in:)` de novo. Aqui, ao contrário da barra, o seu código roda a
cada quadro, então um `path(in:)` que faz trabalho de verdade é pago em cada um dos 21 quadros que uma
animação de 0,35 segundo tem a 60 Hz.

## O que não interpola

| mudança | o que acontece |
|---|---|
| uma largura, uma opacidade, um deslocamento, uma cor | interpolada, quadro a quadro |
| o texto de um `Text`, `"120 min"` para `"150 min"` | trocado, com um esmaecimento cruzado; `.contentTransition(.numericText())` pede dígitos que rolam |
| `if done { checkmark }` | o check é inserido ou removido: isso é uma **transição**, seção 05 |
| uma view diferente no mesmo lugar | remoção de uma e inserção da outra, também seção 05 |
| uma propriedade `Bool` ou enum sua | trocada, porque não há nada entre `true` e `false` |

A regra por baixo da tabela: **o SwiftUI interpola valores e faz transição de identidades.** Uma view que
é a mesma view com números novos se mexe; uma view que deixa de existir, ou começa, é entregue a uma
transição. A aula 3 é onde a identidade estrutural foi definida, e este é o primeiro lugar onde ela
aparece na tela.
