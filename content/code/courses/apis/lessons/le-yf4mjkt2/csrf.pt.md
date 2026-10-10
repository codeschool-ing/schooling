---
title: Cookies e requisições entre sites
version: 1
---

**O navegador anexa cookies sozinho.** Sempre que manda uma requisição ao host do shelf, ele
acrescenta os cookies que tem para aquele host, e não pergunta qual página iniciou a requisição. É
isso que torna o login por cookie cômodo, e é também um buraco: uma página de qualquer outro site
consegue fazer o seu navegador mandar uma requisição ao shelf, com um formulário oculto por exemplo,
e o seu cookie vai junto.

A outra página não consegue ler a resposta, porque a política de mesma origem do navegador a esconde
dos scripts da página; a lição 13 trata dessa política. Ela não precisa ler. Uma requisição que
acrescenta um livro à lista de desejos, muda um e-mail ou transfere dinheiro já fez o serviço quando a
resposta volta. Isso é **falsificação de requisição entre sites**, CSRF, e é o preço do cookie
automático.

A defesa errada é a óbvia: "esse endpoint exige login, então está protegido". O login é exatamente o
que o navegador fornece em nome da outra página. Uma defesa tem de se apoiar em algo que a outra
página não consegue fornecer, e há duas coisas assim.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" aria-label=\"Uma sequência em três raias: uma página de outro site, o navegador e o shelf. Primeiro o navegador entra no shelf e guarda o cookie sid com SameSite=Lax. Depois uma página de outro site envia um formulário que faz POST na lista de desejos do shelf. Com SameSite=Lax o navegador manda esse POST entre sites sem o cookie e o shelf responde 401. Se um cookie fosse junto mesmo assim, a requisição não tem X-CSRF-Token, porque a outra página não consegue lê-lo, e o shelf responde 403.\"><defs><marker id=\"l08-csrf-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"10\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">página de outro site</text><rect x=\"270\" y=\"10\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">seu navegador</text><rect x=\"510\" y=\"10\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shelf</text><line x1=\"110\" y1=\"50\" x2=\"110\" y2=\"320\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"350\" y1=\"50\" x2=\"350\" y2=\"320\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"590\" y1=\"50\" x2=\"590\" y2=\"320\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"350\" y1=\"78\" x2=\"588\" y2=\"78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l08-csrf-ah)\"></line><text x=\"469.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">POST /login</text><line x1=\"590\" y1=\"112\" x2=\"352\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l08-csrf-ah)\"></line><text x=\"471.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Set-Cookie: sid=…; SameSite=Lax</text><text x=\"470\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 · você entra, o navegador guarda o cookie</text><line x1=\"110\" y1=\"170\" x2=\"348\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l08-csrf-ah)\"></line><text x=\"229.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um formulário oculto, enviado</text><text x=\"230\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 · você abre outro site</text><line x1=\"350\" y1=\"222\" x2=\"588\" y2=\"222\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l08-csrf-ah)\"></line><text x=\"469.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">POST /wishlist</text><text x=\"470\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 · o navegador decide o que vai junto</text><rect x=\"395\" y=\"258\" width=\"140\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"465.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sem cookie</text><text x=\"465.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Lax, POST entre sites</text><rect x=\"545\" y=\"258\" width=\"140\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cookie, sem token</text><text x=\"615.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">se fosse junto</text><text x=\"465\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">401</text><text x=\"615\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">403</text></svg>", "caption": "Falsificação de requisição entre sites, e as duas verificações que a barram. A outra página consegue fazer o navegador mandar a requisição; não consegue ler nem o cookie nem o token CSRF."}
```

## SameSite: o navegador decide

O `SameSite` diz ao navegador quando uma requisição iniciada por outro site pode levar o cookie:

| valor | o cookie vai com uma requisição que outro site iniciou | na prática |
|---|---|---|
| `Strict` | nunca | seguir um link para o shelf a partir de um e-mail chega deslogado |
| `Lax` | só quando o usuário segue um link, um `GET` de nível superior | um `POST` forjado, uma imagem, um frame ou a requisição de um script vão sem ele |
| `None` | sempre, e só com `Secure` | o comportamento antigo, para cookies que precisam funcionar dentro de outros sites |

O `sessions.py` define `Lax`. Chrome e Edge aplicam `Lax` a um cookie que não diz nada, e os outros
navegadores não, então ele vem escrito. Um `POST` forjado para `/wishlist` chega, portanto, sem
cookie, e o servidor responde 401 como responderia a um estranho. O `Lax` ainda envia o cookie quando
alguém segue um link, o que é mais um motivo, depois da seção sobre métodos da lição 1, para que **um
`GET` nunca mude nada**: um link em outro site para `GET /wishlist/add?book=3` levaria o cookie e
faria o estrago.

## Um token que a outra página não consegue ler

O `SameSite` é a verificação do navegador, e depende do navegador. Navegadores antigos o ignoram, e
dois sites sob o mesmo domínio registrável, como `shop.example.com` e `blog.example.com`, contam como
o mesmo site para ele. Por isso o servidor também confere algo por conta própria: **um segredo por
sessão que a página precisa devolver num cabeçalho**. O `sessions.py` guarda um em cada linha de
sessão como `csrf` e o devolve no `/me`. As páginas do próprio shelf conseguem ler essa resposta; a
página de outro site não, e um formulário oculto nem consegue definir cabeçalhos.

Entre de novo, já que a seção anterior fez logout, e peça um livro na lista de desejos só com o
cookie:

```
ana@api:~/shelf$ curl -s -c jar.txt localhost:8000/login -H 'Content-Type: application/json' -d '{"name": "ana", "password": "correct-horse"}'
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -b jar.txt localhost:8000/wishlist -H 'Content-Type: application/json' -d '{"book_id": 3}'
{"error": "missing or wrong X-CSRF-Token"}
403
```

A sessão é válida e a requisição é recusada mesmo assim: **403**, o servidor sabe quem você é e a
resposta é não. A mesma requisição com o token em `X-CSRF-Token`:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -b jar.txt localhost:8000/wishlist -H 'Content-Type: application/json' -H "X-CSRF-Token: $(curl -s -b jar.txt localhost:8000/me | jq -r .csrf)" -d '{"book_id": 3}'
{"book_id": 3}
201
ana@api:~/shelf$ curl -s -b jar.txt localhost:8000/wishlist
[{"id": 3, "title": "A Hora da Estrela"}]
```

O curl não é um navegador, e nada acima veio de outro site; o que as capturas mostram é a metade
servidor da defesa, que é a metade que você escreve. Mais duas verificações a completam, e as duas
são curtas: recusar uma requisição que muda estado cujo cabeçalho `Origin` aponta outro site, e
aceitar só corpos `application/json`, que um formulário HTML simples não consegue enviar.

**Um bearer token num cabeçalho `Authorization` não fica exposto a nada disso**, porque o navegador
nunca o acrescenta sozinho: algum código da página precisa fazê-lo. Essa é uma vantagem real dos
bearer tokens, e ela some no momento em que alguém guarda o token num cookie, onde ele é anexado tão
automaticamente quanto o `sid`.
