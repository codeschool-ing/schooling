---
title: Zombie.js, e o que a última versão dele diz
version: 1
---

O Zombie.js chegou ao npm em 2011 com uma promessa no subtítulo: "Insanely fast, headless
full-stack testing using Node.js", testes absurdamente rápidos, sem janela, usando Node.js. Durante
anos foi o que um desenvolvedor Node queria dizer com testar uma página sem navegador. **Hoje é uma
ferramenta para reconhecer num projeto antigo, não para começar um**, e o registro do npm diz por
quê antes de qualquer código rodar.

## Como ele se lê

O Zombie dá um único objeto, um `Browser`, que carrega páginas e age sobre elas com as palavras que
uma pessoa usaria: visitar, preencher, apertar um botão, e então conferir. O README dele abre com
este exemplo, escrito para o executor Mocha:

```javascript
const Browser = require('zombie');

// We're going to make requests to http://example.com/signup
// Which will be routed to our test server localhost:3000
Browser.localhost('example.com', 3000);

describe('User visits signup page', function() {

  const browser = new Browser();

  before(function(done) {
    browser.visit('/signup', done);
  });

  describe('submits form', function() {

    before(function(done) {
      browser
        .fill('email',    'zombie@underworld.dead')
        .fill('password', 'eat-the-living')
        .pressButton('Sign Me Up!', done);
    });

    it('should be successful', function() {
      browser.assert.success();
    });

    it('should see welcome page', function() {
      browser.assert.text('title', 'Welcome To Brains Depot');
    });
  });
});
```

**Toda ação recebe um callback, e o callback é a espera.** O `visit` chama `done` quando o Zombie
decide que a página terminou de carregar; o `pressButton` chama quando o formulário foi enviado e a
página seguinte carregou. Você nunca escreve uma espera. Isso se lê bem, e põe a pergunta inteira
de *quando a página está pronta* dentro do Zombie, onde você não enxerga.

## O estado dele, pelo registro

O `npm view` pergunta ao registro sobre um pacote sem instalá-lo. A lista de versões termina
assim:

```
ana@laptop:~/quitanda$ npm view zombie time | tail -6
  '6.1.0': '2018-04-02T23:14:43.758Z',
  '6.1.1': '2018-04-07T17:12:16.567Z',
  '6.1.2': '2018-04-29T21:26:50.740Z',
  '6.1.3': '2018-08-12T03:18:03.070Z',
  '6.1.4': '2018-11-27T17:53:28.989Z'
}
```

**A última versão é a 6.1.4, de 27 de novembro de 2018.** Nada foi publicado depois. Do que ele
depende diz o resto:

```
ana@laptop:~/quitanda$ npm view zombie version dependencies.jsdom dependencies.request
version = '6.1.4'
dependencies.jsdom = '11.12.0'
dependencies.request = '^2.85.0'
ana@laptop:~/quitanda$ npm view request deprecated
request has been deprecated, see https://github.com/request/request/issues/3142
```

O Zombie fixa o jsdom em exatamente 11.12.0, e esta aula instala o jsdom 30.1.2: dezenove versões
maiores de trabalho no DOM que ele nunca vai receber. Ele busca as páginas com o `request`, que os
próprios autores declararam obsoleto. Nenhum dos dois faz um teste falhar hoje. Os dois dizem que
ninguém está mantendo a ferramenta em dia com a web.

## Uma rodada, fora do projeto

Para ver com os seus olhos, use uma pasta de rascunho, **não** a `~/quitanda`: não há motivo para
pôr um pacote sem manutenção no `package.json` do projeto. Crie `~/zombie-try`, entre nela e
instale:

