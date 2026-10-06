---
title: Deixar uma moeda decidir
version: 1
---

Toda armadilha desta aula vem da mesma fonte: os grupos comparados diferem em mais do que a coisa de interesse. Um **experimento aleatorizado** elimina isso pela raiz.

## Como a aleatorização funciona

Suponha que a Horta queira saber se os cupons de fato não fazem diferença nos tempos de entrega. Em vez de deixar a equipe de marketing escolher quem recebe um, ela deixa um **sorteio** decidir, cliente por cliente.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 250\" role=\"img\" data-fig=\"l18-randomise\" aria-label=\"As mesmas três caixas de antes, mais uma moeda. A moeda tem uma seta para cupom. A seta de distância para cupom está riscada. A distância ainda tem uma seta para minutos. Uma seta que sobre de cupom para minutos seria agora o efeito do próprio cupom.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"st-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"230.0\" y=\"23.0\" width=\"140.0\" height=\"34.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">distância</text><rect x=\"45.0\" y=\"173.0\" width=\"130.0\" height=\"34.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">cupom</text><rect x=\"425.0\" y=\"173.0\" width=\"130.0\" height=\"34.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">minutos</text><rect x=\"20.0\" y=\"23.0\" width=\"120.0\" height=\"34.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">sorteio</text><path d=\"M90.0 57.0 L105.0 171.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-amber)\"></path><path d=\"M260.0 57.0 L140.0 171.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M188.0 104.0 L212.0 124.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M212.0 104.0 L188.0 124.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M340.0 57.0 L460.0 171.0\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-paper)\"></path><path d=\"M178.0 190.0 L422.0 190.0\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\" marker-end=\"url(#st-ah-paper)\"></path><text x=\"300.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o efeito dele, se houver</text></svg>", "caption": "Quando uma moeda decide quem recebe cupom, a distância não pode mais decidir. Clientes longe e perto recebem cupons com a mesma frequência, então qualquer diferença que sobre nos minutos é do cupom."}
```

Agora a distância não pode influenciar quem recebe cupom. Clientes perto e longe têm a mesma chance de receber, e o mesmo vale para pedidos grandes e pequenos, dias de chuva e de sol, e qualquer outro fator, **inclusive os que ninguém imaginou**. Em média, os dois grupos são parecidos em tudo menos no cupom. Qualquer diferença nos tempos de entrega maior que o acaso pode então ser creditada ao cupom.

Essa última frase é o que torna a aleatorização especial. Ajustar por confundidores, como no exemplo dos cupons, só funciona para os confundidores que foram medidos. A aleatorização equilibra também os não medidos.

## A Horta já fez alguns

O teste da página de pagamento da aula 16 foi aleatorizado: cada visitante viu a página antiga ou a nova por sorteio. É por isso que o resultado, 13,1% contra 11,0%, pode ser lido como a página nova **causando** mais compras, e não só andando junto com elas. O teste da roteirização da aula 13 não foi aleatorizado do mesmo jeito: toda entrega do teste usou o sistema novo. Ele dependeu da comparação com a média anterior de 40 minutos, então uma mudança no trânsito no mesmo período teria se confundido com ele.

## Boas práticas

- **Sorteie a atribuição, não só a amostra.** Uma amostra aleatória de clientes estudada sem atribuição aleatória continua observacional.
- **Mantenha um grupo de controle** que recebe a versão antiga ao mesmo tempo, para que qualquer outra coisa que mude durante o teste afete os dois grupos igualmente.
- **Decida o resultado e a análise antes**, a defesa da aula 14 contra o p-hacking.
- **Cegue quando der.** Na medicina, nem o paciente nem o médico sabem quem recebeu o tratamento de verdade, para que as expectativas não afetem o resultado.

## Quando um experimento é impossível

Algumas causas não podem ser atribuídas. Ninguém pode sortear pessoas para fumar, crescer pobres ou morar em Barão Geraldo. Alguns experimentos seriam antiéticos, e outros lentos ou caros demais. Para essas perguntas, as ferramentas da próxima seção são o que resta.
