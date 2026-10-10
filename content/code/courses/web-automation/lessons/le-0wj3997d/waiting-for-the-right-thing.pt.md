---
title: Esperar a coisa certa
version: 1
---

Um sleep falha porque espera um tempo, e o tempo não é o que interessa ao teste. A cura é esperar
um **estado**: algo na página que é verdade quando o teste pode olhar e falso antes disso. O
Playwright faz disso o jeito comum de escrever uma verificação, e esta seção mostra três formas.
**Duas delas passam nesta página, e as duas estão erradas**, e entender por quê é o objetivo desta
seção.

## Asserções que repetem

`expect(locator).toHaveCount(1)` parece `expect(await locator.count()).toBe(1)` e se comporta de
outro jeito. A segunda conta uma vez e compara. A primeira é uma **asserção web-first**: pergunta à
página de novo e de novo até a resposta ser 1 ou o tempo da asserção acabar, que é de cinco
segundos se nada for configurado, como diz a documentação do Playwright. Todo método de `expect`
que recebe um localizador funciona assim, `toHaveText`, `toBeVisible` e `toHaveAttribute` entre
eles, e o teste de fumaça da aula 1 dependia disso sem dizer. Com uma delas, um servidor lento deixa
de ser motivo para falhar: a verificação espera o quanto a resposta levar, e não mais.

## Esperar uma resposta

`page.waitForResponse` espera o navegador receber uma resposta que satisfaça uma condição. Comece a
esperar **antes** da ação que provoca a requisição, ou a resposta pode chegar antes de alguém estar
ouvindo; é por isso que a promessa é criada primeiro e aguardada depois da digitação. Ela responde a
uma pergunta mais estreita que uma asserção: não *o que a página mostra*, mas *o servidor respondeu
a esta requisição*.

## Esperar a página dizer que terminou

A terceira forma espera o sinal que a própria página publica: o `aria-busy` voltando a `false`.
`toHaveAttribute('aria-busy', 'false')` é uma asserção web-first como as outras, então repete até o
atributo dizer isso, e só então as duas linhas seguintes conferem a lista e a contagem.

Esta versão do arquivo tem um teste de cada tipo. Salve como `tests/search.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  await page.goto('/search.html');
});

test('an assertion that retries', async ({ page }) => {
  await page.getByLabel('Fruit').pressSequentially('papaya');
  await expect(page.locator('#results li')).toHaveCount(1);
});

test('waiting for the answer to "papaya"', async ({ page }) => {
  const answer = page.waitForResponse((response) => response.url().endsWith('?q=papaya'));
  await page.getByLabel('Fruit').pressSequentially('papaya');
  await answer;
  await expect(page.locator('#results li')).toHaveText(['Papaya']);
});

test('waiting until the page is no longer busy', async ({ page }) => {
  await page.getByLabel('Fruit').pressSequentially('papaya');
  await expect(page.locator('#results')).toHaveAttribute('aria-busy', 'false');
  await expect(page.locator('#results li')).toHaveText(['Papaya']);
  await expect(page.locator('#count')).toHaveText('1 found');
});
```

```
%%CAP v2%%
```

**Os dois primeiros passaram, bem abaixo de um segundo, e o terceiro falhou depois de repetir por
cinco.** Leia a falha: o `aria-busy` chegou a `false`, então `toHaveText` esperava um item e recebeu
três, *Papaya, Passion fruit, Pineapple*, e continuou recebendo até desistir.

A asserção que repete passou porque se satisfaz com o primeiro momento em que a lista tem um item,
e a primeira resposta a chegar, a de `papaya`, deu esse momento. **Uma asserção web-first espera a
condição ficar verdadeira; não verifica se ela continua verdadeira.** O teste da resposta passou pelo
mesmo motivo de outra forma: a resposta a `papaya` é real, chegou primeiro, e a lista que ela
desenhou estava certa até a resposta a `p` substituí-la. Os dois testes olharam a página na janela
em que ela estava correta, e pararam de olhar.

