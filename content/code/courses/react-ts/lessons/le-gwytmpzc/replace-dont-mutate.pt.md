---
title: Substitua, nunca mude no lugar
version: 1
---

**Uma atualização de um objeto ou array no estado é um objeto ou array novo.** O React decide se
alguma coisa mudou comparando o valor antigo com o novo usando `Object.is`, que para objetos faz uma
pergunta só: é o mesmo objeto? Mude um array no lugar e devolva o mesmo array, e a resposta é sim,
então nada renderiza de novo. Este é o `toggleDone` escrito do jeito que a maioria tenta primeiro:

```
ana@dev:~/planner$ cp src/App.tsx /tmp/App.tsx
ana@dev:~/planner$ sed -n 14,20p src/App.tsx
  function toggleDone(id: string) {
    setSessions((all) => {
      const session = all.find((s) => s.id === id)!
      session.done = !session.done
      return all
    })
  }
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min'
-- click button Statistics
-- click checkbox Wed 21 Oct · 40 min
- main:
  - button "Back to courses"
  - heading "Statistics" [level=1]
  - list:
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | sed -n 9,11p
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
ana@dev:~/planner$ cp src/main.tsx /tmp/main.tsx
ana@dev:~/planner$ sed -i 's/<StrictMode>/<>/; s/<\/StrictMode>/<\/>/; /^import { StrictMode }/d' src/main.tsx
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' | tail -n 3
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | sed -n 9,11p
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 120 of 195 minutes done
ana@dev:~/planner$ cp /tmp/App.tsx src/App.tsx && cp /tmp/main.tsx src/main.tsx
```

Quatro transcrições, e cada uma diz uma coisa:

1. **A caixa não foi marcada.** A função devolveu `all`, o mesmo array que recebeu, então o React não
   viu mudança e não renderizou. A caixa mostra o estado, e para o React o estado é o mesmo.
2. **Voltando, o total continua 80.** Com strict mode o React roda uma função de atualização duas
   vezes, para achar as impuras, e esta virou `done` para true e depois de volta para false. O strict
   mode pegou a mutação fazendo-a se anular.
3. **Sem strict mode, a caixa continuou desmarcada.**
4. **Mas, voltando, o total diz 120.** O `done` da sessão tinha virado true na memória, pelas costas do
   React, e o resumo o pegou na próxima vez que outra coisa causou uma renderização. Uma tela que
   mostra a mudança em algum lugar e não onde você a fez é a assinatura de uma mutação.

A correção é a linha que o `App` tinha antes:
`all.map((s) => (s.id === id ? { ...s, done: !s.done } : s))`.

```schooling-figure
{"svg": "<svg data-fig=\"replace\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"À esquerda, mudar no lugar: um array antes e depois, o mesmo objeto, com o done do s2 trocado lá dentro, e o Object.is diz que não mudou. À direita, map: um array novo, com um objeto novo para o s2 e os mesmos objetos s1, s3, s4, s5 e s6 de antes, e o Object.is diz que mudou.\"><text x=\"170\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">no lugar</text><rect x=\"40\" y=\"36\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"48\" y=\"44\" width=\"36\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"66.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s1</text><rect x=\"90\" y=\"44\" width=\"36\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"108.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s2</text><rect x=\"132\" y=\"44\" width=\"36\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s3</text><rect x=\"174\" y=\"44\" width=\"36\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"192.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s4</text><rect x=\"216\" y=\"44\" width=\"36\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"234.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s5</text><rect x=\"258\" y=\"44\" width=\"36\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"276.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s6</text><text x=\"170\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o mesmo array, s2 mudado por dentro</text><text x=\"170\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Object.is(old, new) → true</text><text x=\"170\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">nenhuma renderização</text><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">map: um array novo</text><rect x=\"400\" y=\"36\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"56\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">antigo</text><rect x=\"400\" y=\"116\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">novo</text><rect x=\"408\" y=\"44\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"427.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s1</text><rect x=\"408\" y=\"124\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"427.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s1</text><line x1=\"427\" y1=\"68\" x2=\"427\" y2=\"124\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><rect x=\"453\" y=\"44\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"472.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s2</text><rect x=\"453\" y=\"124\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"472.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">s2'</text><rect x=\"498\" y=\"44\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"517.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s3</text><rect x=\"498\" y=\"124\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"517.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s3</text><line x1=\"517\" y1=\"68\" x2=\"517\" y2=\"124\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><rect x=\"543\" y=\"44\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"562.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s4</text><rect x=\"543\" y=\"124\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"562.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s4</text><line x1=\"562\" y1=\"68\" x2=\"562\" y2=\"124\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><rect x=\"588\" y=\"44\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"607.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s5</text><rect x=\"588\" y=\"124\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"607.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s5</text><line x1=\"607\" y1=\"68\" x2=\"607\" y2=\"124\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><rect x=\"633\" y=\"44\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"652.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s6</text><rect x=\"633\" y=\"124\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"652.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s6</text><line x1=\"652\" y1=\"68\" x2=\"652\" y2=\"124\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><text x=\"540\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Object.is(old, new) → false</text><text x=\"540\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tracejado: o mesmo objeto, reaproveitado</text></svg>", "caption": "O React compara identidades. Um array novo com um objeto novo é uma mudança que ele enxerga."}
```

O `map` devolve um array novo, então o React vê uma mudança. A sessão que mudou é um objeto novo,
`{ ...s, done: !s.done }`, copiado do antigo com um campo trocado. **Todas as outras sessões são o
mesmo objeto de antes**, o que não custa nada e deixa o `memo` da aula 21 pular os cartões cujos
dados não mudaram. O original fica intacto, então a função dá a mesma resposta não importa quantas
vezes o strict mode a chame.

O mesmo vale para acrescentar e remover, que a aula 10 vai precisar:

| mudança | no lugar: errado | um array novo: certo |
|---|---|---|
| acrescentar | `all.push(s)` | `[...all, s]` |
| remover | `all.splice(i, 1)` | `all.filter((x) => x.id !== id)` |
| mudar um | `all[i].done = true` | `all.map((x) => (x.id === id ? { ...x, done: true } : x))` |
| ordenar | `all.sort(byDate)` | `[...all].sort(byDate)`, ou `all.toSorted(byDate)` |

O último comando da transcrição põe de volta o `App` correto e o strict mode.
