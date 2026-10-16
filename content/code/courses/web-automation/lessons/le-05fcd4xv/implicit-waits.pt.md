---
title: A espera implícita, e onde ela para
version: 1
---

**Uma espera implícita é uma configuração da sessão do Selenium que muda uma coisa só: quanto tempo
`findElement` e `findElements` continuam procurando antes de desistir.** A aula 8 definiu uma e
mediu. Ela achou os cartões na hora, porque eles estavam lá, e gastou o tempo inteiro com um
elemento ausente, porque não sabe distinguir *ainda não* de *nunca*. Esta seção trata da parte que a
aula 8 deixou para depois: o que a espera implícita não cobre, e o que acontece quando ela encontra
uma espera explícita.

A crença comum é que a espera implícita faz o Selenium esperar *pela página*: defina dez segundos
uma vez, e cada passo espera até a página estar pronta para ele. A documentação do Selenium descreve
algo mais estreito. Nas palavras dela, a espera implícita é *"a global setting that applies to
every element location call for the entire session"*, uma configuração global que vale para toda
chamada que localiza um elemento, durante a sessão inteira. Localizar quer dizer achar. Depois que
um comando já tem o elemento, ler o texto, perguntar se ele está visível, clicar nele, tudo acontece
na hora, sem espera nenhuma, diga a configuração o que disser.

## Um botão que existe e não faz nada

A página `/ssr` da aula 6 é o caso mais claro, porque o elemento de que o teste precisa existe desde
o primeiro byte e fica inútil por um segundo e meio. Este script define uma espera implícita de
cinco segundos e usa a página duas vezes: uma confiando na espera implícita, outra com a condição
escrita no próprio localizador. Salve como `selenium/implicit.mjs`:

```schooling-example
{"language": "javascript", "file": "selenium/implicit.mjs", "parts": [{"code": "// What an implicit wait waits for, and what it does not.\n// Run it with the shop started: node selenium/implicit.mjs\nimport { Builder, By, until } from 'selenium-webdriver';\nimport chrome from 'selenium-webdriver/chrome.js';\n\nconst shop = 'http://localhost:3000';\nconst options = new chrome.Options().addArguments('--headless=new');\nconst driver = await new Builder().forBrowser('chrome').setChromeOptions(options).build();\nlet start = Date.now();\nconst say = (text) => console.log(`${String(Date.now() - start).padStart(5)} ms  ${text}`);", "note": "Um Chrome sem janela, como na aula 8, e `say()`, que imprime uma linha com os milissegundos desde `start`. Cada experimento abaixo zera `start`, então cada tempo conta a partir do próprio começo."}, {"code": "\ntry {\n  await fetch(`${shop}/api/reset`, { method: 'POST' });\n  await driver.manage().setTimeouts({ implicit: 5000 });\n  console.log('implicit wait: 5000 ms');", "note": "A cesta é esvaziada, e a espera implícita é definida uma vez para a sessão inteira: daqui em diante, todo `findElement` continua procurando por até cinco segundos."}, {"code": "\n  await driver.get(`${shop}/ssr`);\n  start = Date.now();\n  const button = await driver.findElement(By.css('[data-testid=product-banana] button'));\n  say('found the banana button');\n  await button.click();\n  const count = await driver.findElement(By.css('[data-testid=basket-count]'));\n  say(`clicked it; the basket says ${await count.getText()}`);\n  await driver.sleep(2000); // only to show that the click was lost\n  say(`two seconds later it says ${await count.getText()}`);", "note": "O primeiro experimento confia na espera implícita. Acha o botão, clica e lê a contagem. O sleep não é um jeito de testar; está ali para provar que o clique se perdeu, e não que demorou."}, {"code": "\n  await driver.get(`${shop}/ssr`);\n  start = Date.now();\n  await driver.findElement(By.css('body[data-ready=\"true\"]'));\n  say('found body[data-ready=\"true\"]');\n  await driver.findElement(By.css('[data-testid=product-banana] button')).click();\n  await driver.findElement(By.xpath('//span[@data-testid=\"basket-count\" and text()=\"1\"]'));\n  say('clicked, and found a count that says 1');", "note": "O segundo põe a condição dentro do localizador. O `<body>` só casa depois que o `ssr.js` define `data-ready`, e o XPath só casa com a contagem quando o texto dela é `1`, então achar cada um é esperar por ele."}, {"code": "\n  start = Date.now();\n  await driver.wait(until.elementLocated(By.css('.error')), 1000).catch((e) => say(e.message));\n  await driver.manage().setTimeouts({ implicit: 0 });\n  console.log('implicit wait: 0 ms');\n  start = Date.now();\n  await driver.wait(until.elementLocated(By.css('.error')), 1000).catch((e) => say(e.message));\n} finally {\n  await driver.quit();\n}", "note": "O terceiro mistura as duas: uma espera explícita de um segundo por um elemento que a loja nunca desenha, primeiro com a implícita ainda em cinco segundos, depois com ela em zero. O `catch` imprime o estouro em vez de encerrar o script."}]}
```