```
ana@laptop:~/zombie-try$ npm install zombie@6.1.4
npm warn deprecated request-promise-native@1.0.9: request-promise-native has been deprecated because it extends the now deprecated request package, see https://github.com/request/request/issues/3142
npm warn deprecated har-validator@5.1.5: this library is no longer supported
npm warn deprecated whatwg-encoding@1.0.5: Use @exodus/bytes instead for a more spec-conformant and faster implementation
npm warn deprecated abab@2.0.6: Use your platform's native atob() and btoa() methods instead
npm warn deprecated domexception@1.0.1: Use your platform's native DOMException instead
npm warn deprecated left-pad@1.3.0: use String.prototype.padStart()
npm warn deprecated w3c-hr-time@1.0.2: Use your platform's native performance.now() and performance.timeOrigin.
npm warn deprecated uuid@3.4.0: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
npm warn deprecated request@2.88.2: request has been deprecated, see https://github.com/request/request/issues/3142
npm warn deprecated core-js@2.6.12: core-js@<3.23.3 is no longer maintained and not recommended for usage due to the number of issues. Because of the V8 engine whims, feature detection in old core-js versions could cause a slowdown up to 100x even if nothing is polyfilled. Some versions have web compatibility issues. Please, upgrade your dependencies to the actual version of core-js.

added 104 packages in 4s

4 packages are looking for funding
  run `npm fund` for details
```

Cada aviso de obsolescência ali é um pacote que o Zombie puxa. Depois escreva um arquivo chamado
`visit.js` nessa pasta. Ele visita a página inicial da loja, que precisa estar rodando em outro
terminal, e conta os cards duas vezes: quando o `visit` diz que a página está pronta, e dois
segundos depois.

```javascript
// Zombie against the shop: count the cards when visit() is done, and later.
const Browser = require('zombie');

const browser = new Browser({ site: 'http://localhost:3000' });

browser.visit('/', () => {
  console.log(`when visit() called back: ${browser.queryAll('#products li').length} cards`);
  setTimeout(() => {
    console.log(`two seconds later: ${browser.queryAll('#products li').length} cards`);
  }, 2000);
});
```

```
ana@laptop:~/zombie-try$ node visit.js
(node:19961) [DEP0044] DeprecationWarning: The `util.isArray` API is deprecated. Please use `Array.isArray()` instead.
(Use `node --trace-deprecation ...` to show where the warning was created)
when visit() called back: 0 cards
two seconds later: 8 cards
```

**Zero, depois oito.** O callback voltou antes de os cards serem desenhados. A variável `DEBUG`
liga o log do próprio Zombie, e ele mostra a ordem dos acontecimentos:

```
ana@laptop:~/zombie-try$ DEBUG=zombie node visit.js
2026-10-16T01:17:17.222Z zombie Opened window http://localhost:3000/ 
(node:20018) [DEP0044] DeprecationWarning: The `util.isArray` API is deprecated. Please use `Array.isArray()` instead.
(Use `node --trace-deprecation ...` to show where the warning was created)
2026-10-16T01:17:17.263Z zombie GET http://localhost:3000/ => 200
2026-10-16T01:17:17.291Z zombie Loaded document http://localhost:3000/
2026-10-16T01:17:17.296Z zombie GET http://localhost:3000/app.js => 200
2026-10-16T01:17:17.315Z zombie Event loop is empty
when visit() called back: 0 cards
2026-10-16T01:17:17.320Z zombie GET http://localhost:3000/api/products => 200
2026-10-16T01:17:17.335Z zombie GET http://localhost:3000/api/basket => 200
two seconds later: 8 cards
```

O Zombie buscou o `app.js`, rodou, deu o laço de eventos como vazio e chamou o callback. Só depois
disso saíram as requisições para `/api/products` e `/api/basket`. Seja qual for o motivo lá dentro
do Zombie, a requisição de que a página depende não entrou no que ele esperou. Um teste escrito no
estilo dele, `visit` e depois `assert`, falha numa página que está boa; uma verificação de que a
lista começa vazia passa pelo motivo errado.

É a corrida da aula 3, levada para dentro da ferramenta. **Uma ferramenta que decide por você
quando a página está pronta é tão boa quanto a ideia de pronto que ela tem**, e a do Zombie foi
escrita para as páginas de 2018. A resposta do Playwright é esperar pela coisa que você confere, e
não pela página (aula 10). Apague a `~/zombie-try` quando terminar.
