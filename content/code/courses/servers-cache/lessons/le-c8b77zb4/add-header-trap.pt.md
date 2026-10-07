---
title: A armadilha do add_header
version: 1
---

Este é o erro que desliga todos os cabeçalhos da seção anterior sem um único aviso, e merece uma seção
própria porque quase todo mundo o comete uma vez.

A API nunca deveria ser guardada por um navegador, então o location dela ganha um cabeçalho
`Cache-Control` próprio:

```
ana@web:~$ sudo sed -i 's|        proxy_read_timeout 10s;|        proxy_read_timeout 10s;\n        add_header Cache-Control "no-store";|' /etc/nginx/sites-available/ipelivros && grep -n 'add_header' /etc/nginx/sites-available/ipelivros
31:        add_header Cache-Control "no-store";
ana@web:~$ curl -sI https://ipelivros.example/api/books/1 | grep -iE "^(cache-control|strict-transport|content-security)"
Cache-Control: no-store
```

**O HSTS e o CSP sumiram de toda resposta da API.** O Nginx não reclamou, o teste passou, e os
cabeçalhos de que o site depende desapareceram de um location porque alguém acrescentou ali um
cabeçalho sem relação nenhuma. A regra é curta e surpreendente:

> as diretivas `add_header` são herdadas do bloco de fora **só se o bloco atual não tiver nenhum
> `add_header` próprio.** Um `add_header` num `location` substitui todos os do `server`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Um bloco server tem cinco cabeçalhos de segurança. O location de / não tem add_header próprio e herda os cinco. O location de /api/ tem um add_header, Cache-Control, e por isso não herda nenhum dos cinco: as respostas dele trazem só o Cache-Control.\"><defs><marker id=\"fih-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"660\" height=\"222\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"40\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">server { ... }</text><text x=\"40\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">add_header Strict-Transport-Security</text><text x=\"40\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">add_header Content-Security-Policy</text><text x=\"40\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">add_header X-Content-Type-Options</text><text x=\"40\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">add_header Referrer-Policy</text><text x=\"40\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">add_header Permissions-Policy</text><rect x=\"330\" y=\"30\" width=\"330\" height=\"80\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"495.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">location / { }</text><text x=\"495.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nenhum add_header aqui: herda os cinco</text><rect x=\"330\" y=\"135\" width=\"330\" height=\"85\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"495.0\" y=\"170.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">location /api/ { }</text><text x=\"495.0\" y=\"185.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">add_header Cache-Control ...</text><text x=\"495.0\" y=\"198.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">um add_header: não herda nenhum</text><line x1=\"270\" y1=\"85\" x2=\"328\" y2=\"70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fih-ah)\"></line><line x1=\"270\" y1=\"115\" x2=\"328\" y2=\"178\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#fih-ah)\"></line></svg>", "caption": "A herança do add_header é tudo ou nada. Um cabeçalho num location substitui a lista inteira do server.", "same": ["location / { }", "location /api/ { }"]}
```

A correção é repeti-los onde o cabeçalho novo é acrescentado, o que um snippet torna barato:

```
ana@web:~$ sudo sed -i 's|        add_header Cache-Control "no-store";|        add_header Cache-Control "no-store";\n        include snippets/security-headers.conf;|' /etc/nginx/sites-available/ipelivros && grep -n 'add_header\|security-headers' /etc/nginx/sites-available/ipelivros
12:    include snippets/security-headers.conf;
31:        add_header Cache-Control "no-store";
32:        include snippets/security-headers.conf;
ana@web:~$ curl -sI https://ipelivros.example/api/books/1 | grep -iE "^(cache-control|strict-transport|content-security)"
Cache-Control: no-store
Strict-Transport-Security: max-age=31536000
Content-Security-Policy: default-src 'self'; img-src 'self' data:; frame-ancestors 'none'; base-uri 'self'; form-action 'self'
```

Os três voltaram. Esse é também o argumento para manter os cabeçalhos de segurança num snippet em vez
de escrevê-los no bloco server: no dia em que precisam ser repetidos num location, é um `include`, e a
lista fica num arquivo só.

**A verificação que pega isso é um teste do site no ar, location por location**, não uma leitura da
configuração: uma linha num script de deploy que pede uma URL sob cada location e falha se o
`Strict-Transport-Security` faltar.
