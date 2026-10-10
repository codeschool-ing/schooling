---
title: Um defeito da loja, não um teste instável
version: 1
---

O teste que espera `aria-busy="false"` falhou, e vai falhar em toda execução, na mesma linha, com as
mesmas três frutas. **É isso que separa um defeito de um teste instável**: um teste instável falha
*às vezes*, por um motivo no teste ou no ambiente em volta, e a aula 14 trata desses; este falha
*sempre*, porque a página está errada. Um cliente que digita rápido e lê a lista recebe a fruta
errada. A correção pertence ao `search.js`, e o seu trabalho é dizer isso de um jeito que um
desenvolvedor consiga usar.

## O relato

A aula 15 de `manual-testing` cobre o que um relato de defeito precisa ter. Este se escreve sozinho
com as evidências que a aula já produziu:

- *o que foi feito*: em `/search.html`, digitar `papaya` sem pausa entre as teclas;
- *o que se esperava*: a lista mostra Papaya, a contagem diz *1 found*;
- *o que aconteceu*: a lista mostra Papaya, Passion fruit e Pineapple e a contagem diz *3 found*,
  depois que o `aria-busy` fica `false`;
- *por quê*: uma requisição por tecla, as respostas chegam ao contrário porque as buscas curtas são
  mais lentas, e a página desenha a resposta que chegar por último, inclusive respostas a perguntas
  que a caixa não faz mais;
- *como ver*: a saída do `race.mjs`, e o teste que falha.

A última linha é o que torna o relato difícil de descartar. *Comigo funciona* é uma primeira
resposta comum a um defeito de tempo, e é verdade: o desenvolvedor digitou no ritmo de uma pessoa.

## O que fazer com o teste enquanto isso

O teste está certo e a suíte está vermelha. Três coisas podem acontecer com ele enquanto o defeito
espera a correção, e só uma delas mantém honestos a suíte e o teste.

**Apagá-lo, ou deixá-lo fora do projeto**, e o defeito passa a viver só no relato. Ninguém vai
perceber quando ele for corrigido, nem se voltar depois da correção.

**Pulá-lo** com `test.skip()`, e o Playwright nem o roda. A suíte fica verde, o teste para de olhar,
e no dia em que o defeito for corrigido nada avisa ninguém para religá-lo.

**Marcá-lo como falha esperada** com `test.fail()`. O Playwright o roda toda vez e o relata como
aprovado **enquanto ele falhar**. No dia em que alguém corrigir a página, o teste passa, e o
Playwright relata *isso* como falha: a anotação agora está errada e precisa sair. O teste continua
vigiando o defeito dos dois lados. É esta a opção que o curso usa, e a versão final do arquivo a
carrega. Um teste com `fill` fica ao lado, escrito desta vez com asserções web-first, porque confere
a metade da página que não tem corrida. Salve como `tests/search.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  await page.goto('/search.html');
});

test('one request: filling the box finds papaya', async ({ page }) => {
  await page.getByLabel('Fruit').fill('papaya');
  await expect(page.locator('#results li')).toHaveText(['Papaya']);
  await expect(page.locator('#count')).toHaveText('1 found');
});

test('typed key by key, the list settles on papaya', async ({ page }) => {
  // A known defect, reported: the answer to "p" arrives last and replaces
  // the list. Delete this line when it is fixed; the test must then pass.
  test.fail();
  await page.getByLabel('Fruit').pressSequentially('papaya');
  await expect(page.locator('#results')).toHaveAttribute('aria-busy', 'false');
  await expect(page.locator('#results li')).toHaveText(['Papaya']);
  await expect(page.locator('#count')).toHaveText('1 found');
});
```

```
%%CAP v3%%
```

**Leia as marcas e o resumo separadamente.** A marca ao lado de cada teste diz o que o teste fez: o
segundo falhou, então leva `✘`, depois de repetir pelos seus cinco segundos. O resumo diz se cada
teste fez o que foi declarado que faria, e um teste declarado para falhar que falhou é contado entre
os *2 passed*. Olhe o comentário acima de `test.fail()`: ele diz qual é o defeito e o que fazer
quando for corrigido. Uma anotação sem essa frase é um teste vermelho escondido por um motivo que
ninguém consegue reencontrar.

## O dia em que for corrigido

A correção cabe ao desenvolvedor, e há mais de uma. A página poderia cancelar a requisição antiga
quando chega uma tecla nova (o `fetch` aceita um `AbortSignal` para isso), ou poderia lembrar o que
perguntou e descartar qualquer resposta a uma pergunta que a caixa não tem mais. Esta é a segunda,
como substituta do ouvinte em `app/public/search.js`:

```javascript
%%CAP fixed-listener%%
```

Com essa mudança, o mesmo arquivo de testes:

```
%%CAP v3-fixed%%
```

**As marcas e o resumo trocaram de lugar.** O segundo teste passou, então leva `✓`, e como foi
declarado para falhar, o resumo o conta como *1 failed* e explica: *Expected to fail, but passed.*
É a anotação fazendo o seu trabalho: ela transformou *o defeito foi corrigido* numa linha vermelha
que ninguém deixa passar, e a correção do teste é apagar uma linha. Se você testar a mudança, ponha
o `search.js` original de volta depois. As falhas da loja ficam lá de propósito.

O `test.fail()` tem uma fraqueza que vale conhecer antes de confiar nele: **ele aceita qualquer
falha**. Se a página de busca deixasse de carregar, o teste falharia antes de digitar uma tecla e
ainda assim seria relatado como aprovado. É o preço de uma quarentena, e a aula 14 trata de pagá-lo
com cuidado.
