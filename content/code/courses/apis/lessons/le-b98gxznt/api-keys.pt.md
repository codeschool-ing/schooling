---
title: Chaves de API
version: 1
---

**Uma chave de API identifica uma aplicação, não uma pessoa.** Uma livraria parceira que mostra o
estoque do shelf no próprio site tem um programa chamando a API às três da manhã, e não há ninguém ali
para digitar uma senha. Ela precisa de uma credencial que pertença ao programa, que dure até alguém
decidir o contrário, e que possa ser retirada sem mexer na senha de ninguém.

Uma pessoa a cria. A ana, autenticada com Basic, pede uma chave com o nome do parceiro:

```
ana@api:~/shelf$ curl -s -u ana:river-lamp-42 localhost:8000/v1/keys -H 'Content-Type: application/json' -d '{"name": "Livraria Parceira"}' | tee partner.json
{"key": "shelf_2ff69109_yOyZM1dhEnBovsmbwPZYBT6yAZJQYimsG5297JFqa2U", "prefix": "shelf_2ff69109", "name": "Livraria Parceira", "note": "shown once: store it now"}
```

**Essa resposta é a única vez que a chave existe fora das mãos do parceiro.** O servidor responde com a
chave inteira uma vez, e o `note` diz isso; a ana a repassa ao parceiro, e daí em diante o servidor só
consegue reconhecê-la, nunca mostrá-la de novo. O parceiro a envia em `X-API-Key`:

```
ana@api:~/shelf$ curl -s -H "X-API-Key: $(jq -r .key partner.json)" localhost:8000/v1/whoami
{"kind": "application", "name": "Livraria Parceira"}
ana@api:~/shelf$ curl -s -H "X-API-Key: $(jq -r .key partner.json)" localhost:8000/v1/books/6
{"id": 6, "title": "Americanah", "stock": 4}
```

O `/v1/whoami` diz `application`, e o nome é o que a ana deu à chave. Toda requisição que o parceiro
fizer daqui em diante pode ser atribuída à "Livraria Parceira", seja qual for o funcionário que escreveu
o código.

## O prefixo e o hash

Isto é o que o servidor guardou:

```
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT * FROM api_keys'
shelf_2ff69109|22beab89b426a9d53de806590b74ced4eace1267072b17489cc2fbdd46899614|Livraria Parceira|2026-10-10T04:26:06Z|2026-10-10T04:26:06Z
```

A chave tem duas partes, e o servidor trata cada uma de um jeito. **`shelf_2ff69109` é o prefixo, e ele
não é secreto.** Fica guardado como está, é a chave primária da linha, e é o que o `keys.py` usa para
achar a linha antes de comparar qualquer coisa. É também o que torna uma chave reconhecível: numa linha
de log, num chamado de suporte, ou colada por engano num repositório público, onde serviços de varredura
de segredos procuram justamente esses padrões e avisam o dono. Uma chave que fosse só 43 caracteres
aleatórios pareceria, para todos eles, uma sequência aleatória qualquer.

A segunda coluna é o SHA-256 da chave inteira, pelo mesmo motivo do token: a chave é aleatória, então um
hash rápido basta, e uma tabela vazada não serve para chamar a API. As duas últimas colunas são quando a
chave foi criada e quando foi usada pela última vez.

Gerenciar chaves é coisa de pessoa, e uma chave que tenta é recusada com o código que a seção sobre o
401 prometeu:

```
ana@api:~/shelf$ curl -si -H "X-API-Key: $(jq -r .key partner.json)" localhost:8000/v1/keys
HTTP/1.1 403 Forbidden
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:26:06 GMT
Content-Type: application/json
Content-Length: 43

{"error": "an API key cannot manage keys"}
```

**403, não 401.** A chave se autenticou perfeitamente; o `keys.py` sabe que está falando com a Livraria
Parceira. O que ele recusa é a ação. Isso é autorização, na forma mais simples, e a aula 11 constrói o
resto.

## Rotação com duas chaves vivas

