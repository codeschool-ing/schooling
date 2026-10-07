---
title: O Nginx na frente da aplicação
version: 1
---

Consultada diretamente, a livraria responde na própria porta, e enxerga exatamente quem perguntou:

```
ana@web:~$ curl -s localhost:8001/api/echo
{"server": "shop1", "peer": "127.0.0.1", "host": "localhost:8001", "x_real_ip": null, "x_forwarded_for": null, "x_forwarded_proto": null}
```

**Um proxy reverso é um servidor que responde em nome da aplicação.** O cliente se conecta ao Nginx e
nunca fica sabendo que a aplicação existe; o Nginx abre uma conexão própria com a aplicação, repassa
a requisição e copia a resposta de volta. A palavra "reverso" está ali porque um proxy comum trabalha
para o cliente, como o proxy de um escritório trabalha para os funcionários, e um proxy reverso
trabalha para o servidor.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"O cliente se conecta só ao Nginx na porta 80. O Nginx serve sozinho os arquivos de /var/www/ipe e abre conexões próprias com as duas cópias da loja, em 127.0.0.1 portas 8001 e 8002, para tudo o que está sob /api/.\"><defs><marker id=\"fpx-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"95\" width=\"120\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cliente</text><text x=\"80.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">curl, navegador</text><rect x=\"230\" y=\"70\" width=\"170\" height=\"110\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"315.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nginx :80</text><text x=\"315.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">upstream shop</text><line x1=\"140\" y1=\"125\" x2=\"228\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fpx-ah)\"></line><text x=\"184\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">conexão 1</text><rect x=\"500\" y=\"20\" width=\"180\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">/var/www/ipe</text><text x=\"590.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">arquivos</text><rect x=\"500\" y=\"100\" width=\"180\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop1</text><text x=\"590.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">127.0.0.1:8001</text><rect x=\"500\" y=\"180\" width=\"180\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop2</text><text x=\"590.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">127.0.0.1:8002</text><line x1=\"400\" y1=\"95\" x2=\"498\" y2=\"45\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fpx-ah)\"></line><line x1=\"400\" y1=\"125\" x2=\"498\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fpx-ah)\"></line><line x1=\"400\" y1=\"155\" x2=\"498\" y2=\"205\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fpx-ah)\"></line><text x=\"440\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/css/...</text><text x=\"450\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/api/...</text><text x=\"440\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">conexão 2</text></svg>", "caption": "Duas conexões onde antes havia uma. A aplicação só enxerga a segunda, e por isso a próxima seção precisa contar a ela sobre a primeira.", "same": ["nginx :80", "shop1", "shop2", "/var/www/ipe"]}
```

Um bloco `location` dentro do bloco server da aula 1 basta. Um `location` nomeia uma parte do espaço
de URLs, e tudo sob `/api/` agora é entregue à primeira cópia da loja:

```
ana@web:~$ grep -A2 'location /api/' /etc/nginx/sites-available/ipelivros
    location /api/ {
        proxy_pass http://127.0.0.1:8001;
    }
ana@web:~$ curl -si http://ipelivros.example/api/books/3
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
Date: Wed, 07 Oct 2026 03:25:39 GMT
Content-Type: application/json
Content-Length: 131
Connection: keep-alive
X-Served-By: shop1
ETag: "ec5dc1095232d72e"
Last-Modified: Tue, 01 Sep 2026 13:00:00 GMT

{"id": 3, "title": "A Hora da Estrela", "author": "Clarice Lispector", "price_cents": 3990, "stock": 20, "updated_at": 1788267600}
```

Os cabeçalhos são uma mistura dos dois programas. `Server`, `Date` e `Connection` são do Nginx;
`X-Served-By`, `ETag` e `Last-Modified` vieram da loja sem mudança. O resto do site continua sendo
arquivos de `/var/www/ipe`, então **um nome agora serve a vitrine estática e a API**, que é o arranjo
de quase toda aplicação web em produção.

## O que a aplicação vê agora

Pergunte à loja o que lhe disseram:

```
ana@web:~$ curl -s http://ipelivros.example/api/echo
{"server": "shop1", "peer": "127.0.0.1", "host": "127.0.0.1:8001", "x_real_ip": null, "x_forwarded_for": null, "x_forwarded_proto": null}
```

Duas coisas se perderam, e as duas importam. **`peer` é o Nginx**, porque foi o Nginx que abriu a
conexão. Toda requisição que a loja recebe agora vem de `127.0.0.1`, então os logs dela, os limites de
taxa e qualquer coisa que queira saber quem é o cliente enxergam um cliente só. E **`host` é
`127.0.0.1:8001`**, o endereço do `proxy_pass`, não o nome que o navegador pediu, então uma aplicação
que monta links a partir do cabeçalho `Host` agora os monta errado. A próxima seção devolve os dois.

Repare também no que o `proxy_pass` faz com o caminho. Escrito como `http://127.0.0.1:8001`, sem
caminho, o caminho da requisição passa sem mudança: `/api/books/3` chega à loja como `/api/books/3`.
Escrito com caminho, como seria `proxy_pass http://127.0.0.1:8001/;`, a parte da URL que bateu com o
`location` é trocada por ele, e a loja receberia `/books/3`. Uma barra muda a requisição que a
aplicação recebe, e é a surpresa mais comum numa primeira configuração de proxy.
