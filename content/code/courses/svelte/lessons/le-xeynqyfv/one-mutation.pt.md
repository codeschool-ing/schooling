---
title: Contando o que muda na página
version: 1
---

**Uma mudança no Svelte mexe só nos nós que a mostram, e o navegador consegue contá-los para
você.** Um `MutationObserver` é uma API do navegador que relata cada mudança feita na página: um nó
acrescentado ou removido, um atributo definido, um pedaço de texto trocado. Ponha um na página do
planner e aperte os botões, e cada relato é uma coisa que mudou.

Esta versão da página inicia um observador no `<main>` assim que a página está na tela, e escreve
cada relato no console. O efeito não lê nenhum estado, então roda uma vez; a função que ele devolve
roda quando a página vai embora, e para o observador:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport Counter from '#lib/Counter.svelte';", "note": "O contador, como a seção anterior deixou."},
 {"code": "\t$effect(() => {\n\t\tconst observer = new MutationObserver((records) => {\n\t\t\tfor (const record of records) {\n\t\t\t\tconsole.log(`changed: ${record.type}, now \"${record.target.textContent}\"`);\n\t\t\t}\n\t\t});", "note": "Um relato por mudança, com o que o nó alterado diz depois."},
 {"code": "\t\tobserver.observe(document.querySelector('main'), {\n\t\t\tsubtree: true,\n\t\t\tchildList: true,\n\t\t\tcharacterData: true,\n\t\t\tattributes: true\n\t\t});\n\t\treturn () => observer.disconnect();\n\t});\n</script>\n\n<main>\n\t<h1>Study planner</h1>\n\t<Counter />\n</main>", "note": "Observa tudo dentro do `<main>`: filhos acrescentados ou removidos, texto mudado, atributos mudados."}
]}
```

Dois cliques num botão e um no outro:

```
ana@dev:~/planner$ look http://localhost:5173/ --console --click 'Add 30 minutes' --click 'Add 30 minutes' --click 'Raise the goal'
console: [vite] connecting...
console: [vite] connected.
console: the script ran
console: the effect ran: minutes is 0
-- click Add 30 minutes
console: the effect ran: minutes is 30
console: changed: characterData, now "30 minutes this week"
-- click Add 30 minutes
console: the effect ran: minutes is 60
console: changed: characterData, now "60 minutes this week"
-- click Raise the goal
console: changed: characterData, now "The goal is 180 minutes."
at /
- main:
  - heading "Study planner" [level=1]
  - button "Add 30 minutes"
  - button "Raise the goal"
  - paragraph: 60 minutes this week
  - paragraph: The goal is 180 minutes.
```

**Um clique, uma mudança.** Cada linha `characterData` é um nó de texto cujo conteúdo foi trocado, e
nada mais na página foi tocado: nenhum elemento foi recriado, nenhum atributo reescrito, o botão
apertado foi deixado em paz. O nó de texto é o que está dentro do parágrafo, e o conteúdo inteiro
dele é a frase, por isso o relato mostra a frase toda.

## O que isto não prova

Seria fácil ler isto como "o Svelte mexe menos na página que o React", e estaria errado. **Um DOM
virtual termina no mesmo lugar.** O React, depois do diff, também trocaria exatamente um pedaço de
texto, e um observador numa página React imprimiria as mesmas três linhas. O trabalho no DOM é o
mesmo porque os dois frameworks estão fazendo o seu trabalho.

A diferença está no trabalho **antes** dessa mudança. O React chamou `Counter` de novo, montou uma
descrição nova de um botão e dois parágrafos, e comparou com a antiga, tudo para achar o único nó de
texto que um efeito do Svelte já conhecia. Num contador isso não custa nada que alguém consiga medir.
Numa página com alguns milhares de linhas, em que uma linha muda, é a diferença entre comparar
alguns milhares de descrições e definir um nó, e cada framework com DOM virtual tem as suas próprias
ferramentas para evitar a comparação quando ela pesa. A posição do Svelte é que você não deveria
precisar delas.

Volte o `+page.svelte` para a versão de "O script roda uma vez" antes do exercício: o observador era
uma sonda, e a aula 3 troca a página de qualquer jeito.
