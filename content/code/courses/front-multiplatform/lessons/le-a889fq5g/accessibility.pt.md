---
title: Acessibilidade, dos dois lados
version: 1
---

**Um app React Native é acessível pelo leitor de tela da própria plataforma**: o TalkBack no Android, o
VoiceOver no iOS. O que eles anunciam vem das mesmas props que você vem escrevendo: `role` diz o que um
elemento é, `aria-label` o nomeia quando o texto dele não nomeia, e um `Text` com `role="alert"` é lido
quando aparece. O React Native também aceita os nomes antigos, `accessibilityRole` e
`accessibilityLabel`, que você vai encontrar na maior parte do código escrito antes de 2023.

Quatro regras carregam a maior parte do peso:

- **Todo controle tem um papel e um nome.** Um `Pressable` sem `role="button"` é anunciado como nada em
  particular, e um campo sem rótulo é anunciado como "campo de texto", o que não diz qual.
- **Uma área de toque é grande o bastante para acertar.** As diretrizes da Apple pedem 44 por 44 pontos e
  as do Google 48 por 48 pixels independentes de densidade; o espaçamento interno é o jeito comum de
  chegar lá, como as linhas de curso fazem.
- **O texto cresce com as configurações da pessoa**, como a seção anterior disse, e o layout tem que
  deixar.
- **O agrupamento é deliberado.** Por padrão um leitor de tela para em cada `Text`. Uma linha que se lê
  melhor como uma frase, a data e a duração de uma sessão, pode virar um elemento só com `accessible` na
  `View` dela; uma linha com um botão dentro não deve, ou o botão some dentro dela.

## Conferindo num navegador, com o axe

O **axe** é o verificador de acessibilidade que este repositório roda nas próprias telas. Ele lê uma
página e informa o que viola regras do WCAG que uma máquina consegue decidir: contraste, nomes faltando,
papéis que não encaixam. Rodado sobre o build web, ele confere o que o `react-native-web` produziu a
partir das suas props, o que é um teste justo das próprias props. Instale-o ao lado do Playwright, na
versão que este curso usou:

```
ana@dev:~/planner-native$ npm install -E -D @axe-core/playwright@4.14.0

added 2 packages, and audited 538 packages in 1s

5 high severity vulnerabilities

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

E um programa curto em volta dele, salvo como `axe.mjs`:

```javascript
// axe.mjs: run axe, the accessibility checker, over one address, and print what it found.
//
//   node axe.mjs URL [--click NAME]
import { chromium } from "playwright";
import { AxeBuilder } from "@axe-core/playwright";

const [url, flag, name] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await (await browser.newContext()).newPage();
await page.goto(url);
if (flag === "--click") await page.getByRole("button", { name, exact: true }).click();
await page.getByRole("main").waitFor();
const { violations, passes } = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa", "wcag21aa", "wcag22aa"]).analyze();
for (const v of violations) console.log(`${v.id} (${v.impact}): ${v.help}, ${v.nodes.length} element(s)`);
console.log(`${violations.length} rule(s) failed, ${passes.length} passed`);
await browser.close();
```

As duas telas:

```
ana@dev:~/planner-native$ node axe.mjs 'http://localhost:8082/?today=2026-10-21'
0 rule(s) failed, 18 passed
ana@dev:~/planner-native$ node axe.mjs 'http://localhost:8082/?today=2026-10-21' --click Statistics
0 rule(s) failed, 25 passed
```

**Nada falhou.** Para ver como é uma falha, dê ao "Mark done" um azul mais claro, `#7aa7e8`, o tipo de
cor que parece bem numa tela clara, e rode de novo na tela do curso:

```
ana@dev:~/planner-native$ sed -i 's/action: { color: "#0a58ca"/action: { color: "#7aa7e8"/' 'app/course/[id].tsx'
ana@dev:~/planner-native$ npx expo export --platform web > /dev/null
ana@dev:~/planner-native$ node axe.mjs 'http://localhost:8082/?today=2026-10-21' --click Statistics
color-contrast (serious): Elements must meet minimum color contrast ratio thresholds, 1 element(s)
1 rule(s) failed, 25 passed
```

**`color-contrast` é a regra**, e o elemento é o único rótulo "Mark done" daquela tela, a sessão de
Statistics ainda por fazer. A cor voltou para `#0a58ca` depois. O axe no build web não consegue dizer
como o TalkBack lê uma tela, nem se a ordem do foco faz sentido, e é por isso que o teste de verdade da
acessibilidade de um app é o próprio leitor de tela do celular, ligado, de olhos fechados. *Esse teste
não foi rodado para este curso; ele precisa de um celular.*
