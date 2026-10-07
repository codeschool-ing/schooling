---
title: Borda e origem
version: 1
---

Um servidor em São Paulo responde a um visitante em São Paulo em poucos milissegundos e a um visitante
em Lisboa em bem mais de cem, porque a luz na fibra leva esse tempo para cruzar um oceano e voltar, e
uma página precisa de várias idas e voltas antes de qualquer coisa aparecer. **Nenhuma configuração do
servidor muda essa distância.** O que muda é responder de algum lugar mais perto.

Uma **rede de distribuição de conteúdo**, uma CDN, é uma empresa que roda caches em centenas de lugares,
chamados **pontos de presença** ou **bordas** (*edges*), e os põe entre os seus visitantes e o seu
servidor, que no vocabulário dela vira a **origem**. Um visitante em Lisboa é mandado para a borda de
Lisboa. Se essa borda tem uma cópia fresca, a resposta nunca cruza o oceano; se não tem, a borda a busca
na origem uma vez e a guarda para todos os outros em Lisboa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 240\" role=\"img\" aria-label=\"Visitantes em Lisboa e em Recife chegam cada um a uma borda próxima por uma linha curta. Só num erro de cache a borda busca na origem em São Paulo, por uma linha longa; os acertos nunca percorrem essa distância.\"><defs><marker id=\"fed-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"130\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">visitantes, Lisboa</text><rect x=\"20\" y=\"160\" width=\"130\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">visitantes, Recife</text><rect x=\"220\" y=\"30\" width=\"150\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"295.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">borda, Lisboa</text><rect x=\"220\" y=\"160\" width=\"150\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"295.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">borda, Recife</text><rect x=\"530\" y=\"95\" width=\"150\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"605.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">origem</text><text x=\"605.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">São Paulo</text><line x1=\"150\" y1=\"52\" x2=\"218\" y2=\"52\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fed-ah)\" marker-start=\"url(#fed-ah)\"></line><line x1=\"150\" y1=\"182\" x2=\"218\" y2=\"182\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fed-ah)\" marker-start=\"url(#fed-ah)\"></line><text x=\"184\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">poucos ms</text><text x=\"184\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">poucos ms</text><path d=\"M 370 52 C 450 52, 470 110, 528 115\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#fed-ah)\"></path><path d=\"M 370 182 C 450 182, 470 130, 528 128\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#fed-ah)\"></path><text x=\"455\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">só num erro, ~100+ ms</text><text x=\"455\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">só num erro</text></svg>", "caption": "Cada visitante chega à borda mais próxima. A viagem longa até a origem é paga uma vez por cópia, não uma vez por visitante.", "same": ["São Paulo"]}
```

Dois mecanismos mandam cada visitante para uma borda próxima, e os dois são invisíveis para ele. Com
**DNS**, os servidores de nomes da CDN respondem ao nome do site com o endereço de uma borda perto de quem
perguntou. Com **anycast**, muitas bordas anunciam o mesmo endereço, e o roteamento da internet entrega
cada pacote à mais próxima. De um jeito ou de outro, o nome do site aponta para a CDN, em geral com um
registro `CNAME`, e só a CDN sabe onde está a origem.

Tudo o que a aula 5 disse sobre caches compartilhados vale para uma borda, porque uma borda é um: ela
obedece ao `Cache-Control`, o `s-maxage` é endereçado a ela, o `private` a mantém de fora, e a chave dela
decide quem recebe qual cópia. O que é novo é que **não é você quem a opera**. A configuração dela é uma
página web ou uma API, os logs chegam atrasados, e limpar uma cópia é uma requisição às máquinas de outra
empresa em cem cidades. Esta aula monta uma borda pequena no seu servidor, para que cada uma dessas
coisas possa ser vista funcionando, e a última seção as liga às comerciais.
