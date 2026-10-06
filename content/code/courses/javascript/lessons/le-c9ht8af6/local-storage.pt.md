---
title: localStorage: lembrado entre visitas
version: 1
---

**O `localStorage` é um pequeno armazém de chaves e valores que um site guarda no navegador**, e
continua lá na próxima vez que o usuário abre o site. A interface dele são quatro métodos: `setItem`,
`getItem`, `removeItem` e `clear`.

```html
<!doctype html>
<script>
  const visits = Number(localStorage.getItem("visits") ?? 0) + 1;
  localStorage.setItem("visits", visits);
  console.log("visit number", visits);

  localStorage.setItem("lastBook", { title: "Iracema" });
  console.log(localStorage.getItem("lastBook"));

  localStorage.setItem("prefs", JSON.stringify({ theme: "dark", perPage: 50 }));
  const prefs = JSON.parse(localStorage.getItem("prefs"));
  console.log(prefs.perPage, typeof localStorage.getItem("visits"));

  console.log(localStorage.length, localStorage.getItem("nothing-here"));
</script>
```

```
ana@dev:~/js$ page shelf.html --fresh
visit number 1
[object Object]
50 string
3 null
ana@dev:~/js$ page shelf.html
visit number 2
[object Object]
50 string
3 null
ana@dev:~/js$ page shelf.html --do newtab
visit number 3
[object Object]
50 string
3 null
-- newtab
visit number 4
[object Object]
50 string
3 null
```

O perfil do navegador é mantido entre as execuções do `page`, então cada execução é uma visita. **O
contador foi 1, 2, 3**, depois 4 numa segunda aba da mesma execução: o valor sobreviveu ao fechamento
do navegador, e as duas abas viram o mesmo armazém.

## Tudo vira string

As outras linhas mostram a regra que pega todo mundo:

- `setItem("lastBook", { title: "Iracema" })` guardou **`[object Object]`**. O valor foi convertido em
  string, do jeito que a aula 2 mostrou um objeto virando texto, e o título se perdeu;
- `typeof localStorage.getItem("visits")` é `string`. O código converteu com `Number` ao ler de volta,
  e é por isso que o contador funcionou;
- **`JSON.stringify` na entrada e `JSON.parse` na saída** é como guardar um objeto, como faz `prefs`. O
  aviso da aula 16 vale: o que o JSON não guarda, como um `Date` ou um `Map`, volta mudado;
- uma chave que nunca foi definida dá `null`, não `undefined`.

## Para que serve

Coisas pequenas que tornam a próxima visita mais agradável: **um tema, uma língua, a última aba que o
usuário tinha aberta, um rascunho ainda não enviado**. Coisas cuja perda seria um incômodo, porque o
usuário pode limpar os dados do site a qualquer momento, janelas privadas os esquecem ao fechar, e um
navegador com pouco espaço pode descartá-los. O que precisa ser guardado vai para um servidor.
