---
title: Uma lista de imagens que rola
version: 1
---

**Uma lista é onde tudo desta aula acontece ao mesmo tempo e rápido.** Uma pessoa passa por cinquenta
cursos num segundo; linhas aparecem e somem mais rápido que as capas baixam; e toda linha que aparece
pede uma imagem. Três regras mantêm isso suave, e cada uma é uma seção desta aula posta para trabalhar.
Esta seção é SwiftUI, escrita a partir da documentação da Apple para `List`, `task(id:)` e
`displayScale`, e **não foi executada**.

## A linha

A linha carrega a própria capa, pelo cache compartilhado, reduzida ao que ela desenha:

```swift
// CourseRow.swift
import SwiftUI
import PlannerCore

struct CourseRow: View {
    let course: Course
    let cover: URL
    let images: ImageCache
    @Environment(\.displayScale) private var scale
    @State private var picture: UIImage?

    var body: some View {
        HStack {
            Group {
                if let picture {
                    Image(uiImage: picture).resizable().scaledToFill()
                } else {
                    Color.secondary.opacity(0.2)
                }
            }
            .frame(width: 80, height: 80)
            .clipped()
            .accessibilityHidden(true)
            Text(course.title)
        }
        .task(id: cover) {
            guard let data = try? await images.data(for: cover) else { return }
            picture = downsample(data, maxPixels: Int(80 * scale))
        }
    }
}
```

**A primeira regra é um cache só para a lista inteira.** O `images` é passado de fora, não criado na
linha, então toda linha compartilha o dicionário de downloads em andamento da seção 06, e cinquenta
linhas de três cursos fazem três downloads. Um cache criado dentro de cada linha não guardaria nada.

**A segunda é decodificar pequeno, fora do main actor, antes de qualquer coisa ser desenhada.** A
closure do `task` roda o download e o downsampling como trabalho assíncrono; só a `UIImage` pequena é
atribuída ao estado que a view desenha. No app, o cache da seção 06 guardaria essa imagem pequena, e na
próxima vez que a linha aparecer o trabalho nem é feito.

**A terceira é que uma linha que sai para de esperar.** O `task(id:)` cancela o trabalho dele quando a
linha some, como a aula 12 mostrou. A linha para de esperar, e nada do que ela atribuiria chega. O
download em si continua, porque mora na `Task` do próprio cache e outra linha ainda pode querê-lo; uma
imagem que ninguém quer fica então guardada, pronta para o momento em que a pessoa rolar de volta.

O `try?` descarta o erro de propósito. Uma capa é decoração, e a seção 03 disse que a falha dela é
discreta: o quadrado cinza fica. A capa fica escondida do VoiceOver pelo mesmo motivo, já que o título
do curso ao lado já diz tudo o que a imagem diz; a aula 19 é onde essa decisão é tomada para toda
imagem do planner.

## O que o `List` faz com as linhas

O `List` é preguiçoso: ele constrói linhas conforme elas entram na tela e as descarta conforme saem, e
é por isso que uma lista de cinco mil cursos abre tão rápido quanto uma de cinco. **Essa preguiça é o
motivo de o trabalho ficar no `task` da linha** e não num inicializador: uma linha construída e
descartada durante uma rolagem rápida não deveria começar nada que não vai terminar. A aula 8 é onde a
preguiça do `List`, e a identidade que o deixa reaproveitar uma linha, são ensinadas.

As collection views do UIKit oferecem um gancho de pré-carregamento, `prefetchDataSource`, que começa os
downloads das linhas prestes a aparecer. O planner não usa um: o cache cobre boa parte da diferença,
já que uma capa que a pessoa viu uma vez está na memória e uma capa pedida por várias linhas é baixada
uma vez só.
