---
title: O que verificar em cada um, e o que deixar para uma pessoa
version: 1
---

Os dois tipos de layout falham em lugares diferentes, então são verificados em lugares
diferentes. **Uma página responsiva falha numa largura; uma página adaptativa falha num palpite.**
A maioria dos sites reais é as duas coisas: um servidor adaptativo escolhendo entre páginas que são,
cada uma, responsivas, o que quer dizer que cada página que ele pode mandar precisa das próprias
verificações responsivas. A página de ofertas mostrou por quê. A página de celular não tem a tag
viewport, então a página feita para celulares é a que um celular desenha com 980 pixels.

## Uma lista para cada tipo

| | responsiva | adaptativa |
|---|---|---|
| quem decide | a largura da janela, no navegador | o `User-Agent`, no servidor |
| onde testar | dos dois lados de cada breakpoint da folha de estilos | dos dois lados da regra do servidor, com descritores |
| só a janela | é o teste inteiro | não testa nada: uma janela estreita de computador recebe a página de computador |
| o que cada teste pergunta | o que aparece, o que some, o que os controles fazem | que página chegou, e se ela diz `Vary: User-Agent` |
| o que quebra em silêncio | uma rolagem lateral, um texto cortado | um cache servindo uma página a todo mundo, um aparelho que a regra não previu |

E para as duas, em toda largura que um celular pode ter:

- **Nenhuma rolagem lateral.** O teste da seção sobre a rolagem lateral, em cada largura em que
  você testar qualquer coisa.
- **Nada cortado.** Um elemento com `overflow: hidden` e largura ou altura fixa esconde o que não
  cabe, sem barra de rolagem. A mesma comparação o encontra no elemento em vez da página: o
  `scrollWidth` dele maior que o `clientWidth`.
- **Alvos que um dedo acerta.** O critério de sucesso 2.5.8 das WCAG 2.2, *Target Size (Minimum)*,
  no nível AA, pede um alvo de ponteiro de pelo menos 24 por 24 pixels CSS, ou espaço suficiente em
  volta de um menor, e ainda lista exceções. Leia o texto do próprio critério em w3.org antes de
  contar com uma delas: ele não pôde ser baixado da máquina de onde vêm estas transcrições, então
  esta aula cita só o número. As aulas 12 a 15 de `non-functional-testing` testam acessibilidade de
  verdade.
- **As duas orientações**, que o próximo parágrafo mostra.

A maioria dos celulares na lista do Playwright tem uma entrada `landscape` ao lado, e virar um
celular de lado pode levá-lo para o outro lado de um breakpoint:

```
ana@laptop:~/quitanda$ node -p "require('@playwright/test').devices['iPhone 13 landscape'].viewport"
{ width: 750, height: 342 }
```

De lado, o iPhone 13 tem 750 de largura, então recebe o layout de computador da loja, com os links
e sem o botão Menu, numa janela de 342 pixels de altura. Se esse layout ainda cabe é uma pergunta
que vale um teste próprio.

## Um robô que mede, e uma pessoa que julgou

Um teste consegue medir a caixa de cada alvo. Ele não consegue aplicar a alternativa do espaço em
volta sem a geometria de todos os vizinhos, e um teste que tentasse seria uma segunda implementação
da norma, escrita por alguém que não a leu inteira. Então o teste abaixo mede, e **o que é pequeno
foi olhado por uma pessoa, que anotou por que é aceitável**. Um alvo pequeno novo reprova o teste
até alguém olhar para ele também. Salve-o como `tests/targets.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// WCAG 2.2, success criterion 2.5.8: a target is at least 24 by 24 CSS
// pixels, or has enough space around it. The robot measures the size.
// Whether the space is enough, a person judged, and wrote down here.
const judged = {
  Shop: 'under 24 px tall, with the 1rem gap of the open menu below it',
  Search: 'under 24 px tall, with the same gap above it',
};

test('every target on a phone is 24 by 24, or was judged', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 664 });
  await page.goto('/');
  await expect(page.locator('#products li')).toHaveCount(8);
  await page.getByRole('button', { name: 'Menu' }).click();
  const small = [];
  for (const target of await page.locator('a:visible, button:visible').all()) {
    const box = await target.boundingBox();
    if (box.width < 24 || box.height < 24) small.push((await target.textContent()).trim());
  }
  expect(small).toEqual(Object.keys(judged));
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/targets.spec.js

Running 1 test using 1 worker

  ✓  1 tests/targets.spec.js:11:1 › every target on a phone is 24 by 24, or was judged (367ms)

  1 passed (1.6s)
```

Os dois links do menu aberto são os únicos alvos abaixo de 24 pixels, e a coluna em que estão tem
`gap: 1rem` entre eles, que é o que a pessoa julgou. Todos os botões da loja passam de 24 nas duas
direções. O `:visible` no seletor deixa de fora o que não está na tela: numa janela com mais de 600
o botão Menu escondido tem uma caixa de 0 por 0, e um elemento que ninguém vê não é alvo de
ninguém.

## O que um robô não deve julgar

**Se a página parece certa.** Um robô consegue dizer que a linha da cesta tem 400 pixels de
largura; não consegue dizer se o layout de celular é agradável, se o botão Menu está onde o polegar
o espera, ou se um título que quebra em três linhas fica ruim de ler. Capturas de tela comparadas
com uma cópia revisada são o mais perto que o robô chega, e a aula 16 mostra o que elas pegam e
quanto custam. A aula 22 trata dos testes que custam mais que os defeitos que acham, e um teste que
afirma a aparência de uma página muitas vezes é um deles.

Então a divisão é a que esta aula seguiu do começo ao fim: **o robô mede o que tem uma resposta
certa** (uma largura, uma contagem, um cabeçalho, que página chegou) e uma pessoa olha o resto, num
celular de verdade, de vez em quando.
