---
title: O teste que passa uma vez
version: 1
---

**Um teste é um programa que altera a aplicação que ele verifica.** Todo teste que cadastra
alguém, põe algo na cesta ou faz um pedido deixa alguma coisa para trás, e o próximo teste, ou a
próxima execução do mesmo teste, começa do que sobrou. Quase tudo o que dá errado com dados de
teste é um teste que supôs estar sozinho, ou supôs ser o primeiro. Esta seção monta o menor caso
disso.

## Clientes, enfim

A loja ganha contas: um nome, e mais nada. `POST /api/users` com um nome cria uma conta e responde
`201`; um nome que já existe é recusado com `409 Conflict` e uma frase dizendo isso;
`DELETE /api/users?name=…` remove uma conta e responde `204`, existindo ela ou não. Como a cesta,
os clientes vivem em memória, no conjunto `users` de `app/store.js`, e `POST /api/reset` o
esvazia junto com a cesta e a oferta. Salve como `app/routes/users.js`:

```javascript
import { send } from '../http.js';
import { store } from '../store.js';

export const routes = [
  {
    method: 'POST', path: '/api/users',
    handle: ({ res, body }) => {
      const name = String(body.name ?? '').trim();
      if (!name) return send(res, 400, { error: 'a name is required' });
      if (store.users.has(name)) return send(res, 409, { error: `${name} already exists` });
      store.users.add(name);
      send(res, 201, { name });
    },
  },
  {
    method: 'DELETE', path: '/api/users',
    handle: ({ res, url }) => {
      store.users.delete(url.searchParams.get('name'));
      res.writeHead(204);
      res.end();
    },
  },
];
```

A página tem um formulário de um campo e escreve a resposta do servidor num parágrafo marcado com
`role="status"`: *Welcome, maria* ou *maria already exists*. Salve como `app/public/signup.html`:

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign up · Quitanda</title>
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  <main>
    <h1>Sign up</h1>
    <form>
      <label for="name">Name</label>
      <input id="name" name="name" required>
      <button type="submit">Create account</button>
    </form>
    <p role="status"></p>
  </main>
  <script>
    document.querySelector('form').addEventListener('submit', async (event) => {
      event.preventDefault();
      const name = document.querySelector('#name').value;
      const response = await fetch('/api/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name }),
      });
      const answer = await response.json();
      document.querySelector('[role=status]').textContent =
        response.ok ? `Welcome, ${answer.name}` : answer.error;
    });
  </script>
</body>
</html>
```

Reinicie a loja, porque o servidor lê `app/routes/` quando inicia, e peça duas vezes o mesmo
cliente num segundo terminal. O número no fim de cada linha é o código de status, que o `-w` pede
ao `curl` para imprimir:

```
ana@laptop:~/quitanda$ curl -s -w ' %{http_code}\n' -X POST -H 'Content-Type: application/json' -d '{"name":"maria"}' http://localhost:3000/api/users
{"name":"maria"} 201
ana@laptop:~/quitanda$ curl -s -w ' %{http_code}\n' -X POST -H 'Content-Type: application/json' -d '{"name":"maria"}' http://localhost:3000/api/users
{"error":"maria already exists"} 409
ana@laptop:~/quitanda$ curl -s -w '%{http_code}\n' -X DELETE 'http://localhost:3000/api/users?name=maria'
204
ana@laptop:~/quitanda$ curl -s -w ' %{http_code}\n' -X POST -H 'Content-Type: application/json' -d '{"name":"maria"}' http://localhost:3000/api/users
{"name":"maria"} 201
```

A segunda requisição é recusada, o `DELETE` responde `204` sem corpo, e depois dele o nome fica
livre de novo. **Esse `409` é o comportamento correto.** Dois clientes com o mesmo nome seriam um
defeito, e a loja tem razão em recusar.

## O teste óbvio

Quem escreve o primeiro teste da página escolhe um nome, digita, aperta o botão e confere a
saudação. Salve como `tests/signup.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('a new customer can sign up', async ({ page }) => {
  await page.goto('/signup.html');
  await page.getByLabel('Name').fill('maria');
  await page.getByRole('button', { name: 'Create account' }).click();
  await expect(page.getByRole('status')).toHaveText('Welcome, maria');
});
```

Pare qualquer loja que esteja rodando e execute duas vezes:

```
ana@laptop:~/quitanda$ npx playwright test tests/signup.spec.js

