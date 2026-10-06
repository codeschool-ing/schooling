---
title: Tentando de novo, com cuidado
version: 1
---

Algumas falhas são temporárias: um servidor reiniciando, ou ocupado, responde **`503 Service
Unavailable`** e espera ser chamado de novo. O `/api/flaky` do laboratório falha as duas primeiras
requisições desse jeito:

```html
<!doctype html>
<script type="module">
  import { getJSON } from "./get-json.js";
  const wait = (ms) => new Promise((ok) => setTimeout(ok, ms));

  async function withRetries(url, attempts = 4) {
    for (let i = 1; i <= attempts; i++) {
      try {
        return await getJSON(url);
      } catch (err) {
        console.log(`attempt ${i} failed: ${err.message}`);
        if (i === attempts) throw err;
        await wait(100 * 2 ** (i - 1));
      }
    }
  }

  const answer = await withRetries("/api/flaky?fails=2");
  console.log("answered on attempt", answer.attempt);
</script>
```

```
ana@dev:~/js$ page retry.html --wait 1500
[error] Failed to load resource: the server responded with a status of 503 (Service Unavailable)
attempt 1 failed: /api/flaky?fails=2: 503 busy, try again
[error] Failed to load resource: the server responded with a status of 503 (Service Unavailable)
attempt 2 failed: /api/flaky?fails=2: 503 busy, try again
answered on attempt 3
```

A terceira tentativa foi respondida. Entre as tentativas, `withRetries` esperou **100 ms, depois
200 ms**, dobrando a cada vez. Isso é **backoff exponencial**: um servidor em apuros ganha mais fôlego a
cada nova tentativa, em vez de uma multidão de clientes tentando de novo ao mesmo tempo e o mantendo em
apuros. Clientes de verdade costumam acrescentar um pouco de aleatoriedade à espera, chamada de
**jitter**, para que mil clientes que falharam juntos não voltem todos juntos.

## O que é seguro tentar de novo

**Tente de novo só requisições seguras de repetir.** Ler um livro, um `GET`, pode ser pedido duas
vezes sem dano. Criar um empréstimo, um `POST`, pode ter dado certo no servidor antes de a resposta se
perder, e tentar de novo criaria um segundo empréstimo. Esse é o caso em que a seção anterior
terminou: o cliente não consegue distinguir "falhou" de "deu certo e eu nunca soube".

Então um laço de novas tentativas precisa de três limites:

- **que falhas**: um 503 ou uma conexão perdida, sim; um 404 ou um 422, nunca, porque perguntar de
  novo traz a mesma resposta;
- **que requisições**: leituras à vontade; escritas só quando a API as torna seguras de repetir,
  em geral com uma chave de idempotência que o servidor usa para reconhecer uma requisição que já
  tratou;
- **quantas vezes**: `attempts = 4` aqui, e depois o erro vai para o usuário, que merece saber.

O `withRetries` só tem o último dos três, o que basta para um `GET` no laboratório e não para código
de verdade, em que os dois primeiros decidem se tentar de novo ajuda ou atrapalha.
