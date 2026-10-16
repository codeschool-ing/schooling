---
title: Um gesto é um dedo que se move
version: 1
---

**Para um teste, um swipe não é um comando. É um dedo que encosta num ponto, vai até outro em
alguns milissegundos e sai da tela.** O protocolo W3C da lição 15 tem uma única requisição para
todo gesto que existe, `POST /session/{id}/actions`. O corpo dela descreve o dedo: uma *fonte de
entrada* do tipo `pointer` com `pointerType` `touch`, e a lista do que ele faz, na ordem. Cinco
tipos de passo bastam para todo gesto num celular:

| passo | o que o dedo faz |
|---|---|
| `pointerMove` | vai até um ponto, de uma vez ou ao longo de uma `duration` em milissegundos |
| `pointerDown` | encosta na tela |
| `pause` | fica onde está por uma `duration` |
| `pointerUp` | sai da tela |

Então um *toque* é encostar e soltar num ponto. Um *toque longo* é encostar, esperar um segundo
ou coisa assim, e soltar. Um *swipe* é encostar, mover com uma duração e soltar. Uma *pinça*
precisa de dois dedos, ou seja, duas fontes de ponteiro na mesma requisição, cada uma com os seus
passos, executadas juntas.

## Vendo um

Num aparelho, um gesto é invisível do lado do teste. A requisição sai, a tela se mexe, e a resposta
é `null`. O driver fake do Appium da lição 15 é o jeito de ver um. Ele guarda um registro das ações
que recebe, coisa que nenhum outro driver faz. Com o servidor da lição 15 rodando e o driver fake instalado,
salve como `appium/fake-gestures.mjs`:

```js
// appium/fake-gestures.mjs: gestures sent to Appium's fake driver, to see what a gesture is
import path from 'node:path';
import { remote } from 'webdriverio';

const ID = 'id=example.tickets:id/';

const driver = await remote({
  hostname: '127.0.0.1',
  port: 4723,
  logLevel: 'silent',
  connectionRetryCount: 0,
  capabilities: {
    platformName: 'Fake',
    'appium:automationName': 'Fake',
    'appium:app': path.resolve('appium/tickets-model.xml'),
  },
});

// The fake driver keeps every gesture it receives in a log of its own; print the last one.
async function received(name) {
  const log = await driver.getLogs('actions');
  console.log(`${name}:`);
  for (const source of log.at(-1)) {
    for (const action of source.actions) console.log('  ' + JSON.stringify(action));
  }
}

try {
  const list = await driver.$(ID + 'shows');
  const refresh = await driver.$(ID + 'refresh');
  console.log('the list:', await list.getLocation(), await list.getSize());

  // A swipe up the list, by hand: a finger down near the bottom, moved up, lifted.
  await driver.action('pointer', { parameters: { pointerType: 'touch' } })
    .move({ x: 540, y: 2100 })
    .down()
    .pause(100)
    .move({ x: 540, y: 700, duration: 400 })
    .up()
    .perform();
  await received('swipe by hand');

  // A long press on the button: down, a second without moving, up.
  await driver.action('pointer', { parameters: { pointerType: 'touch' } })
    .move({ origin: refresh })
    .down()
    .pause(1000)
    .up()
    .perform();
  await received('long press by hand');

  // The same two gestures through WebdriverIO's helpers.
  await driver.swipe({ scrollableElement: list, direction: 'up', percent: 0.5 });
  await received('driver.swipe()');
  await refresh.longPress({ duration: 800 });
  await received('longPress()');

  // A gesture of the UiAutomator2 driver's own, which this driver does not have.
  try {
    await driver.execute('mobile: swipeGesture', { elementId: list.elementId, direction: 'up', percent: 0.5 });
  } catch (error) {
    console.log('mobile: swipeGesture failed:', error.message.split('. ')[0]);
  }
} finally {
  await driver.deleteSession();
}
```

