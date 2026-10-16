---
title: O axe num script do Playwright
version: 1
---

**O axe é um motor de regras de acessibilidade**: uma biblioteca JavaScript, escrita pela Deque
Systems e publicada como código aberto, que roda dentro de uma página e confere o documento que o
navegador montou contra uma lista de regras. É disso que a maioria das ferramentas automáticas de
acessibilidade é feita. O Lighthouse o roda, várias extensões de navegador também, e também a
suíte que confere toda tela da plataforma em que este curso é servido. Rodado sozinho, a partir de
um script, ele vira um teste como outro qualquer: abre a página, roda as regras, reprova se algo
quebrou.

Esta aula o dirige com o Playwright, a automação de navegador que a aula 10 de `web-automation`
ensinou. O assunto é a página de reserva da aula 12, servida pela bilheteria como antes.

## O projeto

`~/a11y` é a pasta que a aula 12 criou para o `contrast.py`. Ela vira um projeto Node próprio, com
dois pacotes: o Playwright na versão que a aula 10 instalou e a integração do axe com ele.

```sh
cd ~/a11y
npm init -y
npm install playwright@1.56.0 @axe-core/playwright@4.13.0
```

O `npm init -y` escreve um `package.json` e o imprime. A instalação imprime:

```
ana@nft:~/a11y$ npm install playwright@1.56.0 @axe-core/playwright@4.13.0

added 5 packages, and audited 6 packages in 3s

found 0 vulnerabilities
```

Nenhum navegador é baixado. A aula 10 pôs o Chromium do Playwright em `~/.cache/ms-playwright`, e
todo projeto da máquina que usa a mesma versão do Playwright o encontra ali.

Antes da auditoria, uma olhada no que o motor conhece. `nano rules.js`:

```javascript
// a11y/rules.js
// What the axe engine in this project knows: how many rules, and how many
// carry each tag that audit.js asks for, against the best-practice ones.
const axe = require("axe-core");

const rules = axe.getRules();
console.log(`axe ${axe.version}: ${rules.length} rules`);
for (const tag of ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa", "best-practice"]) {
  const tagged = rules.filter(r => r.tags.includes(tag)).map(r => r.ruleId);
  console.log(`  ${tag.padEnd(14)}${String(tagged.length).padStart(3)}` +
              (tagged.length < 3 ? `  (${tagged.join(", ")})` : ""));
}
```

```
ana@nft:~/a11y$ node rules.js
axe 4.13.0: 105 rules
  wcag2a         62
  wcag2aa         3
  wcag21a         1  (label-content-name-mismatch)
  wcag21aa        3
  wcag22aa        1  (target-size)
  best-practice  30
```

**Leia as duas últimas linhas antes de confiar em qualquer resultado.** A WCAG 2.2 acrescentou
nove critérios de sucesso, e a tag do nível AA dela tem uma regra: `target-size`, para o 2.5.8.
Foco não encoberto, movimentos de arrastar e autenticação acessível não têm nenhuma, porque um
programa que lê o documento não consegue decidi-los. E trinta regras têm a tag `best-practice`:
checagens que a Deque acha que valem a pena e que nenhum critério da WCAG exige. O script abaixo as
deixa de fora, então o veredito dele é sobre a WCAG e nada mais.

## A auditoria

`nano audit.js`, e o botão de copiar leva o programa sem as notas:

