---
title: Comentários que ensinam
version: 1
---

**Um comentário que ensina diz o que o revisor notou, por que isso importa e o quanto ele tem certeza,
e deixa espaço para o autor responder.** Um comentário que só dá ordens ("renomeie isto", "use um
dict") corrige a linha e ensina o autor a esperar a próxima ordem.

## Uma revisão real, linha por linha

Em julho, Diego revisou seu primeiro pull request fora do checkout, de Rafael, que tinha entrado na
logística três semanas antes. A mudança oferecia aos motoristas as próximas janelas de entrega. Lívia
leu os rascunhos dos comentários com Diego antes de ele publicá-los, como parte do plano da aula 10.
Estes são os comentários que ele publicou, ao lado do código de que tratavam:

```schooling-example
{"language": "python", "file": "slots.py", "parts": [{"code": "from datetime import datetime, timedelta\n\nCLOSING_HOUR = 22\n", "note": "issue (bloqueante): CLOSING_HOUR é definido e nunca usado, então nada impede a função de oferecer uma janela depois que o depósito fecha. Chamada às 21:10, ela devolve 22:00, 23:00 e 00:00. O laço poderia parar no horário de fechamento?"}, {"code": "\n\ndef next_slots(now, count=3):\n    first = now.replace(minute=0, second=0, microsecond=0) + timedelta(hours=1)\n", "note": "question: o depósito fecha às 22:00 no sábado também? Não conheço os horários da logística. Se mudam por dia, uma constante só não basta."}, {"code": "    slots = []\n    for i in range(count):\n        slots.append(first + timedelta(hours=i))\n    return slots\n", "note": "praise: o laço é fácil de acompanhar, e o nome diz o que devolve. nitpick (não bloqueante): poderia ser uma list comprehension; tanto faz."}]}
```

Chamada às 21:10, a função devolve 22:00, 23:00 e 00:00 do dia seguinte. O depósito fecha às 22:00,
então duas das três janelas que ela oferece não existem. A constante que teria evitado isso está ali
mesmo, sem uso. O comentário do Diego sobre ela é o que importa, e os outros estão lá porque a revisão
é sobretudo ensino.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"O comentário bloqueante do Diego dividido em quatro partes. O rótulo, issue blocking: quanto importa. O que foi notado, CLOSING_HOUR nunca é usado: uma coisa específica. Por que importa, às 21:10 oferece 22:00, 23:00 e 00:00: o efeito, concreto. A abertura, o laço poderia parar: espaço para responder.\"><defs><marker id=\"commentana-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"6\" y=\"30\" width=\"128\" height=\"54\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"12\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">issue (blocking):</text><text x=\"10\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">rótulo</text><text x=\"10\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quanto importa</text><rect x=\"140\" y=\"30\" width=\"196\" height=\"54\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"146\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CLOSING_HOUR is never used</text><text x=\"144\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o que foi notado</text><text x=\"144\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma coisa específica</text><rect x=\"342\" y=\"30\" width=\"208\" height=\"54\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"348\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">21:10 → 22:00, 23:00, 00:00</text><text x=\"346\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">por que importa</text><text x=\"346\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o efeito, concreto</text><rect x=\"556\" y=\"30\" width=\"150\" height=\"54\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"562\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">could the loop stop…?</text><text x=\"560\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a abertura</text><text x=\"560\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">espaço para responder</text><text x=\"14\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um comentário que só manda fica com a segunda caixa e larga as outras três</text></svg>", "caption": "A anatomia de um comentário que ensina, com o comentário do Diego do exemplo acima. Os trechos em fonte de código ficam como no código."}
```

## Diga o quanto importa

O hábito mais útil daquela revisão é o rótulo no início de cada comentário. Os **Conventional
Comments**, uma pequena convenção publicada, sugerem começar todo comentário com uma palavra que diz
que tipo de comentário ele é:

| rótulo | significa |
|---|---|
| **praise** | algo bem-feito, dito de forma específica |
| **issue** | um problema que precisa ser corrigido antes do merge |
| **question** | o revisor não entende e está perguntando, não insinuando |
| **suggestion** | um jeito melhor, que o autor pode recusar |
| **nitpick** | trivial; aceite ou deixe pra lá |
| **thought** | uma ideia para depois, não para esta mudança |

Com os rótulos, Rafael soube de relance que um comentário bloqueava o merge e os outros não. Sem eles,
um engenheiro novo lê cinco comentários de um revisor como cinco exigências, e o que importa se perde
entre os quatro que não importam.

## Pergunte quando estiver perguntando

Uma pergunta numa revisão muitas vezes é uma ordem disfarçada: "Você pensou em usar um dict aqui?"
quer dizer "use um dict". **Se a intenção é sugerir, escreva como sugestão; pergunte só quando você não
souber a resposta.** A pergunta do Diego sobre os sábados era real: ele não sabia se o horário do
depósito mudava nos fins de semana, e Rafael sabia. A resposta, "muda, tem uma tabela para isso",
virou um segundo issue que nenhum dos dois tinha visto de início.

## Elogie de forma específica

"LGTM" não ensina nada. "O loop é fácil de acompanhar e o nome diz o que ele devolve" diz ao Rafael o
que continuar fazendo. **Elogio específico é calibração**: diz ao autor quais escolhas foram boas e
deliberadas, para que ele as repita de propósito.
