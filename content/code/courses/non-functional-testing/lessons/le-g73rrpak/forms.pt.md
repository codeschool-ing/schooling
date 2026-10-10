---
title: Formulários que provam de onde vieram
version: 1
---

Um navegador manda os cookies de um site em toda requisição a esse site, inclusive nas que outro site
iniciou. Isso é o cross-site request forgery, CSRF: uma página em outro lugar envia um formulário ao
`account.py`, o navegador anexa o cookie de sessão do cliente, e **sem mais uma conferência o serviço
não distingue um cancelamento que o cliente escolheu de um que outra página fez em nome dele.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l20-csrf\" aria-label=\"Três atores da esquerda para a direita: outro site, o navegador do cliente e o account.py. Em cima, a própria página do cliente leva o token CSRF no formulário, e o cancelamento com o token é aceito com 303. Embaixo, outro site faz o navegador enviar o mesmo formulário; o navegador pode anexar o cookie de sessão, mas o outro site não consegue ler o token, então a requisição chega sem ele e é recusada com 403.\"><defs><marker id=\"l20-csrf-nf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l20-csrf-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l20-csrf-nf-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"90.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">outro site</text><path d=\"M90.0 54.0 L90.0 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"290.0\" y=\"20.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"360.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o navegador</text><path d=\"M360.0 54.0 L360.0 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"560.0\" y=\"20.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"630.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">account.py</text><path d=\"M630.0 54.0 L630.0 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M630.0 90.0 L360.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-csrf-nf-ah-paper-dim)\"></path><text x=\"495.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">página com o token no formulário</text><path d=\"M360.0 125.0 L630.0 125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l20-csrf-nf-ah-phosphor)\"></path><text x=\"495.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">cookie + token</text><text x=\"495.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">303</text><path d=\"M90.0 175.0 L360.0 175.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"6 4\" marker-end=\"url(#l20-csrf-nf-ah-amber)\"></path><text x=\"225.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">um formulário vindo de fora</text><path d=\"M360.0 205.0 L630.0 205.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"6 4\" marker-end=\"url(#l20-csrf-nf-ah-amber)\"></path><text x=\"495.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">cookie, sem token</text><text x=\"495.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">403 stale form</text></svg>", "caption": "O cookie vai com qualquer formulário que o navegador manda. O token vai só com os formulários que o serviço desenhou.", "same": ["cookie + token"]}
```

O `account.py` tem duas camadas, e a aula 17 mostrou a primeira: `SameSite=Lax` no cookie, que diz ao
navegador para deixá-lo de fora de um formulário enviado por outro site. A segunda é um **token
CSRF**: um valor aleatório criado com a sessão, escrito em todo formulário que o serviço desenha e
conferido em toda requisição que muda estado. Outro site consegue fazer o navegador mandar um
formulário; não consegue ler a página que guarda o token, então não consegue preencher o campo.

O teste é o formulário mandado sem o seu token, depois o mesmo formulário com ele:

```
ana@nft:~/boxoffice$ curl -s -b ~/ana.jar -w '%{http_code}\n' -X POST localhost:8001/account/cancel -d 'booking=1'
{"error": "stale form"}
403
ana@nft:~/boxoffice$ curl -s -b ~/ana.jar localhost:8001/account | grep -o 'name="csrf" value="[^"]*"' | head -1 | cut -d'"' -f4 > ~/ana.csrf
ana@nft:~/boxoffice$ curl -s -b ~/ana.jar -o /dev/null -w '%{http_code}\n' -X POST localhost:8001/account/cancel -d "booking=1&csrf=$(cat ~/ana.csrf)"
303
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' localhost:8001/bookings/1 -H "Authorization: Bearer $(cat ~/ana.token)"
{"error": "no such booking"}
404
```

Sem o token, `403` e `stale form`; com ele, `303` de volta para a página, e a reserva 1 sumiu. As duas
respostas importam: **uma defesa que recusasse todo formulário passaria na primeira conferência**, e a
segunda prova que a recusa é a conferência do token e não uma rota quebrada.

Dois detalhes sobre os quais um testador pergunta, e o `account.py` responde. A comparação usa
`hmac.compare_digest`, então o tempo que ela leva não depende de quantos caracteres bateram. E o
token pertence à sessão: o teste em "Os testes dos vetores" manda o token de um cliente com o cookie de
outro e espera uma recusa, porque um token que qualquer sessão aceita é um token que qualquer um
poderia buscar para si.

As rotas JSON pegam a sessão de um cabeçalho `Authorization` em vez do cookie, e um navegador nunca
acrescenta esse cabeçalho sozinho. É por isso que elas não precisam de token CSRF, e é por isso que
passá-las para sessões por cookie as faria precisar de um.