```schooling-example
{"language": "javascript", "file": "a11y/audit.js", "parts": [{"code": "// a11y/audit.js\n// Opens one page in Chromium, runs axe against WCAG 2.2 A and AA, and prints\n// every violation. Exits 1 when there is any, so a pipeline can stop on it.\nconst { chromium } = require(\"playwright\");\nconst { AxeBuilder } = require(\"@axe-core/playwright\");\n\nconst url = process.argv[2] || \"http://localhost:8000/book.html\";\nconst TAGS = [\"wcag2a\", \"wcag2aa\", \"wcag21a\", \"wcag21aa\", \"wcag22aa\"];", "note": "O Playwright dirige o navegador e o `@axe-core/playwright` põe o motor do axe dentro da página que ele abriu. O endereço vem da linha de comando, com `book.html` como padrão. **As tags são a norma**: estas cinco selecionam toda regra que o axe arquiva sob a WCAG 2.0, 2.1 e 2.2 nos níveis A e AA, que é o que \"WCAG 2.2 AA\" quer dizer como lista de regras. As mesmas cinco tags são as que a suíte desta escola pede para as próprias telas."}, {"code": "\n(async () => {\n  const browser = await chromium.launch();\n  const context = await browser.newContext();\n  const page = await context.newPage();\n  await page.goto(url);\n  await page.waitForLoadState(\"networkidle\");", "note": "Um contexto criado explicitamente, porque o axe recusa uma página que veio de `browser.newPage()`. Esperar pelo `networkidle` importa aqui: a lista de espetáculos é preenchida por um `fetch` depois que a página carrega, e auditar uma página que não terminou de desenhar é auditar outra página."}, {"code": "\n  const result = await new AxeBuilder({ page }).withTags(TAGS).analyze();\n  for (const v of result.violations) {\n    console.log(`${v.id} (${v.impact}): ${v.help}`);\n    for (const node of v.nodes) {\n      console.log(`  at ${node.target.join(\" \")}`);\n      const reasons = node.failureSummary.split(\"\\n\").slice(1);\n      for (const reason of reasons) console.log(`    ${reason.trim()}`);\n    }", "note": "O `analyze()` roda toda regra selecionada e devolve quatro listas: `violations`, `passes`, `incomplete` e `inapplicable`. Cada violação traz o id da regra, o quanto o axe acha que ela é grave (`minor`, `moderate`, `serious`, `critical`), uma linha de ajuda e todo elemento em que reprovou, com os motivos."}, {"code": "  }\n  const review = result.incomplete.map(v => v.id).join(\", \") || \"none\";\n  console.log(`${result.violations.length} violations; to review by hand: ${review}`);\n  await browser.close();\n  process.exit(result.violations.length ? 1 : 0);\n})();", "note": "`incomplete` é a lista do que o axe não conseguiu decidir, e ela é impressa porque é trabalho para uma pessoa, não aprovação. **O código de saída é a barreira**: 1 quando há qualquer violação, então um passo de pipeline que roda este arquivo reprova o build."}]}
```

Com a bilheteria rodando no terminal dela, audite a página de reserva:

```
ana@nft:~/a11y$ node audit.js; echo "exit $?"
color-contrast (serious): Elements must meet minimum color contrast ratio thresholds
  at .note
    Element has insufficient color contrast of 2.84 (foreground color: #999999, background color: #ffffff, font size: 12.0pt (16px), font weight: normal). Expected contrast ratio of 4.5:1
html-has-lang (serious): <html> element must have a lang attribute
  at html
    The <html> element does not have a lang attribute
image-alt (critical): Images must have alternative text
  at img
    Element does not have an alt attribute
    aria-label attribute does not exist or is empty
    aria-labelledby attribute does not exist, references elements that do not exist or references elements that are empty
    Element has no title attribute
    Element's default semantics were not overridden with role="none" or role="presentation"
label (critical): Form elements must have labels
  at #customer
    Element does not have an implicit (wrapped) <label>
    Element does not have an explicit <label>
    aria-label attribute does not exist or is empty
    aria-labelledby attribute does not exist, references elements that do not exist or references elements that are empty
    Element has no title attribute
    Element has no placeholder attribute
    Element's default semantics were not overridden with role="none" or role="presentation"
4 violations; to review by hand: none
exit 1
```

## Lendo o resultado

Quatro violações, cada uma nomeada pela regra, pelo impacto e pelos elementos em que reprovou.

- **`color-contrast`** achou a nota e imprimiu a medida: 2.84 contra os 4.5 que o 1.4.3 espera. É o
  mesmo par de cores que o `contrast.py` pôs em 2.85 na aula 12; os dois programas arredondam a
  mesma razão de jeitos diferentes.
- **`html-has-lang`** é o defeito 1, `image-alt` o defeito 4, `label` o defeito 5.
- Abaixo de `image-alt` e de `label` vem uma lista de todos os jeitos pelos quais o elemento
  **poderia** ter recebido um nome, todos ausentes. Essa lista é o cardápio de correções: qualquer
  um deles resolve a regra, e o primeiro, um `alt` de verdade ou um `<label>` de verdade, é quase
  sempre o certo.

O impacto é a estimativa do axe de quanto o defeito machuca um usuário, não um nível da WCAG:
`image-alt` é *critical* e `html-has-lang` é *serious*, embora os dois reprovem em critérios de
nível A.

**`exit 1`** é a linha que um pipeline lê. Nada ficou para revisar à mão nesta página; o
`incomplete` se enche em páginas com texto sobre imagens ou degradês, onde a cor de fundo não pode
ser calculada, e com conteúdo dentro de frames que o script não alcançou.

O que falta importa tanto quanto o que está ali. Os defeitos 3, 6, 7 e 8 não foram relatados: o
contorno de foco removido, o `tabindex` positivo, a `<div>` que faz papel de botão e o erro
mostrado só em vermelho. Quatro achados, quatro não. A seção depois da próxima diz por quê.
