---
title: Os estados, como testes
version: 1
---

**A seção 04 previu o que o Tickets guarda, e esta seção escreve os testes que conferem a
previsão**, por dentro com o Espresso e por fora com o Appium. Eles dividem o trabalho do jeito que
as ferramentas permitem. O Espresso consegue recriar uma activity e levá-la pelo ciclo de vida,
dentro de um processo. O Appium consegue matar o processo e responder ao diálogo de permissão. Só o
Appium consegue testar a linha da tabela que dizia *perdida*.

## Por dentro: `ActivityScenario`

A lição 16 abriu activities com `ActivityScenario.launch`. O scenario que ele devolve também conduz
a vida da activity:

- `recreate()` destrói a activity e cria uma nova com o estado que a antiga salvou. É exatamente
  o que uma rotação faz, sem girar nada;
- `moveToState(Lifecycle.State.CREATED)` a para, como o Home faz, e
  `moveToState(Lifecycle.State.RESUMED)` a traz de volta.

Três testes: a lista sobrevive a uma rotação, a lista continua lá depois do segundo plano, e a chave
de lembrete continua ligada depois de uma rotação. O terceiro precisa da permissão concedida antes.
Senão apareceria um diálogo que o Espresso não consegue responder, como a seção 03 mostrou. O `UiAutomation`
do próprio Android, que todo teste instrumentado alcança sem biblioteca nova, a concede.
Salve como `tickets/app/src/androidTest/java/example/tickets/StatesTest.kt`:

```kotlin
// tickets/app/src/androidTest/java/example/tickets/StatesTest.kt
package example.tickets

import android.Manifest
import android.content.Intent
import android.os.Build
import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ActivityScenario
import androidx.test.core.app.ApplicationProvider
import androidx.test.espresso.Espresso.onData
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.IdlingRegistry
import androidx.test.espresso.action.ViewActions.click
import androidx.test.espresso.assertion.ViewAssertions.matches
import androidx.test.espresso.matcher.ViewMatchers.isChecked
import androidx.test.espresso.matcher.ViewMatchers.isDisplayed
import androidx.test.espresso.matcher.ViewMatchers.withId
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class StatesTest {
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
    fun theListComesBackAfterARotation() {
        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            scenario.recreate()
            onData(showWithId("sh-103")).inAdapterView(withId(R.id.shows)).check(matches(isDisplayed()))
        }
    }

    @Test
    fun theListIsStillThereAfterTheBackground() {
        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            scenario.moveToState(Lifecycle.State.CREATED)
            scenario.moveToState(Lifecycle.State.RESUMED)
            onData(showWithId("sh-103")).inAdapterView(withId(R.id.shows)).check(matches(isDisplayed()))
        }
    }

    @Test
    fun theReminderStaysOnAfterARotation() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        if (Build.VERSION.SDK_INT >= 33) {
            instrumentation.uiAutomation.grantRuntimePermission(
                instrumentation.targetContext.packageName, Manifest.permission.POST_NOTIFICATIONS)
        }
        val show = Intent(ApplicationProvider.getApplicationContext(), ShowActivity::class.java)
            .putExtra("title", "O Pagador de Promessas")
            .putExtra("seats", 4)
        ActivityScenario.launch<ShowActivity>(show).use { scenario ->
            onView(withId(R.id.remind)).perform(click()).check(matches(isChecked()))
            scenario.recreate()
            onView(withId(R.id.remind)).check(matches(isChecked()))
        }
    }
}
```

