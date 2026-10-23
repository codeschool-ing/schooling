---
title: O que uma caixa afirma, e o que uma linha afirma
version: 1
---

**Cada marca num diagrama de arquitetura é uma afirmação sobre o sistema.** Uma caixa afirma que
algo existe e tem um limite. Uma linha afirma que duas dessas coisas se relacionam de algum jeito.
Uma palavra em qualquer uma delas diz que tipo de coisa, ou que tipo de relação. Ler bem um diagrama
é ler cada marca como a afirmação que ela faz, e perceber quando uma marca não afirma nada que o
leitor possa usar.

## A caixa

Uma caixa só com nome diz que existe algo com esse nome. Isso quase nunca basta, porque a mesma
palavra nomeia coisas muito diferentes. Na Carcará, "Booking" é o nome de um time, de um serviço, de
um schema de banco, de uma tabela e de uma tela do app. Uma caixa escrita `Booking` pode ser
qualquer um deles.

Três acréscimos transformam um nome numa afirmação que alguém consegue conferir:

- **um tipo**: é um serviço, um banco de dados, uma fila, uma pessoa, um sistema externo inteiro?
- **uma tecnologia**, quando o leitor é técnico: *serviço Kotlin na JVM*, *PostgreSQL 16*.
- **uma responsabilidade**, em poucas palavras: *guarda reservas e assentos bloqueados*.

O C4, na aula 3, faz desses três uma regra para todo elemento. Você não precisa do C4 para seguir a
regra.

## A linha

A linha é onde a maioria dos diagramas erra, e a seta é a pior parte, porque **uma seta sem rótulo
pode significar pelo menos cinco coisas diferentes**, e as cinco aparecem em diagramas reais, muitas
vezes no mesmo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l01-arrow-meanings\" aria-label=\"Uma seta sem rótulo do app do passageiro para a API de passagens, e cinco coisas que se costuma entender por ela: o app chama a API; dados vão do app para a API; o app depende da API, então uma mudança na API pode quebrá-lo; o app é parte da API, ou pertence a ela; o app vem antes da API numa sequência de passos. As duas primeiras descrevem a mesma conversa e podem apontar em sentidos opostos.\"><defs><marker id=\"l01-arrow-meanings-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"35.0\" y=\"26.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">App do passageiro</text><rect x=\"335.0\" y=\"26.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">API de passagens</text><path d=\"M186.0 46.0 L334.0 46.0\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l01-arrow-meanings-am-fill-paper)\"></path><text x=\"260.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--amber)\">?</text><circle cx=\"48.0\" cy=\"112.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"48.0\" y=\"112.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">1</text><text x=\"72.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">chama</text><text x=\"210.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o app manda pedidos e espera respostas</text><circle cx=\"48.0\" cy=\"148.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"48.0\" y=\"148.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">2</text><text x=\"72.0\" y=\"148.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">manda dados para</text><text x=\"210.0\" y=\"148.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o pedido vai por aqui; a resposta volta pelo outro lado</text><circle cx=\"48.0\" cy=\"184.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"48.0\" y=\"184.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">3</text><text x=\"72.0\" y=\"184.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">depende de</text><text x=\"210.0\" y=\"184.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mude a API e o app pode quebrar</text><circle cx=\"48.0\" cy=\"220.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"48.0\" y=\"220.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">4</text><text x=\"72.0\" y=\"220.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">é parte de</text><text x=\"210.0\" y=\"220.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pertence, é implantado junto, ou está dentro</text><circle cx=\"48.0\" cy=\"256.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"48.0\" y=\"256.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">5</text><text x=\"72.0\" y=\"256.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">vem antes de</text><text x=\"210.0\" y=\"256.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um passo de um processo, nem é uma chamada</text><text x=\"612.0\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">sentidos</text><text x=\"612.0\" y=\"138.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">opostos</text><path d=\"M590 104 L600 104 L600 152 L590 152\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path></svg>", "caption": "Uma seta sem rótulo deixa quem lê escolher entre cinco significados, e leitores diferentes escolhem diferente sem saber."}
```

As duas leituras que mais se confundem são a primeira e a segunda. "O app chama a API" e "os dados
vão da API para o app" apontam em **sentidos opostos** para a mesma conversa: o pedido vai para um
lado, a resposta volta para o outro. Um diagrama que usa setas para chamadas num canto e para dados
em outro é um diagrama em que metade das setas está ao contrário para qualquer leitor.

Então **toda linha leva um rótulo, e o rótulo é um verbo no sentido da seta**: *manda pedidos de
reserva para*, *lê horários de*, *publica eventos de passagem vendida em*. Quando importa, acrescente
o protocolo: *HTTPS/JSON*, *SQL*, *AMQP*. Um rótulo como *usa* é melhor do que nada e não muito
melhor, porque é o único verbo que serve em qualquer seta.

## Posição, tamanho e cor

Mais três coisas num diagrama parecem afirmações e em geral não são:

- **Posição.** Quem lê supõe que o que está à esquerda vem primeiro e que o que está no alto é mais
  importante. Se nenhuma das duas coisas é verdade, o leitor lê assim mesmo; então arrume o desenho
  para que seja verdade, ou deixe a disposição claramente neutra.
- **Tamanho.** Uma caixa maior parece mais importante ou mais complexa. Se a API de passagens está
  desenhada três vezes maior que a integração de pagamento, o leitor vai acreditar que ela faz três
  vezes mais trabalho.
- **Cor e estilo de linha.** Cor é um sinal forte, e o leitor tenta decifrá-la. **Se a cor quer dizer
  algo, uma legenda diz o quê**; se não quer dizer nada, use uma cor só. Uma linha tracejada é lida
  como "diferente" — opcional, assíncrona, planejada —, então também precisa de legenda.

## Fronteiras

Uma caixa desenhada em volta de outras caixas faz mais um tipo de afirmação: estas coisas andam
juntas, e algo do lado de dentro é diferente do lado de fora. Uma fronteira pode querer dizer
*implantados juntos*, *do mesmo time*, *dentro da nossa rede* ou *um contexto delimitado*, e essas
quatro fronteiras raramente coincidem. **Dê nome à fronteira, e desenhe um tipo só por diagrama**, a
menos que a legenda separe os tipos.
