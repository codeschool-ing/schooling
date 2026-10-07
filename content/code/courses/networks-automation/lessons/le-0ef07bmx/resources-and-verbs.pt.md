---
title: Recursos, verbos e códigos de status
version: 2
---

A aula 1 controlou os roteadores pelo CLI: texto entra, texto sai, e um script que precisa
reconhecer prompts. **Uma API troca a conversa por requisições e respostas estruturadas.** A
maior parte do equipamento de rede vendido hoje tem uma ao lado do CLI, e o tipo mais comum é uma
API REST sobre HTTPS: o equipamento publica **recursos** em endereços, e um cliente age sobre
eles com os **verbos** do HTTP.

Os roteadores do lab têm uma em `https://<router>.example.net/api/v1`, servida pelo `devapid`, o
programa que a seção anterior ligou. Perguntando alguma coisa a ela sem dizer quem você é:

```
ana@ctl:~$ curl -si --cacert lab-ca.pem https://edge1.example.net/api/v1/system
HTTP/1.1 401 Unauthorized
Server: devapi/1.0
Date: Tue, 29 Sep 2026 11:00:42 GMT
Content-Type: application/json
Content-Length: 72
WWW-Authenticate: Bearer realm="devapi"

{
  "error": "missing or unknown token: log in at /api/v1/auth/login"
}
```

Tudo o que uma resposta HTTP carrega está nessa transcrição. A primeira linha é o **código de
status**, `401 Unauthorized`. As linhas depois dela são **cabeçalhos**, um nome e um valor cada;
`Content-Type` diz que o corpo é JSON e `WWW-Authenticate` diz que tipo de credencial o servidor
quer. Depois da linha em branco vem o **corpo**, que aqui explica a recusa numa frase.

Os recursos desta API, e o que cada verbo significa neles:

| recurso | GET | POST | PUT | PATCH | DELETE |
|---|---|---|---|---|---|
| `/system` | lê os dados do equipamento | | | | |
| `/interfaces` | lista as interfaces | | | | |
| `/interfaces/eth2` | lê uma | | | altera alguns campos | |
| `/routes` | lista a tabela de roteamento | | | | |
| `/static-routes` | lista as rotas estáticas | cria uma | | | |
| `/static-routes/192.0.2.128%2F25` | lê uma | | cria ou substitui | | remove |

**O verbo diz o que fazer, e o endereço diz com o quê.** `GET` nunca muda nada, e é isso que o
torna seguro para repetir. `POST` numa coleção cria alguma coisa dentro dela. `PUT` num item
torna esse item exatamente o corpo enviado, existisse ele ou não. `PATCH` altera os campos que
nomeia e deixa o resto. `DELETE` remove.

O código de status é a primeira coisa que um programa deve ler, agrupado pelo primeiro dígito:

| código | significa | visto nesta aula |
|---|---|---|
| 2xx | funcionou | `200 OK`, `201 Created`, `204 No Content` |
| 4xx | a requisição está errada, e enviá-la de novo sem mudança vai falhar de novo | `401`, `403`, `404`, `405`, `409`, `422`, `429` |
| 5xx | o servidor falhou; a mesma requisição pode funcionar mais tarde | nenhum, num dia bom |

**Um 4xx é problema seu de resolver, um 5xx é do servidor.** Essa única distinção decide se um
script deve tentar de novo, e `429 Too Many Requests` é o único 4xx em que tentar de novo, depois
de esperar, é exatamente o certo. A seção 08 é sobre ele.
