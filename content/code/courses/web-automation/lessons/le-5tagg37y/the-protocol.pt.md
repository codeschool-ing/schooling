---
title: O protocolo: um teste, um driver e um navegador
version: 1
---

A imagem com que a maioria das pessoas começa é a de que o Selenium é um programa que sai clicando
dentro do navegador, como faria uma extensão. **São três programas, e eles conversam por HTTP.**
O seu teste é um cliente HTTP. O **driver**, o `chromedriver` no caso do Chrome, é um pequeno
servidor HTTP que escuta numa porta. O navegador fica atrás do driver, e só o driver fala com ele,
pelo caminho que os fabricantes daquele navegador construíram para isso. Nada do Selenium roda
dentro da página.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Três caixas em fila. Seu teste, usando selenium-webdriver, é um cliente HTTP. Ele manda requisições como POST /session ao chromedriver na porta 9515 de localhost, um servidor HTTP, e recebe JSON de volta; essa conversa é o padrão W3C WebDriver. O chromedriver comanda o Chrome, onde a página roda, pelo canal próprio do navegador.\"><rect x=\"20\" y=\"50\" width=\"170\" height=\"110\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><rect x=\"275\" y=\"50\" width=\"170\" height=\"110\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><rect x=\"530\" y=\"50\" width=\"170\" height=\"110\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"105\" y=\"80\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" fill=\"var(--paper)\">seu teste</text><text x=\"105\" y=\"104\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">selenium-webdriver</text><text x=\"105\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">um cliente HTTP</text><text x=\"360\" y=\"80\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">chromedriver</text><text x=\"360\" y=\"104\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">localhost:9515</text><text x=\"360\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">um servidor HTTP</text><text x=\"615\" y=\"80\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" fill=\"var(--paper)\">Chrome</text><text x=\"615\" y=\"104\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a página roda aqui</text><text x=\"615\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">faz o trabalho</text><path d=\"M195 92 L270 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M270 92 L260 86 L260 98 Z\" fill=\"var(--phosphor)\"></path><path d=\"M270 120 L195 120\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></path><path d=\"M195 120 L205 114 L205 126 Z\" fill=\"var(--phosphor-dim)\"></path><text x=\"232\" y=\"40\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">POST /session/…</text><text x=\"232\" y=\"184\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pedidos vão, JSON volta</text><path d=\"M450 105 L525 105\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M525 105 L515 99 L515 111 Z\" fill=\"var(--amber)\"></path><text x=\"488\" y=\"184\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">canal próprio</text><text x=\"232\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">W3C WebDriver</text><text x=\"488\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">do navegador</text></svg>", "caption": "Três programas. Só o do meio toca o navegador, e o padrão cobre só a seta da esquerda.", "same": ["Chrome"]}
```

A língua entre os dois primeiros é um **padrão do W3C, o WebDriver**. Cada comando que um teste
pode dar é uma requisição HTTP: `POST /session` abre um navegador, `POST /session/{id}/url` o manda
para um endereço, `POST /session/{id}/element` acha um elemento, `GET .../text` o lê, `DELETE
/session/{id}` o fecha. As respostas são JSON. Por ser um padrão, a mesma requisição funciona com o
`chromedriver`, com o `geckodriver` do Firefox ou com o `safaridriver` da Apple, e uma biblioteca
em qualquer linguagem consegue falá-lo. As bibliotecas do Selenium para Java, Python, C#, Ruby e
JavaScript são, cada uma, um jeito arrumado de escrever essas requisições, e nada além disso.

## O Selenium no projeto

O projeto da loja ganha uma segunda biblioteca de testes ao lado do Playwright. O `package.json`
ganha uma linha, a versão exata do `selenium-webdriver` com que estas transcrições foram gravadas.
Troque o `package.json` por este:

```json
{
  "name": "quitanda",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "node app/server.js",
    "test": "playwright test"
  },
  "devDependencies": {
    "@playwright/test": "1.56.0",
    "selenium-webdriver": "4.51.0"
  }
}
```

```
ana@laptop:~/quitanda$ npm install

added 20 packages, and audited 21 packages in 2s

1 package is looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

Isso instalou a biblioteca e, dentro dela, um pequeno programa chamado **Selenium Manager**, cujo
trabalho é achar um driver que sirva para o seu navegador e baixar um se não houver. Pergunte a ele
que driver usaria para o Chrome. O caminho abaixo é o do Linux; num Mac a pasta é `bin/macos`, e no
Windows é `bin\windows\selenium-manager.exe`:

