---
title: Geometria correspondente, uma view em dois lugares
version: 1
---

**O `matchedGeometryEffect` faz duas views parecerem uma view se movendo.** Quando uma view com um
identificador é removida e outra com o mesmo identificador é inserida na mesma mudança, o SwiftUI
interpola o quadro da primeira até o quadro da segunda. A documentação da Apple para
`matchedGeometryEffect(id:in:properties:anchor:isSource:)` diz isso com todas as letras: o sistema
interpola os retângulos dos quadros delas no espaço da janela "para parecer que há uma única view se
movendo da posição antiga para a nova". Nada nesta seção foi executado; essa documentação, lida em 30 de
outubro de 2026, é a fonte dela.

## O seletor de dia na tela da semana

A tela da semana deixa o estudante escolher um dia para ver as sessões dele. Sete botões, de segunda a
domingo, e uma cápsula atrás do escolhido. Com geometria correspondente a cápsula desliza de dia em dia
em vez de sumir embaixo de um e aparecer embaixo de outro:

```swift
// DayPicker.swift
import SwiftUI

struct DayPicker: View {
    let days: [String]            // the week's days, YYYY-MM-DD, Monday first
    @Binding var selected: String
    @Namespace private var picker

    var body: some View {
        HStack(spacing: 4) {
            ForEach(days, id: \.self) { day in
                Button {
                    withAnimation(.spring) { selected = day }
                } label: {
                    Text(day.suffix(2))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background {
                            if day == selected {
                                Capsule()
                                    .fill(.tint.opacity(0.2))
                                    .matchedGeometryEffect(id: "selection", in: picker)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
```

Três peças fazem isso funcionar:

- **O `@Namespace`** dá aos identificadores um escopo próprio, para que `"selection"` aqui não colida com
  um `"selection"` de outra view.
- **Só existe uma cápsula por vez.** Ela é desenhada embaixo do dia que estiver escolhido, então mudar
  `selected` remove a cápsula de um botão e insere uma embaixo de outro, que é exatamente o caso que a
  documentação descreve.
- **A mudança é animada**, pelo `withAnimation(.spring)`. Como em toda transição da seção 05, sem uma
  animação na transação não há sobre o que interpolar, e a cápsula pula.

## O que ele não faz

A documentação é igualmente clara sobre os limites. Ele liga a **geometria**, o quadro, e nada mais: "os
mecanismos normais de transição definem como cada uma das duas views é desenhada durante a transição".
Duas views de aparência diferente, um ícone pequeno e um grande, ainda esmaecem cada uma com a sua
transição enquanto os quadros delas são correspondidos. E a documentação diz que o resultado é indefinido
se o grupo não tiver exatamente uma view com `isSource` verdadeiro. Duas cápsulas desenhadas ao mesmo
tempo, porque um bug escolheu dois dias, dão uma cápsula que vai para onde ninguém escolheu. Isso faz da
propriedade `selected`, um dia e nunca dois, mais do que capricho.

O `day.suffix(2)` transforma `2026-10-21` em `21`, o dia do mês. Um app de verdade formata o dia com a
localidade da pessoa; a aula 19 é onde o rótulo que cada botão lê em voz alta recebe esse cuidado.
