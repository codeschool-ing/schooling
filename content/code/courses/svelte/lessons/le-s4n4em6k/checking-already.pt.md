---
title: A verificação que já acontece
version: 1
---

**O compilador do Svelte verifica todo componente que compila, em JavaScript ou TypeScript, e parte do
que ele verifica é a acessibilidade da página.** Uma `<div>` com um handler de clique e nada equivalente
no teclado, uma imagem sem `alt`, um label que não aponta para nada: o compilador conhece a marcação o
bastante para notar, e avisa enquanto compila. Ninguém precisa pedir.

A ferramenta que junta esses avisos, e os erros de tipo também, é o **`svelte-check`**. Ele roda o
compilador do Svelte em cada componente e o verificador do TypeScript em cada arquivo, e imprime o que
os dois acharam. Instale-o, e o TypeScript, que ele usa; o servidor de desenvolvimento pode ficar parado
nesta aula até o fim:

```
ana@dev:~/planner$ npm install --save-dev svelte-check@4.7.7 typescript@6.0.3

removed 1 package, changed 7 packages, and audited 57 packages in 1s

13 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

e dê a ele um script, como têm os projetos criados com TypeScript:

```
ana@dev:~/planner$ npm pkg set scripts.check='svelte-kit sync && svelte-check'
```

O `svelte-kit sync` escreve os tipos que o SvelteKit gera para cada rota, que o verificador lê; o script
`prepare` o roda depois de toda instalação, e o `check` o roda primeiro, para que os tipos nunca sejam
mais velhos que as rotas.

## Um aviso, de propósito

Torne o título da página About clicável, do jeito errado. Substitua `src/routes/(info)/about/+page.svelte`
por um momento:

```schooling-example
{"language": "html", "file": "src/routes/(info)/about/+page.svelte", "parts": [
 {"code": "<svelte:head>\n\t<title>About · Study planner</title>\n</svelte:head>"},
 {"code": "<h1 onclick={() => history.back()}>About the planner</h1>\n<p>\n\tThe study planner lists your courses, the sessions you plan for each, and the minutes in your week.\n\tIt keeps everything on this computer, in one small file, and asks nobody for anything.\n</p>\n<p><a href=\"/\">Back to the planner</a></p>", "note": "Um teste. Um título que faz algo quando clicado, e nada para o teclado."}
]}
```

```
ana@dev:~/planner$ npm run check 2>&1 | grep -A3 'about/+page.svelte'
/home/ana/planner/src/routes/(info)/about/+page.svelte:4:1
Warn: Visible, non-interactive element `<h1>` with a click event must be accompanied by a keyboard event handler. Consider whether an interactive element such as `<button type="button">` or `<a>` might be more appropriate
https://svelte.dev/e/a11y_click_events_have_key_events (svelte)
</svelte:head>
--
/home/ana/planner/src/routes/(info)/about/+page.svelte:4:1
Warn: Non-interactive element `<h1>` should not be assigned mouse or keyboard event listeners
https://svelte.dev/e/a11y_no_noninteractive_element_interactions (svelte)
</svelte:head>
```

**Dois avisos do compilador, sobre acessibilidade**: um título não é algo que o teclado alcance ou
aperte, e um clique sem evento de tecla deixa de fora quem usa o teclado. A correção é um `<button>` ou
um link, que têm as duas coisas de graça. Deixe o arquivo de volta como a aula 12 o escreveu:

```schooling-example
{"language": "html", "file": "src/routes/(info)/about/+page.svelte", "parts": [
 {"code": "<svelte:head>\n\t<title>About · Study planner</title>\n</svelte:head>\n<h1>About the planner</h1>\n<p>\n\tThe study planner lists your courses, the sessions you plan for each, and the minutes in your week.\n\tIt keeps everything on this computer, in one small file, and asks nobody for anything.\n</p>\n<p><a href=\"/\">Back to the planner</a></p>", "note": "Como a aula 12 o escreveu."}
]}
```

## E os tipos, em JavaScript

Rode-o sobre o projeto inteiro:

```
ana@dev:~/planner$ npm run check 2>&1 | tail -8
/home/ana/planner/src/routes/(planner)/courses/[id=slug]/sessions.csv/+server.js:24:15
Error: Parameter 'value' implicitly has an 'any' type. 
// formula, and in quotes if it holds a comma, a quote or a line break.
function cell(value) {
	let text = String(value);

====================================
svelte-check found 66 errors and 0 warnings in 13 files
```

**Erros num projeto sem nenhum TypeScript.** O `jsconfig.json`, que o `sv` escreveu na aula 1, pede
verificação estrita, e o TypeScript verifica JavaScript também quando lhe pedem. A maioria dos erros é de
um tipo só:

```
ana@dev:~/planner$ npm run check -- --output machine 2>&1 | grep -c 'implicitly has an'
56
```

`Parameter 's' implicitly has an 'any' type`: o verificador não consegue dizer o que um parâmetro é,
então não consegue verificar nada do que se faz com ele, e o modo estrito diz isso em vez de ficar
quieto. **Cada um deles é um lugar onde um erro de digitação passaria despercebido.** `s.minuts` no lugar
de `s.minutes` daria `undefined`, o total daria `NaN`, e nada reclamaria até um estudante ver. O resto
desta aula diz ao verificador o que cada valor é, convertendo o planner para TypeScript, até a contagem
chegar a zero.
