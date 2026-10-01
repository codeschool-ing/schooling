---
title: Stripping, e o cabeçalho que o impede
version: 1
---

As pessoas digitam `www.example.com`, não `https://www.example.com`, então a primeira requisição do
navegador sai por **HTTP puro**. Antes de esta aula mudar qualquer coisa, a loja respondia a ela em
claro:

```
ana@laptop:~$ curl -sI http://www.example.com/ | head -3
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
Date: Mon, 28 Sep 2026 20:51:47 GMT
```

Agora o proxy é alterado em dois pontos: o servidor HTTP puro não faz nada além de redirecionar, e o
servidor HTTPS acrescenta um cabeçalho a toda resposta:

```
root@www:~# grep -nE "return 301|Strict-Transport" /etc/nginx/sites-enabled/shop
4:    return 301 https://$host$request_uri;
12:    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
ana@laptop:~$ curl -sI http://www.example.com/orders | grep -iE "^HTTP|^location"
HTTP/1.1 301 Moved Permanently
Location: https://www.example.com/orders
ana@laptop:~$ curl -sI https://www.example.com/ | grep -iE "^HTTP|^strict"
HTTP/1.1 200 OK
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

O redirecionamento manda o navegador para o HTTPS, e a resposta HTTPS traz
**`Strict-Transport-Security`**: pelos próximos 31.536.000 segundos, um ano, este navegador tem de
usar HTTPS para este site e para todo subdomínio, sem perguntar.

**O redirecionamento sozinho não basta, e é isso que o stripping explora.** A primeira requisição e o
redirecionamento viajam em claro. Alguém no caminho responde ele mesmo a essa primeira requisição,
busca a página real por HTTPS em nome do usuário e a devolve por HTTP com todos os links reescritos
para HTTP. O usuário nunca chega ao HTTPS, e o redirecionamento que o levaria até lá nunca chega.

O HSTS fecha a brecha **a partir da segunda visita**: um navegador que já viu o cabeçalho recusa HTTP
puro para o site antes de enviar qualquer coisa, então não há requisição em claro para responder. Para
a primeiríssima visita, os sites inscrevem seu domínio na **lista de preload do HSTS** (HSTS preload
list) embutida nos navegadores, e a partir daí nem a primeira requisição sai em claro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Duas visitas a www.example.com. Sem HSTS, o primeiro pedido do navegador sai por HTTP puro, o servidor responde com um redirecionamento em claro, e só então o navegador passa para HTTPS; alguém no caminho pode responder a esse primeiro pedido no lugar do servidor. Com o HSTS lembrado de uma visita anterior, ou da lista de pré-carga, o navegador vai direto ao HTTPS e nenhum pedido em claro chega a sair.\"><defs><marker id=\"hs2-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"hs2-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">sem HSTS</text><rect x=\"20\" y=\"30\" width=\"130\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"45.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">navegador</text><rect x=\"560\" y=\"30\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"45.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www.example.com</text><path d=\"M150 42 L560 42\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#hs2-ah-amber)\" stroke-dasharray=\"4 3\"></path><text x=\"355\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">GET http://www.example.com/</text><path d=\"M560 56 L150 56\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#hs2-ah-amber)\" stroke-dasharray=\"4 3\"></path><text x=\"355\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">301 para https://, em claro: o passo que alguém no caminho pode responder</text><path d=\"M150 92 L560 92\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#hs2-ah-phosphor)\"></path><text x=\"355\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">GET https://www.example.com/</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">com HSTS, ou pré-carregado</text><rect x=\"20\" y=\"152\" width=\"130\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"167.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">navegador</text><rect x=\"560\" y=\"152\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"167.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www.example.com</text><path d=\"M150 167 L560 167\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#hs2-ah-phosphor)\"></path><text x=\"355\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">GET https://www.example.com/</text><text x=\"355\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nenhum pedido em claro sai: nada em claro para responder</text></svg>", "caption": "O redirecionamento viaja em claro. O HSTS elimina o pedido a que ele responde."}
```

Dois cuidados. `includeSubDomains` compromete também todo subdomínio com o HTTPS, então um site
interno antigo em HTTP puro sob o mesmo domínio para de funcionar nos navegadores que viram o
cabeçalho. E um ano é uma promessa longa: implante primeiro com um `max-age` curto, e aumente-o
quando nada tiver quebrado.
