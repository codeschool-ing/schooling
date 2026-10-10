---
title: Do que são feitas uma requisição e uma resposta
version: 1
---

**Uma troca HTTP são duas mensagens de texto puro.** O cliente manda uma requisição; o servidor manda
uma resposta. As duas têm as mesmas três partes: uma primeira linha, um bloco de cabeçalhos e um
corpo opcional depois de uma linha em branco. Isso é o protocolo inteiro no que interessa a quem
testa, e o curl mostra tudo quando chamado com `-v`, de verboso:

```
ana@laptop:~/boxoffice$ curl -v localhost:8080/v1/shows/sh-103
* Uses proxy env variable no_proxy == 'localhost,127.0.0.1'
* Host localhost:8080 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying 127.0.0.1:8080...
* Connected to localhost (127.0.0.1) port 8080
> GET /v1/shows/sh-103 HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/8.5.0
> Accept: */*
> 
< HTTP/1.1 200 OK
< content-type: application/json
< etag: "a2cce3d151c58812"
< Date: Sat, 10 Oct 2026 07:13:49 GMT
< Connection: keep-alive
< Keep-Alive: timeout=5
< Transfer-Encoding: chunked
< 
{"id":"sh-103","title":"O Pagador de Promessas","starts_at":"2026-11-08T18:00:00-03:00","price_cents":6500,"seats_left":4}
* Connection #0 to host localhost left intact
```

O curl marca cada linha pela origem. Linhas que começam com `>` são o que **o curl mandou**, linhas
que começam com `<` são o que **o boxoffice respondeu**, e linhas que começam com `*` são o curl
falando com você sobre a conexão. O corpo, a última linha, não tem marca nenhuma.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 264\" role=\"img\" aria-label=\"O curl manda ao boxoffice uma requisição em três partes: a linha de requisição GET /v1/shows/sh-103 HTTP/1.1, os cabeçalhos Host, User-Agent e Accept, e nenhum corpo. O boxoffice responde com uma resposta nas mesmas três partes: a linha de status HTTP/1.1 200 OK, os cabeçalhos content-type, etag e Date, e um corpo com o espetáculo em JSON.\"><defs><marker id=\"f01exchange-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"95\" width=\"110\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"75\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cliente</text><text x=\"75\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">curl</text><rect x=\"570\" y=\"95\" width=\"110\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">servidor</text><text x=\"625\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">boxoffice</text><text x=\"350\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a requisição</text><rect x=\"170\" y=\"30\" width=\"360\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178\" y=\"41\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">linha de requisição</text><text x=\"278\" y=\"41\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">GET /v1/shows/sh-103 HTTP/1.1</text><rect x=\"170\" y=\"54\" width=\"360\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">cabeçalhos</text><text x=\"278\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Host, User-Agent, Accept</text><rect x=\"170\" y=\"78\" width=\"360\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">corpo</text><text x=\"278\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">(nenhum: um GET não manda corpo)</text><line x1=\"130\" y1=\"112\" x2=\"568\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f01exchange-ah)\"></line><text x=\"350\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a resposta</text><rect x=\"170\" y=\"160\" width=\"360\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">linha de status</text><text x=\"278\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">HTTP/1.1 200 OK</text><rect x=\"170\" y=\"184\" width=\"360\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178\" y=\"195\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">cabeçalhos</text><text x=\"278\" y=\"195\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">content-type, etag, Date</text><rect x=\"170\" y=\"208\" width=\"360\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">corpo</text><text x=\"278\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">{\"id\":\"sh-103\", ... \"seats_left\":4}</text><line x1=\"568\" y1=\"128\" x2=\"132\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f01exchange-ah)\"></line><text x=\"350\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma linha em branco separa os cabeçalhos do corpo, nas duas mensagens</text></svg>", "caption": "Toda troca HTTP são duas mensagens com a mesma forma: uma primeira linha, cabeçalhos e um corpo opcional depois de uma linha em branco."}
```

Leia primeiro a requisição, as quatro linhas com `>`:

- `GET /v1/shows/sh-103 HTTP/1.1` é a **linha de requisição**: o método, o caminho da coisa sobre a
  qual se pergunta e a versão do protocolo. O método é o verbo; a seção 07 trata deles.
- `Host: localhost:8080` nomeia o servidor. Uma máquina pode responder por muitos nomes, e este
  cabeçalho diz qual o cliente quis.
- `User-Agent` e `Accept` também são cabeçalhos. `Accept: */*` diz que o curl aceita qualquer tipo de
  resposta.
- a linha em branco depois deles termina os cabeçalhos. Um GET não carrega corpo, então a requisição
  acaba ali.

Depois a resposta, as linhas com `<`:

- `HTTP/1.1 200 OK` é a **linha de status**: a versão, um código de status de três dígitos e uma
  frase curta para pessoas. Programas leem o número e ignoram a frase. A seção 08 trata dos códigos.
- os cabeçalhos dizem o que é o corpo (`content-type: application/json`), dão a ele uma impressão
  digital (`etag`) e trazem a data. A seção 09 os lê.
- depois da linha em branco vem o **corpo**, o espetáculo em JSON.

## O que quem testa olha, em ordem

A ordem importa porque cada parte decide como ler a seguinte.

1. **O código de status.** Ele diz se a requisição funcionou antes de você ler qualquer outra coisa.
   Um corpo que parece certo debaixo de um `500` não é uma resposta certa.
2. **Os cabeçalhos que descrevem o corpo**, acima de tudo `content-type`. Um corpo JSON rotulado como
   texto é um defeito mesmo quando todo campo nele está correto, porque um cliente que confia no
   rótulo não vai interpretá-lo.
3. **O corpo**, campo a campo, contra o esperado.

Quanto tempo a resposta levou também merece uma olhada. O curl sabe imprimir isso sozinho, em
segundos:

```
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{time_total}\n' localhost:8080/v1/shows/sh-103
0.001588
```

Menos de dois milésimos de segundo, que é o que a seção 01 quis dizer com rápido: sem tela, sem
animação, nada entre a pergunta e a resposta além do servidor.
