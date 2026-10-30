---
title: As abas do planner, como programa
version: 1
---

**Uma biblioteca de navegação é uma estrutura de dados com uma tela presa a ela, e a estrutura de dados
é pequena o bastante para você mesmo escrever.** O planner ganha duas abas, Courses e Week, cada uma
com a própria pilha. A pilha de Courses pode chegar a três telas: a lista de cursos, o detalhe de um
curso e o formulário de uma nova sessão. A pilha de Week começa no plano da semana e pode empilhar o
detalhe de uma sessão. Esta seção escreve as regras como um arquivo de funções simples, sem tela, para
que a próxima possa alimentá-lo com toques e voltar e imprimir o que cada pilha guarda.

**O modelo é um valor, como o `planner.ts` da aula 1.** Um `Nav` diz qual aba está aparecendo e o que
a pilha de cada aba guarda, como uma lista de nomes de tela da raiz para cima. Toda função recebe um e
devolve um novo, e nada é alterado no lugar. Uma tela é uma string como `course:sql`, o que basta para
distinguir as telas numa impressão. Um app de verdade levaria o id do curso num argumento tipado, e os
toolkits da última seção desta aula fazem isso. Salve isto como `backstack.ts` em `~/planner`:

```schooling-example
{"language": "typescript", "file": "backstack.ts", "parts": [{"code": "// backstack.ts: the planner's two tabs, each with a stack of its own\nexport type Tab = \"Courses\" | \"Week\";\nexport type Nav = { tab: Tab; stacks: Record<Tab, string[]> };\n\n// The tab the app opens on. Back returns here before it leaves the app.\nexport const START: Tab = \"Courses\";\n\nexport function start(): Nav {\n  return { tab: START, stacks: { Courses: [\"courses\"], Week: [\"week\"] } };\n}\n", "note": "O estado inteiro da navegação: qual aba aparece, e uma lista por aba, raiz primeiro. `Record<Tab, string[]>` faz o TypeScript exigir uma pilha para cada aba. Cada pilha começa com a raiz, e uma raiz nunca sai."}, {"code": "// Open a screen: push it onto the stack of the tab that is showing.\nexport function open(nav: Nav, screen: string): Nav {\n  const stack = [...nav.stacks[nav.tab], screen];\n  return { ...nav, stacks: { ...nav.stacks, [nav.tab]: stack } };\n}\n", "note": "Empilhar. Só cresce a pilha da aba que aparece; `[nav.tab]` a escolhe pelo nome, e a pilha da outra aba é copiada sem mudança."}, {"code": "// A tap on a tab. Another tab: show it, with its stack as it was left.\n// The tab already showing: go back to that tab's first screen.\nexport function tap(nav: Nav, tab: Tab): Nav {\n  if (tab !== nav.tab) return { ...nav, tab };\n  return { ...nav, stacks: { ...nav.stacks, [tab]: nav.stacks[tab].slice(0, 1) } };\n}\n", "note": "Trocar de aba muda `tab` e mais nada, então cada pilha espera onde foi deixada. Um segundo toque na mesma aba deixa só a raiz, com `slice(0, 1)`."}, {"code": "// Android's system back. `left` is true when there was nothing to go back to.\nexport function back(nav: Nav): { nav: Nav; left: boolean } {\n  const stack = nav.stacks[nav.tab];\n  if (stack.length > 1) {\n    return { nav: { ...nav, stacks: { ...nav.stacks, [nav.tab]: stack.slice(0, -1) } }, left: false };\n  }\n  if (nav.tab !== START) return { nav: { ...nav, tab: START }, left: false };\n  return { nav, left: true };\n}\n", "note": "Três casos, em ordem: desempilhar a tela do topo; na raiz de outra aba, trocar para `START`; na raiz de `START`, avisar que o app sai. Quem chama descobre o que aconteceu por `left`, sem comparar estados."}, {"code": "// iOS has no system back: the app draws a back button above any screen\n// that has one under it, and draws none at a tab's first screen.\nexport function backButton(nav: Nav): boolean {\n  return nav.stacks[nav.tab].length > 1;\n}", "note": "A metade iOS é uma pergunta, não um toque: se um botão de voltar é desenhado. Na raiz não há nenhum, então não há nada a modelar além disso."}]}
```

## O que as quatro regras dizem

**`open` só mexe na aba que está aparecendo.** Empilhar o detalhe de um curso enquanto Courses aparece
faz crescer a pilha de Courses e deixa a de Week em paz. Isso é tudo o que "cada aba tem a própria
pilha" quer dizer: não existe uma lista única de histórico, então não há nada que uma troca de aba
possa embaralhar.

**`tap` são duas regras numa função.** Um toque na outra aba muda `tab` e mais nada, e é por isso que
a aluna encontra a pilha de Courses exatamente como a deixou. Um toque na aba que já está aparecendo
corta a pilha dela de volta à raiz com `slice(0, 1)`, a convenção que a primeira seção desta aula
descreveu. A raiz em si nunca sai, então uma aba sempre tem uma tela para mostrar.

**`back` responde duas coisas: o novo estado, e se o app ainda está lá.** Três casos, em ordem. Com
mais de uma tela na pilha atual, desempilha a do topo. Na raiz de uma aba que não é `START`, troca para
`START`, do jeito que a biblioteca de navegação do Android arruma uma barra inferior. Na raiz de
`START`, não sobra nada dentro do app, então devolve o estado sem mudança e `left: true`. O que
acontece com o app depois é assunto do sistema, não do planner: desde o Android 12 a tarefa vai para
segundo plano.

**`backButton` é a metade iOS, e é uma comparação.** O iOS não tem voltar do sistema, então a única
pergunta é se o app desenha um botão de voltar, e ele desenha um sobre qualquer tela que tenha outra
embaixo. Na raiz de uma aba a resposta é `false` e nada é desenhado; não há toque para modelar, e é por
isso que o arquivo não tem uma versão iOS de `back`.

## O que ficou de fora

**A gaveta e a folha faltam de propósito.** Uma gaveta de destinos se comporta como abas com a barra
escondida, então as mesmas `stacks` serviriam. Uma folha fica por cima da tela atual sem entrar na
pilha dela; acrescentar uma pediria um campo como `sheet: string | null` que `back` limpa antes de
olhar qualquer pilha, que é exatamente a ordem que o Android segue. O planner tem duas seções e
nenhuma folha, então o modelo fica do tamanho do planner.

**Nada aqui sabe do predictive back do Android, também.** O voltar preditivo muda o momento em que o
sistema faz a pergunta, durante o deslize em vez de depois, e não a resposta. As regras acima são a
resposta, e são as mesmas seja qual for o jeito de perguntar.
