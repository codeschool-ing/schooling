---
title: Quatro tipos de ferramenta, três protocolos
version: 1
---

Uma lista como a do título desta aula parece uma lista de sete rivais, cada uma um jeito de fazer
o que o Playwright faz. **Não são rivais, e duas delas nunca tocam num navegador.** Elas ficam em
camadas diferentes da mesma máquina, várias trabalham juntas num mesmo projeto, e uma nem é um
software que se instala. Pôr uma ferramenta na camada certa responde à maior parte do que você
precisa saber sobre ela antes de abrir a documentação.

## As camadas

Todo teste de navegador que você escreveu neste curso passou por quatro camadas, e o Playwright
escondeu três delas fazendo todas:

- **o executor** (o *runner*) acha os arquivos de teste, roda cada teste, impede que a falha de um
  pare os outros e imprime o relatório. `npx playwright test` é um executor. Jest, Jasmine, Mocha e
  o `node --test` do próprio Node também são;
- **as asserções** são o jeito de um teste dizer o que deveria ser verdade: `expect(count).toBe(1)`
  no Jest e no Jasmine, `assert.equal(count, 1)` no Node. Em geral vêm com o executor, e a
  diferença entre elas é quase só de grafia;
- **a biblioteca de condução** transforma o `click()` do seu código numa mensagem que o navegador
  entende. Puppeteer, `selenium-webdriver`, `webdriverio` e a biblioteca do próprio Playwright são
  esta camada;
- **o protocolo** é o formato das mensagens entre a biblioteca e o navegador, e **o navegador** é
  quem obedece.

