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
ana@laptop:~/quitanda$ unzip -l test-results/ssr-a-click-on-ssr-at-once/trace.zip
Archive:  test-results/ssr-a-click-on-ssr-at-once/trace.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
      579  2026-10-15 22:10   resources/src@5921d20bcda9502b03b2934047b8bcfb583299f4.txt
   106675  2026-10-15 22:10   resources/b257c4396365f6539681cc8303663e5eac455c34
     1510  2026-10-15 22:10   resources/628a1333a8dfd0f160cc4e4cb8592bb74a469b4c
    43452  2026-10-15 22:10   resources/725b004999c58a1604cdd2ee106b533de29ff6ec
    11358  2026-10-15 22:10   test.trace
     1913  2026-10-15 22:10   1-trace.trace
     1203  2026-10-15 22:10   1-trace.network
       14  2026-10-15 22:10   resources/e7e8acd9614309b836bf29744b10316e7e9ae74c.json
      142  2026-10-15 22:10   1-trace.stacks
    13105  2026-10-15 22:10   0-trace.trace
     5812  2026-10-15 22:10   0-trace.network
     2459  2026-10-15 22:10   resources/page@aa3c39622ffb7ae6bcfd9f587212f268-1792113041311.jpeg
    27130  2026-10-15 22:10   resources/page@aa3c39622ffb7ae6bcfd9f587212f268-1792113041354.jpeg
     2198  2026-10-15 22:10   resources/7bee19e04ab4993856ea04974b35e260df2b5230.html
     1240  2026-10-15 22:10   resources/39dfe74803f515f71990df1b2934669d13b07de7.css
      124  2026-10-15 22:10   0-trace.stacks
---------                     -------
   218914                     16 files
```

Três tipos de arquivo, e os nomes dizem qual é qual:

- **`0-trace.trace`** e **`0-trace.network`** são o lado do navegador, um objeto JSON por linha:
  as ações com seus horários, e cada requisição com sua resposta. `1-trace.*` é o mesmo para a
  fixture `request` que esvaziou a cesta antes do teste; `test.trace` são os passos do próprio
  executor de testes, hooks e fixtures incluídos.
- **`resources/`** guarda aquilo para que as linhas apontam: o HTML e a folha de estilo da página,
  os quadros `jpeg` da tela e, pelos tamanhos, três arquivos que você já conhece. 106675 bytes é o
  `video.webm`, 43452 é a captura de tela e 1510 é o contexto de erro: o rastro leva uma cópia de
  cada anexo, e é por isso que é o maior arquivo da pasta.
- **`*.stacks`** liga cada ação à linha do teste que a fez.

## Quando o clique aconteceu

Toda linha de `0-trace.trace` que inicia uma ação tem um `"type":"before"`, um `"method"` com o
nome da ação e um `"startTime"` em milissegundos, no relógio do próprio rastro:

```
ana@laptop:~/quitanda$ unzip -p test-results/ssr-a-click-on-ssr-at-once/trace.zip 0-trace.trace | grep '"type":"before"' | grep -o '"method":"[a-zA-Z]*"\|"startTime":[0-9.]*' | paste - -
"startTime":2109.897	"method":"newPage"
"startTime":2149.969	"method":"goto"
"startTime":2191.589	"method":"click"
"startTime":2281.868	"method":"expect"
```

Toda linha de `0-trace.network` tem o endereço, o `"time"` que a requisição levou e quando ela
começou, no mesmo relógio, `"_monotonicTime"`:

```
ana@laptop:~/quitanda$ unzip -p test-results/ssr-a-click-on-ssr-at-once/trace.zip 0-trace.network | grep -o '"url":"[^"]*"\|"time":[0-9.]*\|"_monotonicTime":[0-9.]*' | paste - - -
"time":5.396000000000001	"url":"http://localhost:3000/ssr"	"_monotonicTime":2157.931
"time":5.26	"url":"http://localhost:3000/style.css"	"_monotonicTime":2169.836
"time":1504.583	"url":"http://localhost:3000/slow/ssr.js"	"_monotonicTime":2178.162
```

Ponha as duas numa linha só. O `goto` começou em 2150.0. O `/slow/ssr.js` foi pedido em 2178.2 e
levou 1504.6 ms, então chegou em **3682.8**. O clique começou em **2191.6**, treze milissegundos
depois de o script ser pedido e **1491 ms antes de ele chegar**. A asserção começou em 2281.9 e, com
seus cinco segundos, desistiu por volta de 7282. E o arquivo de rede não tem uma quarta linha:
**nenhum `POST /api/basket` foi enviado**. O clique caiu num botão que ainda não tinha tratador, e
a requisição que mudaria o contador nunca foi feita. Das quatro histórias, sobra uma.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Uma linha do tempo do teste que falhou, tirada do rastro. A página é pedida aos 8 ms e responde em 5. O script /slow/ssr.js é pedido aos 28 ms e chega aos 1533 ms. O clique acontece aos 42 ms, 13 ms depois de o script ser pedido e quase um segundo e meio antes de ele chegar. A asserção começa aos 132 ms e desiste aos 5132 ms. Nenhum POST para /api/basket foi enviado.\"><path d=\"M170.0 33 L170.0 39\" stroke=\"var(--wire)\"></path><text x=\"170.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M265.0 33 L265.0 39\" stroke=\"var(--wire)\"></path><text x=\"265.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1000</text><path d=\"M360.0 33 L360.0 39\" stroke=\"var(--wire)\"></path><text x=\"360.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2000</text><path d=\"M455.0 33 L455.0 39\" stroke=\"var(--wire)\"></path><text x=\"455.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3000</text><path d=\"M550.0 33 L550.0 39\" stroke=\"var(--wire)\"></path><text x=\"550.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4000</text><path d=\"M645.0 33 L645.0 39\" stroke=\"var(--wire)\"></path><text x=\"645.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5000</text><text x=\"170.0\" y=\"240\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">milissegundos depois do goto</text><text x=\"20\" y=\"54\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">GET /ssr</text><text x=\"20\" y=\"86\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">GET /slow/ssr.js</text><text x=\"20\" y=\"118\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">click</text><text x=\"20\" y=\"150\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">expect</text><text x=\"20\" y=\"182\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">POST /api/basket</text><rect x=\"170.8\" y=\"42\" width=\"2\" height=\"16\" rx=\"2\" fill=\"var(--scan)\"></rect><rect x=\"172.7\" y=\"74\" width=\"142.9\" height=\"16\" rx=\"2\" fill=\"var(--scan)\"></rect><circle cx=\"315.6\" cy=\"82\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"325.6\" y=\"86\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">script chega, 1533 ms</text><circle cx=\"174.0\" cy=\"114\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"186.0\" y=\"118\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">clique, 42 ms</text><path d=\"M174.0 119 L174.0 206\" stroke=\"var(--amber)\" stroke-dasharray=\"3 3\"></path><rect x=\"182.5\" y=\"138\" width=\"475.0\" height=\"16\" rx=\"2\" fill=\"var(--panel)\"></rect><rect x=\"182.5\" y=\"138\" width=\"475.0\" height=\"16\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\"></rect><circle cx=\"657.5\" cy=\"146\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"647.5\" y=\"172\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">desiste, 5132 ms</text><text x=\"190.5\" y=\"182\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nunca enviado</text></svg>", "caption": "O rastro do clique que falhou, desenhado em escala. O clique acontece enquanto o script que o ouviria ainda está a caminho, e a requisição que ele deveria ter causado nunca aparece."}
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
ana@laptop:~/quitanda$ npx playwright test --config evidence.config.js evidence/search.spec.js

Running 1 test using 1 worker

  ✘  1 evidence/search.spec.js:5:1 › typed key by key, the list settles on papaya (6.2s)
```

