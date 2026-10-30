---
title: Quatro lugares para um valor, e quanto dura cada um
version: 1
---

**Escolher onde um valor mora é escolher ao que ele sobrevive.** Esta aula conheceu dois lugares e a
aula 2 desenhou uma tabela com quatro; aqui estão eles de novo com os valores do planner dentro,
porque a escolha aparece para cada pedaço de estado que o app vai ter.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l04-lifetimes\" aria-label=\"Quatro barras contra quatro eventos, recomposição, rotação, morte do processo e o app arrastado para fora. remember para na rotação. ViewModel para na morte do processo. rememberSaveable para em arrastado para fora. A barra do banco de dados passa dos quatro.\"><defs><marker id=\"l04-lifetimes-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><line x1=\"250\" y1=\"50\" x2=\"250\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></line><text x=\"250\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">recomposição</text><line x1=\"380\" y1=\"50\" x2=\"380\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></line><text x=\"380\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rotação</text><line x1=\"510\" y1=\"50\" x2=\"510\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></line><text x=\"510\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">morte do processo</text><line x1=\"640\" y1=\"50\" x2=\"640\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></line><text x=\"640\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">arrastado para fora</text><text x=\"150\" y=\"79\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">remember</text><rect x=\"165\" y=\"70\" width=\"215\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><line x1=\"380\" y1=\"66\" x2=\"380\" y2=\"92\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><text x=\"150\" y=\"114\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">rememberSaveable</text><rect x=\"165\" y=\"105\" width=\"475\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><line x1=\"640\" y1=\"101\" x2=\"640\" y2=\"127\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><text x=\"150\" y=\"149\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ViewModel</text><rect x=\"165\" y=\"140\" width=\"345\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><line x1=\"510\" y1=\"136\" x2=\"510\" y2=\"162\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><text x=\"150\" y=\"184\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">banco de dados</text><rect x=\"165\" y=\"175\" width=\"511\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><line x1=\"680\" y1=\"184\" x2=\"712\" y2=\"184\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l04-lifetimes-ah-phosphor)\"></line><text x=\"165\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma barra corre enquanto o valor sobrevive; ela para no evento que o perde</text></svg>", "caption": "Quanto tempo um valor vive em cada um dos quatro lugares, medido pelos eventos que o encerram.", "same": ["ViewModel"]}
```

| onde | sobrevive a | o que o planner guarda ali |
|---|---|---|
| `remember` | recomposição | o progresso de uma animação, uma posição de rolagem que o usuário não vai sentir falta |
| `rememberSaveable` | rotação e morte do processo, pelo `Bundle` | o que o usuário está digitando ou escolhendo: os minutos de um rascunho, um diálogo aberto |
| um `ViewModel`, aula 10 | rotação, enquanto o processo vive | os dados da tela, carregados uma vez e compartilhados pelos composables dela |
| um banco de dados, aula 15 | tudo, menos a desinstalação | cursos e sessões: o trabalho do estudante |

**A pergunta a fazer a um valor é quanto custaria ao usuário perdê-lo.** Uma posição de rolagem
perdida na rotação é um pequeno incômodo; minutos preenchidos pela metade perdidos na rotação são um
formulário que alguém digita duas vezes; uma semana de sessões perdida para a morte do processo é um
motivo para desinstalar o app. Cada resposta aponta para uma linha.

## Dois erros em direções opostas

**Vida curta demais.** O seletor de minutos da seção 06 com `remember` simples perde o número quando o
celular gira. A correção é uma palavra, e a seção 04 a mediu.

**Vida longa demais, ou coisa demais dentro.** Pôr a lista de cursos num `rememberSaveable` sobrevive a uma rotação. Também escreve cada curso no `Bundle` toda vez que a activity para, rumo ao limite de 50 kB que
a aula 2 citou, para dados que um banco de dados já guarda e poderia carregar de novo. O
`rememberSaveable` é para o que só os dedos do usuário produziram e nada mais consegue reconstruir.

O resto do curso segue esta tabela. A aula 10 leva os dados da tela para um `ViewModel` e mantém o
`rememberSaveable` para os rascunhos; a aula 15 põe as sessões no Room; a aula 16 decide em qual dos
dois a tela confia.
