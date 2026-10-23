---
title: Centrifugo, um servidor para os sockets
version: 1
---

O Melody leva o hub para uma biblioteca; **o Centrifugo leva as conexões para fora do seu programa de
vez.** Ele é um servidor à parte, escrito em Go, cujo trabalho inteiro é segurar conexões de WebSocket e
de server-sent events e entregar mensagens a elas. Os clientes se conectam ao Centrifugo. O seu programa
nunca segura uma conexão: quando algo acontece, ele faz uma chamada HTTP à API do Centrifugo, e o
Centrifugo espalha a mensagem para todo mundo inscrito naquele canal.

O que isso compra é quase tudo o que um hub escrito à mão não tem: um deploy do boxoffice não derruba mais
dez mil conexões, porque elas nunca foram do boxoffice; vários nós do Centrifugo dividem seus inscritos
através do Redis; e ele traz presença, histórico de mensagens e recuperação das mensagens perdidas ao
reconectar. O que custa é um segundo servidor para rodar, configurar, proteger e atualizar.

## Instalando

O Centrifugo publica um binário para cada plataforma a cada release, e um arquivo de checksums ao lado.
Baixe os dois, confira um contra o outro e extraia só o binário:

```
ana@vm:~/centrifugo$ curl -sSLO https://github.com/centrifugal/centrifugo/releases/download/v6.9.7/centrifugo_6.9.7_linux_amd64.tar.gz
ana@vm:~/centrifugo$ curl -sSLO https://github.com/centrifugal/centrifugo/releases/download/v6.9.7/centrifugo_6.9.7_checksums.txt
ana@vm:~/centrifugo$ grep linux_amd64.tar.gz centrifugo_6.9.7_checksums.txt | sha256sum -c
centrifugo_6.9.7_linux_amd64.tar.gz: OK
ana@vm:~/centrifugo$ tar xzf centrifugo_6.9.7_linux_amd64.tar.gz centrifugo && ./centrifugo version
Centrifugo v6.9.7 (Go version: go1.26.8)
```

O arquivo compactado tem uns 24 MB e o binário dentro dele 67 MB. **A conferência do checksum é o passo
que as pessoas pulam**, e é ela que diz que o arquivo que chegou é o que foi publicado. O `version` também
informa o Go com que ele foi compilado, que não é o Go da sua máquina e nem precisa ser. Há também uma
imagem de container oficial, `centrifugo/centrifugo`, para quando o runtime de containers da aula 16
estiver instalado.

## Configurando

O `genconfig` escreve um `config.json` com segredos novos, e é por isso que o arquivo é criado legível só
pelo dono:

```
ana@vm:~/centrifugo$ ./centrifugo genconfig && python3 -c "import json; print(sorted(json.load(open(\"config.json\"))))"
['admin', 'client', 'http_api']
ana@vm:~/centrifugo$ python3 - <<'PY'
import json
c = json.load(open("config.json"))
c["http_server"] = {"address": "127.0.0.1", "port": 8000}
c["channel"] = {"without_namespace": {"allow_subscribe_for_client": True}}
json.dump(c, open("config.json", "w"), indent=2)
PY
```

O `client.token.hmac_secret_key` assina os tokens com que os clientes se conectam, o `http_api.key` é a
senha que o seu programa usa para publicar, e `admin` é uma interface web, desligada por padrão. O
`client.allowed_origins` é a verificação de `Origin` da seção 05: vazio, como aqui, ele admite programas
que não mandam `Origin`, e uma página de navegador vai precisar do seu site listado ali. Faltam duas
configurações para esta aula, e umas linhas de Python as acrescentam: escutar só em `127.0.0.1`, porta
8000, e deixar qualquer cliente conectado se inscrever em canais de nome simples como `event-1`. Por
padrão um cliente não tem permissão de se inscrever em nada; configurações de produção agrupam os canais
em namespaces, cada um com suas regras.

Inicie-o em outro terminal com `./centrifugo -c config.json`. O log dele é JSON, como o do boxoffice:

