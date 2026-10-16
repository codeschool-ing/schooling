---
title: Onde os testes moram, e do que precisam
version: 1
---

**O projeto que o Android Studio criou na lição 14 já está preparado para o Espresso.** O modelo pôs
duas pastas de teste ao lado de `src/main`, escreveu nos arquivos de build as bibliotecas de que elas
precisam, e deixou um teste de exemplo em cada uma. Você acrescenta arquivos; não muda nenhum
arquivo de build.

| pasta | o que roda lá | roda em |
|---|---|---|
| `app/src/test/` | testes locais, na JVM do seu computador | o seu computador, sem Android |
| `app/src/androidTest/` | testes instrumentados: Espresso | o aparelho, dentro do app |
| `app/src/main/` | o próprio app | o aparelho |

Dentro de `androidTest`, o modelo criou as pastas do pacote, `java/example/tickets/`, e nelas um
arquivo chamado `ExampleInstrumentedTest.kt`, que confere o nome do pacote do app. Ele pode ficar ou
sair; os testes desta lição vão ao lado dele.

## O que o modelo já declara

Abra `tickets/app/build.gradle.kts`. Duas partes dele interessam a esta lição. Em `defaultConfig`, o
executor que o APK de teste entrega à instrumentação do Android:

```kotlin
testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
```

E no fim, entre as dependências, três linhas para testes:

```kotlin
testImplementation(libs.junit)
androidTestImplementation(libs.androidx.junit)
androidTestImplementation(libs.androidx.espresso.core)
```

`testImplementation` é para os testes locais e `androidTestImplementation` para os instrumentados;
nenhum dos dois vai para o app que um usuário instala. Os nomes depois de `libs.` apontam para
`tickets/gradle/libs.versions.toml`, onde o modelo escreveu quais versões; deixe-as como ele
escolheu.

| nome no arquivo de build | a biblioteca | o que ela dá a um teste |
|---|---|---|
| `libs.junit` | JUnit 4 | `@Test`, `@Before`, `@After`, as regras: a moldura que todo teste aqui usa |
| `libs.androidx.junit` | as extensões de JUnit do AndroidX Test | `AndroidJUnit4`, o executor que uma classe de teste nomeia, e `ActivityScenarioRule`, que abre uma activity para cada teste |
| `libs.androidx.espresso.core` | Espresso | `onView`, `onData`, os matchers, ações e asserções, e os idling resources da seção 05 |

A segunda e a terceira trazem o resto do AndroidX Test junto, incluindo `ActivityScenario` e
`ApplicationProvider`, que a seção 06 usa.

## Uma primeira classe de teste

Dois testes: o botão de atualizar está na tela, e tocar no espetáculo `sh-103` o abre com título e
preço. Crie o arquivo em `androidTest/java/example/tickets/`: na visão *Project*, clique com o botão
direito no pacote e escolha *New › Kotlin Class/File*.
Salve como `tickets/app/src/androidTest/java/example/tickets/ListTest.kt`:

```kotlin
// tickets/app/src/androidTest/java/example/tickets/ListTest.kt
package example.tickets

import androidx.test.espresso.Espresso.onData
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.action.ViewActions.click
import androidx.test.espresso.assertion.ViewAssertions.matches
import androidx.test.espresso.matcher.BoundedMatcher
import androidx.test.espresso.matcher.ViewMatchers.isDisplayed
import androidx.test.espresso.matcher.ViewMatchers.withId
import androidx.test.espresso.matcher.ViewMatchers.withText
import androidx.test.ext.junit.rules.ActivityScenarioRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.hamcrest.Description
import org.hamcrest.Matcher
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** A row of the list, chosen by the show it holds rather than by its position. */
fun showWithId(id: String): Matcher<Any> =
    object : BoundedMatcher<Any, Show>(Show::class.java) {
        override fun describeTo(description: Description) {
            description.appendText("a show with id $id")
        }

        override fun matchesSafely(item: Show) = item.id == id
    }

@RunWith(AndroidJUnit4::class)
class ListTest {
    @get:Rule
    val activity = ActivityScenarioRule(MainActivity::class.java)

    @Test
    fun theRefreshButtonIsShown() {
        onView(withId(R.id.refresh)).check(matches(isDisplayed()))
    }

    @Test
    fun aShowOpensWithItsTitleAndPrice() {
        onData(showWithId("sh-103")).inAdapterView(withId(R.id.shows)).perform(click())
        onView(withId(R.id.title)).check(matches(withText("O Pagador de Promessas")))
        onView(withId(R.id.price)).check(matches(withText("R$ 65,00")))
    }
}
```

Os valores que o segundo teste espera são os do boxoffice, como a lição 1 os leu. O preço é de 6500
centavos, que o `price()` do app escreve como `R$ 65,00`:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows | jq -r '.shows[] | "\(.id)  \(.price_cents)  \(.title)"'
sh-101  8000  Auto da Compadecida
sh-102  8000  Auto da Compadecida
sh-103  6500  O Pagador de Promessas
```

A seção 04 lê a classe parte por parte. Um aviso antes disso: **esta versão é instável**, e a seção
05 diz por quê e a corrige.

**Nenhum código de teste desta lição foi compilado ou executado para este curso.** Ele precisa do
AndroidX Test, que vem do repositório do próprio Google, e a máquina de gravação não alcança nem esse
repositório nem um emulador. Ele foi escrito contra as partes do Espresso que não mudam há anos, e a
seção 07 diz como rodá-lo.