`logLevel: 'silent'` e `connectionRetryCount: 0` impedem o WebdriverIO de imprimir os próprios
avisos. Também o impedem de repetir o comando que deve falhar no fim. O script imprime esse erro ele
mesmo. A partir
de `~/boxoffice`:

```
ana@laptop:~/boxoffice$ node appium/fake-gestures.mjs
the list: { x: 42, y: 306 } { width: 996, height: 2052 }
swipe by hand:
  {"type":"pointerMove","button":0,"x":540,"y":2100,"duration":100,"origin":"viewport"}
  {"type":"pointerDown","button":0}
  {"type":"pause","duration":100}
  {"type":"pointerMove","button":0,"x":540,"y":700,"duration":400,"origin":"viewport"}
  {"type":"pointerUp","button":0}
long press by hand:
  {"type":"pointerMove","button":0,"x":0,"y":0,"duration":100,"origin":{"ELEMENT":"2","element-6066-11e4-a52e-4f735466cecf":"2"}}
  {"type":"pointerDown","button":0}
  {"type":"pause","duration":1000}
  {"type":"pointerUp","button":0}
driver.swipe():
  {"type":"pointerMove","button":0,"x":540,"y":1845,"duration":100,"origin":"viewport"}
  {"type":"pointerDown","button":0}
  {"type":"pause","duration":10}
  {"type":"pointerMove","button":0,"x":540,"y":819,"duration":1500,"origin":"viewport"}
  {"type":"pointerUp","button":0}
longPress():
  {"type":"pointerMove","button":0,"x":0,"y":0,"duration":100,"origin":{"ELEMENT":"2","element-6066-11e4-a52e-4f735466cecf":"2"}}
  {"type":"pointerDown","button":0}
  {"type":"pause","duration":800}
  {"type":"pointerUp","button":0}
mobile: swipeGesture failed: WebDriverError: Unsupported execute method 'mobile: swipeGesture'
```

