---
title: Projetos, e rodar em mais de um navegador
version: 1
---

Um teste passa no Chromium. **Isso não diz nada sobre o Firefox ou o Safari**: três motores
desenham, cronometram e interpretam a mesma página de jeitos um pouco diferentes, e a aula 7 de
`manual-testing` trata do que isso custa a um site. O Playwright roda uma suíte em vários deles por
meio de **projetos**: conjuntos de configurações com nome, cada um rodando todos os testes de novo.

## Uma configuração separada para isso

O `playwright.config.js` fica como a aula 1 o escreveu; todas as aulas deste curso rodam com ele.
Os navegadores vão num segundo arquivo, que importa o primeiro e acrescenta três projetos. Cada
projeto tira suas configurações de `devices`, a lista de descrições prontas do Playwright: um
tamanho de janela, um user agent e o motor a usar. Salve-o como `browsers.config.js`:

```javascript
import { defineConfig, devices } from '@playwright/test';
import base from './playwright.config.js';

// The project's own settings, run once per browser.
export default defineConfig(base, {
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
  ],
});
```

O `defineConfig` aceita mais de uma configuração e as junta em ordem, então o `testDir`, o
reporter, o `baseURL` e o `webServer` que inicia a loja vêm todos do arquivo base. Uma configuração
é escolhida com `--config`, e `--list` mostra o que ela rodaria sem rodar nada:

```
ana@laptop:~/quitanda$ npx playwright test --config browsers.config.js --list tests/smoke.spec.js
Listing tests:
  [chromium] › smoke.spec.js:3:1 › the shop opens and lists its fruit
  [firefox] › smoke.spec.js:3:1 › the shop opens and lists its fruit
  [webkit] › smoke.spec.js:3:1 › the shop opens and lists its fruit
Total: 3 tests in 1 file
```

**Um teste virou três.** Todo arquivo de teste em `tests/` se multiplica do mesmo jeito, e esse é o
preço da cobertura: uma suíte que leva quatro minutos num navegador leva uns doze em três.

## Escolhendo um projeto, e uma armadilha

`--project` escolhe um ou mais projetos pelo nome. Ele toma **toda palavra que vem depois** como
nome de projeto, então um nome de arquivo posto depois é lido como projeto:

```
ana@laptop:~/quitanda$ npx playwright test --config browsers.config.js --project chromium tests/smoke.spec.js
Error: Project(s) "tests/smoke.spec.js" not found. Available projects: "chromium", "firefox", "webkit"
    at filterProjects (/home/ana/quitanda/node_modules/playwright/lib/runner/projectUtils.js:80:11)
    at runTests (/home/ana/quitanda/node_modules/playwright/lib/program.js:217:42)
    at i.<anonymous> (/home/ana/quitanda/node_modules/playwright/lib/program.js:71:7)
```

Escreva o nome com sinal de igual, que encerra a opção, ou ponha os arquivos antes. Aqui está o
projeto Chromium sozinho, sobre o teste de fumaça e o teste de contextos da próxima seção:

```
ana@laptop:~/quitanda$ npx playwright test --config browsers.config.js --project=chromium tests/smoke.spec.js tests/contexts.spec.js

Running 5 tests using 2 workers

  ✓  1 [chromium] › tests/smoke.spec.js:3:1 › the shop opens and lists its fruit (278ms)
Ana's page reads ana
Bia's page reads null
  ✓  2 [chromium] › tests/contexts.spec.js:8:1 › two contexts share nothing in the browser (458ms)
cookies: Ana [], Bia []
Ana's total after Bia's mango: R$ 10,40
  ✓  3 [chromium] › tests/contexts.spec.js:31:1 › two shoppers, one basket: the shop's flaw (400ms)
  ✓  4 [chromium] › tests/contexts.spec.js:57:1 › the page fixture: storage written in one test (100ms)
  ✓  5 [chromium] › tests/contexts.spec.js:63:1 › the next test in the same browser starts without it (89ms)

  5 passed (2.5s)
```

O `[chromium]` na frente de cada linha é o projeto, e numa execução dos três é assim que você sabe
qual navegador falhou.

## O que o Firefox imprime quando não está lá

Os navegadores são downloads à parte, como a aula 1 descobriu com o Chromium. No seu computador,
`npx playwright install` sem argumento baixa os três, e `npx playwright install firefox webkit`
baixa os dois que esta configuração acrescenta. **Na máquina em que estas aulas foram gravadas,
esses downloads são bloqueados**, então só o Chromium está instalado, e o projeto Firefox falha
antes da primeira linha:

```
ana@laptop:~/quitanda$ npx playwright test --config browsers.config.js --project=firefox tests/smoke.spec.js

Running 1 test using 1 worker

  ✘  1 [firefox] › tests/smoke.spec.js:3:1 › the shop opens and lists its fruit (4ms)


  1) [firefox] › tests/smoke.spec.js:3:1 › the shop opens and lists its fruit ──────────────────────

    Error: browserType.launch: Executable doesn't exist at /home/ana/.cache/ms-playwright/firefox-1495/firefox/firefox
    ╔═════════════════════════════════════════════════════════════════════════╗
    ║ Looks like Playwright Test or Playwright was just installed or updated. ║
    ║ Please run the following command to download new browsers:              ║
    ║                                                                         ║
    ║     npx playwright install                                              ║
    ║                                                                         ║
    ║ <3 Playwright Team                                                      ║
    ╚═════════════════════════════════════════════════════════════════════════╝

  1 failed
    [firefox] › tests/smoke.spec.js:3:1 › the shop opens and lists its fruit ───────────────────────
```

O caminho cita `firefox-1495`: o Playwright 1.56.0 procura uma versão específica do seu Firefox
modificado, como faz com o Chromium. **Os projetos Firefox e WebKit não foram executados para este
curso**, então nenhuma transcrição aqui mostra um teste passando em nenhum dos dois. Rode
`npx playwright test --config browsers.config.js` na sua máquina depois de instalá-los e você deve
ver cada teste três vezes; quando um teste falha num motor só, a falha é o achado.

Mais duas coisas que um projeto pode escolher, segundo a documentação do Playwright.
`channel: 'chrome'` ou `channel: 'msedge'` roda o Google Chrome ou o Microsoft Edge de marca
instalado no computador em vez do Chromium do Playwright, o que importa quando os usuários de um
site usam o Chrome e um defeito só aparece lá. E `devices['Pixel 7']`, ou qualquer um dos celulares
da lista, define uma janela pequena, uma tela de toque e um user agent de celular, e indica o motor
que aquele celular usa: Chromium para um Pixel, WebKit para um iPhone. Esse é um jeito de apontar
a página adaptativa da aula 7 para um celular. Nenhum dos dois foi executado aqui.
