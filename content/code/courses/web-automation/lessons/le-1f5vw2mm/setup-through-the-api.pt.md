---
title: Preparar pela API
version: 1
---

**Um teste tem um assunto e uma preparação, e só o assunto precisa passar pela tela.** O assunto
do teste de cadastro é o formulário: digitar um nome, apertar o botão, ler a saudação. Agora pense
num segundo teste, que verifica se o formulário recusa um nome já tomado. O assunto dele é a
recusa. A preparação é um cliente que já existe, e nada sobre como esse cliente passou a existir
está sendo testado.

O hábito que muita gente traz do teste manual é montar a preparação como uma pessoa faria: abrir o
formulário, cadastrar o primeiro cliente, e depois cadastrar o segundo com o mesmo nome. Funciona,
e custa duas vezes. **É mais lento**, porque cada passo de uma preparação pela tela carrega uma
página, encontra elementos e espera por eles. **E falha pelo motivo errado**: se o formulário
quebra, todo teste que cadastra alguém como passo a caminho de outra coisa fica vermelho, e o
relatório traz cinquenta falhas para um defeito, a maioria em testes cujo assunto está bom.

## Quanto mais lento, medido

O fixture `request` do Playwright, visto nas aulas 10 e 11 chamando `POST /api/reset`, envia
requisições HTTP sem página nenhuma. Ele pega o `baseURL` da configuração, e o `data` vai como
JSON. Um arquivo que cria dez clientes de cada jeito e imprime quanto tempo levou. Salve como
`tests/setup-cost.spec.js`:

```javascript
import { test, expect } from '@playwright/test';
import { randomUUID } from 'node:crypto';

const fresh = () => `cost-${randomUUID().slice(0, 8)}`;

test('ten customers through the form', async ({ page }) => {
  const started = performance.now();
  for (let i = 0; i < 10; i += 1) {
    const name = fresh();
    await page.goto('/signup.html');
    await page.getByLabel('Name').fill(name);
    await page.getByRole('button', { name: 'Create account' }).click();
    await expect(page.getByRole('status')).toHaveText(`Welcome, ${name}`);
  }
  console.log(`form: ${Math.round(performance.now() - started)} ms for 10`);
});

test('ten customers through the API', async ({ request }) => {
  const started = performance.now();
  for (let i = 0; i < 10; i += 1) {
    const response = await request.post('/api/users', { data: { name: fresh() } });
    expect(response.status()).toBe(201);
  }
  console.log(`API: ${Math.round(performance.now() - started)} ms for 10`);
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/setup-cost.spec.js

Running 2 tests using 1 worker

form: 1492 ms for 10
  ✓  1 tests/setup-cost.spec.js:6:1 › ten customers through the form (1.6s)
API: 57 ms for 10
  ✓  2 tests/setup-cost.spec.js:18:1 › ten customers through the API (65ms)

  2 passed (2.9s)
```

Dez clientes levaram 1492 ms pelo formulário e 57 ms pela API: umas 26 vezes mais, quase tudo páginas carregando e um navegador esperando por elas. **E este é o caso mais favorável ao formulário** que você vai medir na vida: um campo, um
botão, uma página sem imagens, um servidor em memória na mesma máquina. Um cadastro de verdade tem
mais campos, uma confirmação e um servidor mais lento, e a diferença cresce com cada um deles. O
tempo que o executor imprime ao lado de cada teste inclui a criação do contexto, e por isso fica um
pouco acima do número que o teste imprimiu.

## O segundo teste, com a preparação pela API

O teste da recusa cria o cliente com uma requisição, confere que a requisição funcionou, e só
então abre a página. Salve como `tests/signup.spec.js`:

```javascript
import { test, expect } from '@playwright/test';
import { randomUUID } from 'node:crypto';

// A name no other test and no earlier run has used: readable at the
// front, random at the back.
const newName = (who) => `${who}-${randomUUID().slice(0, 8)}`;

test('a new customer can sign up', async ({ page }) => {
  const name = newName('maria');
  await page.goto('/signup.html');
  await page.getByLabel('Name').fill(name);
  await page.getByRole('button', { name: 'Create account' }).click();
  await expect(page.getByRole('status')).toHaveText(`Welcome, ${name}`);
});

test('a name that is taken is refused', async ({ page, request }) => {
  const name = newName('joao');
  // The setup goes through the API: this test is about the refusal.
  const created = await request.post('/api/users', { data: { name } });
  expect(created.status()).toBe(201);

  await page.goto('/signup.html');
  await page.getByLabel('Name').fill(name);
  await page.getByRole('button', { name: 'Create account' }).click();
  await expect(page.getByRole('status')).toHaveText(`${name} already exists`);
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/signup.spec.js

Running 2 tests using 1 worker

  ✓  1 tests/signup.spec.js:8:1 › a new customer can sign up (226ms)
  ✓  2 tests/signup.spec.js:16:1 › a name that is taken is refused (184ms)

  2 passed (1.9s)
```

**Confira a resposta da preparação.** A linha `expect(created.status()).toBe(201)` parece
exagero e é a mais útil do teste. Sem ela, uma preparação que falhou, um `400` por corpo errado ou
um `404` porque a rota mudou, deixa o teste seguir e falhar mais tarde na saudação, com uma
mensagem sobre o formulário quando o formulário está bom. Com ela, a falha aponta o passo que
quebrou.

## Onde isso deixa de estar certo

Preparar pela API está certo quando a preparação **não é o assunto**. Está errado em dois lugares:

- **o teste do próprio formulário.** O teste de cadastro acima continua digitando na página,
  porque a página é o que ele testa. Um teste, ou alguns, devem criar um cliente do jeito que um
  cliente cria;
- **uma API que não faz o que a tela faz.** Se o formulário também mandasse um e-mail de boas-vindas
  ou preenchesse valores padrão que o endpoint pula, um cliente feito pela API é outro cliente.
  Antes de confiar num atalho, compare o que cada caminho deixa para trás.

A mesma ideia cresce. Um teste que precisa de um cliente *com histórico de pedidos* pode recebê-lo
com algumas requisições, ou com uma carga no banco, em vez de dez minutos de cliques. As camadas
abaixo da tela, e quanto de uma suíte cabe em cada uma, são o assunto da aula 21; testar uma API
por ela mesma é o próximo curso, `api-mobile-automation`.