Só o terceiro esperou o que o teste de fato afirma: *quando a busca termina, a lista tem Papaya*. É o
teste honesto dos três, e é o que falhou. A figura põe as seis maneiras de esperar desta aula numa
mesma linha do tempo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A mesma linha do tempo do que a lista mostra, Papaya até 600 ms, duas frutas até 750 ms, três depois, com seis testes marcados no momento em que cada um olha. count(), lido logo de cara, olha em 0 ms e acha a lista vazia. waitForTimeout(500) olha em 500 ms e passa. waitForTimeout(1000) olha em 1000 ms e falha com três frutas. toHaveCount(1) e waitForResponse se satisfazem com a primeira resposta e passam cedo demais. Esperar aria-busy false olha em 750 ms e falha com três frutas, que é o estado final real da página.\"><text x=\"20\" y=\"45\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">a lista</text><rect x=\"250\" y=\"30\" width=\"240\" height=\"22\" rx=\"3\" fill=\"var(--scan)\"></rect><text x=\"370\" y=\"45\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Papaya</text><rect x=\"490\" y=\"30\" width=\"60\" height=\"22\" rx=\"3\" fill=\"var(--wire)\"></rect><text x=\"520\" y=\"45\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><rect x=\"550\" y=\"30\" width=\"140\" height=\"22\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"620\" y=\"45\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--ink)\">3 found</text><text x=\"250\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0 ms</text><text x=\"350\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">250 ms</text><text x=\"450\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">500 ms</text><text x=\"550\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">750 ms</text><text x=\"650\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1000 ms</text><text x=\"20\" y=\"104\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">count()</text><path d=\"M250 54 L250 96\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"250\" cy=\"100\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"260\" y=\"104\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">vazia: falha</text><text x=\"20\" y=\"136\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">waitForTimeout(500)</text><path d=\"M450 54 L450 128\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"450\" cy=\"132\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"460\" y=\"136\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">passa, por sorte</text><text x=\"20\" y=\"168\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">waitForTimeout(1000)</text><path d=\"M650 54 L650 160\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"650\" cy=\"164\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"640\" y=\"168\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">falha com 3</text><text x=\"20\" y=\"200\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">toHaveCount(1)</text><path d=\"M250 54 L250 192\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"250\" cy=\"196\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"260\" y=\"200\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">passa, cedo demais</text><text x=\"20\" y=\"232\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">waitForResponse</text><path d=\"M250 54 L250 224\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"250\" cy=\"228\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"260\" y=\"232\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">passa, cedo demais</text><text x=\"20\" y=\"264\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">aria-busy=\"false\"</text><path d=\"M550 54 L550 256\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"550\" cy=\"260\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"540\" y=\"264\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">falha com 3: a verdade</text></svg>", "caption": "Seis maneiras de esperar, e onde cada uma olha. Só a última olha o estado em que a página termina."}
```

## Esperar um estado que não pode ser verdade cedo demais

Uma condição só vale a espera se não puder ser cumprida antes do momento que você quer. **Olhe o HTML
da página de busca: a lista começa com `aria-busy="false"`.** Antes da primeira tecla, a condição que
o terceiro teste espera já é verdadeira. Funciona aqui porque o `pressSequentially` só retorna
depois que o evento `input` da última tecla rodou, e o primeiro deles já tinha posto o atributo em
`true`. Um teste que começasse a esperar antes de digitar, ou uma página que ligasse o atributo um
instante depois da requisição em vez de antes, passaria a espera na hora e leria uma lista vazia.

Então, ao escolher o que esperar, faça duas perguntas: **é verdade quando a página terminou, e é
falso até lá?** Uma resposta chegando responde à primeira e não à segunda. Uma contagem de um não
responde a nenhuma nesta página. O `aria-busy` responde às duas, e por isso o teste construído nele
é o que disse a verdade. A aula 13 transforma isso no vocabulário de esperas explícitas e condições
personalizadas; por enquanto, reconhecer as duas perguntas basta.
