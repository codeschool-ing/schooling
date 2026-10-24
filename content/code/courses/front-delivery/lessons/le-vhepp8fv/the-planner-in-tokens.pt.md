---
title: O planner, reescrito em tokens
version: 1
---

**A folha de estilo do planner é reescrita para usar só tokens, e para importar o arquivo gerado.** Toda
cor, tamanho e espaço vira um `var(--…)`, e algumas regras são acrescentadas para o que o planner não
estilizava antes: links, botões e o painel do formulário. Troque o `src/style.css` por este:

```css
/* src/style.css */
@import "./tokens.css";

:root {
  color-scheme: light dark;
}

[data-theme="light"] {
  color-scheme: light;
}

[data-theme="dark"] {
  color-scheme: dark;
}

body {
  font-family: system-ui, sans-serif;
  font-size: var(--font-size-0);
  line-height: 1.5;
  margin: var(--space-8) auto;
  max-width: 40rem;
  padding: 0 var(--space-4);
  background: var(--surface);
  color: var(--text);
}

h1 {
  font-size: var(--font-size-4);
}

h2 {
  font-size: var(--font-size-2);
}

a {
  color: var(--accent);
}

li {
  margin: var(--space-1) 0;
}

li span {
  color: var(--muted);
}

button {
  font: inherit;
  background: var(--accent);
  color: var(--on-accent);
  border: 0;
  border-radius: var(--space-1);
  padding: var(--space-1) var(--space-3);
}

form {
  display: flex;
  gap: var(--space-4);
  flex-wrap: wrap;
  align-items: end;
  background: var(--raised);
  padding: var(--space-4);
  border-radius: var(--space-2);
}
```

O `@import` no topo traz o `tokens.css`, e o Vite o embute na folha de estilo única que o build grava,
então o navegador continua fazendo uma requisição só. `color-scheme` diz ao navegador quais temas a página
aceita, para os campos de data e de número seguirem o tema em vez de ficarem brancos numa página escura.

## Uma conferência que quem revisa consegue rodar

**A folha de estilo não deve conter nenhuma cor e nenhum valor em pixel.** É fácil de dizer e fácil de
quebrar com pressa, e uma busca acha:

```
ana@dev:~/planner$ grep -nE '#[0-9a-fA-F]{3,6}|[0-9]px' src/style.css; echo $?
1
```

Nenhuma linha impressa, e o `grep` saiu com 1, o jeito dele de dizer que não achou nada. Os dois valores
que sobram e não são tokens, `1.5` e `40rem`, são uma razão e uma largura de coluna, e a última seção da
escala de espaçamento disse por que eles ficam como estão. Uma busca como esta também é um passo justo para
o pipeline.

Construa, e abra o planner com o sistema no modo claro e depois no escuro. A página, o painel atrás do
formulário, os links e os botões mudam todos juntos, e todo par de texto e fundo é um que o script de
contraste mediu.

```
ana@dev:~/planner$ npm run build 2>&1 | grep css
dist/assets/index-BU4yu1tj.css  2.11 kB │ gzip: 0.64 kB
ana@dev:~/planner$ npm run contrast > /dev/null && echo contrast ok
contrast ok
ana@dev:~/planner$ git add tokens.json tokens.mjs contrast.mjs src/tokens.css src/style.css package.json
ana@dev:~/planner$ git commit -qm "Tokens, a type and spacing scale, two themes"
```

A folha de estilo cresceu de 0,18 kB para uns 2 kB com os tokens dentro, 0,64 kB comprimida: o custo de um
design system na rede, para um app deste tamanho.