Chaves vazam, e quem as conhecia vai embora, então uma chave é trocada num calendário e sempre que houver
dúvida. Trocá-la no lugar quebraria o parceiro no momento da troca, entre a chave antiga morrer e a nova
chegar à configuração dele. **Então por um tempo existem duas.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 270\" role=\"img\" aria-label=\"Uma linha do tempo de duas chaves de API. A chave antiga é criada com POST /v1/keys, o segredo é mostrado uma vez nessa resposta, e ela é usada, com last_used avançando. Uma chave nova é criada enquanto a antiga ainda funciona, então por um tempo as duas valem e o parceiro troca a configuração. Quando o last_used da antiga para de avançar, ela é revogada com DELETE, e daí em diante recebe 401. A chave nova continua.\"><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">chave antiga</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">chave nova</text><rect x=\"100\" y=\"55\" width=\"216\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"208.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">em uso: last_used avança</text><rect x=\"323\" y=\"45\" width=\"184\" height=\"120\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><rect x=\"330\" y=\"55\" width=\"170\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"415.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">as duas valem</text><rect x=\"330\" y=\"125\" width=\"170\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"415.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">as duas valem</text><rect x=\"514\" y=\"55\" width=\"166\" height=\"30\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"597.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">401</text><rect x=\"514\" y=\"125\" width=\"166\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"597.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">em uso</text><line x1=\"20\" y1=\"200\" x2=\"680\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><line x1=\"100\" y1=\"45\" x2=\"100\" y2=\"205\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><text x=\"100\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">criada, mostrada uma vez</text><text x=\"100\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">POST /v1/keys</text><line x1=\"330\" y1=\"45\" x2=\"330\" y2=\"205\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><text x=\"330\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">segunda chave criada</text><text x=\"330\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">POST /v1/keys</text><line x1=\"507\" y1=\"45\" x2=\"507\" y2=\"205\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><text x=\"507\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">antiga revogada</text><text x=\"507\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">DELETE /v1/keys/…</text><text x=\"415\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o parceiro troca a chave</text><text x=\"680\" y=\"258\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tempo</text></svg>", "caption": "Rotação sem interrupção: a segunda chave existe antes de a primeira sair, e a antiga só é revogada quando nada mais a usa."}
```

A ana cria a segunda chave e a repassa:

```
ana@api:~/shelf$ curl -s -u ana:river-lamp-42 localhost:8000/v1/keys -H 'Content-Type: application/json' -d '{"name": "Livraria Parceira, rotated"}' -o partner-new.json
ana@api:~/shelf$ curl -s -u ana:river-lamp-42 localhost:8000/v1/keys | jq -c '.[]'
{"prefix":"shelf_2ff69109","name":"Livraria Parceira","created":"2026-10-10T04:26:06Z","last_used":"2026-10-10T04:26:06Z"}
{"prefix":"shelf_2ba45638","name":"Livraria Parceira, rotated","created":"2026-10-10T04:26:06Z","last_used":null}
ana@api:~/shelf$ for f in partner.json partner-new.json; do curl -s -H "X-API-Key: $(jq -r .key $f)" localhost:8000/v1/whoami; done
{"kind": "application", "name": "Livraria Parceira"}
{"kind": "application", "name": "Livraria Parceira, rotated"}
```

As duas chaves funcionam, as duas aparecem na lista, e a nova nunca foi usada. O parceiro troca a
configuração para a chave nova; no servidor, a ana acompanha o `last_used`. Quando o da chave antiga
para de avançar, nada mais a usa, e ela a revoga pelo prefixo:

```
ana@api:~/shelf$ curl -si -u ana:river-lamp-42 -X DELETE localhost:8000/v1/keys/$(jq -r .prefix partner.json)
HTTP/1.1 204 No Content
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:26:07 GMT
Content-Length: 0

ana@api:~/shelf$ curl -s -w '%{http_code}\n' -H "X-API-Key: $(jq -r .key partner.json)" localhost:8000/v1/whoami
{"error": "authentication required"}
401
ana@api:~/shelf$ curl -s -u ana:river-lamp-42 localhost:8000/v1/keys | jq -c '.[]'
{"prefix":"shelf_2ba45638","name":"Livraria Parceira, rotated","created":"2026-10-10T04:26:06Z","last_used":"2026-10-10T04:26:07Z"}
```

A chave antiga agora recebe 401 como qualquer estranho, e sobra uma chave, com um `last_used` recente.

Mais uma coisa pertence à chave, e não a uma pessoa: **com que frequência ela pode ser usada**. Um
parceiro cujo programa tem um defeito que pede todos os livros uma vez por segundo deve ser freado pela
própria chave, sem frear mais ninguém. A aula 12 conta requisições por chave.