```
ana@laptop:~/quitanda$ node_modules/selenium-webdriver/bin/linux-x86_64/selenium-manager --browser chrome --debug
[2026-10-10T19:46:58.703Z DEBUG] Sending stats to Plausible: Props { browser: "chrome", browser_version: "", os: "linux", arch: "x86_64", lang: "", selenium_version: "4.51" }
[2026-10-10T19:46:58.709Z DEBUG] Found chromedriver 141.0.7390.122 in PATH: /home/ana/bin/chromedriver
[2026-10-10T19:46:58.709Z DEBUG] Found google-chrome in PATH: /home/ana/bin/google-chrome
[2026-10-10T19:46:58.709Z DEBUG] Running command: /home/ana/bin/google-chrome --version
[2026-10-10T19:46:58.733Z DEBUG] Output: "Chromium 141.0.7390.37 "
[2026-10-10T19:46:58.735Z DEBUG] Detected browser: chrome 141.0.7390.37
[2026-10-10T19:46:58.735Z DEBUG] Discovering versions from https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json
[2026-10-10T19:46:58.737Z WARN ] Exception managing chrome: error sending request for url (https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json)
[2026-10-10T19:46:58.737Z WARN ] Error sending stats to Plausible: error sending request for url (https://plausible.io/api/event)
[2026-10-10T19:46:58.737Z INFO ] Driver path: /home/ana/bin/chromedriver
[2026-10-10T19:46:58.737Z INFO ] Browser path: /home/ana/bin/google-chrome
```

As duas últimas linhas são a resposta: um driver e um navegador. A seção 04 lê o resto dessa saída;
o que importa aqui é que agora você tem um `chromedriver` e sabe onde ele está. Na sua máquina o
caminho fica numa pasta de cache, algo como `~/.cache/selenium/chromedriver/linux64/` seguido de uma
versão; na máquina de onde vêm estas transcrições ele está no `PATH`, então basta o nome. Use o
caminho que a sua imprimiu.

## A conversa feita à mão

**Você mesmo consegue falar o protocolo com o `curl`**, e fazer isso uma vez deixa mais fácil ler
toda mensagem de erro que vier depois. São três terminais: a loja rodando no primeiro (`npm start`
em `~/quitanda`), o driver no segundo e as requisições no terceiro. No Windows, rode isto no Git
Bash, que vem com o `curl` e põe aspas do jeito das transcrições; as regras de aspas do PowerShell
estragariam o JSON.

Inicie o driver na porta que o padrão sugere:

```
ana@laptop:~/quitanda$ chromedriver --port=9515
Starting ChromeDriver 141.0.7390.122 (b477534e7e10d193e916cd4e2967c589383625b2-refs/branch-heads/7390@{#2667}) on port 9515
Only local connections are allowed.
Please see https://chromedriver.chromium.org/security-considerations for suggestions on keeping ChromeDriver safe.
[1791661614.462][SEVERE]: CreatePlatformSocket() failed: Address family not supported by protocol (97)
ChromeDriver was started successfully on port 9515.
```

A linha `SEVERE` é a máquina de onde vêm estas transcrições sem IPv6; o driver segue com IPv4, como
diz a linha seguinte. Ele agora é um servidor web, e responde em `/status` como um:

```
ana@laptop:~/quitanda$ curl -s http://localhost:9515/status
{"value":{"build":{"version":"141.0.7390.122 (b477534e7e10d193e916cd4e2967c589383625b2-refs/branch-heads/7390@{#2667})"},"message":"ChromeDriver ready for new sessions.","os":{"arch":"x86_64","name":"Linux","version":"6.18.44-fc-v114"},"ready":true}}
```

**Uma sessão é um navegador, aberto por uma requisição.** O corpo diz qual navegador e com que
opções; `--headless=new` pede ao Chrome que rode sem janela, porque a máquina de onde vêm estas
transcrições não tem tela:

