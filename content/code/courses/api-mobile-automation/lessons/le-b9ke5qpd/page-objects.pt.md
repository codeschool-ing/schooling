---
title: Objetos de tela
version: 1
---

**Um teste deve dizer o que uma pessoa faz, e um objeto de tela deve dizer como.** O teste da seção
05 mistura os dois: os resource ids, as esperas e as posições das linhas estão nas mesmas linhas que
a coisa sendo conferida. Com um teste, tudo bem. Com trinta, o id `example.tickets:id/title` está
escrito trinta vezes, e no dia em que um desenvolvedor o renomeia, trinta testes falham por um único
motivo e alguém edita trinta arquivos.

O padrão que resolve isso se chama **page object** na web, e `web-automation` terá mostrado esse
padrão lá se você fez o curso; num celular ele é um **objeto de tela**. Cada tela do app ganha uma
classe. A classe conhece os ids e as esperas da tela, e oferece ao teste o que uma pessoa pode fazer
ali. Quando o app muda, uma classe muda.

## Duas telas

A lista. O `open` toca numa linha e devolve a tela a que ela leva, já esperada, então um teste não
tem como esquecer a espera. Salve como `appium/screens/list.mjs`:

```js
// appium/screens/list.mjs: Tickets's list screen, as a test sees it
import { ShowScreen } from './show.mjs';

const ID = 'id=example.tickets:id/';

export class ListScreen {
  constructor(driver) {
    this.driver = driver;
  }

  get banner() {
    return this.driver.$(ID + 'banner');
  }

  async waitUntilLoaded() {
    await this.driver.$(ID + 'title').waitForDisplayed({ timeout: 15000 });
    return this;
  }

  async rows() {
    await this.waitUntilLoaded();
    return this.driver.$$(ID + 'title');
  }

  async open(position) {
    const rows = await this.rows();
    await rows[position].click();
    return new ShowScreen(this.driver).waitUntilShown();
  }
}
```

O espetáculo. Ele responde perguntas e não faz mais nada, porque nada nele é tocado ainda; a chave
de lembrete chega na lição 21. Salve como `appium/screens/show.mjs`:

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
}
```

## O teste, reescrito

O teste da seção 05 vira dois, e nenhum menciona um id. Substitua o arquivo; salve como
`appium/tickets.test.mjs`:

```js
// appium/tickets.test.mjs: the same test, written against two screen objects
import assert from 'node:assert/strict';
import path from 'node:path';
import { after, before, test } from 'node:test';
import { remote } from 'webdriverio';
import { ListScreen } from './screens/list.mjs';

let driver;

before(async () => {
  driver = await remote({
    hostname: '127.0.0.1',
    port: 4723,
    logLevel: 'warn',
    capabilities: {
      platformName: 'Android',
      'appium:automationName': 'UiAutomator2',
      'appium:app': path.resolve('tickets/app/build/outputs/apk/debug/app-debug.apk'),
    },
  });
});

after(async () => {
  await driver?.deleteSession();
});

test('the list shows the three shows', async () => {
  const rows = await new ListScreen(driver).rows();
  assert.equal(rows.length, 3);
});

test('the third show opens with the seats boxoffice reports', async () => {
  const show = await new ListScreen(driver).open(2);
  assert.equal(await show.title(), 'O Pagador de Promessas');

  const api = await (await fetch('http://localhost:8080/v1/shows/sh-103')).json();
  assert.equal(await show.seats(), `${api.seats_left} seats left`);
});
```

Leia o segundo teste em voz alta e ele é a frase que um caso de teste manual de `manual-testing`
teria sido: abra o terceiro espetáculo; o título é *O Pagador de Promessas*; os lugares são o que o
boxoffice diz. Os ids, os prazos e a ordem das linhas estão nas telas, ditos uma vez.

**Esta versão não foi executada**, pelo motivo que a seção 05 dá: não há aparelho. As telas usam só
as chamadas do WebdriverIO que aquele arquivo usava, e o comando para rodar é o mesmo.

## O que não pertence a um objeto de tela

- **Asserções.** A tela responde `seats()`; o teste decide qual deve ser a resposta. Uma tela que
  fizesse asserções levaria as expectativas de um teste para todo teste que a usasse.
- **Pausas**, pelos motivos da seção 06. A tela é o lugar natural das esperas, e as explícitas
  pertencem a ela.
- **Dados.** Qual espetáculo abrir é assunto do teste, passado como argumento.

Dois hábitos mantêm os objetos de tela honestos. Devolva a próxima tela a partir de uma ação que leva
a uma, como o `open` faz, para que o teste siga o caminho do próprio app. E mantenha-os pequenos: um
objeto de tela com quarenta métodos costuma ser três telas, ou uma tela e a suíte inteira de alguém.
