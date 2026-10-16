---
title: O Tickets sem rede, e numa rede ruim
version: 1
---

**Há dois jeitos de dar ao app uma rede ruim: tirar a rede do celular, ou pôr o proxy lento entre o
app e o boxoffice.** O primeiro é o que uma pessoa num elevador tem. O segundo é o que uma pessoa num
trem tem, e só o segundo é igual em toda execução. Um plano de testes precisa dos dois.

## O que o Tickets faz, lido do código dele

A lição 14 escreveu todo o comportamento de rede do app no `Shows.load`:

```
ana@laptop:~/boxoffice$ grep -n 'Timeout\|catch\|return Loaded\|Loaded\.\(Fresh\|Offline\)(' tickets/app/src/main/java/example/tickets/Shows.kt
55:            connection.connectTimeout = 5000
56:            connection.readTimeout = 5000
61:            Loaded.Fresh(shows)
62:        } catch (e: Exception) {
63:            val body = saved.getString("body", null) ?: return Loaded.Failed
64:            Loaded.Offline(parse(body), saved.getString("at", "") ?: "")
```

Leia com os dois limites da seção 02 em mente. A linha 55 dá cinco segundos para conectar, e a
linha 56 cinco segundos de silêncio durante a leitura. Dentro deles, a linha 61 devolve uma lista
nova. Além de qualquer um, ou em qualquer outro erro, entra o `catch` da linha 62. A linha 64 devolve
a cópia salva com o horário dela, se houver uma. Se não houver, a linha 63 devolve `Failed`, que a
tela de lista mostra como a linha de erro. Três coisas decorrem disso sem que nenhuma linha as diga, e cada uma é uma pergunta para
um teste:

- Nada aparece enquanto uma carga roda. A lista mantém as linhas antigas, ou nenhuma, até o
  `display` ser chamado. Não há indicador, então uma atualização que espera cinco segundos parece uma
  atualização que não fez nada.
- "Offline" quer dizer "não deu certo". Uma resposta de seis segundos, por uma rede que funciona,
  termina na faixa *Offline: showing the list from…*. Isso é verdade sobre a lista e mentira sobre o
  celular.
- O limite de leitura é para silêncio, não para a resposta inteira. O `readTimeout` do Java
  dispara quando nenhum dado chega por esse tempo. Uma resposta que pinga alguns bytes de cada
  vez pode levar um minuto e nunca dispará-lo.

## Tirando a rede

No emulador, num terminal. Como tudo do lado do aparelho nesta lição, estes não foram rodados para
este curso, por falta de emulador, como a lição 14 explicou:

```sh
adb shell svc wifi disable
adb shell svc data disable
adb shell cmd connectivity airplane-mode enable
adb shell cmd connectivity airplane-mode disable
adb shell svc wifi enable
adb shell svc data enable
```

O `svc` liga e desliga Wi-Fi e dados móveis separadamente, que é como você testa um celular que cai de
um para o outro. O modo avião desliga todos os rádios de uma vez. Depois de cada um, abra o Tickets e
aperte Atualizar, e compare a tela com os três resultados acima. Antes de confiar num teste construído
sobre uma dessas chaves, confira à mão que a requisição falha de verdade no seu emulador. O link dele
com o seu computador não é um rádio de verdade, e este curso não pôde conferir o que cada chave corta.

Pelo Appium, o driver UiAutomator2 tem as mesmas chaves. O `mobile: setConnectivity` recebe `{ wifi:
false, data: false }` ou `{ airplaneMode: true }`, e o `mobile: getConnectivity` as lê de volta.

## Uma rede lenta no emulador

O emulador consegue deixar a própria rede lenta. Ele pode iniciar assim, com `-netspeed` e
`-netdelay`. O texto de ajuda dele, que não precisa de emulador rodando, lista os perfis:

```
ana@laptop:~/boxoffice$ emulator -help-netspeed

  the Android emulator supports network throttling, i.e. slower network
  bandwidth as well as higher connection latencies. this is done either through
  skin configuration, or with '-netspeed <speed>' and '-netdelay <delay>'.

  the format of -netspeed is one of the following (numbers are kbits/s):

    -netspeed gsm          GSM/CD           (up: 1.8 KiB/s, down: 1.8 KiB/s)
    -netspeed hscsd        HSCSD            (up: 1.8 KiB/s, down: 7.0 KiB/s)
    -netspeed gprs         GPRS             (up: 3.5 KiB/s, down: 7.0 KiB/s)
    -netspeed umts         UMTS/3G          (up: 46.9 KiB/s, down: 46.9 KiB/s)
    -netspeed edge         EDGE/EGPRS       (up: 57.8 KiB/s, down: 57.8 KiB/s)
    -netspeed hsdpa        HSDPA            (up: 703.1 KiB/s, down: 1706.5 KiB/s)
    -netspeed lte          LTE              (up: 7080.1 KiB/s, down: 21118.2 KiB/s)
    -netspeed evdo         EVDO             (up: 9155.3 KiB/s, down: 34179.7 KiB/s)
    -netspeed 5g           no limit         (up: 0.0 KiB/s, down: 0.0 KiB/s)
    -netspeed full         no limit         (up: 0.0 KiB/s, down: 0.0 KiB/s)

    -netspeed <num>        select both upload and download speed
    -netspeed <up>:<down>  select individual up and down speed

  The format of -netdelay is one of the following (numbers are msec):

    -netdelay gsm          GSM/CD           (min 150, max 550)
    -netdelay hscsd        HSCSD            (min 80, max 400)
    -netdelay gprs         GPRS             (min 35, max 200)
    -netdelay umts         UMTS/3G          (min 35, max 200)
    -netdelay edge         EDGE/EGPRS       (min 80, max 400)
    -netdelay hsdpa        HSDPA            (min 0, max 0)
    -netdelay lte          LTE              (min 0, max 0)
    -netdelay evdo         EVDO             (min 0, max 0)
    -netdelay 5g           no latency       (min 0, max 0)
    -netdelay none         no latency       (min 0, max 0)
    -netdelay <num>        select exact latency
    -netdelay <min>:<max>   select min and max latencies

  the emulator uses the following defaults:

    Default network speed   is 'full'
    Default network latency is 'none'
```

