---
title: Ensinando o Espresso a esperar a carga
version: 1
---

**A classe de teste da seção 03 tem uma corrida dentro, e numa máquina rápida ela vai passar muitas
vezes mesmo assim.** Quando a regra abre a `MainActivity`, o `onCreate` dela inicia uma thread que
pede os espetáculos ao boxoffice, e retorna. A thread principal fica ociosa, então o Espresso segue
direto para `onData(showWithId("sh-103"))`. Se a resposta do boxoffice já chegou e a lista está
preenchida, o teste passa. Se não chegou, a lista ainda não tem dados, e o teste falha por não achar
espetáculo nenhum para tocar.

Num emulador falando com o boxoffice no mesmo computador, a resposta tende a ganhar. Numa máquina
mais lenta, num runner de CI ocupado ou num celular no Wi-Fi, às vezes ela perde. O teste então falha
de vez em quando, sem nada no relatório que aponte a causa:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 332\" role=\"img\" aria-label=\"Quatro faixas ao longo do tempo. Na thread principal, o onCreate aumenta o busy e inicia a carga, e bem depois o busy diminui quando a lista é desenhada. Na thread da carga, nesse intervalo, a requisição GET /v1/shows espera o boxoffice. Um teste sem idling resource chama o onData enquanto a requisição ainda está fora e não encontra dados. Um teste com o idling resource espera enquanto o busy for maior que zero e chama o onData depois que a lista é desenhada.\"><defs><marker id=\"f16race-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"150\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">thread principal</text><line x1=\"160\" y1=\"70\" x2=\"690\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><text x=\"150\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">thread da carga</text><line x1=\"160\" y1=\"130\" x2=\"690\" y2=\"130\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><text x=\"150\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">teste, sem idling</text><line x1=\"160\" y1=\"190\" x2=\"690\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><text x=\"150\" y=\"250\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">teste, com idling</text><line x1=\"160\" y1=\"250\" x2=\"690\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><text x=\"425\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tempo</text><line x1=\"380\" y1=\"30\" x2=\"410\" y2=\"30\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"440\" y1=\"30\" x2=\"470\" y2=\"30\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#f16race-ah)\"></line><rect x=\"165\" y=\"52\" width=\"120\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"225\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">busy++</text><text x=\"225\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">inicia a carga</text><rect x=\"295\" y=\"112\" width=\"200\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"395\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GET /v1/shows</text><text x=\"395\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">esperando o boxoffice</text><rect x=\"505\" y=\"52\" width=\"150\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"580\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">busy--</text><text x=\"580\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">a lista é desenhada</text><line x1=\"285\" y1=\"76\" x2=\"300\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f16race-ah)\"></line><line x1=\"495\" y1=\"130\" x2=\"510\" y2=\"88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f16race-ah)\"></line><rect x=\"295\" y=\"172\" width=\"160\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"375\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">onData</text><text x=\"375\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">ainda sem dados: falha</text><rect x=\"295\" y=\"236\" width=\"360\" height=\"28\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"475\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">o Espresso espera enquanto busy é maior que zero</text><rect x=\"590\" y=\"272\" width=\"95\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"637.5\" y=\"287\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">onData</text><line x1=\"637\" y1=\"264\" x2=\"637\" y2=\"270\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f16race-ah)\"></line><text x=\"425\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a thread principal fica ociosa enquanto a carga está fora, então o Espresso sozinho não espera</text></svg>", "caption": "Entre o busy++ e o busy-- a thread principal não tem nada a fazer, então o Espresso vê um app ocioso; o idling resource o faz esperar pela carga."}
```

## Onde o app conta as cargas

A lição 14 escreveu o Tickets pensando neste teste. O `Shows.busy` conta as cargas em andamento. A
tela de lista o aumenta antes de iniciar uma carga e o diminui depois que o resultado está na tela:

```
ana@laptop:~/boxoffice$ grep -n busy tickets/app/src/main/java/example/tickets/*.kt
tickets/app/src/main/java/example/tickets/MainActivity.kt:39:        Shows.busy++
tickets/app/src/main/java/example/tickets/MainActivity.kt:44:                Shows.busy--
tickets/app/src/main/java/example/tickets/Shows.kt:39:    var busy = 0
```

A linha 39 de `MainActivity.kt` o aumenta na thread principal, antes de a thread começar. A linha 44
o diminui também na thread principal, dentro do `runOnUiThread`, depois que o `display` preencheu a
lista. Então **enquanto o `busy` estiver acima de zero, a tela não está pronta**, e quando ele volta a
zero, está.

## Um idling resource

O Espresso fica sabendo de um trabalho que não vê por um **idling resource**. É um objeto com um
nome que responde a uma pergunta, *você está ocioso agora?*, e chama o Espresso de volta quando a
resposta vira sim. O Espresso pergunta a todo recurso registrado antes de cada passo, e
espera enquanto algum deles disser não. Salve como
`tickets/app/src/androidTest/java/example/tickets/ShowsIdlingResource.kt`:

```kotlin
// tickets/app/src/androidTest/java/example/tickets/ShowsIdlingResource.kt
package example.tickets

import android.os.Handler
import android.os.Looper
import androidx.test.espresso.IdlingResource

/** Tells Espresso that Tickets is busy while a load of the shows is running. */
class ShowsIdlingResource : IdlingResource {
    private val mainThread = Handler(Looper.getMainLooper())
    private var callback: IdlingResource.ResourceCallback? = null

