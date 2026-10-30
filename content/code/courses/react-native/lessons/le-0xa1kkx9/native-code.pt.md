---
title: Kotlin e Swift
version: 1
---

O lado Android substitui a classe do modelo. Salve o
`modules/week-start/android/src/main/java/org/example/weekstart/WeekStartModule.kt`:

```kotlin
// modules/week-start/android/src/main/java/org/example/weekstart/WeekStartModule.kt
// The first day of the week in the phone's own calendar, for JavaScript.
package org.example.weekstart

import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import java.util.Calendar
import java.util.Locale

// The rule, with nothing of React Native in it, so a plain JVM test can run it.
// Calendar counts SUNDAY = 1 to SATURDAY = 7; JavaScript's Date.getDay() counts Sunday = 0.
fun firstWeekday(locale: Locale): Int = Calendar.getInstance(locale).firstDayOfWeek - 1

class WeekStartModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("WeekStart")

    Function("firstWeekday") {
      firstWeekday(Locale.getDefault())
    }
  }
}
```

- **O `firstWeekday(locale)` é a regra, e é uma função Kotlin comum.** Ela não sabe nada do React Native,
  então a JVM do seu computador consegue rodá-la num teste, que é o que a seção de testes na JVM faz.
- **O `Calendar.getInstance(locale).firstDayOfWeek`** é o calendário do Java, que o Android implementa com
  os mesmos dados de calendário que a plataforma usa em todo lugar. Ele conta domingo como 1, então a função
  subtrai um para contar como o `Date.getDay()` do JavaScript conta.
- **O `ModuleDefinition` descreve o que o JavaScript vê.** O `Name("WeekStart")` é o nome que o JavaScript
  pede; o `Function("firstWeekday")` é uma função síncrona, chamada pelo JSI na thread do JavaScript, cujo
  valor de retorno é convertido num número JavaScript.

O lado iOS faz o mesmo em Swift. Salve o `modules/week-start/ios/WeekStartModule.swift`:

```swift
// modules/week-start/ios/WeekStartModule.swift: the first day of the week in the phone's own calendar, for JavaScript.
import ExpoModulesCore

public class WeekStartModule: Module {
  public func definition() -> ModuleDefinition {
    Name("WeekStart")

    // Calendar counts Sunday = 1; JavaScript's Date.getDay() counts Sunday = 0.
    Function("firstWeekday") { () -> Int in
      return Calendar.current.firstWeekday - 1
    }
  }
}
```

O `Calendar.current` é o calendário da própria pessoa, com o primeiro dia da semana que ela escolheu nos
ajustes do celular, e ele também conta domingo como 1. **As duas definições têm a mesma forma de
propósito**: um `Name`, uma `Function` com o mesmo nome, um valor com o mesmo significado. Nada confere que
elas concordam além de você, e de um teste em cada plataforma. *O arquivo Swift não foi compilado para este
curso: construir para iOS precisa do Xcode, que só roda num Mac. A aula 20 é sobre construir para iOS sem
um.*

Uma função que leva tempo, a leitura de um arquivo ou uma chamada de rede, seria uma `AsyncFunction`, que o
JavaScript recebe como uma promise; os `Events` mandam valores ao JavaScript conforme acontecem; uma `View`
expõe uma view nativa como componente. A pergunta do planner não precisa de nenhum deles.
