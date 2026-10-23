---
title: Escolhendo um código de status
version: 1
---

**Um código de status é a primeira coisa que um cliente lê, e muitas vezes a única que um programa
lê.** O corpo explica; o código decide o que acontece em seguida: tentar de novo, desistir, perguntar
ao usuário, seguir um link. Então cada código que o serviço links manda é escolhido para deixar óbvio
o próximo passo do cliente. Estes são todos, depois desta aula:

| status | quando o serviço links o manda | o que o cliente deve fazer |
|---|---|---|
| 200 OK | um link, ou a lista do administrador | usar o corpo |
| 201 Created | um link novo, com `Location` | guardar o código |
| 204 No Content | um link apagado | nada mais |
| 302 Found | um link curto seguido | ir até o `Location` |
| 304 Not Modified | a cópia do cliente ainda está atual | usar a cópia que tem |
| 400 Bad Request | um corpo, um código ou um limite que nunca dariam certo | corrigir a requisição; tentar de novo é inútil |
| 401 Unauthorized | a chave de administração falta ou está errada | mandar a chave |
| 404 Not Found | não existe esse link, ou esse caminho | parar de perguntar |
| 405 Method Not Allowed | um método que o caminho não tem, com `Allow` | usar um daqueles |
| 406 Not Acceptable | um `Accept` que o serviço não consegue atender | pedir JSON |
| 413 Content Too Large | um corpo acima de 1 kB | mandar menos |
| 500 Internal Server Error | erro nosso, registrado | tentar depois, ou nos avisar |

Duas linhas dessa tabela guardam a distinção que vale aprender. **4xx quer dizer que o cliente deve
mudar algo; 5xx, que o servidor deve.** Um serviço que responde os próprios bugs com 400 diz a todo
cliente que o bug é dele, e um serviço que responde entrada ruim com 500 acorda alguém de madrugada
por um erro de digitação numa requisição.

Alguns códigos que o serviço não manda são igualmente deliberados. Não há 422 para um corpo que foi
lido mas não passou na validação: um 400 com a lista de problemas diz a mesma coisa, e muitas APIs
usam um ou outro. Não há 429 para requisições demais, porque nada aqui limita taxa ainda; um proxy na
frente pode, o que o curso `servers-cache` monta. O curso `apis`, dois cursos adiante, toma essas
decisões para uma API inteira, com versionamento e erros num formato padrão, e esta tabela é o
primeiro rascunho desse tipo de decisão.
