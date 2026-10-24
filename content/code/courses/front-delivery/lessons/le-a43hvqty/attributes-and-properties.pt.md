---
title: Atributos, propriedades e o ciclo de vida
version: 1
---

**Um elemento tem duas formas de receber dados: atributos, que são strings escritas no HTML, e
propriedades, que são qualquer valor JavaScript definido por código.** Os elementos nativos mantêm os dois
em sintonia onde faz sentido: `input.value` e o atributo `value`, `button.disabled` e `disabled`. Um custom
element precisa fazer isso por conta própria, e `<planner-session>` mostra os três casos.

| | atributo | propriedade | mantidos em sintonia por |
|---|---|---|---|
| `date` | `date="2026-10-15"` | nenhuma | só o atributo |
| `minutes` | `minutes="45"`, uma string | nenhuma | `Number(...)` na hora de desenhar |
| `done` | presente ou ausente | `element.done`, um booleano | o getter e o setter, que leem e escrevem o atributo |

**Atributos são sempre strings.** `minutes="45"` chega como `"45"`, e `"45" + 15` dá `"4515"`. É por isso
que o `#render` o converte, e por isso dados mais ricos, uma lista de sessões ou um objeto, entram por uma
propriedade definida em JavaScript e não pelo HTML. Um atributo booleano é verdadeiro por estar presente:
`done`, `done=""` e `done="false"` são todos verdadeiros para o `hasAttribute`, o que surpreende todo mundo
uma vez.

## O ciclo de vida

O navegador chama a classe em quatro momentos, e o elemento usa dois deles:

| callback | roda quando | `<planner-session>` |
|---|---|---|
| `constructor` | o elemento é criado, antes de estar numa página | monta a raiz shadow e liga o botão |
| `connectedCallback` | o elemento é posto num documento | desenha |
| `attributeChangedCallback` | muda um atributo listado em `observedAttributes` | desenha de novo |
| `disconnectedCallback` | o elemento é removido | não precisa: não há nada para limpar |

**O `disconnectedCallback` é onde um elemento que inicia um timer ou escuta em `window` precisa parar**, ou
o listener sobrevive ao elemento; a aula 19 de javascript mostrou quanto custa um vazamento assim. Este
elemento só escuta o próprio botão, que vai embora junto com ele.

## Upgrades

O HTML pode conter `<planner-session>` antes de a classe ser registrada: o navegador trata a tag como um
elemento desconhecido até o `customElements.define` rodar, e então faz o **upgrade** de cada uma que já
está na página, chamando o construtor e os callbacks de cada uma. É por isso que a página de demonstração
pode pôr as linhas no HTML e registrar a classe num script depois delas, e por isso uma página renderizada
no servidor pode mandar as tags antes de chegar qualquer JavaScript: elas mostram o conteúdo do light DOM,
o nome do curso, até o script completá-las.
