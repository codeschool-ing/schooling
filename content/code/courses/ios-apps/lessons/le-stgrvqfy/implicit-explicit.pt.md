---
title: Duas formas de pedir uma animação
version: 1
---

**O SwiftUI nunca anima uma view; ele anima uma mudança de estado.** A crença a largar é que uma
animação é algo que você inicia, como um cronômetro. No SwiftUI o estado muda de uma vez, o body roda de
uma vez com o valor novo, e uma animação é uma instrução presa a essa mudança, dizendo como a tela deve
ir do que mostrava ao que agora tem de mostrar. Há dois lugares onde prendê-la. Nada nesta seção foi
executado: ela foi escrita a partir da documentação da Apple para `animation(_:value:)`,
`withAnimation(_:_:)` e `Transaction`, como estava em 30 de outubro de 2026.

## Implícita: na view, para um valor

A barra da semana do planner se enche conforme as sessões são marcadas como feitas. Ela pode dizer, uma
vez, que sempre que a fração dela mudar a mudança é animada:

```swift
// WeekBar.swift
import SwiftUI
import PlannerCore

struct WeekBar: View {
    let total: WeekTotal

    var body: some View {
        let fraction = total.planned == 0 ? 0 : Double(total.done) / Double(total.planned)
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule().fill(.tint).frame(width: proxy.size.width * fraction)
            }
        }
        .frame(height: 12)
        .animation(.easeInOut, value: fraction)
    }
}
```

A documentação da Apple para `animation(_:value:)` diz que ele aplica a animação a esta view sempre que
o valor muda. **O `value` é a parte que importa.** A barra anima quando `fraction` muda e por nenhum outro
motivo, então girar o telefone ou mudar o tamanho da fonte, o que redesenha a barra, não se arrasta por
0,35 segundo. O antigo `animation(_:)` sem valor animava a view sempre que qualquer coisa nela mudava, e
a documentação da Apple o marca como obsoleto justamente pelas surpresas que isso causava.

## Explícita: em volta da mudança, para tudo o que ela toca

O outro lugar é o momento da própria mudança:

```swift
// CourseDetailView.swift, the button on a session's row
Button("Mark done") {
    withAnimation(.easeOut) {
        markDone(session.id)
    }
}
```

O `markDone(_:)` é o método da própria tela que muda o plano. A documentação da Apple para
`withAnimation(_:_:)` diz que ele põe a animação na **transação** atual, o registro que o SwiftUI guarda
de uma mudança e de tudo o que ela causa. Então toda view cuja aparência muda por causa desse toque anima
com `.easeOut`: o check da linha, a linha passando para outro grupo, a barra da semana, o total na barra
de navegação, onde quer que estejam na tela. Nenhuma dessas views precisa saber.

## Qual usar

| | `animation(_:value:)` | `withAnimation` |
|---|---|---|
| escrita em | a view que se mexe | o código que muda o estado |
| anima | esta view, quando este valor muda | tudo o que a mudança causa |
| bom para | uma view que se mexe sempre do mesmo jeito, como a barra | uma ação cujo efeito inteiro deve se mexer junto |
| surpresa a vigiar | uma mudança vinda de outro lugar também anima, se mexer o mesmo valor | uma view que devia pular agora desliza, porque mudou na mesma transação |

Quando as duas valem para a mesma mudança, o `animation(_:value:)` da própria view ganha para ela. A
documentação da Apple para `Transaction` descreve a ordem: a animação posta pelo `withAnimation` desce
pela árvore de views, e um modificador mais abaixo pode trocá-la para a sua subárvore. O planner usa a
forma implícita para a barra, para que ela se mexa do mesmo jeito seja quem for que mude o total, e a
explícita para "marcar como feita", para que a linha e todo o resto se mexam juntos.

O `withAnimation` sem animação nenhuma usa o `Animation.default`, e a seção 04 mostra o que ele é.
