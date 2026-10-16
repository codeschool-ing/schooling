---
title: Testando a faixa de offline
version: 1
---

**O Tickets tem dois jeitos de falhar e um de se virar, e cada um é uma tela que um teste deve
conferir.** A lição 14 os escreveu. Quando o boxoffice não pode ser alcançado e o app tem uma cópia
salva da lista, ele mostra essa cópia com a faixa *Offline: showing the list from HH:mm*. Quando não
tem cópia, mostra a linha de erro. Os dois dependem de o boxoffice ter sumido, o que uma pessoa com o
celular na mão não consegue arranjar quando quer. Também dependem de uma cópia ter sido salva, o que
essa pessoa não consegue ver.

Um teste consegue arranjar as duas, por dentro, e é aí que a caixa cinza da seção 02 se paga:

- para o boxoffice sumido, o `Shows.baseUrl` é uma `var`, então o teste o aponta para um endereço onde
  nada responde, antes da carga que deve falhar;
- para não haver cópia salva, o teste limpa o arquivo de `SharedPreferences` do app chamado
  `shows`, onde a cópia mora, antes de começar.

## Qual endereço ninguém responde

"Um endereço onde nada responde" pode querer dizer duas coisas diferentes, e elas custam tempos
diferentes. No computador, com curl e o mesmo limite de cinco segundos que o Tickets põe na conexão:

```
ana@laptop:~/boxoffice$ curl -sS --connect-timeout 5 http://localhost:9/v1/shows; echo "exit $?"
curl: (7) Failed to connect to localhost port 9 after 0 ms: Couldn't connect to server
exit 7
```

```
ana@laptop:~/boxoffice$ curl -sS --connect-timeout 5 http://10.255.255.1:8080/v1/shows; echo "exit $?"
curl: (28) Failed to connect to 10.255.255.1 port 8080 after 5002 ms: Timeout was reached
exit 28
```

**Uma porta em que nada escuta é recusada na hora**: o computador responde imediatamente que não há
ninguém lá, depois de 0 ms. **Um endereço que ninguém responde espera o tempo limite**, 5002 ms aqui,
porque nada nunca diz não. `10.255.255.1` é um endereço privado que nenhuma máquina da rede da
máquina de gravação tem. O app se comportaria do mesmo jeito, já que o `Shows.load` dá 5000 ms à
conexão. Então o teste usa o primeiro tipo. De dentro do emulador, `10.0.2.2` é o seu computador, como a
lição 14 mostrou. Na maioria dos computadores nada escuta na porta 9, o que faz de
`http://10.0.2.2:9` um boxoffice que está fora do ar e diz isso na hora. Se o seu computador roda
algo na porta 9, escolha qualquer outra porta sem nada atrás.

## O teste

Salve como `tickets/app/src/androidTest/java/example/tickets/OfflineTest.kt`:

```kotlin
// tickets/app/src/androidTest/java/example/tickets/OfflineTest.kt
package example.tickets

import android.content.Context
import androidx.test.core.app.ActivityScenario
import androidx.test.core.app.ApplicationProvider
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.IdlingRegistry
import androidx.test.espresso.action.ViewActions.click
import androidx.test.espresso.assertion.ViewAssertions.matches
import androidx.test.espresso.matcher.ViewMatchers.isDisplayed
import androidx.test.espresso.matcher.ViewMatchers.withId
import androidx.test.espresso.matcher.ViewMatchers.withText
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.hamcrest.CoreMatchers.not
import org.hamcrest.CoreMatchers.startsWith
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/** Port 9 of the computer: nothing listens there, so a connection is refused at once. */
private const val NOBODY = "http://10.0.2.2:9"

@RunWith(AndroidJUnit4::class)
class OfflineTest {
    private val loads = ShowsIdlingResource()
    private val boxoffice = Shows.baseUrl

    @Before
    fun startWithNoSavedCopy() {
        IdlingRegistry.getInstance().register(loads)
        ApplicationProvider.getApplicationContext<Context>()
            .getSharedPreferences("shows", Context.MODE_PRIVATE)
            .edit().clear().commit()
    }

    @After
    fun putBoxofficeBack() {
        Shows.baseUrl = boxoffice
        IdlingRegistry.getInstance().unregister(loads)
    }

    @Test
    fun noServerAndNoCopyShowsTheError() {
        Shows.baseUrl = NOBODY
        ActivityScenario.launch(MainActivity::class.java).use {
            onView(withId(R.id.error)).check(matches(isDisplayed()))
            onView(withId(R.id.banner)).check(matches(not(isDisplayed())))
        }
    }

    @Test
    fun noServerWithACopyShowsTheBanner() {
        ActivityScenario.launch(MainActivity::class.java).use {
            onView(withId(R.id.shows)).check(matches(isDisplayed()))
            Shows.baseUrl = NOBODY
            onView(withId(R.id.refresh)).perform(click())
            onView(withId(R.id.banner))
                .check(matches(isDisplayed()))
                .check(matches(withText(startsWith("Offline: showing the list from"))))
            onView(withId(R.id.error)).check(matches(not(isDisplayed())))
        }
    }
}
```