Então `emulator -avd Pixel_8_API_35 -netspeed edge -netdelay gprs` inicia o aparelho da lição 14 num
link EDGE com o atraso do GPRS. Um emulador já rodando aceita os mesmos perfis pelo console dele:
`adb emu network speed edge` e `adb emu network delay gprs`. O `mobile: networkSpeed` do Appium,
`{ speed: 'edge' }`, faz o mesmo. O cabeçalho desse texto de ajuda diz que os números são kbits/s e a
tabela escreve KiB/s. Leia os nomes dos perfis, que são o que você digita, e meça o efeito em vez de
confiar em qualquer uma das unidades.

**O estrangulamento do emulador é amplo**: ele deixa lento tudo o que o aparelho faz, o sistema
inclusive. O proxy lento deixa lentas as respostas de um servidor, exatamente na medida que você define. Ele também consegue perdê-las, o que as configurações do emulador não conseguem. Para um teste que
precisa terminar do mesmo jeito toda vez, o proxy é o melhor instrumento.

## O proxy num teste de Espresso

O emulador alcança o seu computador em `10.0.2.2`, como a lição 14 mostrou, então alcança o proxy em
`http://10.0.2.2:8070`. O arquivo de segurança de rede da lição 14 já permite HTTP puro para esse
endereço em qualquer porta. O `OfflineTest` da lição 16 apontou o `Shows.baseUrl` para uma porta onde
nada responde. Este teste o aponta para proxies que respondem, tarde demais e bem a tempo. Inicie dois
em dois terminais, ambos na frente do boxoffice:

```sh
DELAY=6000 node slow-proxy.mjs
PORT=8071 DELAY=3000 node slow-proxy.mjs
```

Seis segundos está além do limite de leitura do Tickets e três está dentro.
Salve como `tickets/app/src/androidTest/java/example/tickets/SlowNetworkTest.kt`:

```kotlin
// tickets/app/src/androidTest/java/example/tickets/SlowNetworkTest.kt
package example.tickets

import androidx.test.core.app.ActivityScenario
import androidx.test.espresso.Espresso.onData
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

/** Two slow proxies on the computer, started before the tests:
 *  `DELAY=6000 node slow-proxy.mjs` and `PORT=8071 DELAY=3000 node slow-proxy.mjs`. */
private const val SLOWER_THAN_THE_TIMEOUT = "http://10.0.2.2:8070"
private const val SLOW_BUT_IN_TIME = "http://10.0.2.2:8071"

@RunWith(AndroidJUnit4::class)
class SlowNetworkTest {
    private val loads = ShowsIdlingResource()
    private val boxoffice = Shows.baseUrl

    @Before
    fun waitForLoads() {
        IdlingRegistry.getInstance().register(loads)
    }

    @After
    fun putBoxofficeBack() {
        Shows.baseUrl = boxoffice
        IdlingRegistry.getInstance().unregister(loads)
    }

    @Test
    fun anAnswerSlowerThanTheTimeoutShowsTheSavedCopy() {
        ActivityScenario.launch(MainActivity::class.java).use {
            onView(withId(R.id.shows)).check(matches(isDisplayed()))
            Shows.baseUrl = SLOWER_THAN_THE_TIMEOUT
            onView(withId(R.id.refresh)).perform(click())
            onView(withId(R.id.banner))
                .check(matches(isDisplayed()))
                .check(matches(withText(startsWith("Offline: showing the list from"))))
        }
    }

    @Test
    fun aSlowAnswerInTimeIsShownFresh() {
        ActivityScenario.launch(MainActivity::class.java).use {
            onView(withId(R.id.shows)).check(matches(isDisplayed()))
            Shows.baseUrl = SLOW_BUT_IN_TIME
            onView(withId(R.id.refresh)).perform(click())
            onView(withId(R.id.banner)).check(matches(not(isDisplayed())))
            onData(showWithId("sh-103")).inAdapterView(withId(R.id.shows)).check(matches(isDisplayed()))
        }
    }
}
```

Os dois testes deixam a primeira carga chegar direto ao boxoffice, para uma cópia ser salva. Depois
põem o `baseUrl` atrás de um proxy e apertam Atualizar. O idling resource da lição 16 mantém o
Espresso esperando enquanto o `Shows.busy` é maior que zero, durante todo o atraso, então nenhum dos
testes precisa de uma espera própria. O primeiro espera a faixa, depois de cinco segundos de
silêncio. O segundo espera nenhuma faixa e a lista, depois de três. **Juntos eles prendem o timeout
pelos dois lados.** Se alguém o aumentar para dez segundos, o primeiro falha. Se alguém o baixar para
dois, falha o segundo. Um teste de um lado só deixaria o limite andar para o outro lado sem ninguém
notar.

**Esta classe não foi compilada nem rodada para este curso**, pelos motivos que a lição 16 dá. No seu
computador ela roda com os outros testes instrumentados, `./gradlew connectedDebugAndroidTest`, enquanto
o boxoffice e os dois proxies estão rodando.
