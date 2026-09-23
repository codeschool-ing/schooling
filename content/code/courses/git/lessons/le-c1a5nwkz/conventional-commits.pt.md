---
title: Commits convencionais
version: 1
---

**Commits convencionais** (*Conventional Commits*) é uma convenção publicada, hoje na versão 1.0.0, para
a primeira linha e o rodapé de uma mensagem. Ela acrescenta uma estrutura que um programa consegue ler,
sem deixar a mensagem menos legível para uma pessoa:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma mensagem de commit com as partes identificadas. A primeira linha diz feat(order)!: require a pickup time for every order. feat é o tipo, que tipo de mudança é; order entre parênteses é o escopo; o ponto de exclamação diz que quebra alguma coisa; o resto é a descrição, no imperativo. Depois de uma linha em branco vem o corpo, dizendo por quê. Depois de outra linha em branco, o rodapé BREAKING CHANGE declara o que quebra.\"><defs><marker id=\"cm-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"680\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">feat</text><text x=\"64.8\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">(order)</text><text x=\"115.2\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">!</text><text x=\"122.4\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">: require a pickup time for every order</text><text x=\"36\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">The phone line used to accept orders with no time, and nobody knew</text><text x=\"36\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">when to bake them.</text><text x=\"36\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">BREAKING CHANGE: an order sent without a pickup time is refused.</text><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">tipo: que tipo de mudança</text><path d=\"M50 38 L50 64\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"210.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">escopo: qual parte</text><path d=\"M90.0 38 L90.0 64\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"418.8\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">!: quebra alguma coisa</text><path d=\"M118.8 64 L118.8 44 L358.8 38\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"700\" y=\"96\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">descrição: o que faz, no imperativo</text><text x=\"700\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">corpo: por quê, quebrado em uns 72</text><text x=\"700\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">rodapé: a quebra, declarada</text></svg>", "caption": "Toda parte pode ser lida por uma pessoa, e a primeira linha e o rodapé também por um programa."}
```

- **O tipo** é a primeira palavra: `feat` para algo novo, `fix` para um defeito corrigido. Esses dois
  estão na especificação. A maioria das equipes acrescenta mais alguns que ela permite: `docs`,
  `style`, `refactor` para uma mudança que não altera comportamento, `test`, `chore`.
- **O escopo**, opcional, entre parênteses, diz qual parte do projeto: `(menu)`, `(order)`.
- **`!`** depois do tipo ou do escopo diz que a mudança quebra algo que funcionava.
- **A descrição** vem depois dos dois-pontos, no imperativo, como na seção anterior.
- **O rodapé** `BREAKING CHANGE:` declara o que quebra, para quem precisar se adaptar.

Aqui está o site depois de quatro commits assim desde a `v1.0`:

```
ana@vm:~/site$ git log --oneline v1.0..HEAD
566d361 feat(order)!: require a pickup time for every order
d991070 docs: explain how to add a menu item
85d0100 feat(menu): add carrot cake
ca5ac49 fix(menu): show the new price of cheese rolls
ana@vm:~/site$ git log --oneline --grep="^feat" v1.0..HEAD
566d361 feat(order)!: require a pickup time for every order
85d0100 feat(menu): add carrot cake
ana@vm:~/site$ git log -1 --format=%B
feat(order)!: require a pickup time for every order

The phone line used to accept orders with no time, and nobody knew
when to bake them.

BREAKING CHANGE: an order sent without a pickup time is refused.
```

O `git log --grep="^feat"` lista as funcionalidades novas desde a última release, que é a primeira
metade das notas de release dela, escrita por ninguém. O último comando imprime uma mensagem inteira,
para o rodapé ser lido por completo.

## O que a estrutura compra

O objetivo da convenção é que **o histórico passa a responder perguntas que um programa sabe fazer**:

- *O que entra nas notas de release?* Todo `feat` e todo `fix` desde a última tag, agrupados.
- *Qual deve ser o próximo número de versão?* O versionamento semântico da aula 7, decidido pelos
  tipos: um `fix` desde a `v1.0` dá `v1.0.1`, um `feat` dá `v1.1.0`, e uma mudança que quebra dá
  `v2.0.0`. Aqui há um `!`, então a próxima release é a `v2.0.0`.

Ferramentas que fazem as duas coisas a partir do log são comuns, e uma equipe que adota a convenção
costuma adotar uma, junto com um check nos pull requests que recusa mensagem fora do formato.

## Onde ela não ajuda

Um tipo não é um motivo. `fix: fix bug` está no formato e não diz nada; *fix(menu): show the new price
of cheese rolls* está no formato e diz o que aconteceu. A convenção estrutura uma mensagem; não a
escreve. Adote-a quando a equipe quiser que as notas de release e os números de versão saiam do
histórico. Sem isso, uma primeira linha clara vale mais que um prefixo correto.
