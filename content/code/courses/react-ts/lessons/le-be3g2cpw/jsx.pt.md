---
title: JSX é uma chamada de função
version: 1
---

**O JSX parece HTML dentro do JavaScript, e não é nenhum dos dois.** É um jeito mais curto de
escrever chamadas a uma função que monta a descrição de um elemento. O navegador nunca o vê: o Vite
transforma cada `<tag>` numa chamada antes de enviar o arquivo. Ter essa imagem explica cada regra
que o JSX tem, então esta seção começa pela chamada e volta às regras depois.

Aqui está o primeiro componente do planejador. Ele recebe uma segunda-feira e as sessões daquela
semana, e desenha as duas linhas do topo da tela. Salve como `src/WeekSummary.tsx`:

```tsx
import type { Session } from './types'
import { formatWeek, minutes } from './week'

type WeekSummaryProps = {
  monday: string
  sessions: Session[]
}

export function WeekSummary({ monday, sessions }: WeekSummaryProps) {
  const done = sessions.filter((s) => s.done)
  return (
    <section aria-label="This week">
      <p>Week of {formatWeek(monday)}</p>
      <p>
        {minutes(done)} of {minutes(sessions)} minutes done
      </p>
    </section>
  )
}
```

## O que o navegador recebe

O servidor de desenvolvimento responde por qualquer arquivo em `src/`, traduzido do jeito que o
navegador vai recebê-lo. Peça este:

```
ana@dev:~/planner$ curl -s http://localhost:5173/src/WeekSummary.tsx | head -n 24
import { createHotContext as __vite__createHotContext } from "/@vite/client";import.meta.hot = __vite__createHotContext("/src/WeekSummary.tsx");const _jsxDEV = __vite__cjsImport1_react_jsxDevRuntime["jsxDEV"];import { formatWeek, minutes } from "/src/week.ts";
var _jsxFileName = "/home/ana/planner/src/WeekSummary.tsx";
import __vite__cjsImport1_react_jsxDevRuntime from "/node_modules/.vite/deps/react_jsx-dev-runtime.js?v=2f28d197";
export function WeekSummary({ monday, sessions }) {
	const done = sessions.filter((s) => s.done);
	return /* @__PURE__ */ _jsxDEV("section", {
		"aria-label": "This week",
		children: [/* @__PURE__ */ _jsxDEV("p", { children: ["Week of ", formatWeek(monday)] }, void 0, true, {
			fileName: _jsxFileName,
			lineNumber: 13,
			columnNumber: 7
		}, this), /* @__PURE__ */ _jsxDEV("p", { children: [
			minutes(done),
			" of ",
			minutes(sessions),
			" minutes done"
		] }, void 0, true, {
			fileName: _jsxFileName,
			lineNumber: 14,
			columnNumber: 7
		}, this)]
	}, void 0, true, {
		fileName: _jsxFileName,
		lineNumber: 12,
```

Os tipos sumiram, os imports apontam para caminhos de verdade, e **cada tag virou uma chamada a
`_jsxDEV`**: o primeiro argumento é o que criar, `"section"` ou `"p"`; o segundo guarda os atributos
e, em `children`, o que estava entre as tags. O texto `Week of ` e o valor de `formatWeek(monday)`
são dois children do primeiro `p`. O resto, `fileName` e `lineNumber`, está ali para que as
mensagens de erro do React apontem para o seu código; um build de produção usa uma função menor,
`jsx`, sem eles.

```schooling-figure
{"svg": "<svg data-fig=\"jsx-call\" viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Três etapas de um parágrafo. À esquerda o JSX como escrito, um elemento p com o texto Week of e uma expressão. No meio a chamada em que o Vite o transforma, com o tipo p e um objeto de props cujos children são o texto e a expressão. À direita o objeto simples que a chamada devolve, com um tipo e props, e nada na página ainda.\"><text x=\"110\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que você escreve</text><text x=\"360\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que roda</text><text x=\"610\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que devolve</text><rect x=\"10\" y=\"40\" width=\"200\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"22\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">&lt;p&gt;</text><text x=\"34\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Week of</text><text x=\"34\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">{formatWeek(monday)}</text><text x=\"22\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">&lt;/p&gt;</text><line x1=\"212\" y1=\"100\" x2=\"248\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"248.0,100.0 240.5,103.2 240.5,96.8\" fill=\"var(--wire)\"></polygon><rect x=\"250\" y=\"40\" width=\"220\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"262\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">_jsxDEV(&quot;p&quot;, {</text><text x=\"274\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">children: [</text><text x=\"286\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&quot;Week of &quot;,</text><text x=\"286\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">formatWeek(monday)</text><text x=\"274\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">] })</text><line x1=\"472\" y1=\"100\" x2=\"508\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"508.0,100.0 500.5,103.2 500.5,96.8\" fill=\"var(--wire)\"></polygon><rect x=\"510\" y=\"40\" width=\"200\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"522\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">{ type: &quot;p&quot;,</text><text x=\"534\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">props: {</text><text x=\"546\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">children: [</text><text x=\"558\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">&quot;Week of &quot;, &quot;19 Oct 2026&quot;</text><text x=\"534\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">] } }</text><text x=\"610\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ainda não está na página</text></svg>", "caption": "O JSX é o que se escreve, a chamada é o que roda, e o objeto é o que o React recebe."}
```

Chamar essa função não toca na página. **Ela devolve um objeto simples que descreve o elemento**, o
tipo e as props dele, e um componente devolve uma árvore desses objetos. Colocá-los na página é
trabalho do React, e a aula 3 trata de como ele faz isso.

## As regras, lidas através da chamada

Cada regra do JSX é consequência de ele ser uma lista de argumentos:

- **Uma raiz só.** Uma função devolve um valor, então um componente devolve um elemento. Envolva
  irmãos num pai, ou em `<>…</>`, um fragmento, que agrupa sem acrescentar elemento à página.
- **Chaves guardam uma expressão**, qualquer coisa que produza um valor: `{minutes(done)}`, um
  ternário, uma chamada a `map`. Um `if` não é uma expressão, então não pode ir entre chaves; a aula
  8 mostra o que escrever no lugar.
- **Atributos são nomes de propriedade.** `class` é palavra reservada no JavaScript, então o atributo
  é `className`; `for` vira `htmlFor`. Atributos com hífen o mantêm, como `aria-label` acima, e
  chegam à página exatamente como escritos.
- **Toda tag é fechada**, inclusive `<br />`, porque a chamada precisa saber onde terminam os
  children.

O `aria-label="This week"` merece uma segunda olhada. O elemento section não tem título visível,
então o rótulo é o que um leitor de tela anuncia ao chegar ali, e é o que o `look` vai imprimir como
nome da região.
