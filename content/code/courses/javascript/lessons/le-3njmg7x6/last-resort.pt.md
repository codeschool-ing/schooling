---
title: A última linha de defesa
version: 1
---

Alguns erros vão chegar ao topo sem ser pegos, porque ninguém prevê todo bug. **Os dois hospedeiros
deixam um programa saber deles ali**, que é onde se prendem logs e relatórios de erro:

```javascript
process.on("uncaughtException", (err) => {
  console.error(`fatal: ${err.name}: ${err.message}`);
  process.exitCode = 1;
});

setTimeout(() => {
  null.title;
}, 0);
console.log("started");
```

```
ana@dev:~/js$ node last-resort.js; echo "exit code: $?"
started
fatal: TypeError: Cannot read properties of null (reading 'title')
exit code: 1
```

`process.on("uncaughtException", …)` recebeu o `TypeError` lançado no temporizador. O handler o
registrou numa linha e **definiu o código de saída como 1**, para quem quer que tenha iniciado o
programa, um terminal, uma implantação, um agendador, saber que ele falhou. Isso é tudo o que um handler
desses deve fazer. **O programa fica num estado desconhecido depois de um erro não pego**: algo estava
pela metade e nunca terminou. A resposta segura é registrar o que aconteceu e parar, e deixar quem
supervisiona o processo começar um novo.

```html
<!doctype html>
<script>
  window.addEventListener("error", (event) => {
    console.log("reported:", event.message, "at line", event.lineno);
  });
  setTimeout(() => {
    document.querySelector("#missing").textContent = "x";
  }, 0);
</script>
```

```
ana@dev:~/js$ page window-error.html
reported: Uncaught TypeError: Cannot set properties of null (setting 'textContent') at line 7
Uncaught TypeError: Cannot set properties of null (setting 'textContent')
```

Numa página, o evento `error` no `window` faz o mesmo papel. O handler recebeu a mensagem e a linha, e
o navegador ainda o relatou como não pego, como deve. **Uma página não para num erro não pego**: o
resto da página continua funcionando, e só o código que lançou é abandonado. A aula 14 mostrou o
`unhandledrejection`, a mesma ideia para promessas, e serviços de relatório de erros escutam os dois.

Nada disso substitui tratar os erros onde eles acontecem. **Um handler global é para os erros que
ninguém esperava**, para que cada um seja visto uma vez, e vire um relatório de bug em vez de um
mistério.
