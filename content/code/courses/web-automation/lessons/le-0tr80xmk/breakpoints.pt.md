---
title: Breakpoints, testados dos dois lados da linha
version: 1
---

Uma página **responsiva** é uma só página para todo visitante. O servidor manda o mesmo HTML a um
celular e a um computador, e a folha de estilos muda o layout em certas larguras chamadas
**breakpoints**. A loja tem um. O bloco no fim do `style.css` que a aula 1 montou começa com
`@media (max-width: 600px)`, e dentro dele há três regras: `.menu-toggle { display: inline-block; … }`
mostra o botão **Menu**, `nav { display: none; … }` esconde os links, e `nav.open { display:
flex; }` os traz de volta depois que o botão foi apertado. Quem aperta é o script em `app.js`: ele
alterna o `aria-expanded` do botão entre `false` e `true`, e a classe `open` do `<nav>` junto.

## Onde testar: dos dois lados de cada linha

O hábito comum é testar "celular" e "computador", uma janela do tamanho de um telefone e uma
grande. Isso verifica dois layouts e não a linha entre eles, que é onde mora esse tipo de defeito:
uma regra escrita com `min-width` onde se queria `max-width`, um breakpoint em 600 num arquivo e
em 640 em outro, um layout que aguenta em 390 e desmonta em 560. **As larguras que valem um teste
se leem na folha de estilos**, e cada breakpoint ganha a largura de cada lado dele.

`max-width: 600px` quer dizer *600 ou menos*, então 600 ainda é o layout de celular e 601 é o
primeiro de computador. Uma janela de 360 e uma de 1280 acrescentam as pontas. Quatro larguras,
dois layouts, e os testes fazem uma pergunta diferente a cada layout:

- **em 360 e 600**, os links estão escondidos, o botão Menu está lá com `aria-expanded="false"`, e
  apertá-lo mostra os links e põe `aria-expanded="true"`;
- **em 601 e 1280**, os links estão visíveis e o botão Menu não.

## Um arquivo, um bloco describe por largura

`test.use` dentro de um `test.describe` define opções para todos os testes daquele bloco, e
`viewport` é uma delas: o Playwright abre a página de cada teste num contexto daquele tamanho. Um
laço escreve o bloco uma vez por largura. Salve-o como `tests/responsive.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// style.css changes the layout at (max-width: 600px): 600 is still a
// phone, 601 is not. Each side gets the width next to the line and one
// far from it.
for (const width of [360, 600]) {
  test.describe(`${width} px wide`, () => {
    test.use({ viewport: { width, height: 800 } });

    test('the links hide behind the Menu button', async ({ page }) => {
      await page.goto('/');
      const menu = page.getByRole('button', { name: 'Menu' });
      const shop = page.getByRole('link', { name: 'Shop', includeHidden: true });
      await expect(menu).toHaveAttribute('aria-expanded', 'false');
      await expect(shop).toBeHidden();
      await menu.click();
      await expect(menu).toHaveAttribute('aria-expanded', 'true');
      await expect(shop).toBeVisible();
    });
  });
}

for (const width of [601, 1280]) {
  test.describe(`${width} px wide`, () => {
    test.use({ viewport: { width, height: 800 } });

    test('the links show and the Menu button does not', async ({ page }) => {
      await page.goto('/');
      const menu = page.getByRole('button', { name: 'Menu', includeHidden: true });
      await expect(page.getByRole('link', { name: 'Shop' })).toBeVisible();
      await expect(menu).toHaveCount(1);
      await expect(menu).toBeHidden();
    });
  });
}
```

```
ana@laptop:~/quitanda$ npx playwright test tests/responsive.spec.js

Running 4 tests using 1 worker

  ✓  1 tests/responsive.spec.js:10:5 › 360 px wide › the links hide behind the Menu button (213ms)
  ✓  2 tests/responsive.spec.js:10:5 › 600 px wide › the links hide behind the Menu button (161ms)
  ✓  3 tests/responsive.spec.js:27:5 › 601 px wide › the links show and the Menu button does not (121ms)
  ✓  4 tests/responsive.spec.js:27:5 › 1280 px wide › the links show and the Menu button does not (107ms)

  4 passed (2.0s)
```

**Quatro passaram**, e os títulos dizem em que largura cada um rodou, porque o bloco `describe`
leva o nome dela. A largura no título é o que torna uma falha legível: *601 px wide › the links
show* diz onde procurar antes de você abrir qualquer coisa.

## Um elemento escondido que não existe

Dois detalhes desse arquivo evitam um teste que passa pelo motivo errado. O `getByRole` deixa de
fora os elementos escondidos, o que é certo para achar o que uma pessoa pode usar e errado para
provar que algo está escondido: um localizador que não acha nada também está escondido, então
`toBeHidden()` passa num botão que foi renomeado ou apagado. **`includeHidden: true`** faz o
localizador achar o elemento apareça ele ou não, e do lado largo **`toHaveCount(1)`** prova que o
botão Menu está na página antes de `toBeHidden()` dizer que ele não está na tela. Do lado estreito o
clique faz o mesmo papel: o teste não consegue apertar um botão que não existe, e o link que ele
vê em seguida é o mesmo que ele disse estar escondido.

## `test.use` ou `setViewportSize`

`page.setViewportSize({ width, height })` redimensiona uma página já aberta, no meio de um teste.
Use-o para a pergunta *o que acontece quando a janela muda*, como um tablet virado de lado com o
menu aberto. `test.use` decide o tamanho antes de a página existir, que é a pergunta *o que esta
largura recebe*. Para um teste que define o tamanho uma vez e depois abre a página, os dois fazem o
mesmo trabalho, e a próxima seção usa o outro. Os dois mudam só a janela. O toque, a razão de pixels
e o nome de um celular continuam os de um Chromium de computador, e para esta página isso basta,
porque nada no `style.css` pergunta outra coisa além da largura.