**Leia primeiro o swipe feito à mão.** O dedo vai até `540,2100`, perto da base de uma tela de 2400
pixels de altura, e encosta. Espera 100 ms, viaja até `540,700` em 400 ms e sai. O conteúdo embaixo
dele sobe junto com o dedo, e é isso que *swipe para cima* quer dizer. **A direção é a do dedo, não
a da lista**, e um swipe para cima traz à vista as linhas que estão mais abaixo na lista. Confundir
as duas é o defeito de gesto mais comum num teste, e ele falha calado. A lista anda para o lado
errado, nada é encontrado, e o relatório põe a culpa no localizador.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 374\" role=\"img\" aria-label=\"À esquerda, a tela de um celular com a lista desenhada dentro. Um dedo encosta em 540,2100, perto de baixo, e sobe em linha reta até 540,700. À direita, os cinco passos da única requisição de actions que faz isso: pointerMove até 540,2100, pointerDown, uma pausa de 100 ms, pointerMove até 540,700 em 400 ms, pointerUp.\"><defs><marker id=\"f21swipe-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"30\" width=\"140.4\" height=\"312\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"45.46\" y=\"69.78\" width=\"129.48\" height=\"266.76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"110.2\" y=\"81.78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">a lista</text><rect x=\"105.2\" y=\"298\" width=\"10\" height=\"10\" rx=\"5\" fill=\"var(--amber)\"></rect><line x1=\"110.2\" y1=\"296\" x2=\"110.2\" y2=\"123\" stroke=\"var(--amber)\" stroke-width=\"2\" marker-end=\"url(#f21swipe-ah)\"></line><rect x=\"106.2\" y=\"117\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"120.2\" y=\"303\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--amber)\">540,2100</text><text x=\"120.2\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--amber)\">540,700</text><text x=\"110.2\" y=\"358\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o dedo sobe</text><text x=\"385\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um POST /actions, cinco passos</text><rect x=\"260\" y=\"34\" width=\"250\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"385\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pointerMove</text><text x=\"385\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">até 540,2100</text><line x1=\"385\" y1=\"78\" x2=\"385\" y2=\"95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f21swipe-ah)\"></line><rect x=\"260\" y=\"96\" width=\"250\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"385\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pointerDown</text><text x=\"385\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">o dedo encosta</text><line x1=\"385\" y1=\"140\" x2=\"385\" y2=\"157\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f21swipe-ah)\"></line><rect x=\"260\" y=\"158\" width=\"250\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"385\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pause</text><text x=\"385\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">100 ms</text><line x1=\"385\" y1=\"202\" x2=\"385\" y2=\"219\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f21swipe-ah)\"></line><rect x=\"260\" y=\"220\" width=\"250\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"385\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pointerMove</text><text x=\"385\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">até 540,700, em 400 ms</text><line x1=\"385\" y1=\"264\" x2=\"385\" y2=\"281\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f21swipe-ah)\"></line><rect x=\"260\" y=\"282\" width=\"250\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"385\" y=\"297\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pointerUp</text><text x=\"385\" y=\"312\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">o dedo sai</text><text x=\"530\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o conteúdo segue</text><text x=\"530\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o dedo: um swipe para cima</text><text x=\"530\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">mostra as linhas de baixo</text></svg>", "caption": "Um swipe para cima como o WebdriverIO o mandou na execução acima: a direção diz para onde o dedo vai, e a lista se move com ele.", "same": ["100 ms"]}
```

**O toque longo não diz coordenada nenhuma.** A `origin` dele é o botão de atualizar, como uma
referência de elemento do W3C, e `x: 0, y: 0` é um deslocamento a partir do centro do elemento. É a
versão para gestos do conselho da lição 14 sobre localizadores. Um ponto calculado a partir de um
elemento sobrevive a um layout novo, e um ponto digitado em pixels não.

**Os atalhos do WebdriverIO mandam os mesmos cinco passos.** O `driver.swipe()` pediu à lista o
retângulo dela, que começa em `y: 306` e tem 2052 pixels de altura. Ele pegou a metade do meio por
causa do `percent: 0.5`, e fez o swipe de `y: 1845` até `y: 819` em 1500 ms, o padrão dele. O
`longPress()` é o toque longo com 800 ms na pausa. O próprio log do servidor mostra o que passou pelo
HTTP:

```
[5f76d6dd][HTTP] --> POST /session/5f76d6dd-8e9f-42b3-a7c9-7215833eb22e/actions
[5f76d6dd][HTTP] --> DELETE /session/5f76d6dd-8e9f-42b3-a7c9-7215833eb22e/actions
[5f76d6dd][HTTP] --> POST /session/5f76d6dd-8e9f-42b3-a7c9-7215833eb22e/actions
[5f76d6dd][HTTP] --> DELETE /session/5f76d6dd-8e9f-42b3-a7c9-7215833eb22e/actions
[5f76d6dd][HTTP] --> POST /session/5f76d6dd-8e9f-42b3-a7c9-7215833eb22e/actions
[5f76d6dd][HTTP] --> DELETE /session/5f76d6dd-8e9f-42b3-a7c9-7215833eb22e/actions
[5f76d6dd][HTTP] --> POST /session/5f76d6dd-8e9f-42b3-a7c9-7215833eb22e/actions
[5f76d6dd][HTTP] --> DELETE /session/5f76d6dd-8e9f-42b3-a7c9-7215833eb22e/actions
```

Um `POST …/actions` por gesto, cada um seguido de um `DELETE …/actions`. O WebdriverIO manda essa segunda requisição para soltar o que o dedo ainda estivesse segurando. Toda biblioteca de gestos para o Appium
termina nessas requisições. Quando um gesto se comporta mal num aparelho, leia primeiro o corpo desse
`POST` no log do servidor.

## Os gestos do próprio driver

A última linha da execução é o driver fake recusando `mobile: swipeGesture`. **Comandos que começam
com `mobile:` não são do protocolo; pertencem a um driver.** Eles viajam pela requisição padrão de
`execute` com o nome do comando no lugar de um script. O driver UiAutomator2 tem um conjunto deles
que entregam o gesto ao UiAutomator do Android. O UiAutomator o executa no aparelho a partir de um elemento e
de uma porcentagem, sem coordenada nenhuma calculada no teste:

| gesto | o comando do UiAutomator2 | os principais argumentos |
|---|---|---|
| toque | `mobile: clickGesture` | `elementId`, ou `x` e `y` |
| toque longo | `mobile: longClickGesture` | `elementId`, `duration` |
| swipe | `mobile: swipeGesture` | `elementId`, `direction`, `percent` |
| rolagem | `mobile: scrollGesture` | `elementId`, `direction`, `percent`; responde se ainda falta rolar |
| arrastar | `mobile: dragGesture` | `elementId`, `endX`, `endY` |
| pinça | `mobile: pinchOpenGesture`, `mobile: pinchCloseGesture` | `elementId`, `percent` |

No WebdriverIO eles são chamados com `driver.execute('mobile: swipeGesture', { elementId, direction:
'up', percent: 0.75 })`. **A escolha entre os dois tipos é portabilidade contra confiabilidade.** As
ações do W3C funcionam em todo driver, Android e iOS, e deixam as coordenadas com você. Os gestos
`mobile:` costumam ser mais estáveis no Android, porque o UiAutomator conhece a tela, e prendem o
teste a um driver. Uma suíte que roda numa plataforma pode ficar com os `mobile:`. Uma suíte para
as duas fica nas ações, ou nos atalhos do WebdriverIO, que por baixo são ações.

## Rolando até alguma coisa

A maioria dos swipes de uma suíte de verdade existe para trazer um elemento à vista. O
`element.scrollIntoView({ scrollableElement: list, direction: 'up' })` do WebdriverIO faz swipes até
o elemento aparecer, até dez vezes por padrão. O UiAutomator tem o seu próprio jeito, na sintaxe de
seletor da lição 15:

```js
await driver.$('android=new UiScrollable(new UiSelector().scrollable(true))' +
  '.scrollIntoView(new UiSelector().resourceId("example.tickets:id/title").text("O Pagador de Promessas"))');
