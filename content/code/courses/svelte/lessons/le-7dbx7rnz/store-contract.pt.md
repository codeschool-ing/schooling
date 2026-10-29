---
title: O que é um store
version: 1
---

**Um store é qualquer objeto com um método `subscribe`**: você chama `subscribe` com uma função, o
store chama essa função na hora com o valor atual e de novo cada vez que o valor muda, e `subscribe`
devolve uma função que encerra a inscrição. Esse é o contrato inteiro, e ele é mais antigo que as
runes: o Svelte 3 e o 4 usavam stores para todo estado compartilhado entre componentes, e muito código
ainda usa.

Vale conhecer os stores por dois motivos. Você vai lê-los em qualquer código Svelte anterior a 2025, e
eles continuam sendo a ferramenta certa para um tipo de valor: um que **chega de fora ao longo do
tempo**, como um relógio, uma conexão ou um sensor, e que só deve ser escutado enquanto alguém olha.

## Um store escrito à mão

O exemplo mais claro é um relógio. Este é escrito direto contra o contrato, sem biblioteca, para que
cada parte fique à vista. Salve como `src/lib/timer.js`:

```schooling-example
{"language": "javascript", "file": "src/lib/timer.js", "parts": [
 {"code": "// timer.js: a clock, as a store written by hand.\nexport const now = {\n\tsubscribe(run) {", "note": "Um store é um objeto com `subscribe`. Nada mais é exigido."},
 {"code": "\t\trun(Date.now());\n\t\tconst id = setInterval(() => run(Date.now()), 250);", "note": "O contrato: chamar o assinante na hora com o valor atual, e de novo a cada mudança."},
 {"code": "\t\treturn () => clearInterval(id);\n\t}\n};", "note": "O que o `subscribe` devolve encerra a inscrição. Aqui isso também para o timer, então um relógio que ninguém olha não custa nada."}
]}
```

E uma página para observá-lo. O timer não faz parte do planner, então ganha uma página própria em
`/timer`, como as aulas 4 e 8 fizeram com os seus experimentos:

```schooling-example
{"language": "html", "file": "src/routes/timer/+page.svelte", "parts": [
 {"code": "<script>\n\timport { now } from '#lib/timer.js';\n\n\tconst opened = Date.now();\n</script>", "note": "Um `$` na frente do nome de um store, num componente, se inscreve nele quando o componente é criado e cancela a inscrição quando ele é destruído."},
 {"code": "<main>\n\t<h1>Study timer</h1>\n\t<p>{Math.floor(($now - opened) / 1000)} s on this page</p>\n</main>", "note": "`$now` lê o valor atual do store, e o parágrafo se atualiza cada vez que o store chama de volta."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/timer --wait 2400
-- wait 2400
at /timer
- main:
  - heading "Study timer" [level=1]
  - paragraph: 2 s on this page
```

Dois segundos, depois de uma espera de 2,4: o relógio bate a cada quarto de segundo, e a página mostra
segundos inteiros. **O prefixo `$` é o que torna um store agradável de usar**: sem ele você chamaria
`subscribe` por conta própria, guardaria o valor numa variável e lembraria de chamar a função que ele
devolve quando o componente fosse embora. O compilador escreve as três coisas por você sempre que um
componente lê `$now`.

## As regras do `$`

O `$store` funciona no script e na marcação de um componente, para um store importado ou declarado no
nível de cima desse componente. Ele não funciona num módulo `.js` comum, que o compilador não
reescreve, e não funciona para um store criado dentro de uma função, porque o compilador precisa saber
na hora do build em que nome se inscrever. Nesses lugares, `get(store)` de `svelte/store` lê o valor
uma vez, e o `subscribe` está sempre lá.
