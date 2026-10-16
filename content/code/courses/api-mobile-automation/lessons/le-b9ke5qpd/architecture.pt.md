---
title: Quatro programas entre um teste e um toque
version: 1
---

**O Appium é um servidor que transforma requisições HTTP em toques num celular.** O seu teste
nunca encosta no aparelho. Ele manda uma requisição como *encontre o elemento cujo id é `refresh`*
ao servidor do Appium no seu computador. O servidor a entrega a um **driver** que conhece uma
plataforma, e o driver faz o aparelho executá-la. A resposta volta pelo mesmo caminho, em JSON.

A imagem comum é a do Appium como um programa que "controla o celular". São quatro, e uma falha
pode vir de qualquer um deles. Vale saber para qual deles você está olhando:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 278\" role=\"img\" aria-label=\"Quatro peças entre um teste e o app. No seu computador, o cliente, WebdriverIO ou curl, manda requisições HTTP ao servidor do Appium em localhost, porta 4723. Dentro do servidor, um driver para a plataforma, UiAutomator2 para Android ou XCUITest para iOS, alcança o dispositivo pelo adb. No dispositivo, o app do próprio driver age sobre o Tickets, o app sob teste.\"><defs><marker id=\"f15layers-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"455\" height=\"210\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"247\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">seu computador</text><rect x=\"505\" y=\"30\" width=\"175\" height=\"210\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"592\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o dispositivo</text><rect x=\"35\" y=\"100\" width=\"135\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"102.5\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o cliente</text><text x=\"102.5\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">WebdriverIO, curl</text><rect x=\"215\" y=\"66\" width=\"245\" height=\"160\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"337\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">o servidor do Appium</text><text x=\"337\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">localhost:4723</text><rect x=\"235\" y=\"120\" width=\"205\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"337.5\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o driver</text><text x=\"337.5\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">UiAutomator2</text><text x=\"337\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">XCUITest no iOS</text><rect x=\"520\" y=\"100\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"592.5\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">lado do dispositivo</text><text x=\"592.5\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o app do driver</text><rect x=\"520\" y=\"172\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"592.5\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Tickets</text><text x=\"592.5\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o app sob teste</text><line x1=\"170\" y1=\"125\" x2=\"233\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f15layers-ah)\"></line><text x=\"201.5\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">HTTP</text><line x1=\"440\" y1=\"135\" x2=\"518\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f15layers-ah)\"></line><text x=\"479\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">adb</text><line x1=\"592\" y1=\"150\" x2=\"592\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f15layers-ah)\"></line><text x=\"350\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um protocolo do cliente ao servidor; um driver por plataforma atrás dele</text></svg>", "caption": "O teste fala HTTP com o servidor; o driver dentro dele fala com o dispositivo pelo adb, e o app do driver no dispositivo é quem toca na tela.", "same": ["Tickets"]}
```

| peça | o que é | onde roda |
|---|---|---|
| **o cliente** | uma biblioteca na linguagem do teste: WebdriverIO para JavaScript nesta lição, ou os clientes do Appium para Java, Python e .NET; ou o curl, na seção 04 | o seu computador, no processo do teste |
| **o servidor do Appium** | um programa Node, `appium`, escutando na porta 4723 | o seu computador |
| **o driver** | um plug-in do servidor para uma plataforma: **UiAutomator2** para Android, **XCUITest** para iOS | o seu computador, dentro do servidor |
| **o lado do dispositivo** | o que o driver instala no aparelho para agir lá: um pequeno app servidor no Android, que usa o framework UiAutomator do Google; o WebDriverAgent no iOS | o emulador, o celular ou o simulador de iOS |

O driver de Android alcança o seu lado do dispositivo pelo adb, a ferramenta que a lição 14
instalou. É por isso que o Appium precisa do SDK do Android no computador onde o servidor roda. É também
por isso que um teste falha com a mesma mensagem esteja o emulador fechado ou o adb tenha perdido
a conta dele.

## O protocolo é o da web

**As requisições são W3C WebDriver**, o padrão que toda ferramenta de automação de navegador fala
desde que o W3C o publicou em 2018. Uma sessão começa com `POST /session`. Um elemento é encontrado
com `POST /session/{id}/element` e clicado com `POST …/element/{element}/click`. A sessão termina
com `DELETE /session/{id}`. Um teste web em `web-automation` manda as mesmas requisições ao driver
de um navegador. O Appium as responde para um app, e acrescenta os comandos de que um celular
precisa e um navegador não, como mandar o app para segundo plano na lição 21.

Então um teste mobile é um cliente HTTP, e tudo o que a primeira metade deste curso ensinou sobre
ler uma requisição e a sua resposta vale para ele. A seção 04 conduz uma sessão à mão com curl para
mostrar isso.

## Capabilities: para que serve a sessão

O corpo do `POST /session` leva as **capabilities**, um objeto JSON que diz que tipo de sessão você
quer. O servidor escolhe um driver por duas delas e passa o resto a esse driver:

| capability | o que diz | para o Tickets |
|---|---|---|
| `platformName` | a plataforma, um nome do W3C | `Android` |
| `appium:automationName` | qual driver | `UiAutomator2` |
| `appium:app` | o app a instalar e abrir | o caminho do APK que o Android Studio gerou |
| `appium:udid` | qual aparelho, quando há mais de um conectado | um serial do adb como `emulator-5554` |

O prefixo `appium:` é a regra do W3C para uma capability que o padrão não define. A extensão de
cada fornecedor leva o nome dele, para que duas ferramentas não queiram dizer coisas diferentes
com a mesma palavra. **O Appium recusa uma capability de extensão sem o prefixo.** No iOS o mesmo
teste pede `platformName: iOS` e `appium:automationName: XCUITest`. O driver muda por baixo
enquanto as requisições continuam as mesmas. É esse o sentido de *um driver para Android e iOS* no
título desta lição: um protocolo e um cliente para os dois, com um driver por plataforma atrás.

**Uma promessa não é feita: a de que o mesmo teste roda nos dois.** O id de um elemento no Android
é um resource id. No iOS é um accessibility identifier, que os desenvolvedores do app definem à
parte. Uma suíte que roda nas duas plataformas precisa que os dois apps concordem nos nomes. Isso é
uma promessa entre desenvolvedores e testadores como a que a lição 14 descreveu, cumprida duas
vezes.