    override fun getName() = "Shows.busy"

    override fun isIdleNow(): Boolean {
        val idle = Shows.busy == 0
        if (idle) {
            callback?.onTransitionToIdle()
        } else {
            mainThread.postDelayed({ isIdleNow() }, 100)
        }
        return idle
    }

    override fun registerIdleTransitionCallback(callback: IdlingResource.ResourceCallback) {
        this.callback = callback
    }
}
```

O `isIdleNow` responde a partir do `Shows.busy`. Nada no app avisa o recurso quando o `busy` cai.
Então, enquanto está ocupado, o recurso pergunta a si mesmo de novo um décimo de segundo depois, na
thread principal. Ele chama o Espresso de volta na primeira vez em que a resposta é zero. O nome é o
que o Espresso imprime se algum dia desistir de esperar.

A classe de teste registra o recurso antes de cada teste e o remove depois. Substitua o arquivo;
salve como `tickets/app/src/androidTest/java/example/tickets/ListTest.kt`:

```kotlin
// tickets/app/src/androidTest/java/example/tickets/ListTest.kt
package example.tickets

import androidx.test.espresso.Espresso.onData
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.IdlingRegistry
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
import org.junit.After
import org.junit.Before
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

    private val loads = ShowsIdlingResource()

    @Before
    fun waitForLoads() {
        IdlingRegistry.getInstance().register(loads)
    }

    @After
    fun stopWaitingForLoads() {
        IdlingRegistry.getInstance().unregister(loads)
    }

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

O `IdlingRegistry` é a lista de recursos do Espresso. **Remover o registro importa tanto quanto
registrar.** Um recurso esquecido continua respondendo por um teste que já terminou, por toda classe
de teste que rodar depois.

## Por que não `Thread.sleep`

Um `Thread.sleep(2000)` antes do primeiro `onData` corrige a corrida no dia em que é escrito. É o
mesmo erro da pausa fixa da lição 15. Ele deixa toda execução dois segundos mais lenta, tenha a carga
levado cinquenta milissegundos ou nada. Ainda falha no dia em que uma carga leva dois segundos e
meio. E esconde de quem lê *pelo que* o teste espera. O idling resource espera exatamente o tempo que
a carga leva. Ele falha com um nome quando a carga nunca termina, e diz no código o que o app está fazendo.

**Se os desenvolvedores do app podem mudar o app, há um jeito mais arrumado.** O Espresso publica uma
pequena biblioteca, `espresso-idling-resource`, com um `CountingIdlingResource`. O próprio app o
aumenta e diminui em volta do seu trabalho, e ele chama o Espresso de volta no momento em que chega a
zero. O Tickets usa só as classes do próprio Android, então este curso mantém o contador no app e o
recurso nos testes. Numa equipe, pedir aos desenvolvedores o recurso contador é um pedido justo. É o
mesmo argumento da lição 14 sobre os ids: o app ajuda os testes dele, de propósito.
