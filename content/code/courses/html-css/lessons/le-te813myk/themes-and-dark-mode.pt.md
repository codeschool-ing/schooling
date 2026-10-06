---
title: Temas, e o modo escuro de quem lê
version: 1
---

Como uma variável pode ser redefinida, um esquema de cores inteiro pode ser trocado redefinindo algumas delas. É assim que se constrói o **modo escuro**. A pessoa escolhe uma preferência no sistema operacional, e a media feature **`prefers-color-scheme`** permite que uma folha de estilos responda a ela:

```css
:root {
  --color-page: #fbf8f2;
  --color-text: #1d1d1b;
  --color-accent: #2f6f4e;
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-page: #161a17;
    --color-text: #e8e4dc;
    --color-accent: #8fd1ad;
  }
}

body {
  background: var(--color-page);
  color: var(--color-text);
}
a { color: var(--color-accent); }
```

Toda regra da página usa `--color-page`, `--color-text` e `--color-accent`, e nenhuma menciona uma cor. Um bloco `@media` redefine as três em `:root` quando a pessoa prefere escuro. `probe --dark` abre o Chromium com o esquema escuro, como faria a configuração do sistema:

```
ana@laptop:~/site$ probe theme.html style body background-color,color style a color axe
body  background-color: rgb(251, 248, 242)
body  color: rgb(29, 29, 27)
a  color: rgb(47, 111, 78)
axe: no violations
ana@laptop:~/site$ probe --dark theme.html style body background-color,color style a color axe
body  background-color: rgb(22, 26, 23)
body  color: rgb(232, 228, 220)
a  color: rgb(143, 209, 173)
axe: no violations
```

No esquema claro a página é `rgb(251, 248, 242)`, com texto quase preto e o link verde. No escuro é `rgb(22, 26, 23)`, com texto claro e um link verde **mais claro**, `rgb(143, 209, 173)`, e o axe aprovou os dois. Essa última parte é o trabalho de um tema escuro. O verde que se lê bem sobre o creme, `#2f6f4e`, é escuro demais para ler sobre quase preto, então o tema escuro não é o claro invertido: cada cor é escolhida de novo para o próprio fundo, e conferida. A interface deste repositório faz exatamente isso com a paleta nos dois temas, e roda o axe em toda tela nos dois.

## Dois detalhes fáceis de perder

**`<meta name="color-scheme" content="light dark">`** no head da página diz ao navegador que ela suporta os dois, para que as partes do próprio navegador, as barras de rolagem, os controles de formulário e o fundo padrão antes de a folha de estilos chegar, sigam o esquema de quem lê também. Sem isso, uma página escura pode piscar em branco enquanto carrega.

**Dê nome às variáveis pelo papel, não pela cor.** `--color-text` pode ser escura num tema e clara no outro; `--black` não pode, e uma folha de estilos que diz `--black: #e8e4dc` no tema escuro é uma que a próxima pessoa vai ler errado. A seção 08 é sobre dar nomes assim aos tokens.

A aula 11 trata das outras preferências que a pessoa pode declarar, como movimento reduzido, e a aula 12 usa essa.