```schooling-example
{
 "language": "kotlin",
 "file": "OfflineTest.kt",
 "parts": [
  {
   "code": "    private val boxoffice = Shows.baseUrl",
   "note": "O endereço de antes de qualquer teste mudá-lo, guardado para o `@After` poder devolvê-lo."
  },
  {
   "code": "        ApplicationProvider.getApplicationContext<Context>()\n            .getSharedPreferences(\"shows\", Context.MODE_PRIVATE)\n            .edit().clear().commit()",
   "note": "Limpa a cópia salva, o mesmo arquivo e o mesmo nome que o `Shows.load` usa. O `commit` grava antes de retornar, enquanto o `apply` gravaria depois, possivelmente depois de a activity já ter lido o arquivo."
  },
  {
   "code": "    @After\n    fun putBoxofficeBack() {\n        Shows.baseUrl = boxoffice",
   "note": "Todos os testes instrumentados rodam num só processo, então o `Shows`, um `object` do Kotlin, vive do primeiro teste ao último. Um teste que o mudasse e o deixasse assim quebraria todo teste depois dele, numa ordem que depende de qual rodou primeiro."
  },
  {
   "code": "        Shows.baseUrl = NOBODY\n        ActivityScenario.launch(MainActivity::class.java).use {",
   "note": "Este teste não pode usar a regra do `ListTest`: a regra abre a activity antes de o corpo do teste rodar, e o endereço precisa mudar antes da primeira carga. O `ActivityScenario.launch` a abre quando o teste manda, e o `use` a fecha no fim."
  },
  {
   "code": "            onView(withId(R.id.error)).check(matches(isDisplayed()))\n            onView(withId(R.id.banner)).check(matches(not(isDisplayed())))",
   "note": "Sem servidor e sem cópia: a linha de erro, e não a faixa. As duas views existem em todo início, então `not(isDisplayed())` é a verificação certa, como a seção 04 disse."
  },
  {
   "code": "            onView(withId(R.id.shows)).check(matches(isDisplayed()))\n            Shows.baseUrl = NOBODY\n            onView(withId(R.id.refresh)).perform(click())",
   "note": "O segundo teste deixa a primeira carga chegar ao boxoffice, o que salva uma cópia. A verificação em `shows` está ali para fazer o Espresso esperar, pelo idling resource, até essa carga acabar; só então o boxoffice some e o botão pergunta de novo."
  },
  {
   "code": "            onView(withId(R.id.banner))\n                .check(matches(isDisplayed()))\n                .check(matches(withText(startsWith(\"Offline: showing the list from\"))))",
   "note": "A faixa, e as palavras dela até a hora. A hora em si é quando a cópia foi salva, que nenhum teste sabe de antemão, então a verificação para antes dela."
  }
 ]
}
```

O segundo teste precisa do boxoffice rodando, como o `ListTest`. O primeiro não precisa de nada, e é
justamente esse o ponto dele.

**O que estes testes não cobrem** é uma rede lenta em vez de ausente, ou uma que cai no meio de uma
resposta. Uma conexão recusada é o caso fácil. A lição 22 põe de propósito uma rede ruim entre o app
e o boxoffice, e essa é a metade mais difícil da mesma pergunta.
