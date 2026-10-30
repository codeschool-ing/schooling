---
title: A aplicação que você constrói
version: 1
---

**Toda aula de 2 a 24 acrescenta algo a uma aplicação, um planner de estudos, numa pasta,
`~/planner`.** Ela é pequena de propósito: duas telas e um punhado de registros, para que a ideia
nova de cada aula seja a única coisa nova na página. Até a aula 24 ela tem rotas, formulários, um
servidor com quem conversar, estado, testes e renderização no servidor, e você terá escrito cada
arquivo dela.

## O que ela faz

Quem estuda lista os cursos que está fazendo, abre um, acrescenta sessões de estudo a ele com uma
data e um número de minutos, marca as feitas, e vê o total da semana.

| tela | endereço | o que tem nela |
|---|---|---|
| **a semana** | `/` | o total da semana, planejado e feito, e cada curso com os próprios minutos da semana |
| **um curso** | `/courses/git` | as sessões desse curso, cada uma com a data, os minutos e uma caixa para marcá-la feita, e um formulário para acrescentar uma |

Uma semana vai de segunda a domingo, e o planner conta a semana que contém o dia de hoje. Hoje é o
que o computador diz, o que é um problema para um curso cujas transcrições precisam bater com as
suas, então o `look` tem uma opção `--today` que define a data do navegador. As transcrições usam
sexta-feira, 23 de outubro de 2026.

## Os dados

Três cursos e seis sessões, em outubro de 2026. A aula 2 os salva como `public/courses.json`, um
arquivo que o servidor de desenvolvimento entrega ao navegador como está, e a partir da aula 12 um
pequeno servidor seu os guarda, para que acrescentar uma sessão sobreviva a um recarregamento.

| sessão | curso | data | minutos | feita |
|---|---|---|---|---|
| 1 | JavaScript | terça, 13 de outubro | 45 | sim |
| 2 | HTML and CSS | segunda, 19 de outubro | 30 | sim |
| 3 | JavaScript | terça, 20 de outubro | 60 | sim |
| 4 | Git | quinta, 22 de outubro | 25 | não |
| 5 | JavaScript | sábado, 24 de outubro | 50 | não |
| 6 | HTML and CSS | terça, 27 de outubro | 40 | não |

Com hoje no dia 23, a semana vai do dia 19 ao 25, então as sessões 2 a 5 estão nela. **165 minutos
planejados, 90 deles feitos**: são os dois primeiros números que a aplicação imprime, escritos à mão
na aula 4 e calculados a partir dos dados na aula 6, e vale tê-los calculado você mesmo antes que um
programa o faça.

## As peças

Uma aplicação Angular é uma árvore de componentes, cada um uma classe com um template, cada um
desenhando uma parte da tela e contendo as partes abaixo dele. A árvore do planner, como as aulas 3 a
8 a constroem:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A árvore de componentes do planner. App no topo. Embaixo, as duas telas: Week, que contém um resumo da semana e um cartão por curso, e CoursePage, que contém uma lista de sessões feita de linhas de sessão, e um formulário para adicionar uma sessão.\"><rect x=\"290\" y=\"14\" width=\"140\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">App</text><text x=\"360.0\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a casca</text><rect x=\"110\" y=\"96\" width=\"180\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Week</text><text x=\"200.0\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tela: /</text><rect x=\"430\" y=\"96\" width=\"180\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"520.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CoursePage</text><text x=\"520.0\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tela: /courses/:id</text><line x1=\"330\" y1=\"60\" x2=\"220\" y2=\"94\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"220.0,94.0 226.1,88.8 228.0,94.8\" fill=\"var(--wire)\"></polygon><line x1=\"390\" y1=\"60\" x2=\"500\" y2=\"94\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"500.0,94.0 492.0,94.8 493.9,88.8\" fill=\"var(--wire)\"></polygon><rect x=\"20\" y=\"190\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WeekSummary</text><text x=\"95.0\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">planejado e feito</text><rect x=\"190\" y=\"190\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CourseCard</text><text x=\"265.0\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um por curso</text><rect x=\"380\" y=\"190\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SessionList</text><text x=\"455.0\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">as sessões do curso</text><rect x=\"550\" y=\"190\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">AddSession</text><text x=\"625.0\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um formulário</text><line x1=\"170\" y1=\"142\" x2=\"95\" y2=\"188\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"95.0,188.0 99.7,181.5 102.9,186.8\" fill=\"var(--wire)\"></polygon><line x1=\"230\" y1=\"142\" x2=\"265\" y2=\"188\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"265.0,188.0 258.1,184.0 263.0,180.2\" fill=\"var(--wire)\"></polygon><line x1=\"490\" y1=\"142\" x2=\"455\" y2=\"188\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"455.0,188.0 457.0,180.2 461.9,184.0\" fill=\"var(--wire)\"></polygon><line x1=\"550\" y1=\"142\" x2=\"625\" y2=\"188\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"625.0,188.0 617.1,186.8 620.3,181.5\" fill=\"var(--wire)\"></polygon><rect x=\"380\" y=\"254\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"455\" y=\"271\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SessionRow</text><line x1=\"455\" y1=\"236\" x2=\"455\" y2=\"252\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"455.0,252.0 451.9,244.6 458.1,244.6\" fill=\"var(--wire)\"></polygon><text x=\"540\" y=\"271\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma por sessão</text></svg>", "caption": "Cada caixa é um componente que você escreve; cada linha para baixo é um template usando outro."}
```

Cada caixa é um arquivo que você escreve, e cada linha para baixo é um componente usando outro no seu
template. `App` é a casca que fica na tela; o router da aula 17 decide qual das duas telas fica dentro
dela.

## A mesma aplicação, mais três vezes

A trilha `frontend` se bifurca aqui: React, Angular, Vue ou Svelte, e você faz um. Os quatro cursos
constroem **este mesmo planner**, com as mesmas duas telas e as mesmas seis sessões. Quem fez o curso
de React reconhece cada tela sua e nada do seu código, e isso é proposital. A aula 25 põe os quatro
lado a lado, e como a aplicação é a mesma, as diferenças que você vê ali são dos frameworks e não dos
exemplos.
