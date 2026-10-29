---
title: A camada que não executa nada
version: 1
---

**O teste mais barato é o que você não escreve.** O verificador de tipos lê cada arquivo a cada vez
que você salva e acha uma classe inteira de erros antes de qualquer coisa rodar. Neste projeto é o
`tsc`, o compilador do TypeScript, que o `tsconfig.json` do template manda conferir sem gerar arquivo
nenhum.

Eis o tipo de erro para o qual ele existe. O `FormData.get` devolve o que o navegador leu de um campo,
que é um texto, um arquivo ou nada. Deixe de fora o `Number(…)` em volta dos minutos no `src/view.ts`,
e o formulário entrega ao `addSession` o tipo errado de valor:

```
ana@dev:~/planner$ npx tsc --noEmit
src/view.ts(45,66): error TS2345: Argument of type 'FormDataEntryValue | null' is not assignable to parameter of type 'number'.
  Type 'null' is not assignable to type 'number'.
ana@dev:~/planner$ git checkout src/view.ts
Updated 1 path from the index
ana@dev:~/planner$ npx tsc --noEmit
```

A mensagem diz o arquivo, a linha e a coluna, `src/view.ts(45,66)`, e diz exatamente o que estava
errado: um valor que pode ser um texto, um arquivo ou `null`, passado onde se declarou um número. O
`git checkout` devolveu o arquivo ao que era, e a segunda execução não mostrou nada, que é o `tsc`
dizendo sim.

**Sem o verificador de tipos, esse erro roda.** O JavaScript passaria o texto `"15"` ao `addSession`, o
`Number.isInteger("15")` daria falso, e a pessoa preenchendo o formulário ouviria que 15 não é um
número inteiro de 1 a 600. Um teste unitário do `addSession` passaria, porque chama a função com
números. Um teste de componente que digitasse no formulário pegaria o erro, um segundo depois e uma
camada acima. O verificador pegou pelo custo da leitura.

## O que ele não consegue fazer

O `tsc` conhece o formato dos valores, não se eles estão certos. O `weekTotal(plan, "2026-10-21")`
passa na checagem seja o que for que devolva, contanto que seja um número, e um número errado ainda é
um número. Ele também confia nos dados: o `await response.json()` tem um tipo qualquer, e o `main.ts`
o atribui a um `Plan` sem olhar. Se o `courses.json` dissesse `"minutes": "45"`, o verificador não
teria como saber. Uma checagem em execução dos dados de fora, como a que um servidor faz no que
recebe, está fora do que qualquer quantidade de checagem estática pode dar.

Então a camada estática é a base e não o prédio: ela tira os erros que são de formato, e deixa os que
são de sentido para os testes.

## Ela roda no build

O script `build` do template é `tsc && vite build`, então o `npm run build` se recusa a empacotar um
projeto que não passa na checagem de tipos. O `npm run dev` não confere: o Vite tira os tipos e serve
o arquivo, para continuar rápido, e é por isso que o sublinhado vermelho do editor e a execução do
`tsc` são os lugares onde um erro de tipo aparece enquanto você trabalha.
