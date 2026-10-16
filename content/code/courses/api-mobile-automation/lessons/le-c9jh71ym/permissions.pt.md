---
title: Permissões, e o diálogo que não é do app
version: 1
---

**Num celular, o que um app pode fazer é decidido por quem o segura, uma permissão de cada vez, no
momento em que o app precisa dela pela primeira vez.** Desde o Android 6, as permissões que tocam a
vida privada de alguém, como a câmera, a localização e os contatos, são pedidas em tempo de execução
com um diálogo, e a pessoa pode dizer não. O Android 13 pôs as notificações nessa lista, como
`POST_NOTIFICATIONS`. Então um recurso atrás de uma permissão tem pelo menos dois caminhos, e o
caminho em que a pessoa diz não é aquele que ninguém testa à mão duas vezes.

A crença a abandonar primeiro é a de que o diálogo faz parte do app. **Quem o desenha é o Android**,
um app do sistema chamado controlador de permissões, por cima da janela do app. O app só pede, e
fica sabendo da resposta depois.

## Onde o Tickets pede

A lição 14 pôs uma permissão atrás da chave de lembrete. O manifesto a declara, e a tela do
espetáculo a pede quando a chave é ligada:

```
ana@laptop:~/boxoffice$ grep -n 'POST_NOTIFICATIONS' tickets/app/src/main/AndroidManifest.xml
7:    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
ana@laptop:~/boxoffice$ grep -n 'SDK_INT\|POST_NOTIFICATIONS\|granted' tickets/app/src/main/java/example/tickets/ShowActivity.kt
32:        if (Build.VERSION.SDK_INT < 33) return
33:        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) return
34:        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), ASK)
40:        val granted = results.firstOrNull() == PackageManager.PERMISSION_GRANTED
41:        remind.isChecked = granted
42:        denied.visibility = if (granted) View.GONE else View.VISIBLE
```

Lendo na ordem: abaixo do Android 13 (`SDK_INT < 33`) não há nada a pedir, e a chave simplesmente
fica ligada; se a permissão já foi concedida, o mesmo; senão o app pede, e quando a resposta volta, a
linha 41 põe a chave na posição da resposta e a linha 42 mostra a linha `remind_denied` se ela foi
não. São três resultados de um toque, e a versão do Android decide quais são possíveis:

| Android | antes do toque | a pessoa | o que o Tickets deve mostrar |
|---|---|---|---|
| 12 ou anterior | qualquer coisa | nada é perguntado | a chave ligada |
| 13 ou posterior | nunca perguntado | *Permitir* | o diálogo, depois a chave ligada |
| 13 ou posterior | nunca perguntado | *Não permitir* | o diálogo, depois a chave desligada e a linha dizendo que as notificações estão desligadas |
| 13 ou posterior | já concedida | nada é perguntado | a chave ligada |
| 13 ou posterior | recusada duas vezes antes | nada é perguntado: o Android responde não por ela | a chave desligada e a linha, sem diálogo |

A última linha é a regra do Android desde a versão 11: **depois que uma pessoa recusa a mesma
permissão duas vezes, o diálogo para de aparecer** e todo pedido seguinte é recusado na hora. Um app
que não oferece caminho para as configurações nesse ponto deixa a pessoa com uma chave que se desliga
sozinha e nenhuma ideia do porquê; o Tickets ao menos diz o porquê, e um teste deve cobrar isso dele.

## Preparando o estado antes de um teste

Um teste desses caminhos precisa partir de uma resposta conhecida, e o adb consegue defini-la de
fora. Estes comandos, como todos desta lição que precisam de um aparelho, não foram rodados para
este curso:

```sh
adb shell pm grant example.tickets android.permission.POST_NOTIFICATIONS
adb shell pm revoke example.tickets android.permission.POST_NOTIFICATIONS
adb shell pm reset-permissions
adb install -r -g tickets/app/build/outputs/apk/debug/app-debug.apk
```

`grant` e `revoke` definem uma permissão de um app. `reset-permissions` devolve todos os apps do
aparelho ao padrão, o que pesa num celular que você usa. `install -r -g` reinstala o app com tudo o
que o manifesto pede já concedido. **O único estado que é com certeza *nunca perguntado* é uma
instalação nova**, sem memória de recusas anteriores, então os testes abaixo removem e reinstalam o
app antes de cada um. Isso custa alguns segundos por teste, e compra um ponto de partida sobre o qual
ninguém precisa raciocinar.

O Appium tem as mesmas chaves. A capability `appium:autoGrantPermissions: true` instala o app com
todas as permissões concedidas, o que é certo para uma suíte que não trata de permissões e errado
para esta, já que tira de cena o diálogo em teste. `driver.execute('mobile: changePermissions',
{ permissions: 'android.permission.POST_NOTIFICATIONS', appPackage: 'example.tickets', action:
'revoke' })` muda uma, e `mobile: getPermissions` com `type: 'granted'` as lista.

## Que ferramenta consegue apertar *Não permitir*

**O Appium consegue, porque vê a tela inteira.** O UiAutomator, por baixo do driver UiAutomator2,
lê todas as janelas da tela, a do controlador de permissões inclusive, então os botões dele são
elementos como quaisquer outros; só levam o pacote daquele app nos ids. O diálogo ganha um screen
object próprio; salve como `appium/screens/permission.mjs`:

