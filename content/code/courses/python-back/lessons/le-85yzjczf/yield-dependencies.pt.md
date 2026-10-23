---
title: Dependências com yield: antes, e depois
version: 1
---

Algumas coisas de que uma rota precisa têm de ser devolvidas: uma trava, um arquivo, uma conexão de
banco. Uma dependência que faz **yield** em vez de return ganha as duas metades. O código antes do
`yield` roda antes da rota; o valor que ele entrega é o que a rota recebe; o código depois dele roda
quando a rota terminou. O `registration_lock` do `app/dependencies.py` segura uma trava em volta de
toda inscrição, e imprime quando a pega e quando a solta. Duas inscrições, a segunda recusada:

```
ana@vm:~/agenda-api$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"Gil\", \"email\": \"gil@example.org\"}" -w "\n%{http_code}\n" http://127.0.0.1:8001/events/django-night/registrations
{"name":"Gil","email":"gil@example.org","created_at":"2026-10-22T22:42:42.309531Z"}
201
ana@vm:~/agenda-api$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"Gil\", \"email\": \"gil@example.org\"}" -w "\n%{http_code}\n" http://127.0.0.1:8001/events/django-night/registrations
{"detail":"This address is already registered."}
409
```

E o que o servidor imprimiu enquanto elas rodavam:

```
lock held
registered gil@example.org
INFO:     127.0.0.1:47132 - "POST /events/django-night/registrations HTTP/1.1" 201 Created
lock released
lock held
lock released
INFO:     127.0.0.1:47134 - "POST /events/django-night/registrations HTTP/1.1" 409 Conflict
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Duas linhas do tempo lidas do log do servidor. Numa inscrição bem-sucedida a trava é pega, a rota roda, a resposta é mandada, e depois o bloco finally solta a trava. Numa recusada a trava é pega, a rota levanta erro, o bloco finally solta a trava, e depois o 409 é mandado.\"> <defs><marker id=\"tl-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"20\" y=\"26\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">um 201</text> <rect x=\"70\" y=\"40\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"125.0\" y=\"60\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">trava pega</text> <rect x=\"190\" y=\"40\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"245.0\" y=\"60\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a rota roda</text> <rect x=\"310\" y=\"40\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"365.0\" y=\"60\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">resposta enviada</text> <rect x=\"450\" y=\"40\" width=\"170\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"535.0\" y=\"60\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">finally: trava solta</text> <path d=\"M180 55 L184 55\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#tl-a)\"></path> <path d=\"M300 55 L304 55\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#tl-a)\"></path> <path d=\"M420 55 L444 55\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#tl-a)\"></path> <text x=\"20\" y=\"116\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">um 409</text> <rect x=\"70\" y=\"130\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"125.0\" y=\"150\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">trava pega</text> <rect x=\"190\" y=\"130\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"245.0\" y=\"150\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a rota levanta</text> <rect x=\"310\" y=\"130\" width=\"170\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"395.0\" y=\"150\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">finally: trava solta</text> <rect x=\"490\" y=\"130\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"545.0\" y=\"150\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">409 enviado</text> <path d=\"M180 145 L184 145\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#tl-a)\"></path> <path d=\"M300 145 L304 145\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#tl-a)\"></path> <path d=\"M480 145 L484 145\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#tl-a)\"></path> <text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">A exceção chega no yield; só um finally ou um bloco with roda depois dela.</text> </svg>", "caption": "A ordem das linhas do log, desenhada. Código escrito depois do yield sem um finally só teria rodado no primeiro caso."}
```

Leia as duas metades do log separadas. No 201, **a trava foi solta depois de o Uvicorn registrar a
resposta**, o que ele faz quando a resposta começa a sair: o código depois do `yield` rodou quando a
rota já tinha terminado com ela. No 409, a rota levantou `HTTPException`, e **a exceção chegou no
`yield`**: a soltura veio antes da resposta, e uma linha escrita depois do `yield` sem `finally` nem
teria rodado. É por isso que a dependência envolve o `yield` num `try`/`finally`, dentro de um `with`
que solta a trava aconteça o que acontecer.

## O que ela protege, e o que não

A trava faz a contagem e o append de uma inscrição acontecerem juntos **dentro deste processo**. É só
isso que ela consegue. A aula 16 roda a API em vários processos de trabalho, cada um com a própria
trava e a própria lista, então a correção de verdade é a da aula 10: as inscrições vão para o
PostgreSQL, e a trava é uma trava de linha que todo processo compartilha. **O formato fica**: a sessão
de banco da aula 10 é uma dependência com `yield` exatamente como esta, aberta antes da rota e fechada
depois.
