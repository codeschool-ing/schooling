---
title: O token de sessão, observado na rede
version: 1
---

**A consistência de sessão é mantida por um token, e o token é só um cabeçalho.** Toda escrita num
contêiner responde com `x-ms-session-token`, uma string curta que nomeia a partição em que o item
está e até onde o log dessa partição tinha chegado quando a escrita foi aplicada. Uma leitura que
devolve o token só pode ser servida por uma cópia cujo log chegou a esse ponto. Não há mais nada
envolvido: nenhum bloqueio, nenhuma conexão mantida aberta, nenhum servidor lembrando quem você é. É
por isso que a sessão atravessa processos, e por isso que ela se perde no momento em que um programa
esquece a string.

Esta seção é praticada. Suba o emulador do Cosmos DB como a lição 1 mostrou, e salve o programa
abaixo como `session.py` em `~/azure`:

```sh
docker compose --profile cosmos up -d
```

```schooling-example
{"language": "python", "file": "session.py", "parts": [
{"code": "from azure.cosmos import CosmosClient, PartitionKey, exceptions\n\nURL = \"http://localhost:8081\"\nKEY = \"C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==\"\n\n\ndef sent(request):\n    print(\"   sent:\", request.http_request.headers.get(\"x-ms-session-token\", \"no token\"))\n\n\ndef orders(client):\n    db = client.create_database_if_not_exists(\"quitanda\")\n    return db.create_container_if_not_exists(\"orders\", PartitionKey(\"/customerId\"))\n", "note": "O endereço do emulador e a chave publicada dele, como no `ru.py` da lição 1. O `sent` é chamado pela biblioteca logo antes de cada requisição sair, e imprime o token de sessão que ela leva, se levar algum. Todo cliente abre o mesmo contêiner."},
{"code": "\napp = orders(CosmosClient(URL, KEY, consistency_level=\"Session\"))\nfor n in (\"o-1001\", \"o-1002\"):\n    app.upsert_item({\"id\": n, \"customerId\": \"c-7\", \"status\": \"paid\"})\n    answer = app.client_connection.last_response_headers\n    print(\"the app wrote\", n, \"and was given\", answer[\"x-ms-session-token\"])\ntoken = answer[\"x-ms-session-token\"]\nprint(\"the answer names the item's path:\", \"x-ms-alt-content-path\" in answer)\n", "note": "O app é um cliente em consistência de sessão. Ele grava dois pedidos, e cada resposta traz um token no cabeçalho `x-ms-session-token`. A última linha pergunta se a resposta trouxe também o `x-ms-alt-content-path`, que é o cabeçalho sob o qual a biblioteca Python arquiva um token."},
{"code": "\nprint(\"the app reads o-1002 back\")\napp.read_item(\"o-1002\", \"c-7\", raw_request_hook=sent)\n", "note": "O app lê de volta o que gravou. No Azure a biblioteca anexa aqui o token da própria escrita, sem ninguém pedir."},
{"code": "\nreport = orders(CosmosClient(URL, KEY, consistency_level=\"Session\"))\nprint(\"a second client reads it with the app's token\")\nreport.read_item(\"o-1002\", \"c-7\", session_token=token, raw_request_hook=sent)\n", "note": "Um segundo cliente, que é como um worker em segundo plano ou outro servidor web aparece para o Cosmos DB, lê o mesmo pedido com o token do app passado à mão."},
{"code": "\nprint(\"the second client reads with a token nobody was given\")\ntry:\n    report.read_item(\"o-1002\", \"c-7\", session_token=\"0:0#999\", raw_request_hook=sent)\nexcept exceptions.CosmosHttpResponseError as e:\n    print(\"  \", e.status_code, e.sub_status, e.message.splitlines()[0])\n", "note": "Um token que nomeia uma escrita que a cópia não aplicou. Aqui ele nomeia uma que nunca aconteceu, que é o único jeito de tirar uma cópia atrasada de um emulador que só tem uma."}
]}
```

```
ana@laptop:~/azure$ python session.py
the app wrote o-1001 and was given 0:0#1
the app wrote o-1002 and was given 0:0#2
the answer names the item's path: False
the app reads o-1002 back
   sent: no token
a second client reads it with the app's token
   sent: 0:0#2
the second client reads with a token nobody was given
   sent: 0:0#999
   sent: 0:0#999
   404 1002 (NotFound) The read session is not available for the input session token.
```

**Cada escrita avançou o token em um: `0:0#1`, depois `0:0#2`.** O número antes dos dois-pontos
nomeia a faixa de chaves de partição em que o item está, e o emulador tem uma faixa só, a `0`. O
número depois do `#` é a posição no log dessa faixa. Um token é então uma afirmação sobre uma
partição e não diz nada sobre as outras, e é por isso que as bibliotecas guardam um por faixa e os
juntam.

