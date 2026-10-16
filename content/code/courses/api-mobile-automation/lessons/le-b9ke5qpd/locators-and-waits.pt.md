---
title: Localizadores e esperas
version: 1
---

**Dois hábitos decidem se um teste de Appium merece confiança**: como ele encontra um elemento, e
como espera por um. Um teste que encontra pela posição quebra quando o layout se mexe, e um teste
que espera dormindo quebra quando o aparelho está lento. Os dois passam no dia em que são escritos,
e é por isso que os dois são comuns.

## Estratégias, em ordem de preferência

A lição 14 ordenou as alças que um teste pode usar no Android. Estas são as estratégias que o Appium
oferece para elas, com o jeito como o WebdriverIO escreve cada uma:

| estratégia | WebdriverIO | no Android significa | no iOS |
|---|---|---|---|
| **id** | `$('id=example.tickets:id/refresh')` | o resource id | o nome do elemento, em geral o accessibility identifier |
| **accessibility id** | `$('~Refresh the list')` | a content description | o accessibility identifier |
| **UiAutomator** | `$('android=new UiSelector().text("Refresh")')` | uma consulta na sintaxe do UiAutomator do Google, executada no aparelho | não existe |
| **predicate, class chain** | `$('-ios predicate string:…')` | não existe | as sintaxes de consulta do próprio iOS |
| **class name** | `$('android.widget.Button')` | todo elemento daquela classe | o tipo do XCUITest, como `XCUIElementTypeButton` |
| **XPath** | `$('//android.widget.ListView/android.widget.LinearLayout[3]')` | um caminho pelo page source da seção 04 | o mesmo, sobre a árvore do iOS |

**Accessibility id é a estratégia em que as suítes multiplataforma se apoiam.** Ela lê um atributo
que as duas plataformas mantêm para acessibilidade. Um app feito para as duas pode dar a um elemento
o mesmo nome em cada uma, e um só localizador o encontra em qualquer delas. O Tickets não tem
nenhuma, porque a lição 14 não escreveu. Esse é o defeito de acessibilidade que a lição 14 mandou
você registrar: um leitor de tela lê um botão com texto e sem content description como o texto dele
e nada mais.

**O XPath fica por último, por dois motivos.** Ele descreve posições, que mudam. E o UiAutomator não
tem XPath próprio. Para responder a um, o app do driver no aparelho escreve a tela inteira em XML, o
page source da seção 04, e busca nele. Numa tela comprida, é a busca mais lenta que existe.

## Experimentando no modelo

O driver fake responde a `id`, `accessibility id`, `class name` e `xpath`, entre outras. Isso basta
para ver cada uma funcionar contra o modelo da seção 04 pelo WebdriverIO. Com o servidor rodando e o
driver fake instalado, salve como `appium/fake-session.mjs`:

```js
// appium/fake-session.mjs: a WebdriverIO session against Appium's fake driver
import path from 'node:path';
import { remote } from 'webdriverio';

const ID = 'id=example.tickets:id/';

const driver = await remote({
  hostname: '127.0.0.1',
  port: 4723,
  logLevel: 'warn',
  capabilities: {
    platformName: 'Fake',
    'appium:automationName': 'Fake',
    'appium:app': path.resolve('appium/tickets-model.xml'),
  },
});

try {
  const refresh = driver.$(ID + 'refresh');
  await refresh.click();
  console.log('by id, refresh clicked:', await refresh.getAttribute('clicks'));
  console.log('by id, rows:', (await driver.$$(ID + 'title')).length);
  console.log('by accessibility id, Refresh exists:', await driver.$('~Refresh').isExisting());
  console.log('by XPath, third row exists:',
    await driver.$('//android.widget.ListView/android.widget.LinearLayout[3]').isExisting());

  const banner = driver.$(ID + 'banner');
  console.log('banner displayed now:', await banner.isDisplayed());
  try {
    await banner.waitForDisplayed({ timeout: 3000 });
  } catch (error) {
    console.log('wait failed:', error.message);
  }
} finally {
  await driver.deleteSession();
}
```