As seis requisições de busca, tiradas do arquivo de rede:

```
ana@laptop:~/quitanda$ unzip -p test-results/search-*/trace.zip 0-trace.network | grep -o '"url":"[^"]*search?[^"]*"\|"time":[0-9.]*\|"_monotonicTime":[0-9.]*' | paste - - - | grep search
"time":6.488	"url":"http://localhost:3000/api/search?q=papaya"	"_monotonicTime":2331.021
"time":156.255	"url":"http://localhost:3000/api/search?q=papay"	"_monotonicTime":2319.92
"time":304.797	"url":"http://localhost:3000/api/search?q=papa"	"_monotonicTime":2317.998
"time":455.45799999999997	"url":"http://localhost:3000/api/search?q=pap"	"_monotonicTime":2313.911
"time":602.719	"url":"http://localhost:3000/api/search?q=pa"	"_monotonicTime":2309.842
"time":754.2520000000001	"url":"http://localhost:3000/api/search?q=p"	"_monotonicTime":2305.811
```

**O arquivo lista as respostas na ordem em que terminaram**, e essa ordem é o defeito. Some cada
`time` ao seu início: a resposta a `papaya` chegou primeiro, por volta de 2338, e a resposta a `p`,
pedida primeiro, chegou por último, em **3060.1**. Agora as ações:

```
ana@laptop:~/quitanda$ unzip -p test-results/search-*/trace.zip 0-trace.trace | grep '"type":"before"' | grep -o '"method":"[a-zA-Z]*"\|"startTime":[0-9.]*' | paste - -
"startTime":2144.525	"method":"newPage"
"startTime":2200.275	"method":"goto"
"startTime":2254.442	"method":"type"
"startTime":2342.834	"method":"expect"
"startTime":3238.033	"method":"expect"
```

O primeiro `expect`, o que espera `aria-busy="false"`, começou em 2342.8; o segundo, o que lê a
lista, em **3238.0**, depois que a resposta a `p` já a tinha substituído. O rastro mostra que o
teste leu a lista 178 ms depois de a resposta velha chegar, então só podia ver três frutas. O
terminal disse *esperava Papaya, recebeu três*; o rastro diz qual resposta as colocou ali.

## O que o visualizador acrescenta

O visualizador mostra as mesmas linhas como uma linha do tempo clicável e, para cada ação, a página
como estava, reconstruída a partir dos snapshots em `resources/`, com os painéis de rede e console
da aula 1 ao lado. Isso é mais rápido que `grep` tanto no dia em que você sabe o que procura quanto
no dia em que não sabe. A documentação dele também oferece o `trace.playwright.dev`, uma página que
abre um rastro dentro do seu próprio navegador sem mandar o arquivo para lugar nenhum.
