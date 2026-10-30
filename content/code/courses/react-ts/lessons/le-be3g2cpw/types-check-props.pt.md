---
title: Os tipos conferem as props, mas não enquanto você navega
version: 1
---

**O compilador conhece o contrato de cada componente, e o Vite não pergunta a ele.** É uma troca
deliberada, e conhecê-la é a diferença entre confiar numa página que renderiza e confiar numa página
que está certa. Esta seção comete um erro de propósito e o segue pelos três lugares onde ele poderia
ser pego.

O erro: o `App` passa ao `WeekSummary` um número onde as props pedem uma string.

```
ana@dev:~/planner$ sed -i 's/<WeekSummary monday={MONDAY} sessions={thisWeek} \/>/<WeekSummary monday={19} sessions={thisWeek} \/>/' src/App.tsx
ana@dev:~/planner$ grep -n "<WeekSummary" src/App.tsx
14:      <WeekSummary monday={19} sessions={thisWeek} />
ana@dev:~/planner$ look http://localhost:5173/ 2>&1 | head -n 5
- main:
  - heading "Study planner" [level=1]
  - region "This week":
    - paragraph: Week of Invalid Date
    - paragraph: 80 of 195 minutes done
ana@dev:~/planner$ npx tsc -b
src/App.tsx(14,20): error TS2322: Type 'number' is not assignable to type 'string'.
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc -b && vite build

src/App.tsx(14,20): error TS2322: Type 'number' is not assignable to type 'string'.
ana@dev:~/planner$ sed -i 's/monday={19}/monday={MONDAY}/' src/App.tsx
ana@dev:~/planner$ npx tsc -b && echo no errors
no errors
```

Em ordem:

1. **A página desenhou.** O `look` mostra a tela, com "Week of Invalid Date" onde deveria estar a
   data. O Vite remove os tipos sem conferi-los, o que o deixa rápido o bastante para atualizar a
   página enquanto você ainda digita, e quer dizer que um erro de tipo nunca para o servidor de
   desenvolvimento.
2. **O `npx tsc -b` recusou**, com o arquivo, a linha e a coluna, `src/App.tsx(14,20)`, e uma frase
   que diz exatamente o que está errado. O `tsc` é o compilador do TypeScript; o `-b` constrói o
   projeto do jeito que os três `tsconfig` descrevem, e aqui ele só confere, porque o modelo diz a ele
   para não escrever saída nenhuma.
3. **O `npm run build` também recusou**, porque o script de build do modelo é `tsc -b && vite build`,
   e o `&&` só roda o segundo comando quando o primeiro dá certo. Nada que falhe na checagem de tipos
   pode ser publicado.

O seu editor é o quarto lugar, e o melhor: um editor que entende TypeScript sublinha o
`monday={19}` enquanto você digita, com a mesma frase. O Visual Studio Code faz isso sem extensão.

**Rode `npx tsc -b` antes de confiar numa mudança**, ou deixe-o rodando num terminal próprio com
`npx tsc -b --watch`. Uma página que renderiza só mostrou que nada lançou exceção; esta renderizou
uma data errada com todos os números de baixo certos, porque o `App` calculou a semana a partir da
própria constante e o erro só chegou à linha que lia a prop. A aula 23 acrescenta a checagem de
tipos aos comandos que rodam antes de cada commit, e a aula 19 trata de escrever tipos que pegam mais.
