---
title: A ordem de tabulação, capturada
version: 1
---

Uma passada manual é o teste de verdade, e tem uma fraqueza: não deixa nada para trás. **Um script
que aperta Tab e anota o que alcançou transforma a passada numa transcrição**, algo que você anexa
a um relatório de defeito, compara antes e depois de uma correção e roda de novo em todo commit. O
Playwright aperta teclas além de clicar, e a árvore de acessibilidade do painel das DevTools da
aula 13 pode ser lida por um script, então os dois juntos descrevem a ordem de tabulação como quem
usa teclado a encontra.

Em `~/a11y`, o projeto que a aula 13 montou, `nano tab.js`:

```schooling-example
{"language": "javascript", "file": "a11y/tab.js", "parts": [{"code": "// a11y/tab.js\n// Presses Tab through a page and prints every element that takes the focus,\n// named as the accessibility tree names it, and whether a focus outline shows.\n// Then tries to book a seat with the keyboard alone, and with the mouse.\nconst { chromium } = require(\"playwright\");\n\nconst url = process.argv[2] || \"http://localhost:8000/book.html\";", "note": "Um segundo programa em `~/a11y`, ao lado do `audit.js`, usando o mesmo Playwright. Ele recebe o endereço da página na linha de comando."}, {"code": "\nasync function focused(page) {\n  const here = page.locator(\":focus\");\n  if (await here.count() === 0) return null;\n  const name = (await here.ariaSnapshot()).split(\"\\n\")[0].replace(/^- /, \"\").replace(/:$/, \"\");\n  const outline = await here.evaluate(el => {\n    const s = getComputedStyle(el);\n    return s.outlineStyle !== \"none\" && parseFloat(s.outlineWidth) > 0;\n  });\n  return { name, outline };\n}", "note": "`focused` responde qual elemento está com o foco agora, nomeado como um leitor de tela o ouviria: `:focus` acha o elemento, e a primeira linha do `ariaSnapshot()` dele é o papel e o nome acessível. Ela também pergunta ao navegador se há um contorno desenhado. **Isso é um indício, não uma prova**: uma página pode mostrar o foco com um fundo ou uma sombra, e esta checagem chamaria isso de invisível. Quando ela disser *no focus outline*, olhe."}, {"code": "\nasync function result(page) {\n  await page.waitForFunction(() => document.getElementById(\"result\").textContent, null,\n                             { timeout: 2000 }).catch(() => {});\n  return (await page.textContent(\"#result\")) || \"(nothing happened)\";\n}", "note": "`result` espera até dois segundos pela resposta da reserva aparecer na página."}, {"code": "\n(async () => {\n  const browser = await chromium.launch();\n  const page = await browser.newPage();\n  await page.goto(url);\n  await page.waitForLoadState(\"networkidle\");\n\n  console.log(\"Tab order:\");\n  for (let n = 1; n <= 12; n++) {\n    await page.keyboard.press(\"Tab\");\n    const now = await focused(page);\n    if (!now) { console.log(`  ${n}. (focus left the page)`); break; }\n    console.log(`  ${n}. ${now.name}${now.outline ? \"\" : \"   <- no focus outline\"}`);\n  }", "note": "**A caminhada de Tab.** Aperta Tab, imprime o que está com o foco, até doze vezes, até o foco sair da página para os controles do próprio navegador. A lista que ela imprime é a ordem de tabulação, a sequência que quem usa teclado encontra."}, {"code": "\n  await page.reload();\n  await page.waitForLoadState(\"networkidle\");\n  await page.keyboard.press(\"Tab\");\n  if (/^link \"Skip/.test((await focused(page))?.name || \"\")) {\n    await page.keyboard.press(\"Enter\");\n    await page.keyboard.press(\"Tab\");\n    console.log(`Enter on the skip link, then Tab: ${(await focused(page)).name}`);\n  }", "note": "Numa página recém-carregada, um Tab: se a primeira coisa alcançada for um link de pular, aperta Enter nele, depois mais um Tab, e imprime para onde o foco foi. Numa página sem link de pular isto não imprime nada."}, {"code": "\n  await page.fill(\"#seat\", \"20\");\n  await page.fill(\"#customer\", \"ana\");\n  let reached = false;\n  for (let n = 0; n < 6 && !reached; n++) {\n    await page.keyboard.press(\"Tab\");\n    reached = /\"Book\"/.test((await focused(page))?.name || \"\");\n  }\n  if (reached) {\n    await page.keyboard.press(\"Enter\");\n    console.log(`Keyboard, Enter on Book: ${await result(page)}`);\n  } else {\n    console.log(\"Keyboard: Tab from the name field never reaches Book\");\n  }", "note": "**A reserva pelo teclado.** Digita um assento e um nome, depois aperta Tab até o foco chegar a algo chamado Book, no máximo seis vezes. Se chegar, aperta Enter, como faria quem usa teclado, e imprime o que a página respondeu."}, {"code": "\n  await page.fill(\"#seat\", \"21\");\n  await page.$eval(\"#result\", el => { el.textContent = \"\"; });\n  await page.getByText(\"Book\", { exact: true }).click();\n  console.log(`Mouse, click on Book: ${await result(page)}`);\n  await browser.close();\n})();", "note": "**A reserva pelo mouse**, do jeito que um teste funcional faz: um clique no texto Book, assento 21. As duas linhas lado a lado são a lição da aula."}]}
```

Rode-o contra o `book2.html`, a página que passou em toda auditoria automática da aula 13. Rode
`python3 seed.py` em `~/boxoffice` antes se quiser os mesmos números de reserva daqui.

```
ana@nft:~/a11y$ node tab.js http://localhost:8000/book2.html
Tab order:
  1. textbox "Your name"   <- no focus outline
  2. link "What's on"   <- no focus outline
  3. link "Prices"   <- no focus outline
  4. link "Access"   <- no focus outline
  5. combobox "Show"   <- no focus outline
  6. spinbutton "Seat": "1"   <- no focus outline
  7. (focus left the page)
