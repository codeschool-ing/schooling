---
title: Um processo, uma conexão, um navegador do outro lado
version: 1
---

Todo teste até aqui começou com `import { test, expect } from '@playwright/test'` e um `page` que
fazia o que mandavam. **Esse `page` não está dentro do navegador.** O seu arquivo de teste roda no
Node, num processo próprio, e o navegador é um segundo programa que o Playwright inicia ao lado.
Tudo o que o teste faz na loja atravessa de um para o outro, e o jeito como atravessa é o que faz
o Playwright se comportar diferente das duas ferramentas anteriores.

## Três jeitos de chegar a um navegador

A aula 8 comandou o mesmo Chromium com o Selenium. Lá, cada comando vira uma **requisição HTTP** a
um programa driver separado, o `chromedriver`, que o traduz para o navegador e responde quando
termina. O navegador não pode falar primeiro: um teste que quer saber se algo aconteceu precisa
perguntar, e perguntar de novo.

A aula 9 rodou o Cypress, que vai pelo caminho oposto. O teste é carregado **dentro do navegador**,
ao lado da página testada, e roda no mesmo mundo JavaScript. Nada atravessa a fronteira de um
processo, o que é rápido, e é também por isso que a própria documentação do Cypress lista uma
segunda aba entre o que ele não suporta: o teste mora numa só.

O Playwright fica entre os dois. O teste fica do lado de fora, no Node, e o Playwright mantém **uma
conexão aberta** com o navegador enquanto roda. Os comandos descem por ela; o navegador manda
**eventos** de volta sem que ninguém pergunte: uma requisição saiu, uma resposta chegou, a página
escreveu no console, um frame navegou. O `look.mjs` da aula 1 escutava exatamente esses eventos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Três jeitos de um teste chegar ao navegador. WebDriver: o teste manda uma requisição HTTP por comando a um programa driver, o chromedriver, que comanda o navegador. Cypress: o teste roda dentro do navegador, ao lado da página testada. Playwright: um processo Node mantém uma conexão com o navegador, mandando comandos e recebendo eventos; o protocolo é o CDP para o Chromium e um modificado para Firefox e WebKit.\"><text x=\"120\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">WebDriver, aula 8</text><rect x=\"40\" y=\"40\" width=\"160\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"120\" y=\"65\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o seu teste</text><path d=\"M120 80 L120 128\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M120 128 L115 119 L125 119 Z\" fill=\"var(--phosphor)\"></path><text x=\"126\" y=\"100\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma requisição HTTP</text><text x=\"126\" y=\"114\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">por comando</text><rect x=\"40\" y=\"130\" width=\"160\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"120\" y=\"152\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">um programa driver</text><text x=\"120\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">chromedriver</text><path d=\"M120 180 L120 228\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M120 228 L115 219 L125 219 Z\" fill=\"var(--phosphor)\"></path><rect x=\"40\" y=\"230\" width=\"160\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"120\" y=\"255\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o navegador</text><text x=\"360\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">Cypress, aula 9</text><rect x=\"270\" y=\"40\" width=\"180\" height=\"230\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"360\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o navegador</text><rect x=\"286\" y=\"80\" width=\"148\" height=\"60\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"360\" y=\"105\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o seu teste</text><text x=\"360\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">na mesma aba</text><rect x=\"286\" y=\"160\" width=\"148\" height=\"60\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"360\" y=\"185\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a página testada</text><text x=\"360\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a loja</text><text x=\"360\" y=\"252\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">os dois num só navegador</text><text x=\"600\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">Playwright, esta aula</text><rect x=\"510\" y=\"40\" width=\"180\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"600\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">um processo Node</text><text x=\"600\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">seu teste + Playwright</text><path d=\"M600 100 L600 168\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M600 168 L595 159 L605 159 Z\" fill=\"var(--phosphor)\"></path><path d=\"M600 100 L595 109 L605 109 Z\" fill=\"var(--phosphor)\"></path><text x=\"608\" y=\"122\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">uma conexão</text><text x=\"608\" y=\"136\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">comandos descem,</text><text x=\"608\" y=\"150\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">eventos sobem</text><rect x=\"510\" y=\"170\" width=\"180\" height=\"100\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"600\" y=\"192\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o navegador</text><text x=\"600\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">CDP</text><text x=\"600\" y=\"230\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">para o Chromium</text><text x=\"600\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">um protocolo modificado</text><text x=\"600\" y=\"263\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">para Firefox e WebKit</text></svg>", "caption": "O mesmo clique, de três jeitos. Só o Playwright mantém uma conexão aberta e ouve o que o navegador diz sem perguntar."}
```

## O que passa pela conexão

Para o Chromium, a língua dessa linha é o **Chrome DevTools Protocol**, o CDP: o protocolo que as
ferramentas de desenvolvedor da aula 1 usam para conversar com a página que inspecionam. O
Playwright imprime o que manda quando a variável `DEBUG` pede. Estes são os primeiros comandos do
teste de fumaça da aula 1:

```
%%CAP protocol-methods%%
```

Cada `SEND` é um comando com um número; a resposta do navegador volta como um `RECV` com o mesmo
número, e os eventos voltam como linhas `RECV` sem número nenhum. Contando a execução inteira:

```
%%CAP protocol-count%%
```

@@COUNT@@ O terceiro comando da lista, `Target.createBrowserContext`, vale guardar para a seção
sobre contextos: um contexto é algo que o próprio navegador oferece, e não um truque do
Playwright.

**A conexão aqui é um pipe, e não um socket de rede.** Quando o Playwright inicia o navegador ele
mesmo, entrega a ele um par de pipes e avisa isso na linha de comando:

```
%%CAP pipe%%
```

Quando o navegador roda em outro lugar, em outra máquina ou num contêiner, o Playwright o alcança
por um **WebSocket**, e a conversa é a mesma. Nenhum dos dois precisa de um programa driver no meio,
o que é uma coisa a menos para instalar e manter na versão certa do que na aula 8.

## Firefox e WebKit são builds do próprio Playwright

O CDP é do Chromium. Firefox e WebKit não o falam, então **o Playwright distribui versões
modificadas dos dois**, cada uma estendida com um protocolo que o Playwright comanda do mesmo
jeito. A documentação dele diz isso com todas as letras, e tem uma consequência que você vai
encontrar na próxima seção: `npx playwright install firefox` baixa o Firefox do Playwright, não o
Firefox em que você navega, e o WebKit é o motor de dentro do Safari, não o Safari.

**O mesmo código de teste comanda os três.** `page.click`, `expect(...).toHaveText` e o resto são
escritos uma vez; o protocolo por baixo muda conforme o navegador, e o teste nunca vê. É isso que
torna possíveis os três projetos da próxima seção com um arquivo de configuração e nenhuma mudança
em teste algum.