```schooling-example
{
 "language": "kotlin",
 "file": "StatesTest.kt",
 "parts": [
  {
   "code": "        ActivityScenario.launch(MainActivity::class.java).use { scenario ->\n            scenario.recreate()",
   "note": "Abre a lista, depois a reconstrói como uma rotação faria. O novo `onCreate` inicia uma segunda carga, e o idling resource da lição 16 faz a linha seguinte esperar por ela."
  },
  {
   "code": "            onData(showWithId(\"sh-103\")).inAdapterView(withId(R.id.shows)).check(matches(isDisplayed()))",
   "note": "`onData` com um `check` no lugar de um `perform`: a linha que guarda o `sh-103` está na tela. O `showWithId` é o matcher da lição 16, no `ListTest.kt`, e é visível aqui porque os dois arquivos estão no mesmo pacote."
  },
  {
   "code": "            scenario.moveToState(Lifecycle.State.CREATED)\n            scenario.moveToState(Lifecycle.State.RESUMED)",
   "note": "Parada, como em segundo plano, depois na frente de novo. O `Lifecycle` vem da biblioteca de ciclo de vida do AndroidX, que o AndroidX Test já traz."
  },
  {
   "code": "        if (Build.VERSION.SDK_INT >= 33) {\n            instrumentation.uiAutomation.grantRuntimePermission(\n                instrumentation.targetContext.packageName, Manifest.permission.POST_NOTIFICATIONS)\n        }",
   "note": "Concede a permissão antes do toque, nas versões que a têm, para nenhum diálogo aparecer. É isso que a `GrantPermissionRule` faz por baixo."
  },
  {
   "code": "        val show = Intent(ApplicationProvider.getApplicationContext(), ShowActivity::class.java)\n            .putExtra(\"title\", \"O Pagador de Promessas\")\n            .putExtra(\"seats\", 4)",
   "note": "A tela do espetáculo aberta direto, com os extras que a lista teria posto no intent dela. Os que ficaram de fora, id, horário e preço, saem vazios, e este teste não olha para eles."
  },
  {
   "code": "            onView(withId(R.id.remind)).perform(click()).check(matches(isChecked()))\n            scenario.recreate()\n            onView(withId(R.id.remind)).check(matches(isChecked()))",
   "note": "Ligada, reconstruída, ainda ligada: o `Switch` salvou o próprio estado, como a seção 04 previu."
  }
 ]
}
```

**`recreate()` não é uma morte de processo**, e é fácil acreditar que seja. A activity nova é
construída no mesmo processo, então o `Shows`, o `baseUrl` dele e o contador `busy` estão exatamente
como estavam. Depois de uma morte de processo de verdade eles começam de novo. Um teste
instrumentado não consegue matar o próprio processo e continuar rodando, então a metade do processo
fica com o lado de fora.

## Por fora: o Appium

Dois testes num arquivo. A tela do espetáculo volta depois que o Android mata o app em segundo plano,
e a frase sobre as notificações recusadas continua lá depois de uma rotação. O primeiro precisa do
servidor iniciado com `--allow-insecure uiautomator2:adb_shell`, como a seção 04 mostrou.
Salve como `appium/states.test.mjs`:

```js
// appium/states.test.mjs: what the show's screen keeps when Android recreates it
// Needs the server started with --allow-insecure uiautomator2:adb_shell, for `am kill`.
import assert from 'node:assert/strict';
import path from 'node:path';
import { after, afterEach, before, beforeEach, test } from 'node:test';
import { remote } from 'webdriverio';
import { ListScreen } from './screens/list.mjs';
import { PermissionDialog } from './screens/permission.mjs';

const APP = 'example.tickets';
const APK = path.resolve('tickets/app/build/outputs/apk/debug/app-debug.apk');
let driver;

before(async () => {
  driver = await remote({
    hostname: '127.0.0.1',
    port: 4723,
    logLevel: 'warn',
    capabilities: {
      platformName: 'Android',
      'appium:automationName': 'UiAutomator2',
      'appium:app': APK,
    },
  });
});

after(async () => {
  await driver?.deleteSession();
});

beforeEach(async () => {
  await driver.execute('mobile: removeApp', { appId: APP });
  await driver.execute('mobile: installApp', { appPath: APK });
  await driver.execute('mobile: activateApp', { appId: APP });
});

afterEach(async () => {
  await driver.setOrientation('PORTRAIT');
});

test('the show comes back after Android kills the app in the background', async () => {
  const show = await new ListScreen(driver).open(2);

  await driver.execute('mobile: backgroundApp', { seconds: -1 });
  await driver.execute('mobile: shell', { command: 'am', args: ['kill', APP] });
  assert.equal(await driver.execute('mobile: queryAppState', { appId: APP }), 1);

  await driver.execute('mobile: activateApp', { appId: APP });
  await show.waitUntilShown();
  assert.equal(await show.title(), 'O Pagador de Promessas');
});

test('a refusal is still explained after a rotation', {
  todo: 'defect: remind_denied is hidden again when ShowActivity is recreated',
}, async () => {
  const show = await new ListScreen(driver).open(2);
  await show.tapRemind();
  await (await new PermissionDialog(driver).waitUntilShown()).deny();
  assert.equal(await show.explainsTheDenial(), true);

  await driver.setOrientation('LANDSCAPE');
  await show.waitUntilShown();
  assert.equal(await show.reminderIsOn(), false);
  assert.equal(await show.explainsTheDenial(), true);
});
```