Keyboard: Tab from the name field never reaches Book
Mouse, click on Book: Booked: seat 21, booking 295113.
```

## Lendo o resultado

**A primeira parada é o campo de nome**, no fim do formulário, antes da navegação do site e antes
dos dois campos acima dele. É o `tabindex="1"`, fazendo exatamente o que a seção anterior disse: um
valor positivo põe o elemento na frente da página inteira. Quem usa teclado e enxerga vê o foco
pular para baixo e depois voltar para os links; quem usa leitor de tela chega ao campo de nome
antes de saber que espetáculo está reservando.

**Book nem está na lista.** Depois do campo de assento o foco sai da página. A `<div>` não recebe o
foco, então não pode ser alcançada, então Enter e Espaço nem têm chance de falhar. A linha do
teclado diz isso com todas as letras, e a linha abaixo dela é o mouse reservando o mesmo assento
sem problema. Esse par de linhas é o relatório de defeito: uma tarefa, dois jeitos de fazê-la, um
deles impossível.

**Toda parada diz *no focus outline*.** O `*:focus { outline: none; }` continua valendo, e nada
mais na página desenha o foco de outro jeito. Quem usa teclado e enxerga aperta Tab nesta página e
não vê nada se mexer.

## Transformando em teste

Uma transcrição que uma pessoa lê é o primeiro passo. O segundo é uma asserção em que um pipeline
pode reprovar, e o `tab.js` já tem as peças: a lista de nomes em ordem e se o Book foi alcançado.
Escrito como teste, no executor Playwright Test que a `web-automation` usou, ele afirmaria três
coisas sobre a página de reserva:

- a ordem de tabulação é igual à lista esperada, em ordem de leitura;
- toda parada dela tem um indicador visível;
- a reserva pode ser concluída só com Tab e Enter.

A primeira é a mais valiosa e a mais frágil: ela reprova a cada link novo no cabeçalho, o que está
certo, porque alguém deve olhar a ordem sempre que ela muda. Guarde a lista esperada no teste, ao
lado de um comentário dizendo quem a aprovou.
