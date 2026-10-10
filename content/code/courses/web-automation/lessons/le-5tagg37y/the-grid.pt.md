---
title: O grid: um endereço, muitos navegadores
version: 1
---

A seção 02 terminou no fato de que um driver é só uma porta, e o teste só precisa alcançá-la. O
**Selenium Grid** é esse fato transformado em serviço: um endereço que aceita requisições WebDriver
e entrega cada sessão nova a um navegador numa de muitas máquinas. Uma equipe usa um para rodar a
mesma suíte no Chrome no Linux, no Edge no Windows e no Safari num Mac sem ter os três em cada mesa,
ou para rodar muitas sessões ao mesmo tempo, que é o assunto da aula 19.

A crença comum é que o grid é um modo especial do teste, com API própria. **Para o teste ele é só
mais um driver.** Fala o mesmo protocolo na própria porta, a 4444, e a única linha que muda no teste
é para onde o builder manda as requisições:

```javascript
driver = await new Builder()
  .forBrowser('chrome')
  .setChromeOptions(options)
  .usingServer('http://localhost:4444')
  .build();
```

O `selenium-webdriver` também lê o mesmo endereço de uma variável de ambiente,
`SELENIUM_REMOTE_URL`, e é assim que a execução abaixo aponta o `selenium/shop.test.js` intacto
para um grid sem editá-lo.

