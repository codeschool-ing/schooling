---
title: Lendo um rastro sem o visualizador
version: 1
---

O visualizador de rastros da aula 10 desenha um rastro como uma linha do tempo, uma lista de ações
e uma imagem da página em cada uma. **Ele não foi rodado para este curso**, porque abre uma janela
e a máquina em que estas aulas foram gravadas não tem tela. Isso custa pouco: um rastro é um
arquivo zip de arquivos de texto, e as linhas que explicam uma falha se acham com `unzip` e `grep`.
Fazer isso uma vez à mão também mostra de onde o visualizador tira o que desenha, o que ajuda no dia
em que ele desenhar algo em que você não acredita.

## O que há no zip

```
%%CAP trace-list%%
```

Três tipos de arquivo, e os nomes dizem qual é qual:

- **`0-trace.trace`** e **`0-trace.network`** são o lado do navegador, um objeto JSON por linha:
  as ações com seus horários, e cada requisição com sua resposta. `1-trace.*` é o mesmo para a
  fixture `request` que esvaziou a cesta antes do teste; `test.trace` são os passos do próprio
  executor de testes, hooks e fixtures incluídos.
- **`resources/`** guarda aquilo para que as linhas apontam: o HTML e a folha de estilo da página,
  os quadros `jpeg` da tela e, pelos tamanhos, três arquivos que você já conhece. 114572 bytes é o
  `video.webm`, 43452 é a captura de tela e 1510 é o contexto de erro: o rastro leva uma cópia de
  cada anexo, e é por isso que é o maior arquivo da pasta.
- **`*.stacks`** liga cada ação à linha do teste que a fez.

## Quando o clique aconteceu

Toda linha de `0-trace.trace` que inicia uma ação tem um `"type":"before"`, um `"method"` com o
nome da ação e um `"startTime"` em milissegundos, no relógio do próprio rastro:

```
%%CAP trace-actions%%
```

Toda linha de `0-trace.network` tem o endereço, o `"time"` que a requisição levou e quando ela
começou, no mesmo relógio, `"_monotonicTime"`:

```
%%CAP trace-network%%
```

