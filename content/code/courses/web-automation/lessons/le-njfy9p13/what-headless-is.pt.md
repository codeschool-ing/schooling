---
title: O que um navegador faz sem janela
version: 1
---

Todos os testes deste curso até aqui rodaram em modo **headless**: o navegador inicia, carrega a
loja e fecha, e nenhuma janela aparece. A palavra sugere um navegador com alguma coisa arrancada,
e a crença comum é que essa coisa é quase todo o trabalho: que headless é buscar o HTML e lê-lo,
como faz o `curl`. **Não é. Um navegador headless interpreta a página, roda os scripts, calcula o
layout e pinta, exatamente como um navegador com janela.** O que ele deixa de fora é a tela para
onde a pintura iria.

Você já tem a prova. O teste de fumaça da aula 1 contou oito cartões, e o HTML que o servidor
manda não tem nenhum: um script os desenha depois que a página carrega, então só um navegador que
rodou o script poderia contá-los. A aula 7 mediu a linha da cesta transbordando quarenta pixels de
uma janela de 360, e só um navegador que calculou o layout saberia disso. E um screenshot, que a
aula 16 usa para diagnosticar falhas, é a cópia de pixels pintados sem tela nenhuma para mostrá-los.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"Quatro passos em fila: o HTML chega; interpretar e rodar os scripts; estilo e layout; pintar. De pintar, uma seta sobe para uma janela numa tela, que só o navegador com janela tem, e outra desce para a memória, de onde um screenshot lê. Um navegador headless faz os mesmos quatro passos.\"><rect x=\"20\" y=\"120\" width=\"150\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"95\" y=\"155\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o HTML chega</text><rect x=\"190\" y=\"120\" width=\"150\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"265\" y=\"147\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">interpretar,</text><text x=\"265\" y=\"165\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">rodar os scripts</text><rect x=\"360\" y=\"120\" width=\"150\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"435\" y=\"147\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">estilo e</text><text x=\"435\" y=\"165\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">layout</text><rect x=\"530\" y=\"120\" width=\"150\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"605\" y=\"155\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">pintar</text><path d=\"M170 150 L188 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M188 150 L179 145 L179 155 Z\" fill=\"var(--phosphor)\"></path><path d=\"M340 150 L358 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M358 150 L349 145 L349 155 Z\" fill=\"var(--phosphor)\"></path><path d=\"M510 150 L528 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M528 150 L519 145 L519 155 Z\" fill=\"var(--phosphor)\"></path><rect x=\"530\" y=\"20\" width=\"150\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-dasharray=\"5 4\"></rect><text x=\"605\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">uma janela</text><text x=\"605\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">numa tela</text><path d=\"M605 120 L605 79\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M605 79 L600 88 L610 88 Z\" fill=\"var(--phosphor)\"></path><rect x=\"530\" y=\"224\" width=\"150\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"605\" y=\"248\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">memória</text><text x=\"605\" y=\"266\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um screenshot lê daqui</text><path d=\"M605 180 L605 221\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M605 221 L610 212 L600 212 Z\" fill=\"var(--phosphor)\"></path><text x=\"20\" y=\"44\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">com janela: os cinco, e uma janela</text><text x=\"20\" y=\"260\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">headless: os mesmos quatro, e a memória</text></svg>", "caption": "O modo headless tira a última caixa e nada antes dela: a página continua sendo interpretada, executada, diagramada e pintada.", "same": ["layout"]}
```

## O que muda, então

Três coisas mudam quando a tela some, e cada uma volta nesta aula.

- **O tamanho da janela é inventado.** Um navegador com tela abre uma janela que cabe nela. Sem
  tela não há onde caber, então o navegador escolhe um tamanho, e os dois Chromiums headless
  escolhem tamanhos diferentes. O Playwright esconde isso atrás de um viewport fixo, e por isso
  quase nunca aparece; a seção sobre as diferenças que mordem é o caso em que aparece.
- **A pintura é feita por software.** Servidor, em regra, não tem placa de vídeo, e um navegador
  headless não pede uma. A máquina em que estas transcrições foram gravadas não tem placa em modo
  nenhum, então esta aula não consegue mostrar diferença nisso, e não inventa uma.
- **As fontes são as da máquina.** A folha de estilo da loja pede `system-ui, sans-serif`, ou seja,
  o que o computador chamar de fonte do sistema. Um notebook e um servidor de build sem nada
  instalado respondem com famílias diferentes, e um texto de outra largura quebra em outro lugar.
  Isso pesa mais num screenshot do que em qualquer outra coisa, e a aula 16 é sobre screenshots.

## Perguntando ao navegador o que ele é

Um script curto deixa essas diferenças à vista. Ele inicia o Chromium de um de três jeitos,
escolhido pelo argumento, e faz à página cinco perguntas que o script do próprio site poderia
fazer. Salve-o como `modes.mjs`:

```schooling-example
{"language": "javascript", "file": "modes.mjs", "parts": [{"code": "import { chromium } from '@playwright/test';\n\n// One Chromium build, three ways to start it: node modes.mjs shell|new|headed\nconst ways = {\n  shell: { headless: true },\n  new: { headless: true, channel: 'chromium' },\n  headed: { headless: false },\n};\nconst way = process.argv[2] ?? 'shell';\nconst browser = await chromium.launch(ways[way]);", "note": "O mesmo `launch()` três vezes, com opções diferentes. `headless: true` é o padrão do Playwright e está escrito só para os três se lerem iguais; `channel: 'chromium'` é o assunto da próxima seção."}, {"code": "\n// A page with no viewport of its own takes the size of the browser's window.\nconst bare = await browser.newPage({ viewport: null });\nconst own = await bare.evaluate(() => `${innerWidth}x${innerHeight}`);\nawait bare.close();", "note": "`viewport: null` desliga o tamanho emulado do Playwright, e a página mede a janela que o próprio navegador abriu. Sem tela, essa janela tem o tamanho que o navegador inventar."}, {"code": "\n// A page as Playwright's tests get it, with the default viewport.\nconst page = await browser.newPage();\nawait page.goto('http://localhost:3000/deals');", "note": "O `page` de cada teste é criado assim. A página de ofertas da aula 7 é a que lê o cabeçalho `User-Agent`, então ela mostra o que o servidor acha que este navegador é."}, {"code": "console.log(way, browser.version(), await page.evaluate((own) => ({\n  userAgent: navigator.userAgent,\n  webdriver: navigator.webdriver,\n  ownWindow: own,\n  viewport: `${innerWidth}x${innerHeight}`,\n  deals: document.querySelector('p').textContent,\n}), own));\nawait browser.close();", "note": "Cinco coisas lidas dentro da página, onde o script do próprio site as leria: o nome que o navegador dá, a marca de que um programa o está dirigindo, os dois tamanhos e o parágrafo que o servidor escolheu."}]}
```

Inicie a loja com `npm start` num terminal e rode o script em outro. Sem argumento, ou com
`shell`, ele inicia o Chromium do jeito que os testes do Playwright iniciam:

```
ana@laptop:~/quitanda$ node modes.mjs shell
shell 141.0.7390.37 {
  userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/141.0.7390.37 Safari/537.36',
  webdriver: true,
  ownWindow: '800x600',
  viewport: '1280x720',
  deals: 'Weekly deals, in a table.'
}
```

**O navegador diz o que é, duas vezes.** `HeadlessChrome` no user agent é o nome que um site lê
em toda requisição, e `webdriver: true` é a marca que um navegador levanta quando um programa o
está dirigindo, e o script de um site a lê tão fácil quanto este leu. Depois, os dois tamanhos: a
janela que o navegador inventou para si tem 800 por 600, e a página que um teste recebe tem 1280
por 720, porque o Playwright fixa esse viewport em toda página, a não ser que se peça outra coisa.
A página de ofertas da aula 7 não achou `Mobile` em lugar nenhum do user agent e mandou o
parágrafo de desktop.

Agora peça uma janela numa máquina que não tem tela:

```
ana@laptop:~/quitanda$ node modes.mjs headed 2>&1 | head -12
node:internal/modules/run_main:123
    triggerUncaughtException(
    ^

browserType.launch: Target page, context or browser has been closed
Browser logs:

╔════════════════════════════════════════════════════════════════════════════════════════════════╗
║ Looks like you launched a headed browser without having a XServer running.                     ║
║ Set either 'headless: true' or use 'xvfb-run <your-playwright-app>' before running Playwright. ║
║                                                                                                ║
║ <3 Playwright Team                                                                             ║
```

**O Chromium completo tentou abrir uma janela, não achou tela e desistiu**, e a caixa do próprio
Playwright cita as duas saídas: rodar headless, ou dar ao navegador uma tela que não existe. A
segunda é o `xvfb-run`, e a seção sobre execuções com janela num servidor trata dele.
