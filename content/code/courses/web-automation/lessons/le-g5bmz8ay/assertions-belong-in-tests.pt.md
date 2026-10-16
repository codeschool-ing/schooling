---
title: O page object responde, o teste julga
version: 1
---

**Um page object relata o que a página mostra; o teste decide se isso está certo.** Ponha o
julgamento dentro do page object, um método como `checkBasketHasOneItem()`, e duas coisas dão
errado. A expectativa fica escondida: o teste diz *confira a cesta*, e quem lê precisa abrir outro
arquivo para saber o que se esperava. E o método serve a um teste só: o próximo, que quer dois
itens, precisa de um segundo método ou de um parâmetro, e o page object vira aos poucos uma cópia
da suíte de testes. O artigo de Fowler sobre o padrão diz que ele prefere page objects sem
asserções.

Sobra uma decisão que parece pequena: **quando um teste precisa de um fato da página, o que o page
object devolve?** A contagem da cesta poderia voltar como número, `1`, que é o que o teste quer
dizer. Ou poderia voltar como o localizador, que é o que o `basketCount()` desta aula faz, e o
teste põe a asserção nele.

## Um número é uma foto

A aula 10 mostrou a diferença com um localizador puro: `textContent()` lido logo depois de um
clique devolveu `0`, porque a loja só redesenha a contagem quando chega a resposta do servidor,
enquanto `expect(locator).toHaveText('1')` continuou lendo até bater. Embrulhar a leitura num page
object não muda o que ela é. Este é o método tentador, como acréscimo ao fim da classe em
`pages/basket-summary.js`:

```javascript
  async itemCount() {
    return Number(await this.count.textContent());
  }
```

Em `localhost` a loja responde em poucos milissegundos, então a leitura e a resposta terminam
quase juntas e qualquer uma das duas pode ganhar: rode algumas vezes e ele passa em umas execuções
e falha em outras. Uma rede de verdade dá à resposta mais tempo para se atrasar. Os testes abaixo
fixam esse tempo, para que a corrida dê o mesmo resultado em toda execução: uma rota, como a que o
`at-load.mjs` da aula 3 usou, segura a resposta da cesta por 200 ms. Aí um teste compara o número
uma vez, e outro pede ao `expect.poll` que chame o método de novo até o número bater. Para
experimentar, ponha-os num arquivo próprio, `tests/page-object-number.spec.js`, e apague o arquivo
e o método depois:

```javascript
import { test, expect } from '@playwright/test';
import { ShopPage } from '../pages/shop-page.js';

test.beforeEach(async ({ page, request }) => {
  await request.post('/api/reset');
  // A slower network: the answer to adding a fruit arrives 200 ms late.
  await page.route('**/api/basket', async (route) => {
    if (route.request().method() === 'POST') await new Promise((ok) => setTimeout(ok, 200));
    await route.continue();
  });
});

test('the count, read as a number', async ({ page }) => {
  const shop = new ShopPage(page);
  await shop.open();
  await shop.addToBasket('banana');
  expect(await shop.basket.itemCount()).toBe(1);
});

test('the count, polled as a number', async ({ page }) => {
  const shop = new ShopPage(page);
  await shop.open();
  await shop.addToBasket('banana');
  await expect.poll(() => shop.basket.itemCount()).toBe(1);
});
```

Cinco execuções de cada:

```
ana@laptop:~/quitanda$ npx playwright test tests/page-object-number.spec.js --workers 1 --repeat-each 5 | grep -E 'passed|failed|✘|✓|Received'
  ✘   1 tests/page-object-number.spec.js:13:1 › the count, read as a number (281ms)
  ✓   2 tests/page-object-number.spec.js:20:1 › the count, polled as a number (611ms)
  ✘   3 tests/page-object-number.spec.js:13:1 › the count, read as a number (254ms)
  ✓   4 tests/page-object-number.spec.js:20:1 › the count, polled as a number (626ms)
  ✘   5 tests/page-object-number.spec.js:13:1 › the count, read as a number (252ms)
  ✓   6 tests/page-object-number.spec.js:20:1 › the count, polled as a number (591ms)
  ✘   7 tests/page-object-number.spec.js:13:1 › the count, read as a number (236ms)
  ✓   8 tests/page-object-number.spec.js:20:1 › the count, polled as a number (622ms)
  ✘   9 tests/page-object-number.spec.js:13:1 › the count, read as a number (255ms)
  ✓  10 tests/page-object-number.spec.js:20:1 › the count, polled as a number (595ms)
    Received: 0
    Received: 0
    Received: 0
    Received: 0
    Received: 0
  5 failed
  5 passed (13.4s)
```

**O número falhou cinco vezes em cinco, e toda falha recebeu `0`.** O método leu a contagem
enquanto a resposta ainda estava a caminho, e entregou ao teste uma foto do momento anterior à
chegada da banana. A versão com poll passou nas cinco, e demorou mais, por volta de 600 ms contra
250: o `expect.poll` chama a função, compara e espera entre as tentativas, então percebeu a
resposta algum tempo depois de ela chegar. Em `localhost`, sem atraso, o mesmo par é o teste
instável da aula 14, criado por um page object: vermelho em umas execuções e verde em outras, sem
ninguém mexer em nada.

Então a regra é mais estreita do que *nunca devolva um valor*. **Devolva um localizador sempre
que o teste for fazer uma asserção sobre algo que a página ainda pode estar mudando**, porque só
uma asserção sobre um localizador, ou um poll, espera pela página. Devolva um valor quando ele
estiver assentado e o teste precisar dele para fazer conta, como o Cypress precisou de `.then()`
para usar a contagem na aula 9: leia-o depois que uma asserção tiver estabelecido que a página
terminou.

## A exceção que gera discussão

Uma asserção continua aparecendo dentro de page objects, e tem defensores: **conferir que a página
é a página.** Um `open()` que termina com `await expect(heading).toBeVisible()` falha dentro dos
cinco segundos da asserção, nomeando o título que não encontrou, em vez de deixar o passo seguinte
esperar trinta segundos por um botão ausente. Fowler, que prefere nenhuma, abre espaço para este
tipo: uma conferência do que tem de ser verdade sobre a página naquele ponto. O argumento a favor é
a mensagem: uma pré-condição quebrada em `open()` é relatada onde quebrou. O argumento contra é
que o page object passa a decidir o que *carregou* quer dizer para todos os testes, inclusive para
o que conferia o que acontece quando a página não carrega.

Um caminho do meio mantém os dois lados honestos. A conferência fica uma **pré-condição** sobre
onde o teste está, nunca uma expectativa sobre o que o teste examina: um page object pode se
recusar a continuar na página errada, e não pode decidir que uma contagem de 2 está errada. Os
page objects deste curso a deixam de fora, porque o `addToBasket` já espera pelo seu botão e a
falha dele diz qual.
