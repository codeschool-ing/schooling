---
title: A pilha de navegação, impressa depois de cada toque
version: 1
---

**A pilha de navegação é uma lista de entradas, e a tela que você vê é a última.** `navigate`
acrescenta uma entrada no fim; `popBackStack` remove a última; o botão voltar também desempilha, o
que a seção 06 mostra. Cada entrada lembra a rota, os argumentos e o estado da tela que mostra, e é
por isso que voltar encontra a tela do curso como você a deixou.

`TestNavHostController`, de `navigation-testing`, é um controlador que um teste pode inspecionar. O
teste abaixo o entrega ao `PlannerNavHost`, toca pelo planner como um estudante tocaria e imprime a
pilha depois de cada toque:

```kotlin
// app/src/test/java/com/example/planner/NavigationTest.kt
package com.example.planner

import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.navigation.compose.ComposeNavigator
import androidx.navigation.testing.TestNavHostController
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class NavigationTest {
    @get:Rule val rule = createComposeRule()
    private lateinit var nav: TestNavHostController

    private fun stack(after: String) = rule.runOnIdle {
        val routes = nav.currentBackStack.value.mapNotNull { it.destination.route }
        println("%-22s %s".format(after, routes.joinToString("  >  ") { it.substringAfterLast('.') }))
    }

    @Test fun toAddSessionAndBack() {
        rule.setContent {
            nav = TestNavHostController(LocalContext.current).apply {
                navigatorProvider.addNavigator(ComposeNavigator())
            }
            PlannerNavHost(nav)
        }
        stack("start")
        rule.onNodeWithText("Kotlin").performClick()
        stack("tap Kotlin")
        rule.runOnIdle { println("courseId argument: " + nav.currentBackStackEntry?.arguments?.getString("courseId")) }
        rule.onNodeWithText("Add session").performClick()
        stack("tap Add session")
        rule.onNodeWithText("Save").performClick()
        stack("tap Save")
        rule.onNodeWithText("Back").performClick()
        stack("tap Back")
    }
}
```

`addNavigator(ComposeNavigator())` é a linha que as pessoas esquecem: um controlador de teste começa
sem o navegador que sabe o que é um destino `composable`, e o grafo não pode ser montado sem ele.
`substringAfterLast('.')` só encurta as rotas impressas, que o Navigation nomeia pela classe
completa, `com.example.planner.CourseDetail`.

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*.NavigationTest' 2>&1 | grep -E '^BUILD|FAILED'
BUILD SUCCESSFUL in 53s
ana@vm:~/planner$ grep -h -e 'start ' -e '^tap ' app/build/test-results/testDebugUnitTest/TEST-com.example.planner.NavigationTest.xml | sed 's/.*CDATA\[//'
start                  Courses
tap Kotlin             Courses  >  CourseDetail/{courseId}
tap Add session        Courses  >  CourseDetail/{courseId}  >  AddSession/{courseId}
tap Save               Courses  >  CourseDetail/{courseId}
tap Back               Courses
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l09-stack\" aria-label=\"A pilha de navegação depois de cada passo do teste. No início ela contém Courses. Tocar em Kotlin empilha CourseDetail. Tocar em Add session empilha AddSession. Tocar em Save o desempilha, deixando Courses e CourseDetail. Tocar em Back desempilha CourseDetail, deixando Courses.\"><text x=\"78\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">início</text><rect x=\"14\" y=\"220\" width=\"128\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"78\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Courses</text><line x1=\"14\" y1=\"266\" x2=\"142\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"220\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">toca Kotlin</text><rect x=\"156\" y=\"220\" width=\"128\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"220\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">Courses</text><rect x=\"156\" y=\"168\" width=\"128\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"220\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">CourseDetail</text><line x1=\"156\" y1=\"266\" x2=\"284\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"362\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">toca Add session</text><rect x=\"298\" y=\"220\" width=\"128\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"362\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">Courses</text><rect x=\"298\" y=\"168\" width=\"128\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"362\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">CourseDetail</text><rect x=\"298\" y=\"116\" width=\"128\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"362\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">AddSession</text><line x1=\"298\" y1=\"266\" x2=\"426\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"504\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">toca Save</text><rect x=\"440\" y=\"220\" width=\"128\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"504\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">Courses</text><rect x=\"440\" y=\"168\" width=\"128\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"504\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">CourseDetail</text><line x1=\"440\" y1=\"266\" x2=\"568\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"646\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">toca Back</text><rect x=\"582\" y=\"220\" width=\"128\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"646\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Courses</text><line x1=\"582\" y1=\"266\" x2=\"710\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">a entrada em destaque é a que está na tela</text></svg>", "caption": "As cinco linhas que o teste imprimiu, como pilhas: navigate empilha, popBackStack desempilha, e só a entrada do topo é desenhada."}
```

**Cinco toques, e a pilha nunca teve mais de três entradas.** Salvar a sessão desempilhou o
`AddSession`, que é o certo para um formulário: quando termina, o usuário volta para onde o começou, e
apertar voltar na tela do curso não abre de novo o formulário terminado. O `Back` desempilhou o
`CourseDetail` e deixou a lista, sozinha.

O teste também prova algo que nenhuma captura de tela provaria: **os argumentos foram para onde
deviam**. A tela do curso foi desenhada para `kotlin`, e o formulário depois dela para o mesmo curso,
porque cada `navigate` repassou o `route.courseId`.
