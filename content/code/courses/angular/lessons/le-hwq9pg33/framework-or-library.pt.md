---
title: Quem chama quem
version: 1
---

**Um framework não é uma biblioteca maior.** A diferença está na direção da chamada. O seu código
chama uma biblioteca: você decide quando, com o quê, e o que fazer com a resposta. Um framework
chama o seu código: você escreve peças no formato que ele pede, entrega a ele, e ele decide quando
cada uma roda.

Você já usou os dois. Na aula 21 de `javascript` você instalou pacotes com o npm e os chamou; isso é
uma biblioteca. No navegador, você escreveu uma função e a passou para o `addEventListener`, e o
navegador a chamou quando alguém clicou. Esse segundo formato, em que você abre mão do *quando*, é o
que um framework faz para uma aplicação inteira.

## O que o Angular chama

Aqui está o menor componente Angular que existe. A aula 2 gera um parecido e a aula 3 o desmonta;
por enquanto, leia como uma lista de coisas que você entrega:

```typescript
import { Component } from '@angular/core';

@Component({
  selector: 'app-week',
  template: '<p>This week: {{ minutes }} minutes</p>',
})
export class Week {
  minutes = 165;
}
```

Nada aí roda coisa alguma. Não há `new Week()`, nenhuma chamada que põe o parágrafo na página,
nenhuma linha que decide quando `minutes` é lido. O Angular faz as três coisas. Ele encontra
`<app-week>` numa página, constrói um `Week`, lê `minutes` para dentro do template, e lê de novo
sempre que decide que algo pode ter mudado. As aulas 6 e 7 tratam exatamente de como ele decide.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas colunas. À esquerda, uma biblioteca: o seu código está em cima e chama as funções da biblioteca, e recebe as respostas de volta. À direita, um framework: o Angular está em cima e chama a sua classe, construindo-a, lendo os campos dela para o template, e lendo de novo quando algo muda.\"><text x=\"180\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">uma biblioteca</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">um framework</text><line x1=\"360\" y1=\"12\" x2=\"360\" y2=\"238\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></line><rect x=\"70\" y=\"44\" width=\"220\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o seu código</text><text x=\"180\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">decide quando</text><rect x=\"70\" y=\"170\" width=\"220\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a biblioteca</text><text x=\"180\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">format(date)</text><line x1=\"150\" y1=\"96\" x2=\"150\" y2=\"168\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"150.0,168.0 146.9,160.6 153.1,160.6\" fill=\"var(--phosphor)\"></polygon><text x=\"144\" y=\"132\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">chama</text><line x1=\"210\" y1=\"170\" x2=\"210\" y2=\"98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"210.0,98.0 213.1,105.4 206.9,105.4\" fill=\"var(--paper-dim)\"></polygon><text x=\"216\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">responde</text><rect x=\"430\" y=\"44\" width=\"220\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">Angular</text><text x=\"540\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">decide quando</text><rect x=\"430\" y=\"170\" width=\"220\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a sua classe</text><text x=\"540\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">class Week { minutes = 165 }</text><line x1=\"470\" y1=\"96\" x2=\"470\" y2=\"168\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"470.0,168.0 466.9,160.6 473.1,160.6\" fill=\"var(--amber)\"></polygon><text x=\"474\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">constrói</text><line x1=\"540\" y1=\"96\" x2=\"540\" y2=\"168\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"540.0,168.0 536.9,160.6 543.1,160.6\" fill=\"var(--amber)\"></polygon><text x=\"544\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">lê minutes</text><line x1=\"610\" y1=\"96\" x2=\"610\" y2=\"168\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"610.0,168.0 606.9,160.6 613.1,160.6\" fill=\"var(--amber)\"></polygon><text x=\"614\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">lê de novo</text></svg>", "caption": "Você chama uma biblioteca e ela responde. Um framework chama você, e decide quando.", "same": ["Angular"]}
```

## O que o React deixa para você

O React se descreve como uma biblioteca para construir interfaces, e a descrição é precisa. Ele
transforma os seus componentes em DOM e os mantém atualizados. Rotas, formulários, conversa com um
servidor, injeção de dependência, o build e o executor de testes não estão nele: cada projeto React
escolhe cada um, e dois projetos React em duas empresas muitas vezes escolheram diferente.

O Angular traz todos eles, escritos pelo mesmo time, lançados juntos, com o mesmo número de versão:

| assunto | no Angular | num projeto React |
|---|---|---|
| renderização | `@angular/core` | React |
| rotas | `@angular/router` (aulas 17 e 18) | React Router, TanStack Router, ou um meta-framework |
| formulários | `@angular/forms` (aulas 14 a 16) | React Hook Form, Formik, ou à mão |
| dados do servidor | `HttpClient` (aula 12) | `fetch`, TanStack Query, SWR |
| compartilhar objetos | injeção de dependência (aulas 10 e 11) | context, ou uma biblioteca de estado |
| build e servidor de desenvolvimento | a CLI do Angular (aula 2) | Vite, Next.js, ou outro |
| testes | TestBed e Vitest (aula 24) | Vitest ou Jest, e Testing Library |

**A tabela é o argumento inteiro desta aula.** Cada linha da esquerda é uma decisão que ninguém num
time de Angular precisa tomar, e cada linha da direita é uma decisão que alguém num time de React
tomou, uma vez, e que a próxima pessoa a chegar precisa aprender. A aula 25 olha React, Vue e Svelte
lado a lado com o que você vai saber até lá.

## O preço de ser chamado

Ser chamado tem um custo, e ele é pago adiantado. Você não escreve um componente Angular útil sem
saber o que é um decorator, o que faz a lista `imports`, como um template se liga a uma classe e,
logo depois, como a injeção de dependência entrega a um componente aquilo de que ele precisa. Um
componente React é uma função que devolve marcação, e o primeiro de um iniciante funciona antes de
ele saber muito mais.

Então o Angular é mais lento para começar e mais rápido para assentar. A primeira semana custa mais,
e o centésimo componente se parece com o primeiro, escrito do mesmo jeito por quem quer que o tenha
escrito. A próxima seção é sobre a quem essa troca serve.