```
ana@laptop:~/quitanda$ curl -s -X POST http://localhost:9515/session -H 'Content-Type: application/json' -d '{"capabilities":{"alwaysMatch":{"browserName":"chrome","goog:chromeOptions":{"args":["--headless=new"]}}}}'
{"value":{"capabilities":{"acceptInsecureCerts":false,"browserName":"chrome","browserVersion":"141.0.7390.37","chrome":{"chromedriverVersion":"141.0.7390.122 (b477534e7e10d193e916cd4e2967c589383625b2-refs/branch-heads/7390@{#2667})","userDataDir":"/tmp/.org.chromium.Chromium.4M4Wnx"},"fedcm:accounts":true,"goog:chromeOptions":{"debuggerAddress":"localhost:33389"},"networkConnectionEnabled":false,"pageLoadStrategy":"normal","platformName":"linux","proxy":{},"setWindowRect":true,"strictFileInteractability":false,"timeouts":{"implicit":0,"pageLoad":300000,"script":30000},"unhandledPromptBehavior":"dismiss and notify","webauthn:extension:credBlob":true,"webauthn:extension:largeBlob":true,"webauthn:extension:minPinLength":true,"webauthn:extension:prf":true,"webauthn:virtualAuthenticators":true},"sessionId":"e4229beaca7b1633a5c8a483e578ecc5"}}
```

Duas coisas na resposta importam. `browserVersion` diz que Chrome o driver encontrou, e `sessionId`
é a alça para tudo o que vem depois: todo endereço seguinte o leva. Cole o seu onde esta
transcrição tem o dela. Mande o navegador para a loja:

```
ana@laptop:~/quitanda$ curl -s -X POST http://localhost:9515/session/e4229beaca7b1633a5c8a483e578ecc5/url -H 'Content-Type: application/json' -d '{"url":"http://localhost:3000/"}'
{"value":null}
```

`null` é o jeito do padrão de dizer *feito, nada a relatar*. Agora ache o título do cartão Banana,
com o mesmo seletor CSS que você testaria no painel Elements:

```
ana@laptop:~/quitanda$ curl -s -X POST http://localhost:9515/session/e4229beaca7b1633a5c8a483e578ecc5/element -H 'Content-Type: application/json' -d '{"using":"css selector","value":"[data-testid=product-banana] h2"}'
{"value":{"element-6066-11e4-a52e-4f735466cecf":"f.A30DC6592F8CE9BFBB2A69D15B4FE543.d.C74D23DBB922802EA2E9E604EB4538CF.e.3"}}
```

**Um elemento volta como referência, nunca como o próprio elemento.** A string comprida debaixo
daquela chave esquisita, `element-6066-11e4-a52e-4f735466cecf`, que o padrão fixa para que nenhum
JSON da própria página seja confundido com ela, é o nome que o driver dá a um nó da página. Para
saber qualquer coisa sobre ele, você pergunta de novo:

```
ana@laptop:~/quitanda$ curl -s http://localhost:9515/session/e4229beaca7b1633a5c8a483e578ecc5/element/f.A30DC6592F8CE9BFBB2A69D15B4FE543.d.C74D23DBB922802EA2E9E604EB4538CF.e.3/text
{"value":"Banana"}
```

E feche a sessão, o que fecha o navegador:

```
ana@laptop:~/quitanda$ curl -s -X DELETE http://localhost:9515/session/e4229beaca7b1633a5c8a483e578ecc5
{"value":null}
```

## O que isso custa, e o que explica

Foram cinco idas e voltas para ler uma palavra. **Todo comando do Selenium é uma dessas
requisições**, por mais que a biblioteca disfarce: `driver.findElement(...)` é o `POST .../element`
que você acabou de digitar, e `getText()` é o `GET .../text`. Daí saem três coisas, e as aulas 9 e
10 voltam a cada uma delas.

- Um teste é uma **conversa de fora da página**. Entre duas requisições suas a página continua
  rodando, então um script pode mudá-la enquanto o teste decide o que fazer. Você viu a loja fazer
  isso na aula 1, e a aula 3 trata do que isso faz com um teste.
- A referência ao elemento pode ficar **velha** (*stale*). Ela nomeia um nó do momento em que foi
  achado. Se a página jogar esse nó fora e desenhar outro, a referência não nomeia nada, e o driver
  avisa.
- O teste e o navegador **não precisam estar na mesma máquina**. O driver só precisa de uma porta
  que o teste alcance, que é a ideia inteira do grid no fim desta aula.

Digitando à mão, os segundos entre um comando e outro bastaram para a loja buscar os produtos antes
de você pedir a banana. Um programa pergunta em milissegundos, e a próxima seção mostra o que ele
faz no lugar disso.
