---
title: Seis perguntas, respondidas ao contrário
version: 1
---

Digitado tecla por tecla, `papaya` são seis perguntas: `p`, `pa`, `pap`, `papa`, `papay` e
`papaya`. Elas saem com poucos milissegundos de diferença, porque um robô digita rápido, e o
servidor segura cada uma por um tempo que diminui conforme a pergunta cresce. **Então as respostas
voltam na ordem oposta à das perguntas**, e a página desenha cada uma quando ela chega. A última a
chegar é a resposta a `p`.

Ler isso no código é uma coisa; ver acontecer é o que convence, e este programa imprime tudo na
hora. Ele digita uma palavra na caixa de busca e registra três tipos de linha: uma pergunta saindo,
uma resposta chegando, e o que a lista tem cada vez que muda, com o `aria-busy` ao lado. Salve como
`race.mjs`:

```schooling-example
{"language": "javascript", "file": "race.mjs", "parts": [{"code": "// Types a word into the search page key by key and prints, as they happen,\n// each question asked, each answer, and what the page shows after it.\n// Run it with the shop started: node race.mjs [word] [ms between keys]\nimport { chromium } from '@playwright/test';\n\nconst word = process.argv[2] ?? 'papaya';\nconst delay = Number(process.argv[3] ?? 0);", "note": "A palavra e a pausa entre as teclas vêm da linha de comando. Sem nenhuma das duas, ele digita `papaya` sem pausa alguma, que é o que o Playwright faz se ninguém disser o contrário."}, {"code": "const browser = await chromium.launch();\nconst page = await browser.newPage();\nawait page.goto('http://localhost:3000/search.html');", "note": "Um navegador que ninguém observa, já na página de busca, de modo que as requisições da própria página terminaram antes de a contagem do tempo começar."}, {"code": "const start = Date.now();\nconst log = (text) => console.log(String(Date.now() - start).padStart(5) + ' ms  ' + text);\nconst query = (request) => new URL(request.url()).searchParams.get('q');\npage.on('request', (request) => {\n  if (request.url().includes('/api/search')) log(`asked    \"${query(request)}\"`);\n});\npage.on('response', (response) => {\n  if (response.url().includes('/api/search')) log(`answered \"${query(response.request())}\"`);\n});", "note": "Dois ouvintes no tráfego da página. Um imprime uma linha quando uma pergunta a `/api/search` sai, o outro quando a resposta chega, cada um com os milissegundos desde o início."}, {"code": "// Every time the list changes, the page calls shows() with what it holds.\nawait page.exposeFunction('shows', (text) => log(`  shows  ${text}`));\nawait page.evaluate(() => {\n  const results = document.querySelector('#results');\n  new MutationObserver(() => {\n    const names = [...results.children].map((li) => li.textContent);\n    window.shows(`${document.querySelector('#count').textContent}: ${names.join(', ')}`\n      + `  (aria-busy=${results.getAttribute('aria-busy')})`);\n  }).observe(results, { childList: true });\n});", "note": "Esta parte roda dentro da página. Um `MutationObserver` é um recurso do navegador que chama uma função sempre que uma parte do DOM muda; aqui, sempre que os itens da lista mudam. `page.exposeFunction` torna `shows()` chamável de dentro da página, para que a página possa avisar este programa."}, {"code": "await page.locator('#q').pressSequentially(word, { delay });\nawait page.locator('#results[aria-busy=\"false\"]').waitFor();\nawait browser.close();", "note": "`pressSequentially` digita uma tecla de cada vez, então a caixa dispara um evento `input` por tecla, como faz com uma pessoa. Depois o programa espera até a lista ter `aria-busy=\"false\"`, que é a página dizendo que nenhuma resposta está pendente."}]}
```

## Na velocidade de um robô

Com a loja iniciada, a palavra digitada sem pausa entre as teclas, que é o que o Playwright faz se
ninguém disser o contrário:

```
%%CAP race-0%%
```

Leia de cima para baixo. As seis perguntas saem antes de a primeira resposta voltar. A resposta a
`papaya` é a primeira a voltar, e a lista mostra *1 found: Papaya*, o que está certo. Mais três
respostas concordam com ela. Então chega a resposta a `pa` e a lista cresce para duas, e por último
chega a resposta a `p` e a lista para em **3 found: Papaya, Passion fruit, Pineapple**, numa caixa
que diz `papaya`. Só então o `aria-busy` volta a `false`, porque só então nenhuma resposta está
pendente.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Seis perguntas saem com poucos milissegundos de diferença: p, pa, pap, papa, papay e papaya. O servidor espera 750, 600, 450, 300, 150 e 0 milissegundos antes de responder, então a resposta a papaya chega primeiro e a resposta a p chega por último. Embaixo, o que a lista mostra: Papaya até 600 ms, depois Papaya e Passion fruit, e a partir de 750 ms três frutas, e fica assim.\"><text x=\"20\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">pergunta</text><text x=\"150\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">milissegundos depois da digitação</text><text x=\"20\" y=\"55\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">\"p\"</text><rect x=\"150\" y=\"46\" width=\"465\" height=\"10\" rx=\"2\" fill=\"var(--scan)\"></rect><circle cx=\"615\" cy=\"51\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"625\" y=\"55\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">750 ms</text><text x=\"20\" y=\"81\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">\"pa\"</text><rect x=\"150\" y=\"72\" width=\"372\" height=\"10\" rx=\"2\" fill=\"var(--scan)\"></rect><circle cx=\"522\" cy=\"77\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"532\" y=\"81\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">600 ms</text><text x=\"20\" y=\"107\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">\"pap\"</text><rect x=\"150\" y=\"98\" width=\"279\" height=\"10\" rx=\"2\" fill=\"var(--scan)\"></rect><circle cx=\"429\" cy=\"103\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"439\" y=\"107\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">450 ms</text><text x=\"20\" y=\"133\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">\"papa\"</text><rect x=\"150\" y=\"124\" width=\"186\" height=\"10\" rx=\"2\" fill=\"var(--scan)\"></rect><circle cx=\"336\" cy=\"129\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"346\" y=\"133\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">300 ms</text><text x=\"20\" y=\"159\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">\"papay\"</text><rect x=\"150\" y=\"150\" width=\"93\" height=\"10\" rx=\"2\" fill=\"var(--scan)\"></rect><circle cx=\"243\" cy=\"155\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"253\" y=\"159\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">150 ms</text><text x=\"20\" y=\"185\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">\"papaya\"</text><circle cx=\"150\" cy=\"181\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"160\" y=\"185\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0 ms</text><path d=\"M150 206 L677 206\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M150 206 L150 211\" stroke=\"var(--wire)\"></path><text x=\"150\" y=\"224\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><path d=\"M274 206 L274 211\" stroke=\"var(--wire)\"></path><text x=\"274\" y=\"224\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">200</text><path d=\"M398 206 L398 211\" stroke=\"var(--wire)\"></path><text x=\"398\" y=\"224\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">400</text><path d=\"M522 206 L522 211\" stroke=\"var(--wire)\"></path><text x=\"522\" y=\"224\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">600</text><path d=\"M646 206 L646 211\" stroke=\"var(--wire)\"></path><text x=\"646\" y=\"224\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">800</text><text x=\"20\" y=\"265\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">a lista</text><rect x=\"150\" y=\"250\" width=\"372\" height=\"22\" rx=\"3\" fill=\"var(--scan)\"></rect><text x=\"336\" y=\"265\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Papaya</text><rect x=\"522\" y=\"250\" width=\"93\" height=\"22\" rx=\"3\" fill=\"var(--wire)\"></rect><text x=\"568\" y=\"265\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">+ Passion</text><rect x=\"615\" y=\"250\" width=\"62\" height=\"22\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"646\" y=\"265\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--ink)\">3 found</text><text x=\"150\" y=\"294\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a resposta que chega por último é a que fica</text></svg>", "caption": "Seis perguntas, seis respostas na ordem inversa. A lista fica certa a maior parte do tempo e errada no fim."}
```

