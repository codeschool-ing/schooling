---
title: Toda story nos dois temas
version: 1
---

**Um componente precisa ser conferido em todo tema em que pode aparecer, então a oficina precisa de um
jeito de trocar o tema de toda story de uma vez.** A aula 5 fez de um tema um valor de `data-theme` no
elemento raiz; a oficina ganha um menu na barra de ferramentas que o define.

O Storybook chama uma configuração assim de **global**: um valor que vale para toda story, mostrado na
barra de ferramentas e passado para o render de toda story. Um **decorator** é uma função que envolve toda
story, e este grava o global no elemento raiz antes de a story desenhar. O `preview.ts` cresce para isto:

```schooling-example
{"language": "typescript", "file": ".storybook/preview.ts", "parts": [
 {"code": "// .storybook/preview.ts\nimport type { Preview } from \"@storybook/html-vite\";\nimport \"../src/style.css\";\n\nconst preview: Preview = {", "note": "Como antes: a folha de estilo do planner, com os tokens e os dois temas, carregada no quadro de toda story."},
 {"code": "  globalTypes: {\n    theme: {\n      description: \"Colour theme\",\n      toolbar: { title: \"Theme\", items: [\"light\", \"dark\"], dynamicTitle: true },\n    },\n  },\n  initialGlobals: { theme: \"light\" },", "note": "Um global chamado `theme`, desenhado como menu na barra de ferramentas com dois itens. `dynamicTitle` faz o menu mostrar a escolha atual. Claro é onde toda story começa."},
 {"code": "  decorators: [\n    (story, context) => {\n      document.documentElement.dataset.theme = context.globals.theme;\n      return story();\n    },\n  ],", "note": "Antes de cada story desenhar, o elemento raiz recebe `data-theme`, que o `tokens.css` gerado transforma num conjunto de valores ou no outro. A story em si não sabe nada de temas, que é o ponto da camada semântica."},
 {"code": "  tags: [\"autodocs\"],\n};\n\nexport default preview;", "note": "Igual: uma página de docs para todo componente."}
]}
```

A barra de ferramentas agora tem um menu **Theme**. Escolher *dark* redesenha a story nos valores escuros,
e toda outra story acompanha, já que um global não é por story.

## Um global no endereço

Globais também podem ser definidos no endereço de uma story, o que importa para as próximas seções porque
um teste abre stories pelo endereço. O quadro em que o Storybook desenha uma story é o `iframe.html`, e o
tema vai junto como parâmetro:

```
http://127.0.0.1:6006/iframe.html?id=planner-session-row--to-do&viewMode=story&globals=theme:dark
```

Esse endereço mostra uma linha, sozinha, no tema escuro, sem nada da interface do próprio Storybook em
volta. É o endereço que um teste de captura de tela quer, porque ele contém só o componente.
