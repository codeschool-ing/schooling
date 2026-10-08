---
title: Instalando a ferramenta de linha de comando
version: 2
---

O Tailwind é um programa que lê o seu HTML, encontra os nomes de classe nele e escreve uma folha de estilos com uma regra para cada um. Ele roda em **Node.js**, o runtime de JavaScript que também roda a maior parte das ferramentas de build da web.

**O Node.js já está na sua máquina** se você o instalou na seção 03 da aula 1, para o validador. Se não, essa seção é o caminho curto: instale a LTS a partir do nodejs.org, abra um terminal novo, e `node --version` imprime um número de versão. A seção 04 de lá trata do que dá errado.

**Instale o Tailwind na pasta do site.** Na pasta do seu site, o mesmo comando em todo sistema:

```bash
npm install tailwindcss@4.3.3 @tailwindcss/cli@4.3.3
```

O `npm` é o gerenciador de pacotes do Node, e baixa os dois pacotes para uma pasta `node_modules` ao lado dos seus arquivos. Fixar a versão com `@4.3.3` é o que este curso usou na gravação; sem isso você recebe a mais recente. Esta aula não cita o que o `npm install` imprime, porque isso depende da rede no dia.

**Crie uma pasta para o primeiro exemplo.** Cada exemplo desta aula é um site pequeno à parte: uma pasta dentro de `site` com um `index.html` e um `input.css`, para que um build leia uma página e mais nada. A primeira pasta é `first`, e a página dela, `first/index.html`, é o cartão da seção 02:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <link rel="stylesheet" href="out.css">
  </head>
  <body class="bg-stone-50 text-stone-900">
    <main id="content" class="mx-auto max-w-3xl p-4">
      <h1 id="title" class="text-2xl font-bold">This week</h1>
      <article id="poetry" class="mt-4 rounded-lg border-l-4 border-emerald-700 bg-white p-4">
        <h2 class="text-lg font-semibold">Poetry reading</h2>
        <p class="mt-1 text-stone-600">Thursday, 7 pm.</p>
      </article>
    </main>
  </body>
</html>
```

**Escreva uma folha de entrada**, `first/input.css`, com uma linha:

```css
@import "tailwindcss";
```

**Rode o build.** O `npx` roda um comando de um pacote instalado. Aqui ele é rodado a partir de `~/site` no primeiro exemplo; `--cwd first` faz da pasta `first` o lugar de onde ele lê e onde escreve:

```
ana@laptop:~/site$ npx @tailwindcss/cli --cwd first -i input.css -o out.css --silent
```

Ele não imprimiu nada, porque `--silent` pede que ele só fale de erros. Escreveu `first/out.css`, e a página aponta para esse arquivo com um `<link rel="stylesheet" href="out.css">` comum. Enquanto você trabalha, acrescente **`--watch`**, e o comando continua rodando e refaz o build toda vez que você salva um arquivo.
