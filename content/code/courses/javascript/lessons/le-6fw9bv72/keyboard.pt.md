---
title: O teclado, e por que um botão é um botão
version: 1
---

Algumas pessoas nunca usam mouse: elas andam pela página com Tab e apertam Enter ou Espaço para agir,
ou um leitor de tela faz isso por elas. **Uma interface que só responde a cliques as deixa de fora**,
e o conserto é principalmente usar o elemento certo:

```html
<!doctype html>
<div class="fake" onclick="console.log('div clicked')">Lend (a div)</div>
<button class="real">Lend (a button)</button>
<script>
  document.querySelector(".real").addEventListener("click", () => console.log("button clicked"));
  document.addEventListener("keydown", (event) => {
    console.log("keydown:", JSON.stringify(event.key), event.code, "on", document.activeElement.tagName);
  });
</script>
```

```
ana@dev:~/js$ page keys.html --do 'press Tab' --do 'press Enter' --do 'press Space'
-- press Tab
keydown: "Tab" Tab on BODY
-- press Enter
keydown: "Enter" Enter on BUTTON
button clicked
-- press Space
keydown: " " Space on BUTTON
button clicked
```

A página tem uma `<div>` com handler de clique, estilizada para parecer um botão, e um `<button>` de
verdade. O `page` apertou Tab uma vez, a partir do topo da página:

- **o foco foi direto para o `<button>`. A `<div>` foi pulada**, porque uma `<div>` não recebe foco,
  então um usuário de teclado nunca chega a ela;
- Enter no botão e Espaço no botão **dispararam os dois o listener de `click`**. O navegador
  transforma essas teclas num clique de botão por você; numa `<div>` ele não faz nenhuma das duas
  coisas, nem com foco.

**Use `<button>` para tudo o que age, e `<a href>` para tudo o que leva a algum lugar.** Os dois vêm
com foco, ativação por teclado e o anúncio certo para um leitor de tela. Fazer uma `<div>` se
comportar igual pede um `tabindex`, um `role` e tratamento de teclas escrito por você, e ainda é fácil
errar. O curso `front-quality`, nas aulas 11 e 12, leva navegação por teclado e ARIA adiante.

## Lendo teclas

O `keydown` dispara para toda tecla, no elemento com foco, e borbulha como um clique. **`event.key` é
o que a tecla significa**, `"Enter"` ou `" "` para Espaço ou `"a"`, e depende do layout do teclado;
**`event.code` é que tecla física foi**, `Space` ou `KeyA`, seja qual for o layout. Use `key` para
texto e comandos como Escape para fechar; use `code` para algo ligado à posição de uma tecla, como as
teclas de movimento de um jogo.