Ponha as duas numa linha só. O `goto` começou em 2426.4. O `/slow/ssr.js` foi pedido em 2679.3 e
levou 1504.4 ms, então chegou em **4183.7**. O clique começou em **2690.3**, onze milissegundos
depois de o script ser pedido e **1493 ms antes de ele chegar**. A asserção começou em 2796.7 e, com
seus cinco segundos, desistiu por volta de 7797. E o arquivo de rede não tem uma quarta linha:
**nenhum `POST /api/basket` foi enviado**. O clique caiu num botão que ainda não tinha tratador, e
a requisição que mudaria o contador nunca foi feita. Das quatro histórias, sobra uma.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Uma linha do tempo do teste que falhou, tirada do rastro. A página é pedida aos 9 ms e responde em 220. O script /slow/ssr.js é pedido aos 253 ms e chega aos 1757 ms. O clique acontece aos 264 ms, 11 ms depois de o script ser pedido e quase um segundo e meio antes de ele chegar. A asserção começa aos 370 ms e desiste aos 5370 ms. Nenhum POST para /api/basket foi enviado.\"><path d=\"M170.0 34 L170.0 214\" stroke=\"var(--wire)\" stroke-dasharray=\"2 4\"></path><text x=\"170.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M265.0 34 L265.0 214\" stroke=\"var(--wire)\" stroke-dasharray=\"2 4\"></path><text x=\"265.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1000</text><path d=\"M360.0 34 L360.0 214\" stroke=\"var(--wire)\" stroke-dasharray=\"2 4\"></path><text x=\"360.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2000</text><path d=\"M455.0 34 L455.0 214\" stroke=\"var(--wire)\" stroke-dasharray=\"2 4\"></path><text x=\"455.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3000</text><path d=\"M550.0 34 L550.0 214\" stroke=\"var(--wire)\" stroke-dasharray=\"2 4\"></path><text x=\"550.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4000</text><path d=\"M645.0 34 L645.0 214\" stroke=\"var(--wire)\" stroke-dasharray=\"2 4\"></path><text x=\"645.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5000</text><text x=\"170.0\" y=\"240\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">milissegundos depois do goto</text><text x=\"20\" y=\"54\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">GET /ssr</text><text x=\"20\" y=\"86\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">GET /slow/ssr.js</text><text x=\"20\" y=\"118\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">click</text><text x=\"20\" y=\"150\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">expect</text><text x=\"20\" y=\"182\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">POST /api/basket</text><rect x=\"170.8\" y=\"42\" width=\"20.9\" height=\"16\" rx=\"2\" fill=\"var(--scan)\"></rect><rect x=\"194.0\" y=\"74\" width=\"142.9\" height=\"16\" rx=\"2\" fill=\"var(--scan)\"></rect><circle cx=\"336.9\" cy=\"82\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"346.9\" y=\"86\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">script chega, 1757 ms</text><circle cx=\"195.1\" cy=\"114\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"207.1\" y=\"118\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">clique, 264 ms</text><path d=\"M195.1 119 L195.1 206\" stroke=\"var(--amber)\" stroke-dasharray=\"3 3\"></path><rect x=\"205.2\" y=\"138\" width=\"475.0\" height=\"16\" rx=\"2\" fill=\"var(--panel)\"></rect><rect x=\"205.2\" y=\"138\" width=\"475.0\" height=\"16\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\"></rect><circle cx=\"680.2\" cy=\"146\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"670.2\" y=\"172\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">desiste, 5370 ms</text><text x=\"213.2\" y=\"182\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nunca enviado</text></svg>", "caption": "O rastro do clique que falhou, desenhado em escala. O clique acontece enquanto o script que o ouviria ainda está a caminho, e a requisição que ele deveria ter causado nunca aparece."}
```

Este é o diagnóstico da aula 6, alcançado aqui sem ler o código da página: só o rastro já diz que o
clique veio antes do script, e o conserto é esperar a página ficar pronta, como a aula 6 faz. Um
desenvolvedor que recebe este rastro em vez de *o teste é instável* tem o tempo exato para agir.

## A corrida da busca, pelo rastro

A corrida da aula 3 deixa um rastro que conta a história do mesmo jeito. O teste digita `papaya`
tecla por tecla e espera a página deixar de estar ocupada. Salve como `evidence/search.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// Fails on purpose: the search race of lesson 3. The answer to "p"
// arrives last and replaces the list.
test('typed key by key, the list settles on papaya', async ({ page }) => {
  await page.goto('/search.html');
  await page.getByLabel('Fruit').pressSequentially('papaya');
  await expect(page.locator('#results')).toHaveAttribute('aria-busy', 'false');
  await expect(page.locator('#results li')).toHaveText(['Papaya']);
});
```

```
%%CAP search-run%%
```

As seis requisições de busca, tiradas do arquivo de rede:

```
%%CAP search-network%%
```

**O arquivo lista as respostas na ordem em que terminaram**, e essa ordem é o defeito. Some cada
`time` ao seu início: a resposta a `papaya` chegou primeiro, por volta de 2208, e a resposta a `p`,
pedida primeiro, chegou por último, em **2936.0**. Agora as ações:

```
%%CAP search-actions%%
```

O primeiro `expect`, o que espera `aria-busy="false"`, começou em 2213.9; o segundo, o que lê a
lista, em **3097.3**, depois que a resposta a `p` já a tinha substituído. O rastro mostra que o
teste leu a lista 161 ms depois de a resposta velha chegar, então só podia ver três frutas. O
terminal disse *esperava Papaya, recebeu três*; o rastro diz qual resposta as colocou ali.

## O que o visualizador acrescenta

O visualizador mostra as mesmas linhas como uma linha do tempo clicável e, para cada ação, a página
como estava, reconstruída a partir dos snapshots em `resources/`, com os painéis de rede e console
da aula 1 ao lado. Isso é mais rápido que `grep` tanto no dia em que você sabe o que procura quanto
no dia em que não sabe. A documentação dele também oferece o `trace.playwright.dev`, uma página que
abre um rastro dentro do seu próprio navegador sem mandar o arquivo para lugar nenhum.