Dois tipos de ferramenta não cabem nessa pilha. **Um framework orientado a palavras-chave**, aqui
o Robot Framework, escreve testes como linhas de palavras simples e chama uma biblioteca de
condução por baixo. **Um serviço hospedado**, aqui o QA Wolf, é uma empresa: pessoas que escrevem e
rodam os testes por você, com ferramentas próprias.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 304\" role=\"img\" aria-label=\"Quatro camadas de cima para baixo: executor e asserções, biblioteca de condução, protocolo, navegador. O Playwright Test fica sobre o Playwright, que fala CDP. Jest, Jasmine ou outro executor fica sobre o Puppeteer, que fala CDP e WebDriver BiDi. O executor do WDIO fica sobre o webdriverio, que fala WebDriver BiDi e WebDriver. O Nightwatch fica sobre o selenium-webdriver, que fala WebDriver. O Robot Framework fica sobre a SeleniumLibrary ou a biblioteca Browser; a SeleniumLibrary fala WebDriver. O QA Wolf fica à parte, como um serviço cujo pessoal escreve e roda testes Playwright. Os três protocolos chegam ao navegador.\"><text x=\"14\" y=\"58\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">executor e</text><text x=\"14\" y=\"73\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">asserções</text><text x=\"14\" y=\"122\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">biblioteca</text><text x=\"14\" y=\"137\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">de condução</text><text x=\"14\" y=\"196\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">protocolo</text><text x=\"14\" y=\"270\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">navegador</text><rect x=\"144.0\" y=\"40\" width=\"92\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"190\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Playwright Test</text><rect x=\"244.0\" y=\"40\" width=\"92\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"5 4\"></rect><text x=\"290\" y=\"59\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Jest, Jasmine</text><text x=\"290\" y=\"74\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ou outro</text><rect x=\"344.0\" y=\"40\" width=\"92\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"390\" y=\"59\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">executor WDIO</text><text x=\"390\" y=\"74\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Mocha · Jasmine</text><rect x=\"444.0\" y=\"40\" width=\"92\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"490\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Nightwatch</text><rect x=\"544.0\" y=\"40\" width=\"92\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"590\" y=\"59\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Robot</text><text x=\"590\" y=\"74\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Framework</text><rect x=\"144.0\" y=\"104\" width=\"92\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"190\" y=\"130\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Playwright</text><rect x=\"244.0\" y=\"104\" width=\"92\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"290\" y=\"130\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Puppeteer</text><rect x=\"344.0\" y=\"104\" width=\"92\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"390\" y=\"130\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">webdriverio</text><rect x=\"444.0\" y=\"104\" width=\"92\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"490\" y=\"123\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">selenium-</text><text x=\"490\" y=\"138\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">webdriver</text><rect x=\"544.0\" y=\"104\" width=\"92\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"590\" y=\"123\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">SeleniumLibrary</text><text x=\"590\" y=\"138\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ou Browser</text><path d=\"M190 84 L190 104\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M290 84 L290 104\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M390 84 L390 104\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M490 84 L490 104\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M590 84 L590 104\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"644\" y=\"40\" width=\"92\" height=\"108\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"5 4\"></rect><text x=\"690\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">QA Wolf</text><text x=\"690\" y=\"80\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um serviço:</text><text x=\"690\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o pessoal dele</text><text x=\"690\" y=\"116\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">escreve e roda</text><text x=\"690\" y=\"134\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">testes Playwright</text><rect x=\"140\" y=\"176\" width=\"190\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"235.0\" y=\"197\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">CDP</text><text x=\"235.0\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">só navegadores Chromium</text><rect x=\"345\" y=\"176\" width=\"185\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"437.5\" y=\"197\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">WebDriver BiDi</text><text x=\"437.5\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mão dupla, vários</text><rect x=\"545\" y=\"176\" width=\"195\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"642.5\" y=\"197\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">WebDriver</text><text x=\"642.5\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">todos, via um driver</text><path d=\"M190 148 L190 176\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><path d=\"M290 148 L300 176\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><path d=\"M290 148 L385 176\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><path d=\"M390 148 L415 176\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><path d=\"M390 148 L575 176\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><path d=\"M490 148 L600 176\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><path d=\"M590 148 L625 176\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><rect x=\"140\" y=\"250\" width=\"600\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"440\" y=\"275\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Chrome · Edge · Firefox · Safari</text><path d=\"M235 226 L235 250\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M437 226 L437 250\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M642 226 L642 250\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path></svg>", "caption": "Onde cada ferramenta fica. Duas coisas ficaram de fora para o desenho continuar legível: o Playwright conduz o Firefox e o WebKit por versões modificadas próprias, e a biblioteca Browser do Robot roda sobre o Playwright.", "same": ["Playwright Test", "Mocha · Jasmine", "Nightwatch", "Robot", "Framework", "Playwright", "Puppeteer", "SeleniumLibrary", "QA Wolf", "CDP", "WebDriver BiDi", "WebDriver", "Chrome · Edge · Firefox · Safari"]}
```

## Três protocolos

O protocolo decide o que uma ferramenta consegue ver, a que navegadores ela chega e quanto ela
quebra quando um navegador se atualiza. Há três em uso.

**WebDriver** é um padrão do W3C, e é o que o Selenium fala; a aula 8 desenha a arquitetura dele.
A biblioteca manda uma requisição HTTP a um programa separado, o **driver** (`chromedriver` para o
Chrome, `geckodriver` para o Firefox, `safaridriver` para o Safari), e o driver opera o navegador e
responde. Uma requisição, uma resposta. Como todo fabricante de navegador publica um driver, ele
chega a todos os navegadores. O que ele não consegue é contar algo que você não perguntou: uma
requisição que a página fez, ou uma mensagem que ela escreveu no console.

**O Chrome DevTools Protocol**, o CDP, é o que os painéis do DevTools da aula 1 usam. A biblioteca
abre um WebSocket direto para dentro do navegador, sem driver no meio, e o navegador **manda
eventos de volta** conforme acontecem: cada resposta, cada mensagem de console, cada erro. Foi assim
que o `look.mjs` da aula 1 imprimiu o painel Network. O custo é o alcance: **só navegadores baseados
no Chromium o falam**, Chrome e Edge entre eles, e ele é uma interface interna do Chrome, não um
padrão, então muda junto com o Chrome.

**WebDriver BiDi** é a resposta do W3C a essa lacuna: o alcance padronizado do WebDriver, numa
conexão de mão dupla que carrega eventos como os do CDP. Ainda é um rascunho de padrão. O Puppeteer
já o usa para conduzir o Firefox, e a documentação do WebdriverIO diz que ele passa a usá-lo
sozinho sempre que o navegador dá suporte.

## O mapa em forma de tabela

| ferramenta | tipo | linguagem | conduz o navegador com | traz um executor |
|---|---|---|---|---|
| Puppeteer | biblioteca de condução | JavaScript | CDP para o Chrome, WebDriver BiDi para o Firefox | não |
| Playwright | biblioteca e executor | JavaScript, e também Python, Java e .NET | CDP para o Chromium; versões modificadas do Firefox e do WebKit | sim |
| Selenium | biblioteca de condução | Java, Python, JavaScript, C# e outras | WebDriver, com BiDi para alguns recursos | não |
| WebdriverIO | biblioteca e executor | JavaScript | WebDriver BiDi onde dá, WebDriver no resto | sim |
| Nightwatch | framework | JavaScript | WebDriver, pelo `selenium-webdriver` | sim |
| Jest | executor e asserções | JavaScript | nenhum próprio | ele é um |
| Jasmine | executor e asserções | JavaScript | nenhum próprio | ele é um |
| Robot Framework | framework de palavras-chave | palavras-chave em texto simples, estendido em Python | uma biblioteca por baixo: Selenium ou Playwright | ele é um |
| QA Wolf | serviço | os engenheiros dele escrevem testes Playwright | o que o Playwright usa | eles rodam |

O Cypress ficou de fora de propósito. Ele roda dentro da página em vez de falar com o navegador de
fora, o que não o põe em nenhuma linha desta tabela; a aula 9 trata do que isso dá e do que custa.

**A maior parte da escolha é feita antes de alguém comparar recursos.** Uma equipe cuja aplicação é
testada em Python já tem um executor, e o Robot Framework ou o Selenium para Python cabem nele. Uma
equipe com cem testes WebDriver e uma grade de máquinas para rodá-los, como a aula 8 mostra, migra
para o WebdriverIO mais barato do que para qualquer outra coisa. Uma equipe de front-end cujos
testes unitários já rodam no Jest põe uma biblioteca de navegador dentro do Jest em vez de um
segundo executor. As seções seguintes põem cada ferramenta no mapa, e a que você roda de verdade é
o Puppeteer.
