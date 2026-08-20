---
title: DNS: a tradução de nome para endereço
---

O **DNS** é o serviço que responde "qual o IP de `codeschool.ing`?". Ele é hierárquico: a pergunta sobe até quem sabe, e a resposta desce sendo guardada em cache no caminho.

Os tipos de registro que se usa toda semana:

- `A` — aponta o nome para um IPv4. `AAAA` faz o mesmo para IPv6.
- `CNAME` — diz "este nome é apelido daquele". Não pode existir na raiz do domínio.
- `MX` — para onde vai o e-mail deste domínio.
- `TXT` — texto livre; é onde vivem as provas de posse e as regras antifraude de e-mail (SPF, DKIM).

A restrição do `CNAME` na raiz é a que mais aparece na prática: para apontar `codeschool.ing` (sem `www`) a um serviço hospedado, ou se usa `A` com IPs fixos, ou o provedor oferece um `ALIAS`/`ANAME`, que é uma extensão fora do padrão.

```schooling-figure
{
  "svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"A pergunta sobe do navegador ao resolvedor, e do resolvedor aos servidores raiz, de TLD e autoritativo; a resposta desce sendo guardada em cache\"><g fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.2\" opacity=\".55\"><rect x=\"8\" y=\"60\" width=\"118\" height=\"46\" rx=\"4\"/><rect x=\"176\" y=\"60\" width=\"128\" height=\"46\" rx=\"4\"/><rect x=\"354\" y=\"16\" width=\"120\" height=\"38\" rx=\"4\"/><rect x=\"354\" y=\"72\" width=\"120\" height=\"38\" rx=\"4\"/><rect x=\"354\" y=\"128\" width=\"120\" height=\"38\" rx=\"4\"/></g><g fill=\"currentColor\" font-family=\"IBM Plex Mono, monospace\" font-size=\"11\"><text x=\"67\" y=\"80\" text-anchor=\"middle\">navegador</text><text x=\"67\" y=\"95\" text-anchor=\"middle\" opacity=\".6\">tem cache</text><text x=\"240\" y=\"80\" text-anchor=\"middle\">resolvedor</text><text x=\"240\" y=\"95\" text-anchor=\"middle\" opacity=\".6\">do provedor</text><text x=\"414\" y=\"40\" text-anchor=\"middle\">raiz  .</text><text x=\"414\" y=\"96\" text-anchor=\"middle\">TLD  .ing</text><text x=\"414\" y=\"152\" text-anchor=\"middle\">autoritativo</text></g><g fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.4\" opacity=\".8\"><path d=\"M126 78h42\" marker-end=\"url(#pt)\"/><path d=\"M304 76l44-38\" marker-end=\"url(#pt)\"/><path d=\"M304 83h42\" marker-end=\"url(#pt)\"/><path d=\"M304 90l44 38\" marker-end=\"url(#pt)\"/></g><defs><marker id=\"pt\" viewBox=\"0 0 8 8\" refX=\"7\" refY=\"4\" markerWidth=\"6\" markerHeight=\"6\" orient=\"auto\"><path d=\"M0 0l8 4-8 4z\" fill=\"currentColor\"/></marker></defs><g font-family=\"IBM Plex Mono, monospace\" font-size=\"10\" opacity=\".55\" fill=\"currentColor\"><text x=\"500\" y=\"96\">cada resposta desce</text><text x=\"500\" y=\"112\">guardada por TTL segundos</text></g></svg>",
  "caption": "A pergunta sobe até quem sabe; a resposta desce sendo guardada em cache no caminho. É o cache do caminho que faz a propagação demorar."
}
```