```js
// appium/screens/permission.mjs: Android's permission dialog, drawn over the app by Android
// These ids belong to Android's permission controller, not to Tickets, and a new Android
// version may change them: read them from the page source on your emulator.
const ID = 'id=com.android.permissioncontroller:id/';

export class PermissionDialog {
  constructor(driver) {
    this.driver = driver;
  }

  async waitUntilShown() {
    await this.driver.$(ID + 'permission_allow_button').waitForDisplayed({ timeout: 5000 });
    return this;
  }

  allow() {
    return this.driver.$(ID + 'permission_allow_button').click();
  }

  deny() {
    return this.driver.$(ID + 'permission_deny_button').click();
  }
}
```

**O Espresso não consegue.** O teste dele roda dentro do processo do Tickets e age nas janelas do
Tickets, e o diálogo é uma janela de outro app, então nenhum `onView` acha os botões dele. Um teste
instrumentado tem duas saídas. Pode conceder a permissão antes de o teste começar, pelo
`UiAutomation` do próprio Android, que a `GrantPermissionRule` do `androidx.test:rules` embrulha;
aí nenhum diálogo aparece, e nenhuma recusa pode ser testada também. Ou pode guiar o diálogo com a
biblioteca **UI Automator** do Google, uma dependência que o modelo da lição 14 não declara. Por isso
neste curso os caminhos do diálogo ficam com o Appium, e a seção 05 põe o Espresso para conferir o que
acontece depois de uma concessão.

## O teste

O screen object da tela do espetáculo, da lição 15, ganha a chave e a linha embaixo dela. Substitua o
arquivo; salve como `appium/screens/show.mjs`:

```js
// appium/screens/show.mjs: the screen of one show, as a test sees it
const ID = 'id=example.tickets:id/';

export class ShowScreen {
  constructor(driver) {
    this.driver = driver;
  }

  async waitUntilShown() {
    await this.driver.$(ID + 'seats').waitForDisplayed({ timeout: 5000 });
    return this;
  }

  title() {
    return this.driver.$(ID + 'title').getText();
  }

  seats() {
    return this.driver.$(ID + 'seats').getText();
  }

  // The reminder switch. On Android 13 and later its first tap opens Android's permission dialog.
  async tapRemind() {
    await this.driver.$(ID + 'remind').click();
  }

  async reminderIsOn() {
    return (await this.driver.$(ID + 'remind').getAttribute('checked')) === 'true';
  }

  explainsTheDenial() {
    return this.driver.$(ID + 'remind_denied').isDisplayed();
  }
}
```

`getAttribute('checked')` lê o atributo de mesmo nome no page source, que o UiAutomator2 informa como
a string `true` ou `false`, por isso o método o compara com uma string. Depois, os dois caminhos pelo
diálogo. Salve como `appium/reminder.test.mjs`:

```js
// appium/reminder.test.mjs: the reminder switch and Android's permission dialog
import assert from 'node:assert/strict';
import path from 'node:path';
import { after, before, beforeEach, test } from 'node:test';
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

// A fresh install before each test, so the permission has never been asked for.
beforeEach(async () => {
  await driver.execute('mobile: removeApp', { appId: APP });
  await driver.execute('mobile: installApp', { appPath: APK });
  await driver.execute('mobile: activateApp', { appId: APP });
});

test('Allow turns the reminder on', async () => {
  const show = await new ListScreen(driver).open(2);
  await show.tapRemind();
  await (await new PermissionDialog(driver).waitUntilShown()).allow();
  assert.equal(await show.reminderIsOn(), true);
  assert.equal(await show.explainsTheDenial(), false);
});

test("Don't allow turns it off and says why", async () => {
  const show = await new ListScreen(driver).open(2);
  await show.tapRemind();
  await (await new PermissionDialog(driver).waitUntilShown()).deny();
  assert.equal(await show.reminderIsOn(), false);
  assert.equal(await show.explainsTheDenial(), true);
});
```

```schooling-example
{
 "language": "js",
 "file": "reminder.test.mjs",
 "parts": [
  {
   "code": "beforeEach(async () => {\n  await driver.execute('mobile: removeApp', { appId: APP });\n  await driver.execute('mobile: installApp', { appPath: APK });\n  await driver.execute('mobile: activateApp', { appId: APP });\n});",
   "note": "Uma instalação nova antes de cada teste: a permissão nunca foi pedida, e nenhuma recusa anterior conta. O `activateApp` abre o app como o ícone dele abriria."
  },
  {
   "code": "  const show = await new ListScreen(driver).open(2);\n  await show.tapRemind();",
   "note": "O caminho da lição 15: abrir o terceiro espetáculo, depois o único toque que faz o app pedir."
  },
  {
   "code": "  await (await new PermissionDialog(driver).waitUntilShown()).deny();",
   "note": "Esperar o diálogo do Android, depois apertar *Não permitir*. A espera importa: o diálogo é desenhado por outro processo, um instante depois do toque."
  },
  {
   "code": "  assert.equal(await show.reminderIsOn(), false);\n  assert.equal(await show.explainsTheDenial(), true);",
   "note": "De volta à tela do Tickets, as duas coisas que uma pessoa veria: a chave desligada, e a frase dizendo por quê."
  }
 ]
}
```

Rode como o teste da lição 15, com o emulador da lição 14, que roda o Android 15, e o servidor
rodando: `node --test --test-reporter=tap appium/reminder.test.mjs`. Num emulador com Android 12 ou
anterior não há diálogo, e os dois testes falham na espera por ele, que é a tabela acima dizendo para
qual aparelho o teste foi escrito. **Estes testes não foram rodados para este curso**, pelo motivo que
a lição 15 dá: nem aparelho nem app na máquina de gravação.
