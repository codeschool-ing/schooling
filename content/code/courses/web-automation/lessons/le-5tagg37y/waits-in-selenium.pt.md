---
title: Dois tipos de espera, em resumo
version: 1
---

**Um comando do Selenium pergunta uma vez.** O `findElement` manda uma requisição, o driver olha a
página como ela está naquele instante, e a resposta é um elemento ou um erro. Nada no protocolo
espera a página terminar o que os scripts dela estão fazendo. Por isso o Selenium oferece dois
jeitos de esperar, e você precisa reconhecer os dois antes de a aula 13 compará-los direito.

- Uma **espera implícita** é uma configuração da sessão:
  `driver.manage().setTimeouts({ implicit: 3000 })`. A partir dali, todo `findElement` e
  `findElements` continua procurando por até três segundos antes de desistir. Ela espera um
  elemento **existir**, e mais nada.
- Uma **espera explícita** é uma linha do teste: `driver.wait(condition, 3000)`. Ela pergunta a
  condição de novo e de novo até valer ou o tempo acabar. As condições de `until` cobrem um elemento
  existir, estar visível, ter um texto, um título mudar, e você pode escrever as suas. O teste da
  seção 03 usou duas delas.

O programa abaixo cronometra as duas contra a loja. Não é um teste, então mora como um script
comum, e com a loja rodando você o roda com `node`. Salve-o como `selenium/waits.mjs`:

```javascript
// An implicit wait and an explicit one, timed. Run it with the shop
// started: node selenium/waits.mjs
import { Builder, By, until } from 'selenium-webdriver';
import chrome from 'selenium-webdriver/chrome.js';

const options = new chrome.Options().addArguments('--headless=new');
const driver = await new Builder().forBrowser('chrome').setChromeOptions(options).build();
const timed = async (label, work) => {
  const start = Date.now();
  const result = await work();
  console.log(`${label.padEnd(36)} ${String(result).padEnd(14)} ${Date.now() - start} ms`);
};

try {
  await driver.get('http://localhost:3000/');

  await driver.manage().setTimeouts({ implicit: 3000 });
  await timed('implicit: the cards', async () =>
    (await driver.findElements(By.css('#products li'))).length);
  await timed('implicit: an element that is absent', async () =>
    (await driver.findElements(By.css('.error'))).length);

  await driver.manage().setTimeouts({ implicit: 0 });
  const toast = await driver.findElement(By.css('.toast'));
  await driver.findElement(By.css('[data-testid=product-banana] button')).click();
  await timed('explicit: the toast says', async () => {
    await driver.wait(until.elementTextIs(toast, 'Added Banana'), 3000);
    return await toast.getText();
  });
  await timed('explicit: the toast is empty again', async () => {
    await driver.wait(until.elementTextIs(toast, ''), 3000);
    return `"${await toast.getText()}"`;
  });
} finally {
  await driver.quit();
}
```

```
ana@laptop:~/quitanda$ node selenium/waits.mjs
implicit: the cards                  8              20 ms
implicit: an element that is absent  0              3036 ms
explicit: the toast says             Added Banana   22 ms
explicit: the toast is empty again   ""             2115 ms
```

Quatro linhas, quatro fatos.

**A espera implícita achou os cartões na hora**, porque eles já estavam lá. **E gastou os três
segundos inteiros num elemento ausente**, porque uma espera implícita não distingue *ainda não* de
*nunca*. Toda verificação de que algo falta, uma mensagem de erro que não deveria aparecer, custa o
tempo inteiro, em toda execução.

**A espera explícita pelo texto do aviso** voltou assim que o texto ficou certo. **A última esperou
o aviso esvaziar de novo**, o que o script da loja faz dois segundos depois de um clique, e levou
mais ou menos isso. Uma espera implícita não consegue dizer isso de jeito nenhum: o aviso nunca
deixa de existir, só o texto dele muda.

A documentação do próprio Selenium desaconselha **misturar as duas** numa sessão, porque os tempos
delas se combinam de um jeito difícil de prever; o script acima volta a espera implícita para `0`
antes das explícitas por esse motivo. Prefira esperas explícitas, escreva-as onde a página faz algo
devagar, e deixe a espera implícita no padrão, zero, que é o que os `timeouts` da sessão que você
abriu à mão na seção 02 diziam: `"implicit":0`.

O que é uma boa condição, quanto tempo esperar, e por que um teste que dorme um tempo fixo é o pior
dos três, é assunto da aula 13.
