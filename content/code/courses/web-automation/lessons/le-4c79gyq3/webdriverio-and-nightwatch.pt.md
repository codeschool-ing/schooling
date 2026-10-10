---
title: WebdriverIO e Nightwatch, WebDriver com um executor
version: 1
---

O Selenium da aula 8 é uma biblioteca: ele dá um `driver` e deixa o executor, a espera e o relatório
com você. **WebdriverIO e Nightwatch são o que sai quando alguém embrulha isso num framework.** Os
dois são JavaScript, os dois chegam ao navegador por um driver WebDriver em vez de um protocolo
privado, e os dois trazem executor, arquivo de configuração e asserções próprios. Eles diferem em
quanto já foram além do WebDriver clássico.

Nenhum dos dois foi instalado nem rodado neste curso; os trechos abaixo são a forma comum de cada
ferramenta, o mesmo teste da banana da seção anterior, para você compará-los na página.

## WebdriverIO

O pacote npm dele se descreve como um "next-gen browser and mobile automation test framework for
Node.js", um framework de automação de navegador e de celular, e as duas metades são separadas: o
`webdriverio` é a biblioteca, que dá para usar num script comum, e o `@wdio/cli` é o executor, que
roda os seus testes sob um framework que você escolhe: Mocha, Jasmine ou Cucumber, cada um num
pacote `@wdio/` próprio. A versão atual é a 10.0.2, e ela pede o Node 22.19 ou posterior.

```javascript
describe('quitanda', () => {
  it('puts a banana in the basket', async () => {
    await browser.url('/');
    await $('[data-testid=product-banana] button').click();
    await expect($('[data-testid=basket-count]')).toHaveText('1');
  });
});
```

`browser`, `$` e esse `expect` são globais que o executor fornece. As asserções dele sobre um
elemento esperam e tentam de novo, bem como as do Playwright.

**O protocolo é a parte interessante.** O WebdriverIO fala o WebDriver clássico, e a documentação
dele diz que ele passa sozinho para o **WebDriver BiDi** sempre que o navegador e o driver dão
suporte; a capability `wdio:enforceWebDriverClassic` desliga isso. Então os mesmos testes que rodam
numa grade de máquinas WebDriver, ou nos navegadores de um provedor na nuvem, também podem escutar
a rede e o console da página como fazem as ferramentas de CDP. Ele também entrega um objeto
Puppeteer para o mesmo Chrome, pelo `browser.getPuppeteer()`, quando você precisa de algo que só o
CDP tem.

**Uma equipe o escolhe** quando já tem infraestrutura WebDriver, escreve JavaScript e quer um
executor moderno por cima. Aplicativos de celular são o outro motivo: o mesmo executor conduz o
Appium, assunto do `api-mobile-automation`.

## Nightwatch

O README dele o chama de "an integrated testing framework powered by Node.js and using the W3C
Webdriver API", um framework de testes integrado que usa a API WebDriver do W3C, desenvolvido na
BrowserStack, uma empresa que vende navegadores na nuvem. É o mais tudo-em-um das ferramentas
JavaScript: `npm init nightwatch@latest` faz algumas perguntas e escreve a configuração, o executor
vem embutido, e as asserções também.

```javascript
describe('quitanda', function () {
  it('puts a banana in the basket', function (browser) {
    browser
      .navigateTo('http://localhost:3000/')
      .click('[data-testid=product-banana] button')
      .assert.textEquals('[data-testid=basket-count]', '1');
  });
});
```

O estilo encadeado é a marca do Nightwatch: cada comando entra numa fila, e o executor toca a fila
em ordem. **Por baixo está o Selenium.** O pacote `nightwatch` 3.16.0 depende do
`selenium-webdriver` 4.27.0, então tudo o que a aula 8 diz sobre drivers, grades e capabilities
vale aqui também. O registro do npm mostra a versão mais recente, a 3.16.0, em 25 de maio de 2026,
e a anterior em janeiro. Vale olhar com que frequência uma ferramenta lança versões antes de
construir em cima dela.

**Uma equipe o escolhe** quando os testes dela já rodam na BrowserStack, ou quando herdou uma suíte
Nightwatch. Começando do zero, compare-o com o WebdriverIO e o Playwright pelo que o resto das suas
ferramentas já fala.
