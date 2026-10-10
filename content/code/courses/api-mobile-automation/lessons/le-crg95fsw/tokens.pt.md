---
title: Tokens, e o endpoint que os entrega
version: 1
---

**Um token é uma credencial de vida curta que um programa obtém apresentando uma de vida longa.** O
programa prova quem é uma vez, a um endpoint de token, e recebe uma string que vale por essa prova
até expirar. Toda requisição seguinte leva o token, nunca o segredo original. Se um token vaza, ele
serve por minutos; se o segredo vazasse em toda requisição, serviria até alguém perceber.

Os pedidos do boxoffice funcionam assim, com o grant **client credentials** do OAuth 2.0, o feito
para um programa agindo por conta própria, sem pessoa envolvida: uma suíte de testes, um job
noturno, outro servidor. O programa manda três campos de formulário para `POST /oauth/token`: o tipo
de grant, o `client_id` e o `client_secret`. O boxoffice conhece dois clientes, e a linha da lição 1
usou o primeiro:

| cliente | segredo | escopo |
|---|---|---|
| `ci-tests` | `ci-secret` | `orders:read orders:write` |
| `auditor` | `auditor-secret` | `orders:read` |

## A resposta, linha por linha

```
ana@laptop:~/boxoffice$ curl -si localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret
HTTP/1.1 200 OK
content-type: application/json
cache-control: no-store
Date: Sat, 10 Oct 2026 19:43:07 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{"access_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJjaS10ZXN0cyIsInNjb3BlIjoib3JkZXJzOnJlYWQgb3JkZXJzOndyaXRlIiwiaWF0IjoxNzkxNjYxMzg3LCJleHAiOjE3OTE2NjIyODd9.ZYNygARAi8VHK-A59GydT_uT2q6wG8ebDb8D67_sJQU","token_type":"Bearer","expires_in":900,"scope":"orders:read orders:write"}
```

O corpo tem quatro campos, e cada um é algo a conferir:

| campo | diz | o que testar |
|---|---|---|
| `access_token` | o próprio token, uma string longa que a seção 04 desmonta | que é aceito onde deve e em nenhum outro lugar |
| `token_type` | como mandá-lo: `Bearer` significa no cabeçalho `Authorization`, como `Bearer <token>` | que diz `Bearer` |
| `expires_in` | quantos segundos ele vive, aqui 900, um quarto de hora | que ele para mesmo de funcionar então; a seção 04 confere |
| `scope` | o que o token pode fazer | que um token com menos escopo é recusado no resto; a seção 05 confere |

Um cabeçalho importa tanto quanto o corpo. **`cache-control: no-store` proíbe qualquer cache de
guardar a resposta**, para que nenhum proxy entre o programa e o servidor segure uma cópia de um
token válido para a próxima pessoa receber. O OAuth exige isso neste endpoint (RFC 6749, §5.1),
e uma resposta de token sem ele é um defeito mesmo com todo campo do corpo certo. A mesma seção pede
também `Pragma: no-cache`, a grafia HTTP/1.0 da mesma instrução, e o boxoffice não o manda; isso só
importa para caches velhos o bastante para ignorar `cache-control`, e um relatório pode chamá-lo de
menor.

`expires_in` é relativo: "900 segundos a partir de agora". Um cliente calcula quando buscar um token
novo a partir do momento em que recebeu este, e é por isso que um cliente bem-comportado pede de novo
um pouco antes do fim do prazo em vez de esperar uma recusa.

## Um segredo errado

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=wrong
{"error":"invalid_client"}
```

`invalid_client`, na forma de erro do próprio OAuth, que a lição 2 seção 05 explicou. A resposta é a
mesma quer o cliente exista e o segredo esteja errado, quer o cliente nem exista, pelo mesmo motivo
que as recusas da chave da equipe eram iguais na seção 02.

## Guardando numa variável

O token é longo, então vai para uma variável do shell, como na lição 1, e o resto da lição usa
`$TOKEN`:

```
ana@laptop:~/boxoffice$ TOKEN=$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)
```

`$(…)` roda o comando de dentro e põe no lugar o que ele imprimiu; `jq -r .access_token` imprime o
token sem aspas. A variável vive até o terminal ser fechado. Um token dura quinze minutos, então se
uma requisição mais adiante nesta lição responder `token expired`, rode esta linha de novo.
