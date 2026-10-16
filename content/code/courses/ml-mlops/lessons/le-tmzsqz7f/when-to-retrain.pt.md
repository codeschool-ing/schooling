---
title: Quando retreinar, e até onde o retreino alcança
version: 1
---

**Retreinar é o mesmo pipeline rodado com dados mais novos**, e a pergunta nunca é como, que as
lições 5 a 7 resolveram, e sim quando. Três gatilhos são comuns, e eles se combinam:

| gatilho | dispara quando | a fraqueza dele |
| --- | --- | --- |
| uma agenda | todo mês, todo trimestre | retreina quando nada mudou, espera quando algo mudou |
| deriva nas entradas | o PSI contra os dados de treino passa de um limite | deriva nem sempre é dano, como `tenure_days` mostrou |
| o boletim | o desempenho na noite mais recente com desfechos cai além de um limite | chega 90 dias depois da mudança |

**O atraso do rótulo limita todos eles.** Um modelo só aprende com desfechos que já fecharam, então a
noite mais nova em que ele pode ser treinado tem 90 dias. Em 30 de junho, isso é uma noite no começo
de abril, no máximo, e uma mudança que começou em 1º de abril mal chegou aos rótulos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l10-label-delay\" aria-label=\"Um calendário de dezembro de 2025 a junho de 2026. A noite de treino, 28 de dezembro, tem rótulos que fecham em 28 de março. A noite de teste, 29 de março, tem rótulos que fecham em 27 de junho. O rival abre em 1º de abril, depois de os rótulos do treino fecharem, e os dados terminam em 30 de junho.\"><path d=\"M30.0 190.0 L690.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M30.0 186.0 L30.0 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"56.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">dez</text><path d=\"M126.5 186.0 L126.5 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"152.5\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">jan</text><path d=\"M223.0 186.0 L223.0 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"249.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">fev</text><path d=\"M310.2 186.0 L310.2 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"336.2\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">mar</text><path d=\"M406.7 186.0 L406.7 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"432.7\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">abr</text><path d=\"M500.1 186.0 L500.1 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"526.1\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">mai</text><path d=\"M596.6 186.0 L596.6 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"622.6\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">jun</text><circle cx=\"114.1\" cy=\"70.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"106.1\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">noite de treino</text><rect x=\"120.1\" y=\"63.0\" width=\"274.2\" height=\"14.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"257.2\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os 90 dias de rótulos</text><circle cx=\"397.4\" cy=\"120.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"389.4\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">noite de teste</text><rect x=\"403.4\" y=\"113.0\" width=\"274.2\" height=\"14.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.5\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os 90 dias de rótulos</text><path d=\"M406.7 40.0 L406.7 104.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"406.7\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o rival abre</text><path d=\"M686.9 40.0 L686.9 186.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"686.9\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">os dados terminam</text></svg>", "caption": "A noite de treino mais nova que a regra permite tem rótulos que fecharam antes de qualquer mudança. A mudança está nos desfechos da noite de teste e em nenhum rótulo de treino."}
```

**O retreino também precisa de um teste, e a lição 3 fixou a regra dele**: a noite de teste vem pelo
menos uma janela de rótulo depois da noite de treino, para que todo rótulo de treino já tivesse
fechado na noite em que o modelo é testado, como teria acontecido em produção. Com os dados
terminando em 30 de junho, a noite de teste mais nova cujos desfechos fecharam é 29 de março, que
fecha em 27 de junho. A noite de treino mais nova que a regra permite antes dela é 28 de dezembro de
2025, cujos rótulos fecharam em 28 de março.

**Então nenhum rótulo com que um desafiante pode ser testado honestamente vem de depois de 1º de
abril**, e o rival abriu em 1º de abril. Um modelo treinado em noites mais novas pode ser construído
hoje; o que não pode ser construído hoje é a evidência de que ele é melhor, porque essa evidência são
desfechos, e eles ainda estão sendo escritos.

Esse é o formato honesto do retreino com rótulos atrasados: **uma janela de rótulo atrás para
treinar, duas para provar.** É também por isso que as checagens anteriores importam. O relatório de
deriva, o boletim dividido e o canário são o que uma equipe tem enquanto o próximo lote de rótulos
amadurece.

A política da Ponto Final, escrita para que ninguém precise decidir isso toda vez:

- **retreinar todo mês**, testando na noite mais nova cujos desfechos fecharam, e treinando na noite
  mais nova que a regra dos 90 dias permite antes dela;
- **retreinar antes** quando o boletim dividido mostrar a diferença de um grupo acima de 0,15 por
  duas noites seguidas;
- **promover só se o desafiante vencer o campeão na mesma noite de teste**, em precisão média e em
  calibração, e passar por um canário;
- **nunca promover um modelo que não foi o testado**: retreinar "mais uma vez com os dados mais novos"
  depois do teste produz um modelo que ninguém mediu.
