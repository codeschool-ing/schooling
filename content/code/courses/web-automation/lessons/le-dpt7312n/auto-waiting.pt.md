---
title: Esperar sem que mandem
version: 1
---

Um teste escrito para uma página que muda debaixo dele pareceria precisar de uma pausa antes de cada
passo: esperar o botão, clicar, esperar o total, conferir. **Os testes de Playwright deste curso
não têm pausas nem sleeps**, e passam. Dois mecanismos fazem a espera, um antes de cada ação e
outro dentro de cada asserção, e os dois desistem depois de um tempo fixo. Esta seção dá nome a
eles e mede os tempos; a aula 13 trata de esperas a fundo, e a aula 3 do carregamento assíncrono
que as torna necessárias.

## Antes de uma ação: acionabilidade

Antes de o `click()` apertar qualquer coisa, o Playwright acha o elemento que o localizador
descreve e confere, nas palavras da documentação dele, que ele está **visível**, **estável** (não
se mexendo numa animação), **recebe eventos** (nenhum outro elemento o cobre) e está **habilitado**.
Um `fill()` também exige que ele seja **editável**. Se alguma conferência falha, ele olha de novo,
e de novo, até todas passarem ou o tempo acabar. Um botão que aparece meio segundo depois de a
página carregar é clicado meio segundo depois, e o teste não diz nada sobre isso.

É também por isso que um localizador é uma descrição, e não um elemento.
`page.getByRole('button')` não acha nada quando é escrito; ele é resolvido a cada uso, contra a
página como ela está naquele momento.

## Depois de uma ação: uma asserção que tenta de novo

O **Add to basket** da loja manda uma requisição e redesenha a contagem quando a resposta chega. O
`click()` volta assim que o clique é entregue, não quando a requisição termina. Este teste lê a
contagem dos dois jeitos. Salve-o como `tests/waiting.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a read is a snapshot, an assertion retries', async ({ page }) => {
  await page.goto('/');
  const count = page.getByTestId('basket-count');
  await page.getByTestId('product-mango').getByRole('button', { name: 'Add to basket' }).click();
  console.log(`read straight after the click: ${await count.textContent()}`);
  await expect(count).toHaveText('1');
});
```

```
%%CAP waiting%%
```

O `textContent()` leu a contagem na hora e recebeu `0`: **uma leitura é uma foto**, tirada no
instante em que roda, antes de a resposta da loja voltar. O `expect(count).toHaveText('1')` passou
na mesma página, porque uma asserção sobre um localizador é uma **asserção web-first**: ela lê,
compara e lê de novo até o texto bater. Um teste que conferisse a foto com
`expect(text).toBe('1')` falharia aqui na maioria das execuções e passaria em algumas, que é o
teste instável de que trata a aula 14.

## Quanto tempo é "até"

Nenhum dos mecanismos espera para sempre, e vale conhecer os padrões por uma execução, não de
memória. Para vê-los, acrescente estes dois testes ao fim de `tests/waiting.spec.js`, rode o
arquivo e tire-os de novo. Cada um espera algo que nunca acontece:

```javascript
test('an assertion that is never true', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByTestId('basket-count')).toHaveText('1');
});

test('a click on a button that is not there', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: 'Buy now' }).click();
});
```

```
%%CAP waiting-fail%%
```

As duas falhas mostram dois relógios diferentes:

- **uma asserção desiste depois de @@EXPECT@@**, e a mensagem diz isso, `Timeout: @@EXPECT@@`, com um
  registro de chamadas mostrando quantas vezes ela olhou e o que achou em cada uma;
- **uma ação não tem relógio próprio.** O clique esperou um botão chamado *Buy now* até o teste
  inteiro estourar o tempo, `Test timeout of @@TEST@@ exceeded`, e a duração ao lado do nome do
  teste mostra isso.

Os dois podem ser mudados: `expect.timeout` e `timeout` na configuração, `actionTimeout` dentro de
`use`, ou um `{ timeout }` numa chamada só. Mudá-los é assunto da aula 13. O que importa aqui é ler
a falha: um registro de chamadas dizendo que o localizador **resolveu** e tinha o valor errado é
uma página que fez algo inesperado; um registro que só diz **waiting for** é um localizador que não
casa com nada, e isso costuma ser culpa do teste.
