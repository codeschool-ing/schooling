---
title: Esperando a página ficar pronta
version: 1
---

O teste precisa esperar alguma coisa antes de clicar. O que ele espera é a questão toda, e a
primeira resposta em que a maioria pensa não funciona aqui.

## Por que `toBeEnabled` não ajuda

`await expect(button).toBeEnabled()` espera até um botão estar habilitado. Os botões de `/ssr` estão
habilitados desde o momento em que o HTML chega, então a asserção passa na hora e o clique ainda cai
na lacuna. **Uma espera só ajuda se aquilo que ela observa muda quando a página fica pronta**, e
nada no botão muda quando a função dele é ligada. A aula 13 trata de esperas em geral; esta aula
precisa só dessa regra.

## Três sinais, do mais forte ao mais fraco

- **Uma marca que a página põe quando está pronta.** O `ssr.js` termina com
  `document.body.dataset.ready = 'true'`, depois que todo botão tem sua função, então esperar por
  `data-ready="true"` no `<body>` espera exatamente a condição de que o clique precisa.
- **A resposta do script.** `page.waitForResponse('**/slow/ssr.js')` espera o arquivo chegar. A
  documentação do Playwright diz que o evento de resposta dispara quando o status e os cabeçalhos
  são recebidos, o que acontece antes de o navegador ler o resto do arquivo e rodá-lo. Nesta loja o
  script é curto e roda quase na hora, mas o teste estaria esperando o evento errado e confiando o
  resto aos milissegundos seguintes.
- **A rede ficando quieta.** `page.waitForLoadState('networkidle')` espera até a página passar meio
  segundo sem fazer nenhuma requisição. Aqui funciona por acaso, porque o script lento é a última
  coisa que a página pede. A documentação dele o marca como desaconselhado para testes, e uma página
  que pergunta novidades ao servidor a cada poucos segundos nunca fica quieta.

Vale ver o segundo escrito, porque ele tem uma armadilha própria: a espera precisa começar **antes**
do `goto`, ou a resposta pode chegar enquanto ninguém a está escutando:

```javascript
const script = page.waitForResponse('**/slow/ssr.js');
await page.goto('/ssr');
await script;
```

## O teste, esperando a marca

A versão nova espera o atributo do body e então clica. Ela substitui a primeira. Salve-a como
`tests/ssr.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// The basket is shared, so every test starts by emptying it.
test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a click on /ssr adds to the basket once the page is ready', async ({ page }) => {
  await page.goto('/ssr');
  // ssr.js sets this as its last line, after every button has a handler.
  await expect(page.locator('body')).toHaveAttribute('data-ready', 'true');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toHaveText('1');
});
```

```
%%CAP ready%%
```

READY_SENTENCE

## A correção melhor é da página

A marca funciona, e é um acordo entre a página e os testes dela que mais ninguém vê. Um
desenvolvedor que renomeie o atributo quebra o teste sem mudar nada que um usuário notaria. Existe
uma correção que serve a todos, e cabe aos desenvolvedores fazê-la e a quem testa pedi-la: **enviar
os botões desabilitados e habilitar cada um quando a função dele for ligada.** Uma pessoa então vê
um botão acinzentado em vez de tocar num que a ignora, um leitor de tela o anuncia como
indisponível, e a verificação de acionabilidade do Playwright, que já espera um botão estar
habilitado antes de clicar, faz a espera sem nenhuma linha a mais no teste.

São duas edições. Em `app/routes/ssr.js`, o botão é enviado com `disabled`:

```javascript
        <button type="button" data-id="${p.id}" disabled>Add to basket</button>
```

e em `app/public/ssr.js`, uma primeira linha nova dentro do laço o habilita de novo:

```javascript
  button.disabled = false;
```

Faça as duas, ponha de volta a primeira versão de `tests/ssr.spec.js` da seção anterior, a que clica
na hora, e rode-a:

```
%%CAP disabled%%
```

**O teste que falhou cinco vezes em cinco passa, e nenhuma linha dele mudou.** Depois, desfaça as
duas edições e volte o teste que espera a marca, porque o resto do curso conta com a loja como ela
foi mostrada. Numa equipe, esta execução é a evidência que acompanha o pedido aos desenvolvedores; a
aula 15 de `manual-testing` trata do que um relato desses precisa ter.