## O que tem dentro

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Testes à esquerda mandam requisições WebDriver para um único endereço, a porta 4444. Dentro do grid, quatro partes: o roteador recebe toda requisição; a fila de sessões guarda os pedidos de sessão nova; o distribuidor casa cada um com uma vaga livre num nó; o mapa de sessões lembra que nó guarda cada sessão. À direita, três nós em três máquinas, cada um com seus navegadores e drivers: Chrome num, Firefox e Edge noutro, Safari no terceiro.\"><rect x=\"20\" y=\"130\" width=\"130\" height=\"70\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"85\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">seus testes</text><text x=\"85\" y=\"182\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">qualquer máquina</text><path d=\"M155 165 L225 165\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M225 165 L215 159 L215 171 Z\" fill=\"var(--phosphor)\"></path><text x=\"190\" y=\"152\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">:4444</text><rect x=\"230\" y=\"30\" width=\"220\" height=\"270\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"340\" y=\"54\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">o hub</text><rect x=\"246\" y=\"70\" width=\"188\" height=\"46\" rx=\"4\" fill=\"var(--scan)\"></rect><text x=\"340\" y=\"90\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">roteador</text><text x=\"340\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">toda requisição entra aqui</text><rect x=\"246\" y=\"126\" width=\"188\" height=\"46\" rx=\"4\" fill=\"var(--scan)\"></rect><text x=\"340\" y=\"146\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">fila de sessões</text><text x=\"340\" y=\"163\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sessões novas esperam a vez</text><rect x=\"246\" y=\"182\" width=\"188\" height=\"46\" rx=\"4\" fill=\"var(--scan)\"></rect><text x=\"340\" y=\"202\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">distribuidor</text><text x=\"340\" y=\"219\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">escolhe um nó com vaga livre</text><rect x=\"246\" y=\"238\" width=\"188\" height=\"46\" rx=\"4\" fill=\"var(--scan)\"></rect><text x=\"340\" y=\"258\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">mapa de sessões</text><text x=\"340\" y=\"275\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">que nó guarda que sessão</text><rect x=\"530\" y=\"40\" width=\"170\" height=\"70\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"615\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">nó · Linux</text><text x=\"615\" y=\"88\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Chrome · Chrome</text><path d=\"M455 75 L525 75\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M525 75 L515 69 L515 81 Z\" fill=\"var(--amber)\"></path><rect x=\"530\" y=\"130\" width=\"170\" height=\"70\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"615\" y=\"156\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">nó · Windows</text><text x=\"615\" y=\"178\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Firefox · Edge</text><path d=\"M455 165 L525 165\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M525 165 L515 159 L515 171 Z\" fill=\"var(--amber)\"></path><rect x=\"530\" y=\"220\" width=\"170\" height=\"70\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"615\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">nó · macOS</text><text x=\"615\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Safari</text><path d=\"M455 255 L525 255\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M525 255 L515 249 L515 261 Z\" fill=\"var(--amber)\"></path><text x=\"490\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cada nó: navegadores + drivers</text></svg>", "caption": "Um endereço na frente de muitos navegadores. O teste pede um navegador pelas capacidades e nunca sabe que máquina recebeu.", "same": ["Chrome · Chrome", "Firefox · Edge", "Safari"]}
```

O Selenium Grid 4 é um punhado de partes, e os nomes delas aparecem no registro, então vale
conhecê-las:

- o **roteador** (*router*) é o endereço. Toda requisição entra por ele, e ele encaminha cada uma:
  uma sessão nova para a fila, um comando de uma sessão existente para o nó que a guarda;
- a **fila de sessões** (*session queue*) guarda os pedidos de sessão nova, em ordem, até alguém
  poder atendê-los;
- o **distribuidor** (*distributor*) conhece todos os nós e as **vagas** (*slots*) livres deles, e
  entrega cada pedido da fila a um nó cujas vagas batem com as capacidades pedidas,
  `browserName: chrome` por exemplo;
- o **mapa de sessões** (*session map*) lembra que nó guarda que sessão;
- um **nó** (*node*) é uma máquina com navegadores e drivers. Ele inicia uma sessão quando recebe
  uma, e dali em diante o roteador manda os comandos daquela sessão direto para ele.

Essas partes podem rodar como processos separados em máquinas separadas, que é como se monta um
grid grande. O modo `hub` põe as quatro primeiras num processo, e cada máquina se junta a ele no
modo `node`. **O modo `standalone` põe todas elas, e um nó, num processo só**, que é o que você roda
num computador para ver como funciona.

## Um grid no seu computador

O grid é um programa Java, então precisa de Java; este rodou no OpenJDK 21:

```
ana@laptop:~$ java -version
openjdk version "21.0.12.1" 2026-08-18
OpenJDK Runtime Environment (build 21.0.12.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 21.0.12.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
```

Baixe o `selenium-server-4.51.0.jar` das versões do projeto Selenium no GitHub, o arquivo da versão
`selenium-4.51.0`, para a sua pasta pessoal, e inicie-o num terminal só dele:

```
ana@laptop:~$ java -jar selenium-server-4.51.0.jar standalone
16:47:19.454 INFO [LoggingOptions.configureLogEncoding] - Using the system default encoding
16:47:19.463 INFO [OpenTelemetryTracer.createTracer] - Using OpenTelemetry for tracing
16:47:21.125 INFO [NodeOptions.getSessionFactories] - Detected 4 available processors
16:47:21.127 INFO [NodeOptions.discoverDrivers] - Looking for existing drivers on the PATH.
16:47:21.127 INFO [NodeOptions.discoverDrivers] - Add '--selenium-manager true' to the startup command to setup drivers automatically.
16:47:21.855 WARN [SeleniumManager.lambda$runCommand$0] - Unable to discover proper msedgedriver version in offline mode
16:47:21.864 WARN [SeleniumManager.lambda$runCommand$0] - Unable to discover proper geckodriver version in offline mode
16:47:21.878 INFO [NodeOptions.report] - Adding Chrome for {"browserName": "chrome","platformName": "linux"} 4 times
16:47:21.878 INFO [NodeOptions.report] - Adding Edge for {"browserName": "MicrosoftEdge","platformName": "linux"} 4 times
16:47:21.879 INFO [NodeOptions.report] - Adding Firefox for {"browserName": "firefox","platformName": "linux"} 4 times
16:47:21.914 INFO [Node.<init>] - Binding additional locator mechanisms: relative
16:47:21.938 INFO [LocalGridModel.setAvailability] - Switching Node 31bec0f4-8210-436d-8fea-123ca3a28dd4 (uri: http://192.0.2.2:4444) from DOWN to UP
16:47:21.938 INFO [LocalNodeRegistry.add] - Added node 31bec0f4-8210-436d-8fea-123ca3a28dd4 at http://192.0.2.2:4444. Health check every 120s
16:47:22.191 INFO [Standalone.execute] - Started Selenium Standalone 4.51.0 (revision 35c5fab 35c5fab4a58fa5878edb255eb7747b04ca51a015): http://192.0.2.2:4444
```

Leia de cima para baixo. O nó achou 4 processadores, procurou drivers no `PATH` e ofereceu 4 vagas
para cada navegador que achou que conseguia comandar. A última linha dá o endereço. A quinta linha
importa na sua máquina: o seu `chromedriver` está no cache do Selenium Manager, não no `PATH`, então
inicie o grid com a opção que essa linha sugere, `--selenium-manager true`, e o nó prepara os drivers
sozinho. Essa variante não foi rodada para estas transcrições. **Ele ofereceu também Firefox e Edge,
e nenhum dos dois está instalado nesta máquina**: o Selenium Manager não conseguiu conferi-los sem
internet, e o nó ofereceu as vagas mesmo assim. Uma vaga é uma promessa do nó, não um navegador que
alguém conferiu. O endereço no registro é o endereço de rede da máquina; `localhost:4444` chega ao
mesmo servidor.

Com a loja rodando em outro terminal, rode o mesmo teste pelo grid:

```
ana@laptop:~/quitanda$ SELENIUM_REMOTE_URL=http://localhost:4444 node --test --test-reporter=spec selenium/shop.test.js
✔ adding a banana puts one item in the basket (1371.514675ms)
ℹ tests 1
ℹ suites 0
ℹ pass 1
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 1630.977142
```

Passou, e o terminal do grid imprimiu a história daquela sessão enquanto ela acontecia:

```
16:47:22.894 INFO [LocalDistributor.newSession] - Session request received by the Distributor: 
 [Capabilities {browserName: chrome, goog:chromeOptions: {args: [--headless=new]}, se:remoteUrl: http://localhost:4444}]
16:47:22.900 INFO [LocalNode.newSession] - Not using file system: desiredCapabilities=Capabilities {browserName: chrome, goog:chromeOptions: {args: [--headless=new]}, se:remoteUrl: http://localhost:4444}
16:47:22.960 WARN [SeleniumManager.lambda$runCommand$0] - Exception managing chrome: error sending request for url (https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json)
16:47:22.961 WARN [SeleniumManager.lambda$runCommand$0] - Error sending stats to Plausible: error sending request for url (https://plausible.io/api/event)
16:47:23.624 INFO [LocalNode.newSession] - Session created by the Node. Id: f2ec5ac844c186189c52f5d32461a884, Caps: {acceptInsecureCerts=false, browserName=chrome, browserVersion=141.0.7390.37, chrome={chromedriverVersion=141.0.7390.122 (b477534e7e10d193e916cd4e2967c589383625b2-refs/branch-heads/7390@{#2667}), userDataDir=/tmp/.org.chromium.Chromium.rDkWaQ}, fedcm:accounts=true, goog:chromeOptions={debuggerAddress=localhost:36641}, networkConnectionEnabled=false, pageLoadStrategy=normal, platformName=linux, proxy=Proxy(), se:bidiEnabled=false, se:cdp=ws://localhost:4444/session/f2ec5ac844c186189c52f5d32461a884/se/cdp, se:cdpVersion=141.0.7390.37, setWindowRect=true, strictFileInteractability=false, timeouts={implicit=0, pageLoad=300000, script=30000}, unhandledPromptBehavior=dismiss and notify, webauthn:extension:credBlob=true, webauthn:extension:largeBlob=true, webauthn:extension:minPinLength=true, webauthn:extension:prf=true, webauthn:virtualAuthenticators=true}
16:47:23.635 INFO [LocalSessionMap.add] - Added session to local Session Map, Id: f2ec5ac844c186189c52f5d32461a884, Node: http://192.0.2.2:4444
16:47:23.637 INFO [LocalDistributor.newSession] - Session created by the Distributor. Id: f2ec5ac844c186189c52f5d32461a884 
 Caps: {acceptInsecureCerts=false, browserName=chrome, browserVersion=141.0.7390.37, chrome={chromedriverVersion=141.0.7390.122 (b477534e7e10d193e916cd4e2967c589383625b2-refs/branch-heads/7390@{#2667}), userDataDir=/tmp/.org.chromium.Chromium.rDkWaQ}, fedcm:accounts=true, goog:chromeOptions={debuggerAddress=localhost:36641}, networkConnectionEnabled=false, pageLoadStrategy=normal, platformName=linux, proxy=Proxy(), se:bidiEnabled=false, se:cdp=ws://localhost:4444/session/f2ec5ac844c186189c52f5d32461a884/se/cdp, se:cdpVersion=141.0.7390.37, setWindowRect=true, strictFileInteractability=false, timeouts={implicit=0, pageLoad=300000, script=30000}, unhandledPromptBehavior=dismiss and notify, webauthn:extension:credBlob=true, webauthn:extension:largeBlob=true, webauthn:extension:minPinLength=true, webauthn:extension:prf=true, webauthn:virtualAuthenticators=true}
16:47:24.108 INFO [LocalNode.stopTimedOutSession] - Session id f2ec5ac844c186189c52f5d32461a884 is stopping on demand...
16:47:24.109 INFO [SessionSlot.stop] - Stopping session f2ec5ac844c186189c52f5d32461a884 (reason: QUIT_COMMAND)
16:47:24.109 INFO [SessionSlot.stop] - Session stopped successfully: f2ec5ac844c186189c52f5d32461a884
16:47:24.112 INFO [LocalSessionMap.removeWithReason] - Deleted session from local Session Map, Id: f2ec5ac844c186189c52f5d32461a884, Node: http://192.0.2.2:4444, Reason: session closed normally (QUIT command)
16:47:24.113 INFO [LocalGridModel.release] - Releasing slot for session id f2ec5ac844c186189c52f5d32461a884
```

O **distribuidor** recebeu um pedido de `browserName: chrome`, o **nó** criou a sessão, o **mapa de
sessões** registrou que nó ficou com ela, e quando o teste chamou `quit()` a vaga foi liberada para o
próximo pedido. Nada no teste soube que isso aconteceu.

**Uma coisa muda quando o nó é outra máquina:** o `localhost` no `driver.get()` do teste é resolvido
pelo navegador, no nó, onde não há loja nenhuma rodando. Num grid de verdade, a aplicação sob teste
precisa de um endereço que os nós alcancem. Pare o grid com Ctrl+C quando terminar.
