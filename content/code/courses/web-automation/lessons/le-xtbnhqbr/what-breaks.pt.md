---
title: O que quebra um localizador
version: 1
---

**Um localizador quebra quando se apoia em algo que muda por motivos que não têm nada a ver com o
que o teste verifica.** O teste então falha numa página que funciona, alguém passa uma tarde
descobrindo que não há nada errado, e no próximo vermelho se acredita um pouco menos. Quatro tipos
de apoio mudam assim o tempo todo: valores que a página gera, posições, classes que existem para o
estilo e cadeias longas que precisam que cada passo se mantenha.

## Um valor que a página gera

O `id` do cartão parece o melhor apoio que existe. É único na página, um seletor para ele tem dez
caracteres, e o painel Elements o mostra na primeira linha. Peça o cartão da banana de novo,
depois `#card-4821`, o exemplo que a aula 1 deu, e depois qualquer `id` que comece do jeito que
esses começam:

```
%%CAP count-id%%
```

O cartão da banana tem um `id` diferente do que foi impresso no começo desta aula, e o exemplo não
acha nada. O `app.js` sorteia o número com `Math.random()` toda vez que a página carrega. Frameworks
fazem o mesmo por motivos próprios: uma biblioteca de componentes que numera os seus campos, uma
ferramenta de estilo que dá às classes nomes tirados de um hash das suas regras. **Tudo o que um
programa inventou ao desenhar a página é um valor que o próximo desenho pode inventar diferente.**

## Um teste que se apoia nas coisas erradas

Três testes do cartão da banana, cada um por um apoio que alguém poderia escolher com razão. O
primeiro copia o `id` do painel Elements. O segundo pega o primeiro cartão da lista. O terceiro faz
o mesmo depois que algumas linhas de JavaScript, rodadas dentro da página, puseram outro cartão no
topo da lista: é como a loja ficaria no dia em que uma fruta nova entrasse na estação. Salve-o como
`tests/locators.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('banana, by the id the Elements panel showed', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('#card-4821 h2')).toHaveText('Banana');
});

test('banana, by its position', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('#products > li:nth-child(1) h2')).toHaveText('Banana');
});

test('banana, by its position, after one more fruit', async ({ page }) => {
  await page.goto('/');
  await page.locator('#products[aria-busy="false"]').waitFor();
  // What the shop's next release might do: one more card, at the top.
  await page.locator('#products').evaluate((list) => {
    list.insertAdjacentHTML('afterbegin', '<li class="card"><h2>Jabuticaba</h2></li>');
  });
  await expect(page.locator('#products > li:nth-child(1) h2')).toHaveText('Banana');
});
```

Rode esse arquivo sozinho, pelo nome:

```
%%CAP breaks%%
```

**O primeiro teste nunca passou, nem uma vez.** O `id` que ele copiou estava certo para a página no
seu navegador, no momento em que você olhou; a execução abriu uma página nova, que sorteou um
número novo. O Playwright esperou os cinco segundos que uma asserção espera por padrão e relatou
`element(s) not found`. A mensagem parece a de um cartão que sumiu, e o cartão está lá.

**O segundo teste passou, e o terceiro é o mesmo localizador.** Na página como ela está, o
primeiro cartão é a banana. Com um cartão a mais no topo, o localizador ainda acha exatamente um
título, só que o errado, e o Playwright diz isso: esperava `Banana`, recebeu `Jabuticaba`. Ninguém
quebrou o cartão da banana. Um localizador por posição testa a ordem da lista, seja a ordem o
assunto do teste ou não.

## Classes de estilo, e cadeias longas

Os outros dois tipos não precisam de demonstração para convencer. **Uma classe como `.price`
existe para a folha de estilos**, e quem redesenhar o cartão pode renomeá-la, dividi-la em duas ou
passá-la para o `small`, sem nenhuma mudança que alguém chamaria de defeito. Um teste que se apoia
nela tornou os nomes do designer parte do que verifica. **Uma cadeia longa**,
`main > ul#products > li.card > p.price`, precisa que todos os seus passos se mantenham ao mesmo
tempo, então quebra quando qualquer um deles muda, e quanto mais passos tem, mais vezes isso
acontece.

## O outro jeito de errar

Um localizador também pode errar na direção que não deixa nada vermelho. O `contains(., "5,90")`
da seção anterior achou dois preços. Um teste que lesse o primeiro deles estaria verificando a
banana pela sorte da ordem, e no dia em que o caju subisse na lista verificaria o preço errado, e
poderia passar. **Um localizador que acha mais do que você queria esconde um defeito em vez de
relatá-lo**, o que é pior que um alarme falso, porque ninguém investiga uma execução verde. A
próxima seção trata de uma ferramenta que se recusa a adivinhar.
