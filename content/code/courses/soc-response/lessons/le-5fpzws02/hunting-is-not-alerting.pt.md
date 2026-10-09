---
title: Caçar não é alertar
version: 1
---

Um alerta é uma pergunta que alguém escreveu **antes** do evento: "me avise quando isto acontecer". Ele pega o
que o autor imaginou. A **caça a ameaças** vai na direção oposta: uma pessoa parte do pressuposto de que algo
que as regras não imaginaram já está no ambiente, e vai procurar nos dados.

| | alertar | caçar |
|---|---|---|
| parte de | uma regra, escrita de antemão | uma hipótese, escrita hoje |
| roda | continuamente, por máquina | numa campanha, por uma pessoa |
| procura | o que alguém esperava | aquilo para o que ninguém escreveu regra |
| termina | quando o alerta é fechado | num achado, numa regra nova, ou num negativo documentado |

Um engano comum é achar que caçar é folhear logs até algo parecer estranho. Folhear acha o que é
visualmente barulhento, que raramente é o que importa, e não pode ser repetido nem medido. **Uma caçada tem
uma hipótese escrita, um conjunto de dados definido, um método e um resultado**, e cada parte fica
registrada para outro analista poder rodá-la de novo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"O ciclo da caça: uma hipótese leva à escolha dos dados, os dados a uma busca, a busca à validação, e a validação a um de três resultados: um achado entregue à resposta a incidentes, uma regra nova, ou um negativo documentado. Cada resultado alimenta a próxima hipótese.\"><rect x=\"20\" y=\"30\" width=\"120\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"80.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hipótese</text><path d=\"M140 52 L170 52\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M170 52 L162.0 48.0 L162.0 56.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"170\" y=\"30\" width=\"120\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"230.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">dados</text><path d=\"M290 52 L320 52\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M320 52 L312.0 48.0 L312.0 56.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"320\" y=\"30\" width=\"120\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"380.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">busca</text><path d=\"M440 52 L470 52\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M470 52 L462.0 48.0 L462.0 56.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"470\" y=\"30\" width=\"120\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"530.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">validar</text><rect x=\"30\" y=\"140\" width=\"200\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"130.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">achado: para a resposta</text><rect x=\"260\" y=\"140\" width=\"200\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma regra nova</text><rect x=\"490\" y=\"140\" width=\"200\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"590.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um negativo documentado</text><path d=\"M530 74 L530 100 L130 100 L130 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M130 140 L134.0 132.0 L126.0 132.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M530 100 L360 100 L360 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M360 140 L364.0 132.0 L356.0 132.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M530 100 L590 100 L590 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M590 140 L594.0 132.0 L586.0 132.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M690 160 L705 160 L705 15 L80 15 L80 30\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M80 30 L84.0 22.0 L76.0 22.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path></svg>", "caption": "Uma caçada termina de um de três jeitos, e os três são resultados."}
```

Os três resultados da linha de baixo são todos resultados. Um **achado** vai para a resposta a incidentes
como escalação (aula 7). Uma **regra nova** quer dizer que esta pergunta nunca mais precisa ser caçada à mão.
E um **negativo documentado**, "procuramos X nestes dados com este método, e não está lá", é informação em
que a próxima pessoa pode confiar, desde que diga exatamente o que foi procurado.
