---
title: O que uma ferramenta encontra
version: 1
---

O **axe** é um mecanismo de código aberto que testa uma página contra os critérios da WCAG que uma máquina
consegue decidir. O script abaixo abre o loanbook no Chromium em duas larguras, roda o axe com as regras A
e AA da WCAG, e também confere se a página rola para o lado:

```schooling-example
{"language": "javascript", "file": "axe-check.mjs", "parts": [{"code": "// Open the page in Chromium at two widths and print what axe finds.\nimport { chromium } from 'playwright';\nimport { AxeBuilder } from '@axe-core/playwright';\n\nconst url = process.argv[2] || 'http://127.0.0.1:8000/';\nconst browser = await chromium.launch();", "note": "Duas bibliotecas: o Playwright dirige um Chromium de verdade, e o `@axe-core/playwright` roda o axe dentro da página aberta."}, {"code": "for (const width of [1280, 320]) {\n  const context = await browser.newContext({ viewport: { width, height: 800 } });\n  const page = await context.newPage();\n  await page.goto(url);\n  await page.waitForSelector('#items tr');", "note": "A mesma página numa largura de desktop e em 320 pixels. Espera a primeira linha da tabela, porque a lista é desenhada por JavaScript depois que a página carrega, e verificar antes disso seria verificar uma tabela vazia."}, {"code": "  const { violations } = await new AxeBuilder({ page })\n    .withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa'])\n    .analyze();", "note": "Só as regras A e AA da WCAG, até a 2.2, que é o nível que esta aula chama de piso. O axe também tem regras de boas práticas; são úteis, e não são o padrão."}, {"code": "  const sideways = await page.evaluate(\n    () => document.documentElement.scrollWidth > window.innerWidth);\n  console.log(`${width}px: ${violations.length} problem(s)` +\n    (sideways ? ', and the page scrolls sideways' : ''));\n  for (const v of violations) {\n    console.log(`  ${v.id}: ${v.nodes.length} element(s). ${v.help}`);\n  }\n  await context.close();\n}\nawait browser.close();", "note": "Rolagem lateral não é regra do axe, então o script confere por conta própria: um documento mais largo que a janela rola. Depois uma linha por problema, com quantos elementos o têm."}]}
```

Essas verificações não rodaram no laboratório, que não tem navegador; rodaram na máquina que gravou o
curso, contra o mesmo loanbook construído pelo `lab.sh`. Aqui está a página no passo 10, **antes** do commit
de acessibilidade:

```
$ node axe-check.mjs
1280px: 0 problem(s)
320px: 1 problem(s), and the page scrolls sideways
  target-size: 1 element(s). All touch targets must be 24px large, or leave sufficient space
```

Em 1280 pixels, nada. Em 320, um problema, um alvo de toque menor que 24 pixels, e a página rola para o
lado: a tabela é mais larga que o celular. Agora a mesma verificação **depois** dos passos 11 e 12:

```
$ node axe-check.mjs
1280px: 0 problem(s)
320px: 0 problem(s)
```

Limpo nas duas larguras. Seria fácil parar aqui, e seria errado. Olhe o que o axe **não** apontou na página
de antes: o campo de nome só tinha um placeholder, *Borrower*, sem rótulo, e o axe aprovou. Um placeholder
conta como nome acessível, então uma máquina que verifica *este campo tem nome?* encontra um. O que ela não
consegue verificar é que o placeholder some no instante em que você começa a digitar, e que *Borrower* não
diz para qual item é o empréstimo. **A ferramenta respondeu à pergunta que sabe responder.** A próxima
seção faz a que ela não sabe.
