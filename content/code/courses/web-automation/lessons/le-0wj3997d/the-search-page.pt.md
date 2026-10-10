---
title: A página de busca, e a sua falha
version: 1
---

A loja ganha uma segunda página: uma caixa onde você digita o nome de uma fruta e uma lista das
frutas que combinam. **Ela é feita do jeito que muitas caixas de busca reais são feitas, e tem a
falha que muitas delas têm.** Cada tecla que você aperta envia uma requisição, nada cancela as que
já estão a caminho, e a página desenha a resposta que chegar por último. Três arquivos a compõem, e
a loja não precisa de nenhuma outra mudança: o servidor pega a rota nova na próxima vez que
iniciar, como a aula 1 explicou.

## A rota

A busca em si é uma linha: os produtos cujo nome contém o que foi digitado, em minúsculas. A linha
acima dela é a falha. O servidor espera antes de responder, e espera **mais por uma pergunta mais
curta**: 900 milissegundos menos 150 por letra, então `p` espera 750 ms e `papaya` não espera nada.
Um servidor real é lento por motivos reais, como uma palavra curta que combina com mais linhas, um
cache frio ou uma máquina mais ocupada, e nenhum deles promete que as respostas voltem na ordem em
que as perguntas saíram. Este torna a desordem certa, para você poder vê-la todas as vezes. Salve
como `app/routes/search.js`:

```javascript
import { send, pause } from '../http.js';
import { store } from '../store.js';

export const routes = [
  {
    method: 'GET', path: '/api/search',
    handle: async ({ res, url }) => {
      const q = (url.searchParams.get('q') ?? '').toLowerCase();
      // A known flaw, on purpose: a short query takes longer to answer, so
      // the answer to "p" arrives after the answer to "papaya".
      await pause(Math.max(0, 900 - 150 * q.length));
      send(res, 200, store.products.filter((p) => p.name.toLowerCase().includes(q)));
    },
  },
];
```

## A página

Um rótulo, a caixa, uma linha que diz quantas frutas foram achadas, e a lista. Dois atributos
importam para um teste. `role="status"` na contagem faz um leitor de tela anunciá-la quando ela
muda. **`aria-busy` na lista diz se a página ainda está esperando uma resposta**: a página o põe em
`true` quando uma pergunta sai e de volta em `false` quando nenhuma está pendente. Ele existe para a
tecnologia assistiva, que não deve ler em voz alta uma lista prestes a mudar, e o mesmo fato é
exatamente o que um teste precisa. Salve como `app/public/search.html`:

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Search · Quitanda</title>
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  <main>
    <h1>Search</h1>
    <label for="q">Fruit</label>
    <input id="q" type="search" autocomplete="off">
    <p id="count" role="status"></p>
    <ul id="results" aria-busy="false"></ul>
  </main>
  <script src="/search.js"></script>
</body>
</html>
```

## O script

Ele escuta `input`, o evento que uma caixa de texto dispara toda vez que o valor muda, ou seja, uma
vez por tecla. Conta em `waiting` as perguntas ainda sem resposta e desenha cada resposta quando
ela chega, sem verificar se ela corresponde ao que está na caixa agora. Salve como
`app/public/search.js`:

```javascript
const input = document.querySelector('#q');
const results = document.querySelector('#results');
const count = document.querySelector('#count');
let waiting = 0;

// One request per key pressed, and nothing cancels the older ones.
input.addEventListener('input', async () => {
  waiting += 1;
  results.setAttribute('aria-busy', 'true');
  const response = await fetch('/api/search?q=' + encodeURIComponent(input.value));
  const found = await response.json();
  // A known flaw, on purpose: whichever answer arrives LAST is shown, even
  // when it answers an older question.
  results.replaceChildren(...found.map((p) => {
    const li = document.createElement('li');
    li.textContent = p.name;
    return li;
  }));
  count.textContent = `${found.length} found`;
  waiting -= 1;
  if (waiting === 0) results.setAttribute('aria-busy', 'false');
});
```

`fetch` e `await` são o assunto das aulas 14 e 16 de `javascript`; o que importa aqui é o que o
`await` faz com a ordem das coisas. Cada chamada do ouvinte para no seu `await fetch(...)` e só
continua quando a sua própria resposta chega, enquanto a tecla seguinte começa outra chamada ao
lado. Seis teclas, seis chamadas no ar ao mesmo tempo, e cada uma termina quando a sua resposta
deixa.

## Testando à mão

Inicie a loja com `npm start`, abra `http://localhost:3000/search.html` e digite `papaya`. Depois
limpe a caixa e cole a palavra de uma vez. As duas tentativas provavelmente terminam em **Papaya** e
*1 found*, o que está certo.

Colar é uma mudança de valor só, então uma requisição e uma resposta. Digitar são seis requisições,
e se as respostas voltam em ordem depende da velocidade com que você digitou. Quarenta palavras por
minuto, uma velocidade de digitação comum, dá umas 200 letras por minuto, ou uma tecla a cada
300 ms, e nesse ritmo as respostas voltam em ordem. **O resultado depende da velocidade de quem
digita**, que é o primeiro sinal de um defeito de tempo e o motivo de alguém testando à mão poder
nunca vê-lo. A próxima seção digita mais rápido do que você consegue e imprime o que acontece.
