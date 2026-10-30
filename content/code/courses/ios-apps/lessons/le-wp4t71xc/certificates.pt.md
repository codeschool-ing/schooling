---
title: Certificados, e a cadeia que termina na Apple
version: 1
---

**Um certificado de assinatura é uma chave pública com um nome junto, assinada por alguém cuja
assinatura o aparelho já aceita.** Você guarda a chave privada; a Apple assina a metade pública e o
nome; quem tiver o certificado consegue então conferir que uma assinatura foi feita pela chave
privada correspondente, e que a Apple avalizou de quem é a chave. Nada nesta seção foi executado: os
tipos de certificado vêm do *Certificates overview* da Apple, lido em 30 de outubro de 2026. A seção
05 roda o mesmo mecanismo com uma autoridade certificadora feita para isso, que é a parte que roda em
qualquer lugar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l21-chain\" aria-label=\"A cadeia de confiança atrás de um certificado de assinatura, desenhada de cima para baixo. No topo, o certificado raiz da Apple, embutido em todo aparelho Apple. Ele assina o certificado intermediário Worldwide Developer Relations. Esse assina o seu certificado Apple Development, que guarda a sua chave pública e o seu nome. A sua chave privada fica no seu Mac, fora da cadeia, e assina o app. Um aparelho confere a assinatura do app contra o seu certificado e sobe a cadeia até a raiz em que já confia. Um Mac sem o intermediário não completa a subida.\"><defs><marker id=\"l21-chain-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l21-chain-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l21-chain-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l21-chain-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"300\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Apple Root CA</text><text x=\"190\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">embutido em todo aparelho</text><rect x=\"40\" y=\"110\" width=\"300\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Apple WWDR intermediate</text><text x=\"190\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o elo que as pessoas esquecem</text><rect x=\"40\" y=\"200\" width=\"300\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Apple Development: you</text><text x=\"190\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a sua chave pública e o seu nome</text><path d=\"M190 80 L190 108\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-chain-ah-phosphor)\"></path><text x=\"240\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">assina</text><path d=\"M190 170 L190 198\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-chain-ah-amber)\"></path><text x=\"240\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">assina</text><rect x=\"430\" y=\"200\" width=\"260\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"560\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">a sua chave privada</text><text x=\"560\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no seu Mac, nunca enviada</text><rect x=\"430\" y=\"60\" width=\"260\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Planner.app</text><text x=\"560\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">assinado, cada arquivo</text><path d=\"M560 198 L560 122\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-chain-ah-amber)\"></path><text x=\"608\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">assina o app</text><path d=\"M428 90 C 380 90, 370 225, 342 228\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l21-chain-ah-paper-dim)\"></path><text x=\"388\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">conferido contra</text></svg>", "caption": "Um aparelho confia na raiz e desce até o seu certificado; a sua chave privada assina e nunca faz parte da cadeia."}
```

**A cadeia tem três elos, e o do meio é o que as pessoas esquecem.** O certificado raiz da Apple vem
embutido em todo aparelho Apple. Ele assina o certificado intermediário **Worldwide Developer
Relations** da Apple, o WWDR, e o intermediário assina o seu. Um Mac que tem o seu certificado mas não
o intermediário WWDR atual não fecha a cadeia, e o Xcode mostra o certificado como não confiável; a
ajuda da conta da Apple mantém uma página com os intermediários justamente para esse caso. A seção 05
mostra como essa falha aparece no `openssl`.

## Os dois que você usa

O overview da Apple lista mais de vinte tipos. Um app iOS precisa de dois, e a página diz o que os
separa:

- **Apple Development**, para "run an iOS, iPadOS, macOS, tvOS, visionOS, watchOS app on devices".
  Certificados de desenvolvimento "belong to individuals", e a Apple acrescenta o nome do computador
  para distingui-los.
- **Apple Distribution**, para distribuir em aparelhos registrados ou "submit it to App Store
  Connect". Certificados de distribuição "belong to the team", um de cada tipo por time, e só o
  Account Holder ou um Admin pode criá-los.

**A chave privada é o único segredo do certificado, e ela nunca sai do seu Mac a não ser que você a
exporte.** Perdê-la significa fazer um certificado novo; compartilhá-la significa que outra pessoa
consegue assinar como você. O overview da Apple é direto: "Do not share Apple Certificates outside of
your organization." Um certificado de distribuição é do time, então um time o compartilha pelos
ajustes de conta do Xcode em vez de mandar um arquivo por aí, e o revoga na conta de desenvolvedor no
dia em que ele vazar.
