---
title: Previews, uma tela em todos os estados de uma vez
version: 1
---

**Uma preview é uma view desenhada pelo Xcode ao lado do código, redesenhada enquanto você digita, sem
rodar o app.** Ela não é um teste, já que nada falha, e é o jeito mais rápido de olhar uma tela num
estado difícil de alcançar tocando: uma semana sem sessões, um título de curso de três linhas, o maior
tamanho de texto, o tema escuro. Nada aqui foi executado; precisa do canvas do Xcode. Foi escrito a
partir da documentação da Apple para a macro `#Preview` e o canvas, lida em 30 de outubro de 2026.

```swift
// WeekView+Previews.swift
import SwiftUI
import PlannerCore

#Preview("An ordinary week") {
    WeekView(total: WeekTotal(monday: "2026-10-19", planned: 180, done: 120))
}

#Preview("Nothing planned yet") {
    WeekView(total: WeekTotal(monday: "2026-10-19", planned: 0, done: 0))
}

#Preview("All done, largest text") {
    WeekView(total: WeekTotal(monday: "2026-10-19", planned: 180, done: 180))
        .environment(\.dynamicTypeSize, .accessibility5)
}
```

**Cada `#Preview` é um estado com nome**, e o canvas os mostra como abas. Os valores são os tipos do
próprio pacote, montados à mão, e esse é o ganho de manter os dados do planner em Swift puro: uma
preview não precisa de servidor, de banco de dados nem de estado de simulador, só de um valor.

## Usando como ferramenta de trabalho

- **Escreva primeiro os estados incômodos.** A semana comum fica boa por construção. `planned: 0` é onde
  uma divisão por zero transforma uma barra de progresso em nada, e o maior tamanho de texto é onde os
  layouts da aula 19, seção 05, quebram.
- **O modo Variants do canvas** desenha uma preview em todo esquema de cores, orientação ou tamanho de
  texto de uma vez, então uma tela é conferida contra todos num só olhar.
- **Uma preview que precisa do app inteiro para desenhar é um aviso.** Se o `WeekView` não tem preview
  sem um cliente de rede e um armazenamento, ele está fazendo mais do que desenhar uma semana, e o
  repositório da aula 14 é onde esse trabalho mora.

Uma preview não prova nada sozinha. Ela mostra o que consertar; o teste unitário é o que mantém
consertado.
