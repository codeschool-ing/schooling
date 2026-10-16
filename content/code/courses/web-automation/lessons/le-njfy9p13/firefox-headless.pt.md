---
title: O Firefox sem janela
version: 1
---

**O Firefox tem um só modo headless, e nada nesta seção foi executado.** O download do Firefox do
Playwright está bloqueado na máquina em que estas aulas foram gravadas, como a aula 10 viu quando
o projeto Firefox falhou antes da primeira linha, e nenhum outro Firefox está instalado lá. O que
segue é o código que um aluno escreveria e o que a documentação do Firefox e a do Playwright dizem
que ele faz. No seu computador, `npx playwright install firefox` baixa a versão, e todo comando
daqui pode ser rodado.

Não há shell nem segundo programa para escolher. A documentação da Mozilla descreve um interruptor,
o argumento de linha de comando `-headless`, e uma variável de ambiente, `MOZ_HEADLESS=1`, que faz
o mesmo num Firefox iniciado por outro programa. O motor, o layout e a pintura são os mesmos que o
Firefox usa com janela.

## No Playwright

O Playwright trata o Firefox como trata o Chromium: headless, a não ser que se peça o contrário,
com a mesma opção `headless` e a mesma flag `--headed`. O navegador que ele inicia é a sua própria
versão modificada do Firefox, baixada para a sua versão, e não o Firefox instalado no computador.
Um lançamento difere do `modes.mjs` numa linha:

```javascript
import { firefox } from '@playwright/test';

const browser = await firefox.launch();                      // headless
const watched = await firefox.launch({ headless: false });   // a window
```

Num projeto de testes, a mesma escolha é um projeto, como o `browsers.config.js` da aula 10 tem:
`devices['Desktop Firefox']` cita o motor, e `--headed` na linha de comando dá janela a todos os
projetos. **Nenhum dos dois foi executado para este curso.**

## No Selenium

O Selenium inicia o Firefox pelo **geckodriver**, o servidor WebDriver da Mozilla, que faz o papel
que o chromedriver faz para o Chrome na aula 8. O interruptor headless é o argumento do próprio
Firefox, entregue nas opções:

```javascript
import { Builder } from 'selenium-webdriver';
import firefox from 'selenium-webdriver/firefox.js';

const options = new firefox.Options().addArguments('-headless');
const driver = await new Builder().forBrowser('firefox').setFirefoxOptions(options).build();
```

**Repare no hífen único**: `-headless` é como o Firefox escreve seus argumentos, onde o Chrome
escreve `--headless=new`. O Selenium não traduz um no outro. Montar as opções não precisa de
navegador, então isto dá para conferir aqui: o argumento vai para a capability
`moz:firefoxOptions`, ao lado de uma preferência que o Selenium define por conta própria, e é essa
capability que o geckodriver lê quando inicia o Firefox.

```
ana@laptop:~/quitanda$ node -e "import('selenium-webdriver/firefox.js').then(({ default: firefox }) => console.log(new firefox.Options().addArguments('-headless').get('moz:firefoxOptions')))"
{ prefs: { 'remote.active-protocols': 1 }, args: [ '-headless' ] }
```

Iniciar a sessão precisa do geckodriver e do Firefox, e nenhum dos dois estava disponível, então o
teste que viria depois não foi rodado. Guias antigos chamam, em vez disso, um método `headless()`
nas opções. O próprio changelog do Selenium, em `node_modules/selenium-webdriver/CHANGES.md`, o
marca como obsoleto na 4.8.0 e o remove na 4.17.0, então na 4.51.0 deste projeto essa linha dá erro.

## O que esperar quando você rodar

Duas coisas das seções sobre o Chromium valem a pena conferir no Firefox por conta própria, com uma
versão do `modes.mjs` que importe `firefox`: **a janela que o Firefox inventa sem tela** e **o que
o user agent dele diz**. Esta aula não dá as respostas, porque a única forma de sabê-las é uma
execução, e aqui nenhuma foi possível. A página adaptativa da aula 7 só lê `Mobile`, então um
Firefox de desktop recebe a página de ofertas de desktop, diga o resto da string o que disser.