```

Ele rola a primeira view rolável da tela até aparecer uma linha com esse título, e devolve essa
linha. O Tickets tem três espetáculos e eles cabem em qualquer celular. Então nenhum dos dois é
necessário para a lista como o boxoffice a serve; eles importam no dia em que forem trinta.

## Gestos no Espresso

O Espresso tem os mesmos gestos como **view actions**, executadas numa view que ele encontrou. Como
todo passo do Espresso, elas esperam a thread principal antes:

```kotlin
onView(withId(R.id.shows)).perform(swipeUp())
onData(showWithId("sh-103")).inAdapterView(withId(R.id.shows)).perform(longClick())
```

`swipeUp()`, `swipeDown()`, `swipeLeft()` e `swipeRight()` fazem o swipe atravessando a view que recebem. `longClick()` e `doubleClick()` a pressionam. **O `onData` já rola uma `ListView` até a
linha que encontra**, e é por isso que os testes da lição 16 nunca precisaram de um swipe. O `scrollTo()` faz o mesmo com uma view dentro de uma `ScrollView`. Os gestos do Espresso são eventos
de toque injetados na própria janela do app. Eles só alcançam as views do app, e a próxima seção
esbarra nesse limite.

**Nenhum gesto desta seção foi feito num aparelho para este curso.** Como a lição 14 mostrou,
nenhum emulador consegue iniciar na máquina de gravação. A execução acima é o protocolo, real, pelo
servidor real. O que um swipe faz com a lista do Tickets fica para o seu emulador mostrar.
