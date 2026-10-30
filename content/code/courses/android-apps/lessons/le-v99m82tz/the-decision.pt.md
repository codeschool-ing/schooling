---
title: Uma função para cada resposta que o Android pode dar
version: 1
---

**A parte difícil de uma permissão não é pedir; é decidir o que oferecer.** Quatro fatos chegam de
três lugares: a versão do Android do celular, se a permissão está concedida, o conselho do Android
de explicar, e a memória do próprio app de ter pedido. Espalhado por um composable, isso vira um
emaranhado de `if`s que ninguém consegue testar sem um celular. Reunido numa função sem Android
dentro, vira uma tabela:

```kotlin
// app/src/main/java/com/example/planner/ui/ReminderPermission.kt
package com.example.planner.ui

/** What the reminders card offers, given what Android says about the permission. */
enum class Offer { NotNeeded, Granted, Ask, Explain, OpenSettings }

fun offerFor(sdk: Int, granted: Boolean, showRationale: Boolean, askedBefore: Boolean): Offer = when {
    sdk < 33 -> Offer.NotNeeded
    granted -> Offer.Granted
    showRationale -> Offer.Explain
    askedBefore -> Offer.OpenSettings
    else -> Offer.Ask
}
```

A ordem dos ramos é o raciocínio, de cima para baixo:

1. **Abaixo do Android 13 não há o que pedir.** Os lembretes simplesmente funcionam; a seção 05 da
   aula 19 mostrou a mesma regra dentro do `canNotify`.
2. **Concedida é concedida**, seja qual for a história.
3. **Se o Android aconselha explicar, o estudante recusou exatamente uma vez.** Explique, e peça.
4. **Não concedida, sem conselho, e o app já pediu antes: recusada duas vezes.** A caixa não vai
   aparecer de novo, então a única oferta honesta é a tela de configurações.
5. **Senão o app nunca pediu**, e pode pedir.

O ramo 4 é o que precisa da memória do app. Sem `askedBefore`, "nunca pedida" e "recusada duas
vezes" parecem idênticas para a API do Android: não concedida, sem conselho. Um app que as confundisse
ou abriria as Configurações para um estudante que nunca foi consultado, ou apertaria para sempre um
botão que não faz nada.

## A tabela, impressa

Uma função sem Android dentro é testada com JUnit puro, sem Robolectric e sem emulador:

```kotlin
// app/src/test/java/com/example/planner/ui/OfferTest.kt
package com.example.planner.ui

import org.junit.Test

class OfferTest {
    @Test fun everyCombination() {
        println("sdk  granted  rationale  askedBefore  ->  offer")
        for (sdk in listOf(32, 35)) for (granted in listOf(false, true))
            for (rationale in listOf(false, true)) for (asked in listOf(false, true)) {
                if (granted && (rationale || asked)) continue
                val offer = offerFor(sdk, granted, rationale, asked)
                println("%-4d %-8b %-10b %-12b ->  %s".format(sdk, granted, rationale, asked, offer))
            }
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*OfferTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'
    sdk  granted  rationale  askedBefore  ->  offer
    32   false    false      false        ->  NotNeeded
    32   false    false      true         ->  NotNeeded
    32   false    true       false        ->  NotNeeded
    32   false    true       true         ->  NotNeeded
    32   true     false      false        ->  NotNeeded
    35   false    false      false        ->  Ask
    35   false    false      true         ->  OpenSettings
    35   false    true       false        ->  Explain
    35   false    true       true         ->  Explain
    35   true     false      false        ->  Granted
OfferTest > everyCombination PASSED
BUILD SUCCESSFUL in 16s
```

Toda combinação no Android 12 não oferece nada a pedir, porque não há nada. No Android 15 os quatro
resultados aparecem onde a lista acima os coloca. O teste pula as combinações em que a permissão está
concedida junto com uma história, porque todas dão `Granted` e só acrescentam linhas.

**Uma tabela também é uma especificação de que alguém pode discordar.** Se uma designer decide que
um estudante que recusou duas vezes deve ver o cartão só uma vez por semana, isso é mais uma entrada
e mais uma linha, discutidas num teste em vez de descobertas num relato de bug.
