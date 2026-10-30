---
title: popUpTo e launchSingleTop, para as pilhas que crescem errado
version: 1
---

**`navigate` sempre empilha, e duas situações tornam isso errado.** Um estudante toca num curso duas
vezes, rápido, antes de a tela do primeiro toque aparecer: duas telas de curso idênticas são
empilhadas, e é preciso apertar voltar duas vezes para sair. E um fluxo que termina num lugar por onde
já passou, como "salvar e voltar para a lista", empilha a lista de novo por cima de tudo o que passou
no caminho.

Os dois casos aparecem sem tocar na tela. Este teste comanda o controlador diretamente, na thread
principal, onde a navegação tem de acontecer, e imprime a pilha a cada vez:

```kotlin
// app/src/test/java/com/example/planner/BackStackTest.kt
package com.example.planner

import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.navigation.compose.ComposeNavigator
import androidx.navigation.testing.TestNavHostController
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class BackStackTest {
    @get:Rule val rule = createComposeRule()
    private lateinit var nav: TestNavHostController

    @Before fun start() {
        rule.setContent {
            nav = TestNavHostController(LocalContext.current).apply {
                navigatorProvider.addNavigator(ComposeNavigator())
            }
            PlannerNavHost(nav)
        }
    }

    private fun stack(label: String) = rule.runOnIdle {
        val routes = nav.currentBackStack.value.mapNotNull { it.destination.route }
        println("%-28s %s".format(label, routes.joinToString("  >  ") { it.substringAfterLast('.') }))
    }

    @Test fun doubleTap() {
        rule.runOnUiThread {
            nav.navigate(CourseDetail("kotlin"))
            nav.navigate(CourseDetail("kotlin"))
        }
        stack("navigate twice")
    }

    @Test fun doubleTapSingleTop() {
        rule.runOnUiThread {
            nav.navigate(CourseDetail("kotlin")) { launchSingleTop = true }
            nav.navigate(CourseDetail("kotlin")) { launchSingleTop = true }
        }
        stack("twice, launchSingleTop")
    }

    @Test fun backToTheListPlain() {
        rule.runOnUiThread {
            nav.navigate(CourseDetail("sql"))
            nav.navigate(AddSession("sql"))
            nav.navigate(Courses)
        }
        stack("navigate(Courses)")
    }

    @Test fun backToTheListPopping() {
        rule.runOnUiThread {
            nav.navigate(CourseDetail("sql"))
            nav.navigate(AddSession("sql"))
            nav.navigate(Courses) { popUpTo<Courses> { inclusive = true } }
        }
        stack("with popUpTo inclusive")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*.BackStackTest' 2>&1 | grep -E '^BUILD|FAILED'
BUILD SUCCESSFUL in 32s
ana@vm:~/planner$ grep -h 'navigate twice' app/build/test-results/testDebugUnitTest/TEST-com.example.planner.BackStackTest.xml | sed 's/.*CDATA\[//'; grep -h 'launchSingleTop' app/build/test-results/testDebugUnitTest/TEST-com.example.planner.BackStackTest.xml | sed 's/.*CDATA\[//'
navigate twice               Courses  >  CourseDetail/{courseId}  >  CourseDetail/{courseId}
twice, launchSingleTop       Courses  >  CourseDetail/{courseId}
```

A primeira linha é o toque duplo: duas entradas `CourseDetail` para o mesmo curso. **`launchSingleTop
= true` diz: se o destino já está no topo, não empilhe outro**, e a segunda linha tem um só. É o
padrão certo para tudo o que um usuário pode tocar duas vezes, que é quase tudo; o `onOpen` do planner
poderia passá-lo em todo `navigate` que faz.

```
ana@vm:~/planner$ grep -h 'navigate(Courses)' app/build/test-results/testDebugUnitTest/TEST-com.example.planner.BackStackTest.xml | sed 's/.*CDATA\[//'; grep -h 'popUpTo inclusive' app/build/test-results/testDebugUnitTest/TEST-com.example.planner.BackStackTest.xml | sed 's/.*CDATA\[//'
navigate(Courses)            Courses  >  CourseDetail/{courseId}  >  AddSession/{courseId}  >  Courses
with popUpTo inclusive       Courses
```

A primeira linha é "salvar e ir para a lista" escrito como um `navigate(Courses)` simples: quatro
entradas, duas delas `Courses`, e o formulário ainda no meio. Voltar da lista abriria o formulário
terminado. **`popUpTo<Courses> { inclusive = true }` primeiro desempilha tudo até `Courses`, e esse
`Courses` também**, depois empilha o novo, então a pilha fica com um único `Courses`. Sem `inclusive`,
o `Courses` antigo ficaria e o novo cairia em cima dele, duas listas de novo.

A regra por baixo dos dois: **decida o que o voltar deve fazer a partir da tela para onde você vai, e
dê à pilha a forma que faz isso.** O `popBackStack()` da seção 02 foi o caso mais simples, e o
`popUpTo` é o geral.
