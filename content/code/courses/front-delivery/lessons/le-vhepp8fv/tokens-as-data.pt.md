---
title: Os tokens do planner, como dado
version: 1
---

**Os tokens do planner moram num arquivo JSON na raiz do projeto, e um script curto os escreve como
CSS.** Nada na folha de estilo guarda uma cor ou um tamanho próprio; todo valor vem do arquivo, pelo
script. Essa direção única, do dado para o CSS e nunca o contrário, é o que deixa o mesmo arquivo
alimentar outras saídas depois.

O arquivo segue o formato do **Design Tokens Community Group**, a especificação do grupo comunitário do
W3C para trocar tokens entre ferramentas: cada token é um objeto com um `$value` e, onde importa, um
`$type`, e um token se refere a outro como `{grupo.nome}`. Ele simplifica uma coisa: as cores são
escritas como strings hex simples, onde a versão estável do formato escreve um objeto que diz o espaço de
cor.

```schooling-example
{"language": "json", "file": "tokens.json", "parts": [
 {"code": "{\n  \"color\": {\n    \"green-300\": { \"$type\": \"color\", \"$value\": \"#7fbf9a\" },\n    \"green-600\": { \"$type\": \"color\", \"$value\": \"#2f6f4e\" },\n    \"grey-0\": { \"$type\": \"color\", \"$value\": \"#ffffff\" },\n    \"grey-50\": { \"$type\": \"color\", \"$value\": \"#f4f6f5\" },\n    \"grey-300\": { \"$type\": \"color\", \"$value\": \"#aeb6bd\" },\n    \"grey-400\": { \"$type\": \"color\", \"$value\": \"#8a939b\" },\n    \"grey-600\": { \"$type\": \"color\", \"$value\": \"#59626a\" },\n    \"grey-800\": { \"$type\": \"color\", \"$value\": \"#2a3036\" },\n    \"grey-900\": { \"$type\": \"color\", \"$value\": \"#16191d\" }\n  },", "note": "Os primitivos: toda cor que o planner pode usar, com nome de matiz e luminosidade, 0 a mais clara e 900 a mais escura. Nada no app se refere a eles diretamente."},
 {"code": "  \"theme\": {\n    \"light\": {\n      \"surface\": { \"$value\": \"{color.grey-0}\" },\n      \"raised\": { \"$value\": \"{color.grey-50}\" },\n      \"text\": { \"$value\": \"{color.grey-900}\" },\n      \"muted\": { \"$value\": \"{color.grey-600}\" },\n      \"accent\": { \"$value\": \"{color.green-600}\" },\n      \"on-accent\": { \"$value\": \"{color.grey-0}\" }\n    },", "note": "A camada semântica, para o tema claro. Seis significados: a página, um painel elevado, o texto, um texto mais discreto, a cor de ação, e o texto escrito sobre a cor de ação. Cada um se refere a um primitivo pelo nome."},
 {"code": "    \"dark\": {\n      \"surface\": { \"$value\": \"{color.grey-900}\" },\n      \"raised\": { \"$value\": \"{color.grey-800}\" },\n      \"text\": { \"$value\": \"{color.grey-50}\" },\n      \"muted\": { \"$value\": \"{color.grey-300}\" },\n      \"accent\": { \"$value\": \"{color.green-300}\" },\n      \"on-accent\": { \"$value\": \"{color.grey-900}\" }\n    }\n  },", "note": "Os mesmos seis nomes para o tema escuro, apontando para outros primitivos. O destaque aqui é um verde mais claro, porque o verde escuro da marca ficaria ilegível numa página quase preta."},
 {"code": "  \"type\": {\n    \"base\": { \"$type\": \"dimension\", \"$value\": \"1rem\" },\n    \"ratio\": { \"$type\": \"number\", \"$value\": 1.25 },\n    \"steps\": { \"$type\": \"number\", \"$value\": 5 }\n  },", "note": "Não uma lista de tamanhos, mas a regra que os faz: uma base, uma razão e quantos passos. A próxima seção é sobre ela."},
 {"code": "  \"space\": {\n    \"unit\": { \"$type\": \"dimension\", \"$value\": \"0.25rem\" },\n    \"steps\": { \"$type\": \"number\", \"$value\": 8 }\n  }\n}", "note": "O mesmo para espaçamento: uma unidade de um quarto de rem, quatro pixels no tamanho padrão do navegador, e oito múltiplos dela."}
]}
```

## O script

O `tokens.mjs` lê esse arquivo e grava `src/tokens.css`. É Node puro, sem nada instalado:

