---
title: A testemunha, com e sem a política
version: 1
---

**Uma política é provada do jeito que toda defesa deste curso é: por uma entrada comum que teria feito
algo, e agora não faz nada.** A testemunha aqui é o menor script que existe, um que muda o título da
página, acrescentado à página do jeito que um injetado seria: como elemento, de dentro da página. Salve
como `server/witness.js`:

```javascript
// server/witness.js
const script = document.createElement("script");
script.textContent = 'document.title = "an inline script ran"';
document.body.append(script);
document.title;
```

O `look.mjs` da aula 7 o roda na página e mostra o valor da última linha, o título.

Primeiro no servidor de desenvolvimento, que não manda política:

```
ana@dev:~/planner$ node server/look.mjs http://localhost:5173/ "$(cat server/witness.js)"
result:   an inline script ran
```

**O título mudou**: um script inline acrescentado à página rodou, como qualquer um rodaria. Depois no site
empacotado, sob a sua política:

```
ana@dev:~/planner$ node server/look.mjs http://localhost:4173/ "$(cat server/witness.js)"
console:  Executing inline script violates the following Content Security Policy directive 'script-src 'self''. Either the 'unsafe-inline' keyword, a hash ('sha256-pEY6BBBxZAVxAefxgixuyIDc9Sf/P5B1/XuTyDX/02k='), or a nonce ('nonce-...') is required to enable inline execution. The action has been blocked.
result:   Study planner
```

**O título continua o do planner**, e o console diz exatamente por quê, nomeando a diretiva que recusou e
os três jeitos de permitir: `'unsafe-inline'`, um hash do script, ou um nonce. O primeiro desfaria a
política, e os outros dois são para scripts inline que o próprio site escreve, e o planner não tem
nenhum. O código da própria página rodou, como o teste da seção anterior mostrou; o script que não era
dela não rodou.

## O que a política não consegue fazer

Uma política restringe de onde vem o código, então **ela não faz nada contra um código que vem do lugar
certo e faz a coisa errada**. Se o próprio `assets/index-….js` do planner escrevesse o texto de uma
pessoa na página com `innerHTML`, essa linha roda, porque é o próprio script do planner. O que a política
impede é o passo *seguinte*, um `<script>` injetado ou um atributo de tratador rodando; a aula 9 tira o
primeiro passo, para não sobrar nada para a política impedir.
