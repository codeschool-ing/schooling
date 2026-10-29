---
title: Uma primeira story
version: 1
---

**Uma story é um estado com nome de um componente: o componente, mais os argumentos que o põem naquele
estado.** Stories são escritas em **Component Story Format**, CSF: um módulo cujo export padrão descreve o
componente, e cujo cada outro export é uma story. O Storybook lê os exports; nada mais no arquivo é
especial.

As stories da linha de sessão moram ao lado do componente:

```schooling-example
{"language": "typescript", "file": "src/session-row.stories.ts", "parts": [
 {"code": "// src/session-row.stories.ts\nimport type { Meta, StoryObj } from \"@storybook/html-vite\";\nimport { fn } from \"storybook/test\";\nimport { sessionRow } from \"./components\";\nimport type { Session } from \"./planner\";\n\ntype Args = Session & { onDone: (id: number) => void };", "note": "Os argumentos de uma story são tipados: os campos de uma sessão mais o tratador. `fn` cria uma função espiã que o Storybook mostra no painel Actions toda vez que ela é chamada."},
 {"code": "\nconst meta: Meta<Args> = {\n  title: \"Planner/Session row\",\n  render: ({ onDone, ...session }) => {\n    const list = document.createElement(\"ul\");\n    list.append(sessionRow(session, onDone));\n    return list;\n  },\n  args: { id: 6, course: \"javascript\", date: \"2026-10-15\", minutes: 45, done: false, onDone: fn() },\n};\nexport default meta;", "note": "O export padrão. `title` põe o componente na barra lateral. `render` transforma argumentos num elemento, dentro de um `<ul>` porque uma linha é um item de lista. `args` são os padrões de que toda story parte: a sessão 6 do `courses.json`."},
 {"code": "\ntype Story = StoryObj<Args>;\n\nexport const ToDo: Story = {};\nexport const Done: Story = { args: { done: true } };\nexport const Long: Story = { args: { minutes: 135 } };", "note": "Três stories, cada uma uma diferença em relação aos padrões. `ToDo` não muda nada; `Done` é a mesma sessão terminada; `Long` é uma que passa de duas horas. O Storybook transforma `ToDo` no nome *To Do* na barra lateral."}
]}
```

Com o `npm run storybook` rodando, a barra lateral agora mostra **Planner, Session row** com três stories e
uma página de docs. O quadro de cada story mostra uma linha; o painel Controls lista os argumentos, e mudar
`minutes` para 60 redesenha a linha como *1 h*. Apertar *Mark done* não muda nada na linha, porque a story
não guarda estado, e registra uma chamada a `onDone` com `6` no painel Actions, que é a prova de que o
componente chama o tratador com o id certo.

## O que o Storybook construiu a partir dela

Stories são achadas pelo nome do arquivo e indexadas com um id feito do título e do nome do export. O build
grava esse índice como `index.json`, que é como testes e outras ferramentas acham toda story:

```
ana@dev:~/planner$ npx storybook build > /dev/null 2>&1 && node -e "for (const id in require('./storybook-static/index.json').entries) console.log(id)"
planner-session-row--docs
planner-session-row--to-do
planner-session-row--done
planner-session-row--long
planner-week-summary--docs
planner-week-summary--in-progress
planner-week-summary--all-done
planner-week-summary--empty
```

`planner-session-row--to-do` é o endereço da primeira story daqui em diante. Os ids vêm dos nomes, então
**renomear uma story muda o id dela**, e tudo o que aponta para ela, um teste ou um favorito, quebra. Dê às
stories o nome do estado que mostram, e deixe-as em paz.