A morte de processo são as quatro chamadas a `execute` no meio. Primeiro vêm o Home sem volta e o
`am kill` pelo shell. Depois o `queryAppState` responde `1`, *não rodando*, o que prova que o kill
aconteceu em vez de supor que aconteceu. Por último, o `activateApp` volta. O teste então espera a tela do espetáculo e confere
o título, que o processo novo só consegue saber pelo intent salvo.

**O segundo teste está marcado como `todo`**, uma opção do `node:test`. Ele roda e o resultado é
impresso, com `# TODO` e o motivo ao lado, mas não reprova a suíte. É o jeito honesto de manter um
teste para um defeito conhecido e ainda não corrigido. No dia em que a correção chega, o teste passa e
o relatório diz isso, e a marca sai. Sem a marca, a suíte fica vermelha até a correção e todo mundo aprende a ignorá-la. A próxima falha de verdade chega numa suíte que ninguém lê.

**Nenhum dos arquivos foi rodado para este curso**: sem aparelho, como antes. O defeito para o qual o
segundo teste foi escrito vem da leitura do código na seção 04. A primeira coisa a fazer no seu
emulador é vê-lo com os próprios olhos. Recuse a permissão, gire o emulador com o botão de rotação
dele, e olhe embaixo da chave.

## O defeito, por escrito

O relato que o `manual-testing` ensinou, com o que um desenvolvedor precisa para reproduzi-lo e nada
mais:

> **O motivo de um lembrete recusado some quando o celular é girado**
>
> **Passos.** No Android 13 ou posterior, com o Tickets recém-instalado: abra *O Pagador de
> Promessas*, ligue *Remind me on the day*, aperte *Não permitir* no diálogo do Android. Gire o
> celular para paisagem.
>
> **Esperado.** A chave desligada e *Notifications are off for Tickets, so no reminder can be sent.*
> na tela, como antes do giro.
>
> **Obtido, previsto pelo código e ainda não visto num aparelho.** A chave desligada e a frase
> sumiu. O mesmo decorreria de mudar para o tema escuro ou trocar o tamanho da fonte.
>
> **Causa, pelo código.** A `ShowActivity` mostra a frase só no `onRequestPermissionsResult`; uma
> activity recriada nunca o roda, e a visibilidade de um `TextView` não é salva. Salvar se ela estava
> à vista no `onSaveInstanceState`, e mostrá-la de novo no `onCreate`, a manteria.
>
> **Teste.** `appium/states.test.mjs`, *a refusal is still explained after a rotation*, marcado como
> todo.

Um relato diz se o *Obtido* foi visto ou deduzido, porque um desenvolvedor lê os dois de jeitos
diferentes. No seu emulador você pode trocar a previsão por uma observação, e o título por um simples
*Obtido*.