Com a loja rodando:

```
ana@laptop:~/quitanda$ node selenium/implicit.mjs
implicit wait: 5000 ms
   30 ms  found the banana button
  144 ms  clicked it; the basket says 0
 2162 ms  two seconds later it says 0
 1511 ms  found body[data-ready="true"]
 1683 ms  clicked, and found a count that says 1
 5044 ms  Waiting for element to be located By(css selector, .error)
Wait timed out after 5043ms
implicit wait: 0 ms
 1063 ms  Waiting for element to be located By(css selector, .error)
Wait timed out after 1063ms
```

## Lendo a saída

**A espera implícita achou o botão em 30 ms, e o clique se perdeu.** O botão está no HTML que o
servidor manda, então não havia o que esperar. O tratador dele ainda vinha a caminho, então o clique
não fez nada, e dois segundos depois a cesta ainda dizia `0`. A espera implícita fez exatamente o
trabalho dela; o trabalho é que era o errado.

**A segunda tentativa funcionou, e quem fez foi a espera implícita do mesmo jeito.**
`body[data-ready="true"]` não casa com nada até o `ssr.js` rodar, então achá-lo levou 1511 ms, mais
ou menos o tempo que o script leva para chegar. O XPath faz o mesmo com a contagem: só casa com o
`<span>` quando o texto dele é `1`. Uma condição escrita num localizador é uma condição que a espera
implícita consegue esperar. Isso cobre tudo o que um seletor sabe dizer, atributos, texto no XPath,
a posição de um elemento na árvore, e nada além: não *o texto mudou*, não *dois elementos
concordam*, não *o elemento sumiu*.

## Misturando as duas

As duas últimas linhas da saída são as que valem guardar. A documentação do Selenium põe isso como
aviso: *"Do not mix implicit and explicit waits. Doing so can cause unpredictable wait times. For
example, setting an implicit wait of 10 seconds and an explicit wait of 15 seconds could cause a
timeout to occur after 20 seconds."* Ou seja: não misture esperas implícitas e explícitas, porque os
tempos ficam imprevisíveis; uma implícita de 10 segundos com uma explícita de 15 pode estourar
depois de 20.

O script mostra uma forma disso. **Uma espera explícita de um segundo, com a implícita em cinco,
levou 5043 ms para desistir.** Com a implícita em zero, a mesma linha levou 1063 ms. O motivo está
em como as duas se encaixam. `until.elementLocated` chama `findElements`, e com uma espera implícita
definida essa única chamada não volta antes de cinco segundos. O `driver.wait` só olha o próprio
relógio entre uma chamada e outra da condição, então descobriu que o segundo dele tinha passado
quando a primeira chamada voltou, quatro segundos atrasada. O código instalado mostra isso: a espera
compara o tempo decorrido só depois de cada avaliação, e então espera 200 ms antes da próxima.

Os dois tempos não se somam de nenhum jeito fixo. Eles se intercalam, e o resultado depende de
quantas vezes a condição chama `findElements` e quando. É isso que *imprevisível* quer dizer no
aviso, e o conselho que sai dele é o que a aula 8 deu: **deixe a espera implícita no padrão, zero, e
escreva as esperas de que precisa onde precisa delas.**
