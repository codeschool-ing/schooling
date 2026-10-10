---
title: Puppeteer, rodando de verdade
version: 1
---

**O Puppeteer é uma biblioteca de condução e nada mais.** O README dele o chama de "a JavaScript
library which provides a high-level API to control Chrome or Firefox over the DevTools Protocol or
WebDriver BiDi": uma biblioteca JavaScript com uma API de alto nível para controlar o Chrome ou o
Firefox. Não tem executor, não tem asserções e não sabe o que é um arquivo de teste. Você escreve
um script Node, e o script faz o que diz. Ele vem do Google, das pessoas que fazem as ferramentas de
desenvolvedor do Chrome, e é aí que está a força dele. Pelo CDP ele vê tudo o que o DevTools vê, e
por isso as equipes o usam para trabalhos que nem são testes: uma captura de tela ou um PDF de uma
página, um rastro de desempenho, uma página lida por um programa. Quando ele é usado em testes, um
executor de outro lugar vai em volta dele, e a seção sobre o Jest mostra um.

## Instalando

O `package.json` do projeto agora fixa quatro ferramentas: o Playwright desde a aula 1, o
`selenium-webdriver` da aula 8, o Cypress da aula 9, e o Puppeteer. Salve-o como `package.json`:

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
    "cypress": "16.1.1",
    "puppeteer": "25.13.0",
    "selenium-webdriver": "4.51.0"
  }
}
```

e instale:

```
ana@laptop:~/quitanda$ npm install

added 212 packages, and audited 213 packages in 5s

56 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

**Na sua máquina este passo também baixa um navegador.** Como no Playwright, cada versão do
Puppeteer é feita para uma versão do Chrome, e instalá-la baixa essa versão para
`~/.cache/puppeteer`. Para a 25.13.0, o código-fonte dele indica o Chrome 155.0.8059.39. O README
avisa que alguns gerenciadores de pacotes pulam os scripts de instalação. Aí nada é baixado, a
primeira execução falha, e este comando baixa o navegador à mão:

```sh
npx puppeteer browsers install
```

**Esse download não foi feito para estas transcrições.** A máquina de onde elas vêm não alcança o
servidor, então toda execução do Puppeteer abaixo foi apontada para o Chromium 141 que o Playwright
já tinha instalado, pela variável `PUPPETEER_EXECUTABLE_PATH`. As suas execuções usam o Chrome que o
Puppeteer baixou, e a linha `browser:` mais abaixo mostra outro número.

## Uma banana, pelo Puppeteer

O script abre a loja, espera os cartões, põe uma banana na cesta e imprime quantos itens a cesta
tem. Crie uma pasta para ele com `mkdir puppeteer`. Salve-o como `puppeteer/basket.mjs`:

```schooling-example
{"language": "javascript", "file": "puppeteer/basket.mjs", "parts": [{"code": "// The shop, driven by Puppeteer: add a banana and read the basket.\nimport puppeteer from 'puppeteer';\n", "note": "Um import e nada de executor de testes: o Puppeteer é uma biblioteca, e isto é um script Node comum."}, {"code": "const address = 'http://localhost:3000/';\nawait fetch(address + 'api/reset', { method: 'POST' });\n", "note": "A cesta é uma lista só, de todo mundo, então o script a esvazia primeiro com a rota de reset da loja. O Node 22 já traz `fetch`."}, {"code": "const browser = await puppeteer.launch();\nconsole.log(`browser: ${await browser.version()}`);\nconst page = await browser.newPage();\nawait page.goto(address);\n", "note": "O `launch()` abre um Chrome sem janela e se conecta a ele por CDP. A segunda linha imprime qual navegador respondeu."}, {"code": "await page.waitForSelector('[data-testid=product-banana] button');\nawait page.click('[data-testid=product-banana] button');\n", "note": "Os cartões são desenhados pelo `app.js` depois que a página carrega. O `page.click` não espera: se o botão ainda não existe, ele lança um erro. Por isso a linha anterior espera o botão existir."}, {"code": "await page.waitForFunction(\n  () => document.querySelector('[data-testid=basket-count]').textContent === '1',\n);\n", "note": "O clique manda uma requisição, e a contagem muda quando a resposta volta. Esta função roda dentro da página, de novo e de novo, até devolver true."}, {"code": "const count = await page.$eval('[data-testid=basket-count]', (el) => el.textContent);\nconsole.log(`basket: ${count}`);\n\nawait browser.close();", "note": "O `$eval` acha o elemento e roda a função nele, dentro da página, e só o texto volta para o Node. Sem o `close()` o script nunca termina."}]}
```

Com a loja iniciada por `npm start` num terminal, rode-o em outro:

```
ana@laptop:~/quitanda$ node puppeteer/basket.mjs
browser: Chrome/141.0.7390.37
basket: 1
```

**Toda espera nesse script é escrita à mão**, e cada uma representa algo que a loja faz depois da
linha anterior. O `app.js` desenha os cartões depois que `/api/products` responde, então o script
espera o botão. A cesta muda depois que `POST /api/basket` responde, então o script espera a
contagem.

## Tire uma espera

Apague a chamada a `waitForFunction`, as três linhas dela, e rode o script cinco vezes:

```
ana@laptop:~/quitanda$ for i in 1 2 3 4 5; do node puppeteer/basket.mjs | grep basket; done
basket: 0
basket: 0
basket: 0
basket: 1
basket: 1
```

**Três execuções disseram 0 e duas disseram 1**, com o mesmo script contra a mesma loja. O clique
foi enviado todas as vezes. O que mudou entre as execuções foi se a resposta de `POST /api/basket`
já tinha voltado quando o `$eval` leu a contagem, e nesta máquina a leitura ganhou três vezes de
cinco. A sua divisão vai ser outra, e cinco a zero para qualquer lado também é possível. Um script
que acerta em algumas execuções e erra em outras é o pior que uma suíte de testes pode ter, porque
rodar de novo faz a falha parecer que sumiu.

Nada no script estava errado do jeito que um revisor perceberia: cada linha faz o que diz. O que
falta é uma linha dizendo *e agora espere a loja*. A aula 3 trata dessa corrida entre um teste e uma
página assíncrona, e a aula 13, de todas as formas de esperar por ela. Recoloque as três linhas
antes de seguir.
