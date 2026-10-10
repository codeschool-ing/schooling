---
title: Num cabeçalho, nunca numa URL
version: 1
---

**Uma credencial viaja num cabeçalho, nunca no endereço.** Algumas APIs aceitam o token como parâmetro
da query, `?access_token=…` ou `?api_key=…`, porque é cômodo: um link que funciona sozinho, colado num
navegador. A comodidade é o problema. Um endereço é anotado em mais lugares do que alguém consegue
acompanhar, e um cabeçalho não.

O `keys.py` não aceita token na URL. Aqui está o mesmo token válido enviado dos dois jeitos, com um
servidor recém-iniciado para que o log tenha só estas requisições:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/login -H 'Content-Type: application/json' -d '{"username": "ana", "password": "river-lamp-42"}' -o login.json
ana@api:~/shelf$ curl -s -H "Authorization: Bearer $(jq -r .token login.json)" localhost:8000/v1/books/1
{"id": 1, "title": "Dom Casmurro", "stock": 12}
ana@api:~/shelf$ curl -s "localhost:8000/v1/books/1?access_token=$(jq -r .token login.json)"
{"error": "authentication required"}
```

A primeira requisição funciona e a segunda é recusada, o que parece encerrar o assunto. Não encerra.
Isto é o que o segundo terminal imprimiu:

```
keys on http://127.0.0.1:8000
auth: login ok user='ana'
127.0.0.1 - - [10/Oct/2026 01:26:07] "POST /v1/login HTTP/1.1" 200 -
auth: bearer ok user='ana'
127.0.0.1 - - [10/Oct/2026 01:26:08] "GET /v1/books/1 HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:26:08] "GET /v1/books/1?access_token=kvtHDkMYde-nVBH0REgczY99ZtzqEC-Q53SoZ8zOYHc HTTP/1.1" 401 -
```

**A requisição recusada pôs o token no log do próprio servidor.** O servidor registra toda linha de
requisição, recusadas incluídas, com o status ao lado, e a linha da requisição inclui a query string. A versão com
cabeçalho não deixou nada: `GET /v1/books/1`. O token naquela linha valia quando foi registrado, e
continua valendo pelo resto da hora dele, num arquivo que mais gente consegue ler do que o banco.

O `keys.py` poderia limpar a própria linha de requisição, e continuaria sendo o único a fazer isso. A
mesma URL também vai parar:

- no log de acesso de todo proxy na frente do servidor, como o proxy reverso que o próximo curso,
  Servidores Web e Cache, põe na frente de uma aplicação;
- no histórico do navegador, se alguém a abriu ali, e no cabeçalho `Referer` que o navegador envia ao
  próximo site para onde a página aponta;
- na mensagem de chat, no chamado ou na captura de tela em que alguém a cola, porque um endereço parece
  seguro de compartilhar.

Então a defesa fica na origem: **o servidor recusa credenciais na URL, e a documentação nunca mostra
uma ali.** Um token que esteve numa URL é tratado como vazado. A correção é a que a seção sobre tokens
bearer mostrou: revogá-lo com `/v1/logout` e entrar de novo.
