---
title: Escolhendo entre eles
version: 1
---

Os três respondem à mesma pergunta com compromissos diferentes:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"Três linhas. Uma sessão: a requisição leva o cookie sessionid, e o servidor o confere contra uma linha em django_session; o logout apaga a linha. Um token do DRF: a requisição leva Authorization Token, conferido contra uma linha em authtoken_token; o drf_create_token -r o troca. Um JWT: a requisição leva Authorization Bearer, e o servidor não confere nada guardado, só a assinatura com a SECRET_KEY; ele termina no exp e não antes.\"> <defs><marker id=\"tr-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"130\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a requisição leva</text> <text x=\"430\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o servidor confere contra</text> <text x=\"20\" y=\"58\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">sessão</text> <rect x=\"110\" y=\"34\" width=\"190\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"205\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Cookie: sessionid=…</text> <rect x=\"330\" y=\"34\" width=\"370\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"515\" y=\"50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma linha em django_session</text> <text x=\"515\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o logout apaga a linha</text> <path d=\"M300 52 L326 52\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#tr-a)\"></path> <text x=\"20\" y=\"120\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">token do DRF</text> <rect x=\"110\" y=\"96\" width=\"190\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"205\" y=\"118\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Authorization: Token …</text> <rect x=\"330\" y=\"96\" width=\"370\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"515\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma linha em authtoken_token</text> <text x=\"515\" y=\"126\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o drf_create_token -r o troca</text> <path d=\"M300 114 L326 114\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#tr-a)\"></path> <text x=\"20\" y=\"182\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">JWT</text> <rect x=\"110\" y=\"158\" width=\"190\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"205\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Authorization: Bearer …</text> <rect x=\"330\" y=\"158\" width=\"370\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"515\" y=\"174\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nada: a assinatura, conferida com a SECRET_KEY</text> <text x=\"515\" y=\"188\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ele termina no exp, não antes</text> <path d=\"M300 176 L326 176\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#tr-a)\"></path> </svg>", "caption": "Onde cada tipo de credencial é conferido. Os dois primeiros podem ser tomados de volta na hora porque o servidor guarda uma linha; o terceiro não guarda nada para apagar.", "same": ["JWT"]}
```

| | sessão | token do DRF | JWT |
|---|---|---|---|
| mandado como | um cookie, pelo próprio navegador | um cabeçalho que o cliente acrescenta | um cabeçalho que o cliente acrescenta |
| conferido contra | uma linha | uma linha | uma assinatura |
| tomado de volta | na hora: apague a linha | na hora: troque a chave | **não antes do `exp`** |
| CSRF | **necessário**, porque cookies são automáticos | não é necessário | não é necessário, num cabeçalho |
| uma cópia roubada | o `HttpOnly` a mantém longe de scripts | vale uma senha | vale uma senha até o `exp` |
| serve para | um site e suas próprias páginas | scripts e apps contra um servidor | vários serviços confiando num emissor |

Daí saem três regras práticas.

**Um navegador falando com o próprio site: sessões.** Elas vêm prontas, podem ser revogadas, e cookies
`HttpOnly` ficam fora do alcance de qualquer script que entre numa página. O token de CSRF é o preço, e
o Django o paga por você.

**Programas falando com um servidor: um token de uma tabela.** O do DRF, ou um cujo hash você mesmo
guarda. Revogar um é uma escrita; a busca por requisição é uma consulta com índice.

**Vários serviços que não deveriam todos dividir um banco: um JWT**, de vida curta. O serviço que emite
tokens guarda a chave; os outros conferem assinaturas. Se toda requisição vai buscar o usuário de
qualquer jeito, como o `current_user` faz aqui, o JWT comprou pouco em relação a um token numa tabela.

**Onde um navegador guarda um JWT é um problema à parte.** O `localStorage` é legível por qualquer
script que rode na página, então um script injetado leva o token junto; um cookie marcado `HttpOnly` o
protege de scripts e traz o CSRF de volta. A maioria das aplicações de página única num domínio é mais
bem servida por um cookie de sessão, e o JWT é uma escolha para o espaço entre servidores.
