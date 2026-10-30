---
title: Stacks: HStack, VStack e ZStack
version: 1
---

**Uma stack arruma os filhos ao longo de um eixo, ou uns sobre os outros, e oferece a cada um uma
parte da sua própria proposta.** Três delas cobrem a maioria das telas: `HStack` lado a lado, `VStack`
um embaixo do outro, e `ZStack` em camadas, as últimas na frente. Cada uma aceita dois argumentos
opcionais, um `alignment` para o outro eixo e um `spacing` entre os filhos.

```swift
// CourseRow.swift
import SwiftUI
import PlannerCore

struct CourseRow: View {
    let course: Course
    let minutes: Int

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(course.title)
                    .font(.headline)
                Text("this week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(minutes) min")
                .monospacedDigit()
        }
    }
}
```

**Um `VStack(alignment: .leading)` alinha as bordas iniciais dos filhos, e é para isso que serve o
argumento.** Sem ele os dois textos ficariam centralizados um no outro, uma legenda curta embaixo do
meio de um título longo. O alinhamento do próprio `HStack`, que esta linha deixa no padrão, decide
como o `VStack` e os minutos se alinham na vertical, e a seção 05 compara as escolhas.

O `spacing: 12` é o espaço entre os filhos da stack. Deixe-o de fora e a stack usa um espaçamento que
a plataforma escolhe, que a documentação da Apple descreve como uma distância padrão que depende das
duas views vizinhas; o modelo do curso na seção 08 usa um 8 fixo para manter a aritmética visível.

## Todos os filhos de uma vez, ou só o que está na tela

A documentação da Apple para o `HStack` faz uma distinção que vale conhecer agora: um `HStack` cria
todos os filhos de uma vez, estejam eles na tela ou não, enquanto um `LazyHStack` os cria só quando
são necessários. Para uma linha de três views isso não importa. Para uma coluna de quinhentas sessões
é a diferença de que trata a aula 8, e o `List` é preguiçoso do mesmo jeito.

O `ZStack` é para camadas: uma forma de fundo atrás de um rótulo, um selo sobre um ícone. O planner o
usa uma vez, na aula 11, para um anel de progresso com os minutos escritos dentro.

Nada nesta seção foi executado para o curso. A `CourseRow` foi escrita a partir da documentação da
Apple para `HStack`, `VStack`, `Text` e `Spacer`, lida em 30 de outubro de 2026.
