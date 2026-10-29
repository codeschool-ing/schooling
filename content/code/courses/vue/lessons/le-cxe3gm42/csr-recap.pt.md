---
title: O que o planner do Vite manda
version: 1
---

**Tudo o que o planner do Vite mostra é desenhado no navegador, por JavaScript, depois que a página
chegou.** Isso é *renderização no cliente*, CSR, e as aulas 1 a 17 nunca precisaram de um nome para
ela, porque não havia com o que comparar. Faça o build e peça uma página de curso ao servidor de
preview, do jeito que um programa que não roda JavaScript pediria:

```
ana@dev:~/vue/planner$ curl -s http://localhost:4173/courses/spanish
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <link rel="icon" href="/favicon.ico">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Study planner</title>
    <script type="module" crossorigin src="/assets/index-CNeZWQJG.js"></script>
    <link rel="stylesheet" crossorigin href="/assets/index-BWz-O59j.css">
  </head>
  <body>
    <div id="app"></div>
  </body>
</html>
```

**A resposta inteira é a `<div id="app">` vazia e um script.** Ela é a mesma para todo endereço, como a
aula 17 mostrou, e o curso, as sessões e os totais só existem depois que o `index-….js` foi baixado,
interpretado e executado, e buscou por sua vez o `courses.json`. Um navegador com o JavaScript
desligado vê exatamente isso:

```
ana@dev:~/vue/planner$ look http://localhost:4173/ --no-js --text body
== the text of body
```

Nada. Pouca gente desliga o JavaScript, então esse não é o custo. Os custos são três:

- **Tempo até a primeira palavra.** Até o script rodar, a página fica em branco. Num computador
  rápido isso é uma fração de segundo; num celular barato numa rede lenta, os 47 kB do bundle da
  aula 17 e depois os dados são segundos de tela branca.
- **Programas que leem páginas sem rodá-las.** Um link colado num chat vira uma prévia por meio de um
  programa que lê o HTML; o mesmo vale para boa parte do que um buscador vê primeiro. Os dois
  encontram a `<div>` vazia.
- **Nada é desenhado se o script falha.** Um erro na inicialização, ou um arquivo bloqueado, e o
  leitor recebe a página em branco e mais nada.

Nada disso importa muito para o planner, uma ferramenta usada todo dia pela pessoa cujos dados ela
guarda. Importa muito para uma página cujo trabalho é ser encontrada e lida: a descrição de um curso,
um artigo, uma loja. O resto desta aula são as outras formas de fazer uma página, e o que cada uma
troca.