## Na velocidade de uma pessoa

A mesma palavra, com 200 milissegundos entre as teclas, um ritmo comum de digitação:

```
%%CAP race-200%%
```

Agora cada resposta chega antes da seguinte, porque cada pergunta saiu 200 ms depois da vizinha e é
segurada só 150 ms menos. No caminho a lista passa por três frutas e por duas, enquanto a caixa
ainda diz `papa`, e termina em *1 found: Papaya*. **Nada mudou na página; só a velocidade da
digitação.** Há mais um detalhe nessa execução: o `aria-busy` voltou a `false` uma vez no meio,
quando toda pergunta feita até ali já tinha resposta e a última tecla ainda não tinha sido
apertada.

Faça a conta para qualquer ritmo: uma tecla a cada *k* milissegundos põe a resposta da *n*-ésima
pergunta em *k*×(*n*−1) + 900 − 150×*n*, que cresce com *n* quando *k* passa de 150 e diminui quando
fica abaixo. **Mais devagar que 150 ms por tecla, o defeito nunca aparece; mais rápido, aparece
sempre.** Uma pessoa testando à mão digita no ritmo de uma pessoa e vê a resposta certa. Cole a
palavra, ou digite como um robô digita, e a outra resposta aparece.

## Contra o que um teste está

Três fatos saem dessas duas execuções, e cada uma das duas próximas seções se apoia num deles.

- **Na maior parte do tempo a página está certa.** Na velocidade de um robô a lista mostra
  *Papaya* desde a primeira resposta até a resposta a `pa` substituí-la: pela regra do servidor, de
  cerca de 0 ms a 600 ms dos 750 que a corrida dura. Um teste que olha nessa janela vê uma página
  correta.
- **O estado errado é o final.** O que olhar depois da última resposta vê três frutas, e continua
  vendo enquanto a página ficar aberta.
- **A página diz quando terminou.** O `aria-busy` é `true` da primeira tecla até a última resposta
  e `false` depois dela. É o único sinal na página que separa *a lista está certa por enquanto* de
  *a lista terminou*.