**Depois vem a linha que não é sobre o Azure: a resposta não nomeou o caminho do item.** A biblioteca
Python arquiva um token recebido sob o contêiner de onde ele veio, e descobre qual contêiner por um
cabeçalho de resposta, `x-ms-alt-content-path`, que este emulador não manda. Então a biblioteca nunca
guardou nenhum dos dois tokens, e a leitura do próprio app saiu com `no token`. Contra o Azure a
mesma linha manda `0:0#2` sem ninguém pedir; isso vem da leitura do código da biblioteca, em
`azure/cosmos/_session.py`, e não foi observado, já que nada neste curso chega ao Azure. Neste
emulador uma sessão é só o que você carrega à mão, e essa acaba sendo a coisa mais útil de ter
praticado.

**O segundo cliente leu com o token do app e foi atendido.** Esse é o padrão para uma sessão que
atravessa processos: o servidor web que recebeu o pagamento põe o token na sessão do navegador do
cliente, e o servidor que responde a página seguinte, seja qual for, o repassa na leitura. Um app de
entregador que nunca viu o token não recebe promessa nenhuma sobre a escrita do cliente, só sobre as
suas.

**E o token do futuro foi recusado, com 404 e subestado 1002**: *the read session is not available
for the input session token*, a sessão de leitura não está disponível para o token informado. A
biblioteca mandou a leitura duas vezes antes de desistir, porque no Azure essa resposta é comum e
passageira. Com quatro cópias numa partição, uma leitura pode cair na que ainda não aplicou a
escrita, e a requisição é repetida até uma cópia que já aplicou poder responder:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 332\" role=\"img\" aria-label=\"Uma sequência entre o app e duas cópias da mesma partição. O app grava o-1002 numa cópia, que responde com o token de sessão 0:0#2. Depois o app lê o-1002 levando esse token, e a leitura chega a uma cópia ainda em #1, que responde 404 com subestado 1002 porque ainda não aplicou aquela escrita. A mesma leitura é repetida, chega à cópia em #2 e recebe o pedido de volta com status paid.\" data-fig=\"l12-token\"><defs><marker id=\"l12-tk-ah-p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--phosphor)\"/></marker><marker id=\"l12-tk-ah-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--amber)\"/></marker></defs><rect x=\"30\" y=\"14\" width=\"160\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"110\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">o app</text><line x1=\"110\" y1=\"44\" x2=\"110\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"/><rect x=\"300\" y=\"14\" width=\"160\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"380\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">uma cópia em #2</text><line x1=\"380\" y1=\"44\" x2=\"380\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"/><rect x=\"540\" y=\"14\" width=\"160\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"620\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">uma cópia ainda em #1</text><line x1=\"620\" y1=\"44\" x2=\"620\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"/><line x1=\"114\" y1=\"70\" x2=\"376\" y2=\"70\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12-tk-ah-p)\"/><text x=\"245.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">grava o-1002</text><line x1=\"376\" y1=\"104\" x2=\"114\" y2=\"104\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12-tk-ah-p)\"/><text x=\"245.0\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">x-ms-session-token: 0:0#2</text><line x1=\"114\" y1=\"150\" x2=\"616\" y2=\"150\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12-tk-ah-p)\"/><text x=\"365.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">lê o-1002, token 0:0#2</text><line x1=\"616\" y1=\"184\" x2=\"114\" y2=\"184\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l12-tk-ah-a)\"/><text x=\"365.0\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">404, subestado 1002: ainda não chegou</text><line x1=\"114\" y1=\"230\" x2=\"376\" y2=\"230\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12-tk-ah-p)\"/><text x=\"245.0\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a mesma leitura, de novo</text><line x1=\"376\" y1=\"264\" x2=\"114\" y2=\"264\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12-tk-ah-p)\"/><text x=\"245.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o-1002, status paid</text><text x=\"370\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Uma cópia só responde depois de aplicar a escrita que o token nomeia.</text></svg>", "caption": "A consistência de sessão no Azure, onde uma partição tem várias cópias. O emulador tem uma, e é por isso que o programa acima precisou de um token do futuro para ver uma recusa.", "same": ["o-1002, status paid"]}
```

Um 404 que quer dizer *ainda não* em vez de *não encontrado* vale a pena reconhecer de cara. Se ele
persiste, o token não veio de uma escrita neste contêiner: foi copiado de outro lugar, ou inventado,
como aqui.
