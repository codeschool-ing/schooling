---
title: O que cada um manda além do HTML
version: 1
---

**Uma página renderizada no servidor que vai hidratar precisa mandar os seus dados duas vezes: uma
desenhados como HTML, e outra como dados que o script consiga ler.** O script no navegador tem de
montar a mesma página que o servidor montou, e não consegue fazer isso só com o HTML, então cada
framework escreve na página o que o servidor sabia, dentro de um `<script>` que não é código, e sim
dados. Na aula 1 o planner fazia isso do jeito caro: o seu script buscava o `/courses.json` de novo.
Os quatro frameworks evitam a segunda requisição, e diferem no que põem na página no lugar dela.

`tools/payload.ts` pede uma página a um servidor e mede os scripts escritos dentro dela, os que não
têm `src`. Ele também diz se os títulos dos **outros** cursos estão na página, o que mostra se ela
carrega o plano inteiro ou só o que esta página precisava. Salve ao lado do `weigh.ts`:

```typescript
// tools/payload.ts: what a server-rendered page carries besides its HTML.
//
//   node tools/payload.ts URL...
//
// The scripts written inside the page (no src), their size, and whether the
// titles of the two courses this page does not show are anywhere in it.
for (const url of process.argv.slice(2)) {
  const html = await (await fetch(url)).text();
  const inline = [...html.matchAll(/<script(?![^>]*\ssrc=)[^>]*>([\s\S]*?)<\/script>/g)];
  const bytes = inline.reduce((sum, m) => sum + Buffer.byteLength(m[1]), 0);
  const others = ["HTML and CSS", "JavaScript"].filter((t) => html.includes(`"${t}"`));
  console.log(`${url}  ${inline.length} inline scripts, ${bytes} bytes, other courses: ${others.join(", ") || "none"}`);
}
```

Ele usa o `fetch` do próprio Node, sem navegador, porque a pergunta é o que o servidor mandou. Rode
contra a página do Git dos cinco:

```
ana@dev:~/planner$ node tools/payload.ts http://localhost:3000/courses/git http://localhost:3001/courses/git http://localhost:3002/courses/git http://localhost:3003/courses/git http://localhost:3004/courses/git
http://localhost:3000/courses/git  0 inline scripts, 0 bytes, other courses: none
http://localhost:3001/courses/git  10 inline scripts, 5486 bytes, other courses: none
http://localhost:3002/courses/git  3 inline scripts, 1071 bytes, other courses: HTML and CSS, JavaScript
http://localhost:3003/courses/git  1 inline scripts, 737 bytes, other courses: none
http://localhost:3004/courses/git  3 inline scripts, 1409 bytes, other courses: HTML and CSS, JavaScript
```

## Quatro respostas para o mesmo problema

**O Nuxt e o Angular mandam o plano inteiro.** Cada um registra a resposta de cada requisição de
dados que o servidor fez enquanto renderizava, `useFetch("/api/plan")` num e
`HttpClient.get("/courses.json")` no outro, e a escreve na página: o Nuxt num
`<script id="__NUXT_DATA__">`, o Angular num `<script id="ng-state">`. No navegador a mesma
requisição é atendida por essa cópia em vez da rede. A página mostra um curso e carrega três, porque
a requisição devolveu três.

**O SvelteKit manda o que o `load` devolveu**, e o `load` da página do curso devolveu um curso e as
suas duas sessões. Os dados vão escritos no pequeno script que inicia o app, como argumento de
`kit.start`. Um `load` que devolvesse o plano inteiro mandaria o plano inteiro: o framework manda
exatamente o que você escreveu, e a escolha é sua.

**O Next.js manda outra coisa ainda.** As suas páginas são server components, que nunca rodam no
navegador, então não há componente lá que precise dos dados. O que ele manda, numa série de chamadas
`self.__next_f.push(...)`, é o resultado *renderizado*: uma descrição da árvore de elementos que o
servidor produziu, que o React no navegador usa para hidratar e para manter a página quando a pessoa
navega. Os outros dois cursos não estão nela porque nenhum elemento os mostra. **Os dados que um
server component lê ficam no servidor**, e é também por isso que ele pode ler um arquivo, um banco
ou um segredo sem nada disso chegar à página.

Nenhum desses está errado. São a mesma troca feita de quatro jeitos: dados que o navegador não
recebe têm de ser buscados de novo no momento em que forem necessários, e dados que ele recebe e
nunca usa são bytes em toda primeira carga. A aula 4 é sobre o que o script faz com esses dados
depois que eles chegaram.
