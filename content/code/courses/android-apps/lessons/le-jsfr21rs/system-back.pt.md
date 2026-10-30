---
title: O voltar do sistema, e links de fora do app
version: 1
---

**No Android o gesto de voltar pertence ao sistema, não à sua tela**, e o `NavHost` responde a ele
por você. O curso `mobile-fundamentals`, na aula 10, compara isso com o iOS, onde voltar é um botão
que o app desenha. Aqui basta que a activity tem um `OnBackPressedDispatcher`, que o `NavHost` se
registra nele, e que um gesto de voltar desempilha exatamente como o `popBackStack()`.

Um teste pode apertar voltar do jeito que o sistema aperta, pedindo ao dispatcher da activity. Isso
precisa da própria activity, então este teste usa `createAndroidComposeRule<ComponentActivity>()` em
vez da regra simples, e chama o `PlannerNavHost()` de verdade, sem controlador próprio:

```kotlin
// app/src/test/java/com/example/planner/SystemBackTest.kt
package com.example.planner

import androidx.activity.ComponentActivity
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class SystemBackTest {
    @get:Rule val rule = createAndroidComposeRule<ComponentActivity>()

    private fun back(label: String) {
        rule.runOnUiThread { rule.activity.onBackPressedDispatcher.onBackPressed() }
        rule.waitForIdle()
        println("%-26s finishing: %s".format(label, rule.activity.isFinishing))
    }

    @Test fun theBackButton() {
        rule.setContent { PlannerNavHost() }
        rule.onNodeWithText("Android Apps").performClick()
        rule.onNodeWithText("Add session").performClick()
        back("back from AddSession")
        rule.onNodeWithText("Add session").assertExists()
        back("back from CourseDetail")
        rule.onNodeWithText("Courses").assertExists()
        back("back from Courses")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*.SystemBackTest' 2>&1 | grep -E '^BUILD|FAILED'
BUILD SUCCESSFUL in 25s
ana@vm:~/planner$ grep -h 'finishing' app/build/test-results/testDebugUnitTest/TEST-com.example.planner.SystemBackTest.xml | sed 's/.*CDATA\[//'
back from AddSession       finishing: false
back from CourseDetail     finishing: false
back from Courses          finishing: true
```

**Dois voltar desempilharam; o terceiro encerrou a activity.** Com só `Courses` na pilha, não há o que
o `NavHost` desempilhar, então ele deixa de responder e o dispatcher cai no comportamento padrão, que
fecha a activity: o estudante volta à tela inicial. É o comportamento que os usuários esperam, e veio
da biblioteca, não de código do planner.

**Não executado:** a animação do voltar preditivo. A partir do Android 13 um app pode aderir ao
voltar preditivo, que mostra a tela de baixo enquanto o gesto ainda está acontecendo. É um gesto num
aparelho, e a documentação do Google sobre voltar preditivo o descreve; nada aqui conseguiu
desenhá-lo.

## Deep links

Um **deep link** abre uma tela no meio do app a partir de fora dele: uma notificação de lembrete que
abre um curso, ou um link num e-mail. No Navigation Compose um destino declara os endereços a que
responde com `deepLinks = listOf(navDeepLink<CourseDetail>(basePath = …))`, o manifesto declara que a
activity os atende, e o Navigation monta a pilha que o estudante teria se tivesse tocado até ali. O
curso `mobile-fundamentals`, na aula 11, explica deep links e app links verificados nas duas
plataformas; uma notificação, assunto da aula 19, é a porta de entrada mais comum para um.

**Não executado:** abrir um deep link, o que precisa de um aparelho e de `adb shell am start` com o
link, como mostra a documentação do Google sobre testar deep links.