```
ana@vm:~/centrifugo$ grep -e "starting Centrifugo" -e serving .server.log
{"level":"info","version":"6.9.7","runtime":"go1.26.8","pid":22890,"gomaxprocs":4,"engine":"memory","time":"2026-10-22T19:36:08-03:00","message":"starting Centrifugo"}
{"level":"info","time":"2026-10-22T19:36:08-03:00","message":"serving websocket, api endpoints on 127.0.0.1:8000"}
```

**`"engine":"memory"` quer dizer um nó só**, com as inscrições guardadas na própria memória. Um segundo nó
com o mesmo engine não saberia dos inscritos do primeiro; o engine Redis é o que permite que vários os
dividam.

## Um inscrito e um publicador

Um cliente prova quem é com um JWT assinado com o `hmac_secret_key`. Em produção, o boxoffice assinaria um
quando a pessoa entra, com o id dela como subject; para esta aula, o `gentoken` faz um para a usuária
`ana`:

```
ana@vm:~/centrifugo$ ./centrifugo gentoken -c config.json -u ana
HMAC SHA-256 JWT for user "ana" with expiration TTL 168h0m0s:
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhbmEiLCJleHAiOjE3OTMzMTMzNjgsImlhdCI6MTc5MjcwODU2OH0.iAaNeEmF2qOU_CxWAmRyfodQ0oSx7zJOlAEMKnMhjBM
```

Guarde o token, e a chave da API que está na configuração, em duas variáveis do shell:

```sh
TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...   # the whole token gentoken printed
KEY=$(python3 -c 'import json; print(json.load(open("config.json"))["http_api"]["key"])')
```

O protocolo do Centrifugo sobre um WebSocket é feito de comandos JSON, cada um com um id que a resposta
repete. O cliente da seção 05 manda um `connect` com o token e um `subscribe` em `event-1`, e depois
escuta:

```
ana@vm:~/centrifugo$ ~/boxoffice/watchws ws://localhost:8000/connection/websocket 3s '{"id":1,"connect":{"token":"'"$TOKEN"'"}}' '{"id":2,"subscribe":{"channel":"event-1"}}'
connected: 101 Switching Protocols
19:36:09 {"id":1,"connect":{"client":"af68566c-d5c4-48ba-bc9a-f2df5f09959c","version":"6.9.7 OSS","expires":true,"ttl":604800,"ping":25,"pong":true}}
19:36:09 {"id":2,"subscribe":{}}
19:36:10 {"push":{"channel":"event-1","pub":{"data":{"event_id":1,"available":112}}}}
stopped: context deadline exceeded
```

Enquanto ele escutava, a publicação veio de outro terminal, do jeito que o boxoffice a faria:

```
ana@vm:~/centrifugo$ curl -s -H "X-API-Key: $KEY" --json '{"channel":"event-1","data":{"event_id":1,"available":112}}' localhost:8000/api/publish
{"result":{}}
```

A resposta ao `connect` dá o nome da conexão, a versão e quanto falta para o token vencer, em segundos,
604.800, que são as 168 horas que o `gentoken` lhe deu. O `ping` é 25: o Centrifugo manda um ping a cada
25 segundos, e assim conexões ociosas nunca parecem ociosas para um proxy. A resposta ao `subscribe` vem
vazia porque não havia nada a dizer, e o `push` são os dados publicados, entregues ao único inscrito do
canal. A publicação em si respondeu `{"result":{}}`, que é sucesso.

## No boxoffice

A mudança no boxoffice seria pequena. O `listen` fica, e em vez de `h.publish(id, available)` ele manda
`{"channel":"event-N","data":…}` para a API do Centrifugo; o hub, o `liveEvents` e o `liveSocket` vão
embora, e as páginas se conectam ao Centrifugo com um token que o boxoffice emitiu. **O banco continua
sendo de onde a notícia vem; o Centrifugo só substitui a parte que a entrega.** Se essa troca vale um
segundo servidor é a pergunta da próxima seção.
