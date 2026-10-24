---
title: Uma segunda versão, e o planner uma atrás
version: 1
---

**Uma versão é uma mudança, um número que a descreve, uma nota dizendo o que foi, e uma publicação.** Esta
acrescenta um componente, o que não muda nada que já existia, então é uma versão minor: de `0.1.0` para
`0.2.0`.

## A mudança

Uma barra de progresso da semana, na biblioteca:

```typescript
// src/components.ts: a fourth component, added at the end
/** Minutes done out of minutes planned, as a bar with a name a screen reader can read. */
export function progressBar(done: number, planned: number): HTMLProgressElement {
  const bar = document.createElement("progress");
  bar.max = Math.max(planned, 1);
  bar.value = Math.min(done, bar.max);
  bar.setAttribute("aria-label", "Minutes done this week");
  bar.textContent = `${duration(done)} of ${duration(planned)}`;
  return bar;
}
```

`<progress>` é a barra do próprio navegador, anunciada pelos leitores de tela como um valor de um máximo.
`Math.max(planned, 1)` evita uma barra cujo máximo é zero, o caso da semana vazia que a aula 6 ensinou a
biblioteca a esperar. Exporte-a pela porta de entrada:

```
ana@dev:~/planner-ui$ sed -i 's/export { actionButton, sessionRow, weekSummary }/export { actionButton, progressBar, sessionRow, weekSummary }/' src/index.ts
ana@dev:~/planner-ui$ npx tsc && echo types ok
types ok
```

## A nota

**Um changelog é escrito para quem vai atualizar**, então diz o que essas pessoas ganham e o que precisam
mudar, e não quais arquivos se mexeram. Um arquivo, a versão mais nova primeiro:

```
<!-- CHANGELOG.md -->
# Changelog

## 0.2.0

- Added `progressBar`, which shows minutes done out of minutes planned.

## 0.1.0

- First release: the tokens, the type and spacing scales, two themes, `actionButton`, `sessionRow` and
  `weekSummary`.
```

## A versão e a publicação

O `npm version minor` sobe a versão no `package.json` e no lockfile, faz o commit e marca o commit com a tag
`v0.2.0`, para a versão poder ser achada no histórico:

```
ana@dev:~/planner-ui$ git add -A && git commit -qm "Add progressBar"
ana@dev:~/planner-ui$ npm version minor
v0.2.0
ana@dev:~/planner-ui$ git log --oneline --decorate -2
bb25678 (HEAD -> main, tag: v0.2.0) 0.2.0
4cb7a84 Add progressBar
ana@dev:~/planner-ui$ npm run build > /dev/null && npm publish 2>&1 | tail -1
+ @planner/ui@0.2.0
```

## O planner, avisado de que está atrás

No planner, o `npm outdated` compara o que está instalado com o que o registry tem:

```
ana@dev:~/planner$ npm outdated @planner/ui; echo $?
Package      Current  Wanted  Latest  Location                  Depended by
@planner/ui    0.1.0   0.1.0   0.2.0  node_modules/@planner/ui  planner
1
```

**Current** é o que está instalado; **Wanted** é a mais nova que o intervalo do `package.json` permite, a
mesma `0.1.0` porque o planner a fixa exatamente; **Latest** é a mais nova publicada. O código de saída é 1,
que é como um pipeline poderia notar uma dependência ficando para trás. Atualizar é um comando e um commit,
feitos de propósito, que é o ponto de fixar:

```
ana@dev:~/planner$ npm install --save-exact @planner/ui@0.2.0 2>&1 | tail -1
found 0 vulnerabilities
ana@dev:~/planner$ git commit -qam "@planner/ui 0.2.0"
ana@dev:~/planner$ git log --oneline -1
f7e724d @planner/ui 0.2.0
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Uma linha do tempo de versões de @planner/ui: 0.1.0, depois 0.2.0. O planner está fixado em 0.1.0; o npm outdated relata Current 0.1.0, Wanted 0.1.0 e Latest 0.2.0. Atualizar é um commit que instala a 0.2.0.\"><line x1=\"40\" y1=\"60\" x2=\"680\" y2=\"60\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"680.0,60.0 672.6,63.1 672.6,56.9\" fill=\"var(--wire)\"></polygon><text x=\"680\" y=\"44\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">versões</text><rect x=\"120\" y=\"46\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"160\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">0.1.0</text><rect x=\"420\" y=\"46\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">0.2.0</text><text x=\"460\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+ progressBar</text><rect x=\"100\" y=\"112\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"160\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o planner</text><line x1=\"160\" y1=\"112\" x2=\"160\" y2=\"78\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"160.0,78.0 163.1,85.4 156.9,85.4\" fill=\"var(--amber)\"></polygon><text x=\"240\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Current 0.1.0 · Wanted 0.1.0 · Latest 0.2.0</text><text x=\"240\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">atualizar é um commit, feito de propósito</text></svg>", "caption": "Quem consome com versão fixa fica onde está até alguém mudar, e o npm outdated diz quanto está atrás."}
```

## Ferramentas que fazem a contabilidade

O **Changesets** é a ferramenta que a maioria das bibliotecas JavaScript usa para isto: cada pull request
leva um arquivo pequeno citando os pacotes que muda e se a mudança é patch, minor ou major, com uma linha
para o changelog. Na hora da versão, um comando transforma os arquivos acumulados em números de versão e
entradas de changelog, em todo pacote de um monorepo de uma vez. Ele não foi executado para este curso; os
comandos dele fazem perguntas num terminal, e o que ele automatiza são exatamente os três passos acima.