```schooling-example
{"language": "javascript", "file": "tokens.mjs", "parts": [
 {"code": "// tokens.mjs\nimport { readFile, writeFile } from \"node:fs/promises\";\n\nconst tokens = JSON.parse(await readFile(\"tokens.json\", \"utf8\"));\nconst css = (ref) => ref.replace(/\\{color\\.([\\w-]+)\\}/, \"var(--color-$1)\");\nconst lines = [\"/* src/tokens.css is written by tokens.mjs from tokens.json: edit those, not this */\", \":root {\"];", "note": "Uma referência como `{color.grey-0}` vira `var(--color-grey-0)`, então um token semântico no CSS continua apontando para o seu primitivo em vez de copiar o hex. A primeira linha da saída diz de onde ela veio, para ninguém editá-la à mão."},
 {"code": "for (const [name, token] of Object.entries(tokens.color)) lines.push(`  --color-${name}: ${token.$value};`);", "note": "Todo primitivo, como propriedade personalizada."},
 {"code": "const base = parseFloat(tokens.type.base.$value);\nfor (let step = 0; step < tokens.type.steps.$value; step++) {\n  lines.push(`  --font-size-${step}: ${+(base * tokens.type.ratio.$value ** step).toFixed(3)}rem;`);\n}\nconst unit = parseFloat(tokens.space.unit.$value);\nfor (let n = 1; n <= tokens.space.steps.$value; n++) lines.push(`  --space-${n}: ${unit * n}rem;`);\nlines.push(\"}\");", "note": "As duas escalas, calculadas a partir das suas regras. `toFixed(3)` e o `+` na frente arredondam para três casas e tiram zeros sobrando no fim."},
 {"code": "const theme = (name) => Object.entries(tokens.theme[name]).map(([key, token]) => `  --${key}: ${css(token.$value)};`);\nlines.push(\"\", \":root,\", '[data-theme=\"light\"] {', ...theme(\"light\"), \"}\");\nlines.push(\"\", \"@media (prefers-color-scheme: dark) {\", '  :root:not([data-theme=\"light\"]) {', ...theme(\"dark\").map((l) => \"  \" + l), \"  }\", \"}\");\nlines.push(\"\", '[data-theme=\"dark\"] {', ...theme(\"dark\"), \"}\");", "note": "Os temas, três vezes: claro por padrão, escuro quando o sistema de quem lê pede, e qualquer um dos dois quando a página põe `data-theme` num elemento, o que passa por cima do sistema. A seção sobre temas explica os seletores."},
 {"code": "await writeFile(\"src/tokens.css\", lines.join(\"\\n\") + \"\\n\");\nconsole.log(`src/tokens.css: ${lines.length} lines`);", "note": "Gravado inteiro toda vez, para o CSS nunca guardar algo que o JSON não tem."}
]}
```

Rode, por um script do npm, para o comando ficar no `package.json` para todo mundo:

```
ana@dev:~/planner$ npm pkg set scripts.tokens="node tokens.mjs"
ana@dev:~/planner$ npm run tokens

> planner@0.0.0 tokens
> node tokens.mjs

src/tokens.css: 55 lines
ana@dev:~/planner$ sed -n '1,14p' src/tokens.css
/* src/tokens.css is written by tokens.mjs from tokens.json: edit those, not this */
:root {
  --color-green-300: #7fbf9a;
  --color-green-600: #2f6f4e;
  --color-grey-0: #ffffff;
  --color-grey-50: #f4f6f5;
  --color-grey-300: #aeb6bd;
  --color-grey-400: #8a939b;
  --color-grey-600: #59626a;
  --color-grey-800: #2a3036;
  --color-grey-900: #16191d;
  --font-size-0: 1rem;
  --font-size-1: 1.25rem;
  --font-size-2: 1.563rem;
```

**Faça o commit do `src/tokens.css` junto com a fonte dele**, mesmo sendo gerado. O build o lê, e um
clone novo precisa construir sem rodar nada antes. O que o mantém honesto é uma conferência que as
próximas aulas poderiam acrescentar ao CI: rodar `npm run tokens` e falhar se o `git diff` mostrar uma
mudança, o que quer dizer que alguém editou o CSS à mão ou esqueceu de rodar o script.

O planner faz isso em vinte linhas. O **Style Dictionary**, uma ferramenta de código aberto, é o que a
maioria das equipes usa para o mesmo trabalho em escala: ele lê o mesmo tipo de arquivo e escreve saídas
para CSS, JavaScript, Android e iOS a partir dele, com transformações para cada plataforma. A ideia é
idêntica, e ler vinte linhas antes deixa a configuração dele bem menos misteriosa.