Running 1 test using 1 worker

  ✓  1 tests/signup.spec.js:3:1 › a new customer can sign up (205ms)

  1 passed (1.7s)
ana@laptop:~/quitanda$ npx playwright test tests/signup.spec.js

Running 1 test using 1 worker

  ✓  1 tests/signup.spec.js:3:1 › a new customer can sign up (217ms)

  1 passed (1.5s)
```

**Verde duas vezes, e o motivo não é o teste.** A configuração da aula 1 tem um bloco
`webServer`: sem loja na porta 3000, o Playwright inicia uma antes dos testes e a encerra depois.
Cada execução teve uma loja só sua, nascida vazia, então a Maria de cada execução foi a primeira.

## O mesmo teste contra uma loja que continua de pé

O mesmo bloco diz `reuseExistingServer: !process.env.CI`. Na sua máquina a variável `CI` não está
definida, então, quando alguma coisa já responde na porta 3000, o Playwright usa essa em vez de
iniciar a dele. A aula 1 pediu que você deixasse o `npm start` rodando num segundo terminal para
olhar a loja à mão, e a situação é exatamente essa. Com a loja rodando lá, as mesmas duas
execuções:

```
ana@laptop:~/quitanda$ npx playwright test tests/signup.spec.js

Running 1 test using 1 worker

  ✓  1 tests/signup.spec.js:3:1 › a new customer can sign up (236ms)

  1 passed (1.2s)
ana@laptop:~/quitanda$ npx playwright test tests/signup.spec.js

Running 1 test using 1 worker

  ✘  1 tests/signup.spec.js:3:1 › a new customer can sign up (5.2s)


  1) tests/signup.spec.js:3:1 › a new customer can sign up ─────────────────────────────────────────

    Error: expect(locator).toHaveText(expected) failed

    Locator:  getByRole('status')
    Expected: "Welcome, maria"
    Received: "maria already exists"
    Timeout:  5000ms

    Call log:
      - Expect "toHaveText" with timeout 5000ms
      - waiting for getByRole('status')
        9 × locator resolved to <p role="status">maria already exists</p>
          - unexpected value "maria already exists"


      5 |   await page.getByLabel('Name').fill('maria');
      6 |   await page.getByRole('button', { name: 'Create account' }).click();
    > 7 |   await expect(page.getByRole('status')).toHaveText('Welcome, maria');
        |                                          ^
      8 | });
      9 |
        at /home/ana/quitanda/tests/signup.spec.js:7:42

    Error Context: test-results/signup-a-new-customer-can-sign-up/error-context.md

  1 failed
    tests/signup.spec.js:3:1 › a new customer can sign up ──────────────────────────────────────────
```

A primeira execução criou a Maria na loja que continua de pé. A segunda pediu a Maria de novo e
recebeu a resposta que a loja deve dar: *maria already exists*. **A aplicação está certa e o teste
está errado**, e a mensagem de erro não culpa nenhum dos dois; quem lê *Expected "Welcome, maria",
Received "maria already exists"* num relatório noturno pode perder uma hora decidindo se o
cadastro quebrou.

Três propriedades dessa falha merecem nome, porque todo problema de dados desta aula tem algumas
delas:

- **depende da história.** O teste não tem defeito que se veja lendo o código. Falha por causa de
  uma execução anterior, talvez de outra pessoa;
- **depende do ambiente.** O mesmo arquivo fica verde com uma loja nova e vermelho com uma
  reaproveitada. Num servidor de build, onde `CI` está definida, uma loja nova sobe toda vez e ele
  passaria por meses. Falharia no primeiro dia em que alguém apontasse a suíte para um ambiente de
  teste compartilhado cujo banco nunca é esvaziado;
- **repetir não adianta.** A Maria continua lá na terceira execução. A aula 14 chama de instável o
  teste que falha *de vez em quando*; este falha toda vez que as condições se cumprem, o que o
  torna mais fácil de diagnosticar e igualmente fácil de interpretar errado.

Um ambiente de teste compartilhado, do tipo que a aula 21 de `manual-testing` descreve, é a loja
reaproveitada em escala maior: um banco que vive meses, escrito por toda execução de teste e por
toda pessoa que testa à mão. Um teste que precisa do nome *maria* livre ali é um teste que passa
uma vez.
