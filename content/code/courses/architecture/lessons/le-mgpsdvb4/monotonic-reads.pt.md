---
title: Leituras monotônicas: o tempo que não anda para trás
version: 1
---

Duas cópias raramente estão no mesmo ponto do fluxo, e um balanceador de carga não se importa com qual
delas recebe a requisição. Um cliente olha o café meio segundo depois de ele mudar para 7, e recarrega a página meio segundo
depois disso:

```
ana@vm:~/lab/eventual$ curl -s -X PUT localhost:8001/stock/coffee -d 7
coffee: 7 in stock, version 14
ana@vm:~/lab/eventual$ sleep 0.5; curl -s localhost:8002/product/coffee; sleep 0.5; curl -s localhost:8003/product/coffee
shop-a: coffee: 7 left, version 14
shop-b: coffee: 0 left, version 13
```

A primeira resposta veio da loja `a`, que já tinha a versão 14, e a segunda da loja `b`, ainda na versão
13. Cada resposta era verdade em algum momento. Juntas nessa ordem, **o café foi de 7 de volta para 0**,
o que nunca aconteceu. O cliente pode ter posto um pacote na cesta na primeira página e ouvido na
segunda que não há nenhum.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Um cliente recarrega a página de um produto duas vezes. Um balanceador manda a primeira requisição para a loja a, cuja cópia está na versão 14 e responde restam 7. Manda a segunda para a loja b, cuja cópia está na versão 13 e responde restam 0. Para o cliente o estoque foi de 7 de volta para 0, o que nunca aconteceu nessa ordem.\"><defs><marker id=\"l9-monotonic-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l9-monotonic-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l9-monotonic-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"105\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cliente</text><rect x=\"220\" y=\"105\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">balanceador</text><rect x=\"430\" y=\"40\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"510\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">loja a</text><text x=\"510\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">versão 14: 7</text><rect x=\"430\" y=\"154\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"510\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">loja b</text><text x=\"510\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">versão 13: 0</text><path d=\"M152 125 L218 125\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-monotonic-ah-wire)\"></path><path d=\"M342 115 L428 76\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-monotonic-ah-phosphor)\"></path><path d=\"M342 135 L428 176\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-monotonic-ah-amber)\"></path><text x=\"370\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">1ª</text><text x=\"370\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">2ª</text><text x=\"650\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">restam 7</text><text x=\"650\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">restam 0</text><text x=\"90\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">vê 7, depois 0</text></svg>", "caption": "Duas cópias em pontos diferentes do fluxo. Cada resposta é um valor que já foi verdade, e juntas, nessa ordem, contam uma história que nunca aconteceu."}
```

A garantia que impede isso são as **leituras monotônicas** (*monotonic reads*): depois que uma pessoa
viu uma versão, ela nunca vê uma mais velha. De novo é uma promessa a uma pessoa, e de novo é barata. Há
dois jeitos de mantê-la:

- **Prender a pessoa a uma cópia.** Se toda requisição de uma sessão chega à mesma cópia, as versões
  que ela vê só podem ir para a frente. Os balanceadores chamam isso de afinidade de sessão, ou
  *sticky sessions*. Quebra quando essa cópia é reiniciada ou removida, e distribui a carga de forma
  desigual.
- **Lembrar a maior versão vista**, e mandá-la em toda leitura, exatamente como na seção anterior. Uma
  cópia atrás dela pergunta ao dono, ou espera até se atualizar:

```
ana@vm:~/lab/eventual$ curl -s 'localhost:8003/product/coffee?after=14'
shop-b: coffee: 7 in stock, version 14 (copy behind, asked the stock service)
```

Um mecanismo, uma versão que viaja com a pessoa, dá as duas garantias de sessão: ler as próprias
escritas quando a versão veio de uma escrita dela, e leituras monotônicas quando veio da última leitura.
**Um número de versão nos dados é barato de pôr no primeiro dia e muito difícil de pôr depois**, quando
todo evento e toda cópia já foram projetados sem ele. A próxima seção mostra que a cópia também precisa
dele, por um motivo que não tem nada a ver com o leitor.
