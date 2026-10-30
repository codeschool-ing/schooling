---
title: O estudante diz não duas vezes
version: 1
---

**O caminho inteiro, recusa, explicação, segunda recusa, configurações, pode ser percorrido num
teste**, se o teste fizer o papel do sistema. O papel do sistema são duas coisas: mostrar a caixa e
responder, e mudar o que o `shouldShowRequestPermissionRationale` diz. Um teste de Compose pode
substituir a primeira pelo próprio `ActivityResultRegistry`, o objeto que lança resultados de
activity, e o gerenciador de pacotes do Robolectric deixa ele definir a segunda.

```kotlin
// app/src/test/java/com/example/planner/ui/AskTwiceTest.kt
package com.example.planner.ui

import android.Manifest
import androidx.activity.ComponentActivity
import androidx.activity.compose.LocalActivityResultRegistryOwner
import androidx.activity.result.ActivityResultRegistry
import androidx.activity.result.ActivityResultRegistryOwner
import androidx.activity.result.contract.ActivityResultContract
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.printToString
import androidx.core.app.ActivityOptionsCompat
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf

@RunWith(RobolectricTestRunner::class)
class AskTwiceTest {
    @get:Rule val rule = createAndroidComposeRule<ComponentActivity>()
    private val permission = Manifest.permission.POST_NOTIFICATIONS
    private var dialogs = 0

    // Stands in for the system: every request is shown and denied, and Android's
    // advice to explain is true after the first refusal and false after the second.
    private val owner = object : ActivityResultRegistryOwner {
        override val activityResultRegistry = object : ActivityResultRegistry() {
            override fun <I, O> onLaunch(
                requestCode: Int,
                contract: ActivityResultContract<I, O>,
                input: I,
                options: ActivityOptionsCompat?,
            ) {
                dialogs++
                shadowOf(rule.activity.packageManager)
                    .setShouldShowRequestPermissionRationale(permission, dialogs == 1)
                dispatchResult(requestCode, false)
            }
        }
    }

    private fun card() = rule.onRoot().printToString().lines()
        .filter { "Text = " in it }
        .joinToString(" / ") { it.substringAfter("Text = '[").substringBefore("]'") }

    @Test fun deniedTwice() {
        rule.setContent {
            CompositionLocalProvider(LocalActivityResultRegistryOwner provides owner) {
                RemindersSetting()
            }
        }
        println("start            dialogs=$dialogs  ${card()}")
        rule.onNodeWithText("Turn on reminders").performClick()
        println("denied once      dialogs=$dialogs  ${card()}")
        rule.onNodeWithText("Allow notifications").performClick()
        println("denied twice     dialogs=$dialogs  ${card()}")
        rule.onNodeWithText("Open settings").performClick()
        val opened = shadowOf(rule.activity.application).nextStartedActivity
        println("settings opened  ${opened.action}")
    }
}
```

O registro falso é a única parte inventada, e é pequeno: todo pedido conta como uma caixa mostrada,
o conselho de explicar é `true` depois da primeira recusa e `false` depois da segunda, que é a regra
do Android 11 da seção 02, e toda resposta é uma recusa. `LocalActivityResultRegistryOwner` é como uma
composição encontra o seu registro, então fornecer o falso ali basta para o
`rememberLauncherForActivityResult` de verdade usá-lo. Todo o resto é o código das seções 03 a 05.

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*AskTwiceTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'
    start            dialogs=0  Get a reminder on days with a session planned. / Turn on reminders
    denied once      dialogs=1  Reminders need permission to show a notification. The planner sends at most one a day, and never anything else. / Allow notifications
    denied twice     dialogs=2  Notifications are off for the planner. You can turn them on in its settings. / Open settings
    settings opened  android.settings.APP_NOTIFICATION_SETTINGS
AskTwiceTest > deniedTwice PASSED
BUILD SUCCESSFUL in 33s
```

Leia como o estudante viveria:

1. **Começo.** Nenhuma caixa ainda, e o cartão oferece lembretes.
2. **Negada uma vez.** Uma caixa, e o cartão agora explica, com o botão que pede de novo.
3. **Negada duas vezes.** Duas caixas, e o cartão não tem mais botão que peça. Ele aponta para as
   Configurações.
4. **Configurações.** O toque abre as configurações de notificação do sistema para o app.

**O que o teste não consegue mostrar é um terceiro toque em "Allow notifications", se o cartão o
tivesse mantido.** Num celular, a documentação do Google diz que o launcher responderia `false` na
hora, sem caixa, e o estudante veria um botão que não faz nada. É essa a falha que o `askedBefore` da
seção 04 existe para evitar, e ela **não foi executada** aqui, porque o registro falso mostra uma
caixa para todo pedido, por construção.

## O que a página de configurações pode mudar

Nas configurações de notificação do app, o estudante pode permitir notificações, o que no Android 13
e posteriores também concede `POST_NOTIFICATIONS`. Quando ele volta, o planner precisa perceber: a
nota da seção 03 sobre recalcular quando a tela volta ao primeiro plano é exatamente sobre isso. O
contrário também acontece. Um estudante pode revogar uma permissão nas Configurações a qualquer
momento, e o Android encerra o processo do app quando isso acontece, então um app que conferiu uma vez
na abertura e guardou a resposta está errado depois disso, e é por isso que o `canNotify` da aula 19
confere a cada chamada.
