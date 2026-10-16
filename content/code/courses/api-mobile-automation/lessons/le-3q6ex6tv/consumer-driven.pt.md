---
title: O que um schema não consegue dizer
version: 1
---

**Um schema é a promessa do provedor sobre tudo o que ele manda. Ele não diz nada sobre quem lê que
parte.** O `show.json` diz que um espetáculo tem cinco campos. Suponha que o time do boxoffice queira
renomear `price_cents` para `price`, ou tirá-lo do espetáculo e deixá-lo só nos pedidos. O schema
consegue dizer que a resposta nova quebra o schema antigo, o que é óbvio. Ele não consegue dizer se
alguém notaria, porque o schema não faz ideia de que programas leem `price_cents` e quais nunca olham
para ele.

A crença de costume é que um provedor bem testado mais um cliente bem testado somam um par que
funciona. Não somam. Cada lado testa contra a própria imagem do outro: o provedor contra o schema
dele, o cliente contra um substituto que responde do jeito que os autores do cliente esperam. As duas
suítes podem estar verdes enquanto as duas imagens discordam, e a discordância é achada em produção.

## Contratos escritos pelos consumidores

**O teste de contrato guiado pelo consumidor inverte a pergunta.** Cada consumidor escreve, como um
teste executável, exatamente o que precisa do provedor: que requisição manda, que campos lê da
resposta, de que valores ou tipos depende. O teste produz um arquivo, o *contrato* ou *pact*. O build
do provedor então repete o contrato de cada consumidor contra o provedor de verdade e falha se algum
deles não for cumprido.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 252\" role=\"img\" aria-label=\"Uma grade com os campos de um espetáculo contra três colunas. O schema, show.json, promete id, title, starts_at, price_cents e seats_left. O app Tickets lê title, starts_at e seats_left. O quiosque lê title e precisa de um campo chamado venue, que falta no espetáculo. Um campo que nenhum consumidor lê pode mudar; um campo de que um precisa é uma conversa.\"><text x=\"110\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">campo de um espetáculo</text><text x=\"275\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">show.json</text><text x=\"425\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">app Tickets</text><text x=\"575\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">quiosque</text><rect x=\"40\" y=\"50\" width=\"140\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">id</text><rect x=\"220\" y=\"50\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">prometido</text><rect x=\"40\" y=\"80\" width=\"140\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">title</text><rect x=\"220\" y=\"80\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">prometido</text><rect x=\"370\" y=\"80\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"425\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">lê</text><rect x=\"520\" y=\"80\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">lê</text><rect x=\"40\" y=\"110\" width=\"140\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">starts_at</text><rect x=\"220\" y=\"110\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">prometido</text><rect x=\"370\" y=\"110\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"425\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">lê</text><rect x=\"40\" y=\"140\" width=\"140\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">price_cents</text><rect x=\"220\" y=\"140\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">prometido</text><rect x=\"40\" y=\"170\" width=\"140\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">seats_left</text><rect x=\"220\" y=\"170\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">prometido</text><rect x=\"370\" y=\"170\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"425\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">lê</text><rect x=\"40\" y=\"200\" width=\"140\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">venue</text><rect x=\"520\" y=\"200\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"575\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">precisa: falta</text><text x=\"350\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um campo que nenhum consumidor lê pode mudar; um campo de que um precisa é uma conversa</text></svg>", "caption": "O schema cobre todo campo que o provedor manda; o contrato de cada consumidor cobre só o que aquele consumidor lê."}
```

O desenho é o motivo de a ideia existir. A coluna do schema cobre todo campo. O app Tickets lê três
deles. Um quiosque de ingressos que o teatro está planejando precisa de um campo que o boxoffice nunca
teve. Dessas colunas o time do provedor consegue ler duas coisas que nenhum schema mostra. **Ele pode
mudar `id` e `price_cents` à vontade**, no que depende destes consumidores: nenhum contrato os lê,
então renomeá-los não quebra ninguém que tenha escrito um. E estão pedindo algo a ele: o `venue` do
quiosque é um pedido, achado do lado do provedor antes de o quiosque ser lançado, como uma conferência
que falhou e não como um chamado de suporte.

## O que custa, e o que não substitui

Os contratos só cobrem os consumidores que os escrevem. Uma API pública com desconhecidos como
clientes não tem como perguntar a todos, e é por isso que contratos guiados pelo consumidor servem
melhor dentro de uma organização, onde os consumidores são times conhecidos. Os contratos também
precisam viajar dos consumidores até o build do provedor; times que usam Pact em geral mantêm um
*Pact Broker*, um servidor que guarda os contratos e os resultados das verificações, ou o PactFlow
hospedado. Este curso passa o arquivo à mão.

Nada disso substitui o schema nem o teste de ponta a ponta. O schema confere tudo o que o provedor
manda, o contrato confere aquilo de que cada consumidor depende, e os testes de integração da lição 12
conferem que as peças rodando funcionam juntas. Cada um responde uma pergunta que os outros não
respondem.
