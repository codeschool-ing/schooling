---
title: A árvore que o navegador constrói
version: 1
---

**O Playwright consegue imprimir a árvore de acessibilidade de qualquer parte de uma página**, no mesmo YAML
que usa nas próprias asserções. Eis um programa pequeno que a imprime para cada endereço que recebe. Salve
como `server/tree.mjs`:

```javascript
// server/tree.mjs
import { chromium } from "@playwright/test";

const browser = await chromium.launch();
const page = await browser.newPage();
await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
for (const address of process.argv.slice(2)) {
  await page.goto(address);
  await page.getByRole("heading", { level: 1 }).waitFor();
  console.log(`${address}\n${await page.locator("body").ariaSnapshot()}\n`);
}
await browser.close();
```

O `ariaSnapshot()` devolve cada elemento da árvore numa linha: o papel, o nome entre aspas e o estado entre
colchetes, com o que ele contém indentado abaixo. Elementos sem um papel que um leitor de tela anunciaria,
as `div`s do planner, ficam de fora, e o conteúdo deles aparece no lugar.

```
ana@dev:~/planner$ node server/tree.mjs http://localhost:5173/ 'http://localhost:5173/#/course/javascript'
http://localhost:5173/
- heading "Study planner" [level=1]
- list:
  - listitem:
    - link "HTML and CSS":
      - /url: "#/course/html-css"
    - text: 45 min this week
  - listitem:
    - link "JavaScript":
      - /url: "#/course/javascript"
    - text: 90 min this week
  - listitem:
    - link "Git":
      - /url: "#/course/git"
    - text: 25 min this week
- paragraph: "This week: 160 min"

http://localhost:5173/#/course/javascript
- link "←":
  - /url: "#/"
- heading "JavaScript" [level=1]
- list:
  - listitem: 2026-10-20 · 60 min done
  - listitem:
    - text: 2026-10-22 · 30 min
    - button "Done"
- text: Date
- textbox "Date"
- text: Minutes
- spinbutton "Minutes"
- text: Note
- textbox "Note"
- button "Add session"
- paragraph: "This week: 90 min"
```

## Lendo como um leitor de tela leria

Isso é parecido com o que recebe quem usa leitor de tela, e quatro coisas nela merecem uma pausa.

- **O link de voltar se chama *←*.** Esse é o nome inteiro dele. Um leitor de tela lê o nome do símbolo,
  algo como *seta para a esquerda* dependendo do leitor, e a pessoa precisa adivinhar para onde ele vai.
- **Não há landmark.** Nada diz *main*: a página é um título, uma lista e alguns campos soltos no nível de
  cima, então saltar para o conteúdo principal não leva a lugar nenhum.
- **Os campos são nomeados pelos seus rótulos**, *Date*, *Minutes*, *Note*, que é o trabalho da aula 3. As
  linhas `text:` ao lado deles são as palavras dos rótulos, lidas mais uma vez no modo de navegação.
- **O total no pé muda quando uma sessão é acrescentada, e nada diz isso.** A árvore mostra o que está lá;
  ela não consegue mostrar que uma pessoa que apertou **Add session** não ouviu nada, e ainda perdeu o
  foco, como a caminhada manual da aula 11 descobre.

As próximas seções corrigem cada uma delas, e cada correção começa com um teste que lê a árvore.
