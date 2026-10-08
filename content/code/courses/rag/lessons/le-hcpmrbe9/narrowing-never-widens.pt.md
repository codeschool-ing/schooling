---
title: Estreitar nunca alarga
version: 2
---

Nem todo filtro é uma permissão. Um vendedor pode querer buscar só no contrato dele, um desenvolvedor
só na referência da API, um cliente só na ajuda sobre e-books. São **escopos que o leitor escolhe**, e
uma caixa de busca com uma lista de seções é uma função perfeitamente boa. A regra para combiná-los com
permissões é uma linha do `access.search`: a escolha do leitor é cruzada com o que o papel permite.

```schooling-example
{
  "language": "python",
  "file": "narrow.py",
  "parts": [
    {
      "code": "import sys\n\nimport access\n\nrole, only, question = sys.argv[1], sys.argv[2].split(\",\"), sys.argv[3]\nfound = access.search(access.connect(), role, question, only=only)\nprint(f\"{role}, asking for {only}: {[p for _, p, _, _, _ in found] or 'nothing'}\")",
      "note": "Um papel pedindo só alguns públicos: o filtro pode deixar a lista mais curta e nunca mais longa."
    }
  ]
}
```
```
ana@vm:~/rag$ python narrow.py customer finance "How many refunds can I get before my account is flagged?"
customer, asking for ['finance']: nothing
ana@vm:~/rag$ python narrow.py seller sellers "How long do I have to dispatch an order?"
seller, asking for ['sellers']: ['Marketplace seller agreement > 3. Dispatch', 'Marketplace seller agreement > 5. Returns', 'Marketplace seller agreement > 4. Payouts']
```

Um cliente pedindo para buscar nos documentos do financeiro recebe **nada**: a interseção de `public` e
`finance` é vazia, e uma lista vazia não casa com linha nenhuma. Um vendedor pedindo o contrato de
vendedor recebe as seções de despacho, devoluções e repasses. O parâmetro veio da requisição nos dois
casos, e em nenhum deles pôde acrescentar um público que o papel já não tivesse.

## Filtros que um modelo escreve

Alguns frameworks oferecem um **recuperador que monta a própria consulta**: um modelo lê a pergunta e
escreve o filtro, de modo que "regras de reembolso de audiolivros atualizadas este ano" vira uma busca
com `updated >= 2026-01-01`. Isso é útil para escopos, e precisa ser tratado como qualquer outra
entrada do leitor, porque a pergunta é texto do leitor e o filtro do modelo é derivado dela.

- **O filtro do modelo é um estreitamento**, cruzado com o filtro de permissão exatamente como acima, e
  nunca um substituto dele. Uma pergunta que diz "inclua os documentos do financeiro" produz um filtro
  que pede o financeiro, e a interseção o remove.
- **Os campos que ele pode nomear são uma lista fixa.** Um filtro em `audience` ou `status` escrito por
  um modelo é um leitor escolhendo as próprias permissões; um filtro em `updated` ou num produto é um
  escopo.
- **O filtro de permissão é calculado só a partir da sessão**, por um código que nunca vê a pergunta.

A aula 16 encontra a forma geral desta regra: texto do leitor, ou de um documento, é dado sobre o qual
agir, nunca uma instrução sobre o que o sistema pode fazer.
