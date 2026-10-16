---
title: Uma carta para a sessão que nenhuma ferramenta roda
version: 1
---

A árvore diz o que o navegador oferece ao leitor de tela. **Se o leitor transforma isso em algo que
uma pessoa consegue usar é a parte que só uma pessoa consegue testar**, e é também a parte que a
maioria das equipes pula, porque uma sessão com leitor de tela não tem forma óbvia nem fim óbvio.
Uma carta de teste dá as duas coisas. O formato vem do teste exploratório, onde o *Explore It!* de
Elisabeth Hendrickson o popularizou: uma frase de missão, um limite de tempo e notas.

A árvore já sabe o que há na página, então um script consegue escrever o primeiro rascunho. Em
`~/a11y`, `nano charter.js`:

```schooling-example
{"language": "javascript", "file": "a11y/charter.js", "parts": [{"code": "// a11y/charter.js\n// Writes charter.md: a short charter for one manual session with a screen\n// reader, listing every control the accessibility tree says the page has.\nconst fs = require(\"fs\");\nconst { chromium } = require(\"playwright\");\n\nconst url = process.argv[2] || \"http://localhost:8000/book4.html\";\nconst reader = process.argv[3] || \"NVDA and Firefox\";\nconst ROLES = /^(link|heading|img|combobox|spinbutton|textbox|button|alert|status)\\b/;\n", "note": "Dois argumentos: o endereço que o navegador do seu próprio computador vai abrir, e o leitor e o navegador que a sessão usa. Os papéis em `ROLES` são os que uma pessoa deve ouvir nesta página; opções, parágrafos e texto solto ficam de fora, para a lista continuar curta o bastante para ser percorrida."}, {"code": "(async () => {\n  const browser = await chromium.launch();\n  const page = await browser.newPage();\n  await page.goto(url);\n  await page.waitForLoadState(\"networkidle\");\n  const tree = await page.locator(\"body\").ariaSnapshot();\n  await browser.close();\n\n  const controls = tree.split(\"\\n\").map(line => line.trim().replace(/^- /, \"\").replace(/:$/, \"\"))\n                       .filter(line => ROLES.test(line));", "note": "A árvore é tirada exatamente como o `tree.js` a tira, e cada linha que começa com um desses papéis vira um item para escutar: o papel, e o nome entre aspas, como o navegador os entregará ao leitor."}, {"code": "  const charter = [\n    `# Charter: booking a seat with ${reader}`,\n    \"\",\n    `Explore ${url}`,\n    `with ${reader}, the keyboard only, and the screen out of sight,`,\n    \"to discover whether somebody who cannot see the page can book a seat.\",\n    \"\",\n    \"Before: python3 seed.py, then BOXOFFICE_HOST=0.0.0.0 python3 app.py.\",\n    \"Time box: 30 minutes. Write down what was heard, not what was expected.\",\n    \"\",\n    \"## What the tree says is there: is each one announced like this?\",\n    ...controls.map(control => `- [ ] ${control}`),\n    \"\",\n    \"## Tasks\",\n    \"- [ ] Book a free seat. Is the booking number announced, without moving the focus?\",\n    \"- [ ] Press Book with the name empty. Is the error announced, and is the focus on the name?\",\n    \"- [ ] Book a seat that is taken. Is \\\"seat taken\\\" announced?\",\n    \"- [ ] Move by headings, then by form fields. Is anything missing or out of order?\",\n    \"\",\n    \"## Notes\",\n    \"\",\n  ];\n  fs.writeFileSync(\"charter.md\", charter.join(\"\\n\"));\n  console.log(`charter.md: ${controls.length} things to listen for, 4 tasks`);\n})();", "note": "A carta em si, no formato que testadores exploratórios usam: **explorar** um alvo, **com** recursos, **para descobrir** uma informação. Depois um limite de tempo, os itens, quatro tarefas que são o propósito da página e uma seção vazia para notas. A instrução que mais importa é a segunda linha abaixo da missão: anote o que foi ouvido, porque um testador que sabe o que a página deveria dizer ouve isso tenha sido dito ou não."}]}
```

```
ana@nft:~/a11y$ node charter.js
charter.md: 12 things to listen for, 4 tasks
ana@nft:~/a11y$ cat charter.md
# Charter: booking a seat with NVDA and Firefox

