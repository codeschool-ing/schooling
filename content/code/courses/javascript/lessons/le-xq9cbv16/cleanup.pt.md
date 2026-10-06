---
title: Temporizadores que você esquece de parar
version: 1
---

**Um temporizador segura o seu callback, e tudo o que a closure do callback alcança, até rodar ou ser
limpo.** Um intervalo nunca acaba sozinho. No Node, temporizadores têm mais um efeito: mantêm o
processo vivo.

```javascript
const reminder = setTimeout(() => console.log("this would print after a minute"), 60_000);
reminder.unref();

const round = (ms) => Math.round(ms / 100) * 100;
const start = performance.now();
process.on("exit", () => console.log("process ended after about", round(performance.now() - start), "ms"));

const poll = setInterval(() => console.log("still polling"), 1000);
setTimeout(() => {
  clearInterval(poll);
  console.log("stopped the poll; nothing is left to wait for");
}, 2500);
```

```
ana@dev:~/js$ node alive.js
still polling
still polling
stopped the poll; nothing is left to wait for
process ended after about 2500 ms
```

O Node sai quando não tem mais nada para esperar. **Um temporizador pendente conta como algo a
esperar**, então a consulta manteve o processo rodando até o `clearInterval` pará-la, dois segundos e
meio depois. O lembrete foi armado para um minuto, e mesmo assim o processo terminou por volta de
2500 ms, porque `reminder.unref()` disse ao Node para não ficar vivo só por causa daquele
temporizador: ele ainda dispara se o processo estiver rodando de qualquer jeito, e não segura o
processo aberto. É para isso que servem os métodos do objeto-temporizador, e é por isso que o id do
Node é um objeto.

## A regra

**Todo intervalo, e todo timeout que possa sobreviver à coisa a que pertence, precisa de uma limpeza
correspondente**, escrita junto com o temporizador:

- um componente ou trecho de página que começa uma consulta a para quando é removido. Os frameworks
  dão um lugar para isso, uma função de limpeza ou um gancho "ao destruir", e é ali que vai o
  `clearInterval`;
- um servidor que arma um temporizador por requisição o limpa quando a requisição termina, ou mil
  requisições deixam mil temporizadores;
- um script que deve terminar, termina: se uma ferramenta de linha de comando trava depois de imprimir
  o resultado, um temporizador esquecido ou uma conexão aberta é o motivo de costume.

A aula 19 mede quanto temporizadores e listeners esquecidos custam em memória. A aula 16 usa o jeito
mais novo de cancelar trabalho em andamento, o `AbortController`, que o `fetch` entende.
