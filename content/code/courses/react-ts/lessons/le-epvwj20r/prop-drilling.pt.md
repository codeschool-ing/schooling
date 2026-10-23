---
title: Passando props por componentes que não as usam
version: 1
---

**As props viajam um nível por vez.** Quando um valor é necessário três componentes abaixo, cada
componente no meio precisa recebê-lo e repassá-lo, use ou não. Isso se chama **prop drilling**, e o
planejador já faz um pouco disso. O `toggleDone` é criado no `usePlanner`, devolvido ao `App`, passado
ao `CourseScreen` como `onToggle`, e só ali usado por uma caixa de marcação. O `onOpen` vai do `App`
pelo `CourseList`, que nunca o chama, até o `CourseCard`, que chama.

```schooling-figure
{"svg": "<svg data-fig=\"drilling\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A árvore do planejador antes desta aula. O toggleDone vai do usePlanner ao App, e do App ao CourseScreen como onToggle, onde uma caixa de marcação o usa. O onOpen vai do App pelo CourseList, que não o usa, até o CourseCard, que usa. Os componentes que só repassam uma prop estão marcados.\"><rect x=\"290\" y=\"14\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">App</text><rect x=\"90\" y=\"90\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">CourseScreen</text><rect x=\"460\" y=\"90\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"545.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">CourseList</text><rect x=\"90\" y=\"170\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">&lt;input checkbox&gt;</text><rect x=\"460\" y=\"170\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">CourseCard</text><line x1=\"330\" y1=\"44\" x2=\"175\" y2=\"90\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"175.0,90.0 181.3,84.8 183.1,90.9\" fill=\"var(--phosphor)\"></polygon><text x=\"200\" y=\"62\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">onToggle</text><line x1=\"175\" y1=\"120\" x2=\"175\" y2=\"170\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"175.0,170.0 171.8,162.5 178.2,162.5\" fill=\"var(--phosphor)\"></polygon><line x1=\"390\" y1=\"44\" x2=\"545\" y2=\"90\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,90.0 536.9,90.9 538.7,84.8\" fill=\"var(--amber)\"></polygon><text x=\"520\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">onOpen</text><line x1=\"545\" y1=\"120\" x2=\"545\" y2=\"170\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,170.0 541.8,162.5 548.2,162.5\" fill=\"var(--amber)\"></polygon><text x=\"640\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">só repassa</text><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">contínuo: usa a prop · tracejado: só passa adiante</text></svg>", "caption": "Prop drilling: um valor passado por componentes que só o repassam."}
```

**Dois níveis de drilling não são um problema**, e a primeira lição honesta sobre estado global é que
a maioria dos apps o busca cedo demais. As props são explícitas: ler as props do `CourseList` diz cada
valor de que ele depende, e o verificador de tipos acompanha cada um. O custo aparece em outra escala:
quando um valor é lido por muitos componentes em profundidades diferentes, quando os componentes do
meio mudam com frequência, ou quando os mesmos poucos valores, o usuário logado, o tema, os dados do
app, descem por quase todo ramo da árvore. Aí cada componente intermediário carrega props que não são
assunto dele, e mover um componente quer dizer religar os ancestrais.

O planejador está indo para lá. A aula 17 dá a cada tela um endereço próprio, então a tela do curso
não vai mais ser renderizada pelo `App` com os dados na mão; vai ser renderizada por um roteador, e
vai precisar das sessões e do `toggleDone` de outro lugar. Esse outro lugar é o que esta aula
constrói, primeiro com a ferramenta do próprio React, o context, e depois com as três bibliotecas
entre as quais a maioria dos times React escolhe.

| mantenha as props quando | busque estado compartilhado quando |
|---|---|
| um valor passa por um ou dois componentes | muitos componentes em profundidades diferentes leem o mesmo valor |
| os componentes do meio são estáveis | a árvore do meio muda, ou quem lê se move |
| você quer as dependências de cada componente visíveis nas props | o valor é do app inteiro: o usuário, o tema, os dados do app |