```
ana@laptop:~/boxoffice$ node appium/fake-session.mjs
by id, refresh clicked: 1
by id, rows: 3
by accessibility id, Refresh exists: false
by XPath, third row exists: true
banner displayed now: false
wait failed: element ("id=example.tickets:id/banner") still not displayed after 3000ms
```

O id encontrou o botão e as três linhas. O accessibility id não encontrou nada, porque o modelo,
como o Tickets, não tem descrições. O XPath encontrou a terceira linha contando. Depois a faixa, que
o modelo esconde como o Tickets a esconde quando a lista é nova.

## Esperando

**A crença errada é que um teste deve esperar um tempo fixo pelo app.** `await driver.pause(3000)` é
como isso se escreve, e está errado nos dois sentidos ao mesmo tempo. Num emulador rápido desperdiça
três segundos em cada passo. Num celular lento, ou numa lista que levou quatro segundos para
carregar, não é suficiente, e o teste falha num elemento que teria aparecido um instante depois. Uma
suíte de duzentos passos assim fica dez minutos mais lenta do que precisa e continua instável.

**Uma espera explícita pede uma condição e um prazo em vez disso.** `waitForDisplayed({ timeout:
3000 })` pergunta ao servidor de novo e de novo se o elemento está visível. Ele retorna no instante em
que estiver, ou falha no prazo com uma mensagem que nomeia o elemento. A faixa nunca aparece, então a
última linha da execução acima é essa falha. O terminal do servidor mostra o que a espera ficou
fazendo nesses três segundos, a mesma requisição repetida:

```
[1a7caf83][HTTP] --> GET /session/1a7caf83-b179-4d8b-8b7b-3464377d2a3e/element/6/displayed 
[1a7caf83][HTTP] <-- GET /session/1a7caf83-b179-4d8b-8b7b-3464377d2a3e/element/6/displayed 200 1 ms - 15
[1a7caf83][HTTP] --> GET /session/1a7caf83-b179-4d8b-8b7b-3464377d2a3e/element/6/displayed 
[1a7caf83][HTTP] <-- GET /session/1a7caf83-b179-4d8b-8b7b-3464377d2a3e/element/6/displayed 200 1 ms - 15
[1a7caf83][HTTP] --> GET /session/1a7caf83-b179-4d8b-8b7b-3464377d2a3e/element/6/displayed 
[1a7caf83][HTTP] <-- GET /session/1a7caf83-b179-4d8b-8b7b-3464377d2a3e/element/6/displayed 200 1 ms - 15
```

O prazo não é quanto o teste costuma esperar. É quanto ele **pode** esperar antes de o app ser
declarado quebrado. Defina-o pelo que uma pessoa aguentaria. Quinze segundos para a lista carregar
numa rede ruim é generoso, e um teste que precisa de mais encontrou algo que interessa à lição 22.

As esperas que o WebdriverIO oferece:

| espera | dá certo quando |
|---|---|
| `waitForExist()` | o elemento está na árvore, desenhado ou não |
| `waitForDisplayed()` | ele está na árvore e visível |
| `waitForEnabled()` | dá para agir sobre ele |
| `waitForDisplayed({ reverse: true })` | ele sumiu, como um indicador de progresso |
| `driver.waitUntil(fn, { timeout })` | uma função sua retorna verdadeiro, como um texto chegando a um valor |

O WebdriverIO também espera um pouco por conta própria antes de agir sobre um elemento que ainda não
está lá, e o Appium tem uma configuração de *implicit wait* que faz toda busca se repetir no
servidor. **Escolha um lugar para esperar, e que seja a espera explícita no teste.** Duas camadas de
espera se multiplicam, e um teste cujo implicit wait é de dez segundos leva dez segundos para provar
que algo não está lá.