Explore http://localhost:8000/book4.html
with NVDA and Firefox, the keyboard only, and the screen out of sight,
to discover whether somebody who cannot see the page can book a seat.

Before: python3 seed.py, then BOXOFFICE_HOST=0.0.0.0 python3 app.py.
Time box: 30 minutes. Write down what was heard, not what was expected.

## What the tree says is there: is each one announced like this?
- [ ] link "Skip to the booking form"
- [ ] img "boxoffice"
- [ ] link "What's on"
- [ ] link "Prices"
- [ ] link "Access"
- [ ] heading "Book a seat" [level=1]
- [ ] combobox "Show"
- [ ] spinbutton "Seat": "1"
- [ ] textbox "Your name"
- [ ] alert
- [ ] button "Book"
- [ ] status

## Tasks
- [ ] Book a free seat. Is the booking number announced, without moving the focus?
- [ ] Press Book with the name empty. Is the error announced, and is the focus on the name?
- [ ] Book a seat that is taken. Is "seat taken" announced?
- [ ] Move by headings, then by form fields. Is anything missing or out of order?

## Notes
```

Doze coisas para escutar, e quatro tarefas. Quando for rodar para valer, passe o endereço que o
seu navegador abre e a dupla com que vai testar, por exemplo
`node charter.js http://` seguido do endereço da VM e de `:8000/book4.html "VoiceOver and Safari"`,
para que a carta diga o que foi de fato testado.

## Fazendo a sessão

No seu próprio computador, com a bilheteria respondendo em `0.0.0.0` como a seção sobre os
leitores de tela montou:

1. Inicie o leitor, abra a página e desvie os olhos da tela.
2. **Percorra a lista do jeito do próprio leitor**, não só com Tab: por títulos, por campos, lendo
   do topo. Marque um item quando ele for anunciado com esse papel e esse nome; anote exatamente o
   que você ouviu quando não for.
3. **Faça as quatro tarefas.** A segunda é a que o `book.html` reprova e o `book4.html` foi escrito
   para passar: um nome vazio tem que produzir fala, e o foco tem que terminar no campo.
4. Pare no limite de tempo e registre o que escreveu.

A mesma carta, rodada contra o `book.html`, é o relatório de defeito mais convincente que este
terço do curso consegue produzir: uma imagem sem nome, um campo sem nome, um Book que não é botão e
um erro que não faz som. Cada um desses itens estava na árvore antes de alguém iniciar um leitor de
tela, e é por isso que ler a árvore primeiro deixa a sessão curta.

## Testar direito, e não só passar na ferramenta

As quatro aulas deste terço somam um plano em três camadas, cada uma pegando o que a anterior não
consegue:

| camada | com que frequência | pega | aula |
|---|---|---|---|
| auditoria automática, o axe como barreira | todo commit | nomes ausentes, contraste, `lang` ausente: o que é decidível a partir do documento | 13 |
| checagens por script: a caminhada de Tab, a árvore antes e depois de uma ação | todo commit | a ordem de tabulação, um controle inalcançável, um erro que nunca chega à árvore | 14, 15 |
| uma sessão manual com teclado e leitor de tela, a partir de uma carta | quando uma página muda, e antes de uma entrega | se os nomes fazem sentido, se a fala é utilizável, se a tarefa pode ser concluída | 14, 15 |

**O requisito que a aula 12 escreveu dizia "conferido com uma auditoria automática e à mão"**, e
esta tabela é o que a segunda metade dessa frase quer dizer na prática. Uma página que passa só na
primeira camada passou numa ferramenta. Uma página que passa nas três é uma que um testador pode
chamar de acessível, com a versão, o nível e os leitores nomeados ao lado da afirmação.
