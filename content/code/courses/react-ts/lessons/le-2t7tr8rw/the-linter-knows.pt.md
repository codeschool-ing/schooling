---
title: O linter conhece as regras
version: 1
---

**As duas regras podem ser conferidas lendo o código, sem rodá-lo, e o linter do modelo faz isso.** O
Oxlint, que o `npm run lint` roda, tem a regra do próprio plugin de ESLint do time do React com o nome
`react-hooks/rules-of-hooks`, e o `.oxlintrc.json` do modelo a põe como `error`. Ela achou o hook
depois do `return` antecipado na seção anterior, e acha com a mesma facilidade um hook escondido
dentro de uma expressão:

```
ana@dev:~/planner$ sed -i 's|^  const \[showLeft, setShowLeft\] = useState(false)$|  const [showLeft, setShowLeft] = sessions.length > 0 ? useState(false) : [false, () => {}]|' src/WeekSummary.tsx
ana@dev:~/planner$ sed -n 10,12p src/WeekSummary.tsx
export function WeekSummary({ monday, sessions }: WeekSummaryProps) {
  const [showLeft, setShowLeft] = sessions.length > 0 ? useState(false) : [false, () => {}]
  if (sessions.length === 0) {
ana@dev:~/planner$ npm run lint 2>&1 | head -n 12

> planner@0.0.0 lint
> oxlint


  x react-hooks(rules-of-hooks): React Hook "useState" is called conditionally. React Hooks must be called in the exact same order in every component render.
    ,-[src/WeekSummary.tsx:11:57]
 10 | export function WeekSummary({ monday, sessions }: WeekSummaryProps) {
 11 |   const [showLeft, setShowLeft] = sessions.length > 0 ? useState(false) : [false, () => {}]
    :                                   ^^^^^^^^^|^^^^^^^^^   ^^^^^^^|^^^^^^^
    :                                            |                   `-- This Hook call is not reachable on every render path.
    :                                            `-- Only one side of this conditional expression calls the Hook.
ana@dev:~/planner$ cp /tmp/WeekSummary.tsx src/WeekSummary.tsx
```

`sessions.length > 0 ? useState(false) : [false, () => {}]` é uma tentativa de chamar um hook só
quando há algo a mostrar, escrita para parecer uma linha só em vez de um `if`. O linter não está lendo
linhas. Ele aponta para as duas metades da expressão e diz qual delas chama o hook.

**Trate o erro dessa regra como um erro de compilação.** Um componente que a quebra pode funcionar
hoje, com os dados que você por acaso testa, e quebrar quando os dados mudarem de forma; as duas
últimas seções são exatamente isso. A aula 23 põe o linter entre os comandos que rodam antes de cada
commit, para que um erro de `rules-of-hooks` nunca chegue ao branch principal, e mostra a mesma regra
no ESLint para um projeto que use ele.

O linter tem uma segunda regra de hooks, a `exhaustive-deps`, que a aula 5 encontrou como aviso sobre
o título. Ela é um aviso, e não um erro, por escolha do modelo, porque há casos raros em que o array
certo não é o que ela sugere. Esses casos são raros o bastante para que o hábito seguro seja tratar o
aviso como erro também, e escrever um comentário onde você decidir o contrário. A próxima seção é o
motivo mais comum de ele disparar.
