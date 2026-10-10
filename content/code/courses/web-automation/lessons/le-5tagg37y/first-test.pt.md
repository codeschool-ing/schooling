---
title: Um primeiro teste com selenium-webdriver
version: 1
---

O teste com Selenium desta seção faz o que o teste de fumaça da aula 1 fez, e um passo a mais: abre
a loja, espera os oito cartões, põe uma banana na cesta e lê a contagem. **O Selenium não traz
executor de testes**, o que surpreende quem conheceu o Playwright primeiro. O `selenium-webdriver`
é uma biblioteca para comandar um navegador, e o executor fica à sua escolha: Mocha, Jest ou, como
aqui, o que vem embutido no Node desde a versão 18, o `node:test`, que não pede nada instalado.

Os testes com Selenium moram numa pasta própria, `selenium/`, para que o `npx playwright test`, que
lê `tests/`, nunca tente rodá-los. Crie a pasta (`mkdir ~/quitanda/selenium`) e salve isto como
`selenium/shop.test.js`:

```schooling-example
{"language": "javascript", "file": "selenium/shop.test.js", "parts": [{"code": "import { test, before, after } from 'node:test';\nimport assert from 'node:assert/strict';\nimport { Builder, By, until } from 'selenium-webdriver';\nimport chrome from 'selenium-webdriver/chrome.js';", "note": "O executor de testes do próprio Node e suas asserções, então não há mais nada a instalar. `Builder` cria um driver, `By` diz como achar um elemento, e `until` guarda as condições que uma espera explícita sabe esperar."}, {"code": "\nconst shop = 'http://localhost:3000';\nlet driver;", "note": "Ninguém inicia a loja por você: aqui não existe `webServer`. Rode `npm start` em outro terminal antes."}, {"code": "\nbefore(async () => {\n  const options = new chrome.Options().addArguments('--headless=new');\n  driver = await new Builder().forBrowser('chrome').setChromeOptions(options).build();\n});", "note": "É no `build()` que o Selenium Manager acha um driver, o driver inicia e um `POST /session` abre o Chrome. O Selenium abre uma janela por padrão; `--headless=new` é a chave do próprio Chrome para rodar sem ela. Apague esse argumento para assistir ao teste."}, {"code": "\nafter(async () => {\n  await driver?.quit();\n});", "note": "`quit()` manda o `DELETE` que encerra a sessão e fecha o navegador. Sem ele, cada execução deixa um Chrome e um driver para trás. O `?.` impede que um `build()` que falhou acrescente um segundo erro, enganoso."}, {"code": "\ntest('adding a banana puts one item in the basket', async () => {\n  await fetch(`${shop}/api/reset`, { method: 'POST' });\n  await driver.get(`${shop}/`);", "note": "A cesta é uma só para todo mundo, então o teste a esvazia primeiro. O `get()` retorna quando a página carregou, o que não diz nada sobre os produtos, que um script busca depois."}, {"code": "  const cards = await driver.wait(until.elementsLocated(By.css('#products li')), 5000);\n  assert.equal(cards.length, 8);", "note": "Uma espera explícita: perguntar de novo até existir ao menos um cartão, por até cinco segundos, e devolver o que achou."}, {"code": "\n  await driver.findElement(By.css('[data-testid=product-banana] button')).click();\n  const count = await driver.findElement(By.css('[data-testid=basket-count]'));\n  await driver.wait(until.elementTextIs(count, '1'), 5000);\n  assert.equal(await count.getText(), '1');\n});", "note": "O `click()` retorna quando o navegador despachou o clique, não quando a loja respondeu, então a contagem é esperada em vez de lida na hora. Se ela nunca disser 1, a espera lança um `TimeoutError` e o teste falha ali."}]}
```

## Rodando

A loja precisa estar rodando antes, então inicie-a num terminal com `npm start` e deixe-a lá. Em
outro, em `~/quitanda`:

```
ana@laptop:~/quitanda$ node --test --test-reporter=spec selenium/shop.test.js
✔ adding a banana puts one item in the basket (633.08805ms)
ℹ tests 1
ℹ suites 0
ℹ pass 1
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 865.904299
```

**Um teste, um sucesso.** `--test-reporter=spec` pede o relatório legível; é o que o Node imprime
num terminal de qualquer jeito, e está escrito aqui porque um terminal que não é interativo, o de um
servidor de build por exemplo, recebe o formato TAP, mais seco, se não pedir. Os 633 ms ao lado
do teste são só o teste; iniciar o Chrome aconteceu no `before`, e o `duration_ms` no pé é a
execução inteira.

Para ver uma falha, troque a contagem esperada de `'1'` para `'2'` na espera e rode de novo; depois
desfaça a troca:

```
ana@laptop:~/quitanda$ node --test --test-reporter=spec selenium/shop.test.js
✖ adding a banana puts one item in the basket (5633.567052ms)
ℹ tests 1
ℹ suites 0
ℹ pass 0
ℹ fail 1
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 5866.427682

✖ failing tests:

test at selenium/shop.test.js:18:1
✖ adding a banana puts one item in the basket (5633.567052ms)
  Error [TimeoutError]: Waiting until element text is
  Wait timed out after 5066ms
      at /home/ana/quitanda/node_modules/selenium-webdriver/lib/webdriver.js:939:22
      at process.processTicksAndRejections (node:internal/process/task_queues:105:5) {
    remoteStacktrace: ''
  }
```

A espera desistiu depois de cinco segundos, e a mensagem nomeia o tipo de condição, *element text
is*, sem o texto que ela queria nem o que encontrou. **O `driver.wait` aceita uma mensagem como
terceiro argumento**, e uma espera cuja falha você vai ler à meia-noite merece uma:
`driver.wait(until.elementTextIs(count, '1'), 5000, 'basket count never became 1')`.

## O mesmo teste, dito em Playwright

Ponha este ao lado do `tests/smoke.spec.js` da aula 1 e a diferença está quase toda no que **você**
precisa dizer e o Playwright dizia por você:

| | Playwright | Selenium com `node:test` |
|---|---|---|
| iniciar a loja | o `webServer` da configuração faz | você roda `npm start` antes |
| o navegador | a fixture `page` abre um por teste e o fecha | `build()` e `quit()`, escritos por você |
| uma janela | sem janela, a não ser que você peça `--headed` | uma janela, a não ser que você passe `--headless=new` |
| esperar | `expect(...).toHaveCount(8)` repete até ser verdade | `driver.wait(until...)`, escrito onde faz falta |
| um endereço | `page.goto('/')`, sobre a `baseURL` | o endereço inteiro, toda vez |
| navegadores | as versões que o Playwright baixa para a versão dele | os navegadores já instalados, pelos drivers deles |

**A linha da espera é a que custa.** As asserções do Playwright continuam perguntando até passar ou
estourar o tempo; um `findElement` do Selenium pergunta uma vez, e se você esquecer a espera o teste
passa numa máquina rápida e falha numa lenta. A aula 10 mostra como o Playwright faz isso, e a aula
13 trata das esperas nos dois. A última linha é uma força do Selenium, não um custo: ele comanda o
Chrome, o Firefox, o Edge ou o Safari que o usuário de fato tem, por um padrão que o fabricante de
cada navegador implementa.
