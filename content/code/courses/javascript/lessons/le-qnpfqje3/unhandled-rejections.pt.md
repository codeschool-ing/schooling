---
title: Uma promessa que ninguém esperou
version: 1
---

O erro que o `await` facilita é **esquecê-lo**. Chamar uma função `async` sem `await` começa o trabalho
e segue direto, e se o trabalho falhar, não há nada lá para pegá-lo:

```javascript
const save = async (book) => {
  await new Promise((ok) => setTimeout(ok, 50));
  throw new Error(`could not save ${book}`);
};

function onClick() {
  save("Iracema");
  console.log("saved!");
}

onClick();
```

```
ana@dev:~/js$ node forgot.mjs; echo "exit code: $?"
saved!
file:///home/ana/js/forgot.mjs:3
  throw new Error(`could not save ${book}`);
        ^

Error: could not save Iracema
    at save (file:///home/ana/js/forgot.mjs:3:9)

Node.js v22.22.0
exit code: 1
```

`onClick` imprimiu **`saved!` antes de qualquer coisa ser salva**, porque `save` devolveu uma promessa
pendente e ninguém a esperou. Cinquenta milissegundos depois a promessa rejeitou, nenhum `.catch` nem
`try` estava preso a ela, e o Node **encerrou o processo inteiro com código de saída 1**. Essa é a regra
do Node desde a versão 15: uma rejeição não tratada é tratada como uma exceção não pega, porque a
alternativa é uma falha que acontece e nunca é mencionada.

## No navegador

```html
<!doctype html>
<script>
  window.addEventListener("unhandledrejection", (event) => {
    console.log("nobody handled:", event.reason.message);
  });
  const save = async (book) => {
    throw new Error(`could not save ${book}`);
  };
  save("Iracema");
  console.log("saved!");
</script>
```

```
ana@dev:~/js$ page forgot.html
saved!
nobody handled: could not save Iracema
Uncaught Error: could not save Iracema
```

A página não para: ela relata a rejeição como não pega, e dispara um **evento `unhandledrejection`**
no `window`, que a página usou para registrá-la. Serviços de relatório de erros escutam esse evento, e
é assim que uma equipe fica sabendo de falhas para as quais ninguém escreveu um `catch`.

## Como evitar

- **Dê `await` em toda promessa que você começar, ou a devolva para quem vai dar.** Uma regra de
  linter, `no-floating-promises` nas ferramentas do TypeScript, aponta as que você esqueceu;
- quando você de propósito não espera, como num salvamento em segundo plano, **prenda um `.catch` que
  faça algo visível**: registre, tente de novo, ou avise o usuário;
- nunca imprima "saved!" antes de o salvamento se resolver. A mensagem é uma afirmação, e só a
  promessa sabe se ela é verdadeira.
