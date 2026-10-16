---
title: Quem é o cliente
version: 1
---

**Um limite por cliente precisa de uma resposta para "que cliente é este?", e a resposta é a chave sob
a qual o limite é guardado.** Há três candidatas comuns, e elas não são igualmente boas:

| chave | de onde vem | o que dá errado |
|---|---|---|
| **chave de API** | um cabeçalho que o cliente envia em toda requisição | nada, desde que as chaves sejam emitidas por cliente e mantidas em segredo |
| **conta** | o usuário a quem pertence uma sessão ou um token (aulas 8 e 9) | nada, depois que a requisição foi autenticada; antes disso não há conta |
| **endereço IP** | a conexão por onde a requisição chegou | muita gente divide um, uma pessoa pode ter muitos, e o cabeçalho que o carrega pode ser digitado por qualquer um |

O limitador desta aula usa uma **chave de API**, enviada como `X-API-Key`. É a coisa mais simples que
nomeia um cliente em vez de uma máquina, e uma chave pertence a alguém que se cadastrou para tê-la,
então o limite pode variar conforme o plano contratado. Como uma chave é emitida e guardada é a aula
7; aqui, três chaves fixas de demonstração estão escritas no programa.

## Por que o endereço é a fraca

Ele parece de graça: toda requisição chega de um endereço, e nenhum cliente precisa fazer nada. Ele
nomeia a coisa errada nas duas direções.

**Muitos clientes atrás de um endereço.** Um escritório, uma universidade ou uma operadora de celular
põe centenas ou milhares de pessoas atrás de poucos endereços IPv4 públicos com NAT. Um limite por
endereço trata o escritório inteiro como um cliente, e o colega que roda um script faz todos os outros
serem recusados.

**Um cliente atrás de muitos endereços.** Um único cliente IPv6 costuma receber um `/64`, que tem mais
endereços do que a internet IPv4 inteira, e um cliente que quiser um endereço novo a cada requisição
pode ter. Um limite por endereço não detém ninguém que esteja tentando.

**E o endereço que você lê pode não ser o do cliente.** Quando um proxy ou um balanceador de carga fica
na frente da API, toda conexão chega do proxy, e o endereço do cliente viaja num cabeçalho, normalmente
`X-Forwarded-For`. Um cabeçalho é texto que o cliente pode escrever. Contra o `rest.py` da aula 1, com
`-v` para o curl mostrar o que enviou e o que voltou:

```
ana@api:~/shelf$ curl -sv -H 'X-Forwarded-For: 203.0.113.7' localhost:8000/v1/books/1 2>&1 | grep -E '^[<>] (GET|X-Forwarded|HTTP)'
> GET /v1/books/1 HTTP/1.1
> X-Forwarded-For: 203.0.113.7
< HTTP/1.1 200 OK
```

O curl pôs o cabeçalho porque mandaram, com um endereço de uma faixa reservada para documentação, e o
servidor aceitou a requisição como qualquer outra. O segundo terminal mostra de onde a requisição
veio de verdade:

```
127.0.0.1 - - [10/Oct/2026 01:48:43] "GET /v1/books/1 HTTP/1.1" 200 -
```

**O `X-Forwarded-For` só é confiável quando o seu próprio proxy o escreveu**: o proxy sobrescreve o
cabeçalho ou acrescenta a ele, e a aplicação lê só a parte que o proxy pôs e ignora o resto. Uma
aplicação que lê o cabeçalho diretamente, sem proxy próprio na frente, está limitando pelo que o
cliente resolveu digitar. Configurar isso direito é trabalho do proxy, e o `servers-cache`, o curso
depois deste, é onde os proxies são montados.

## Onde o endereço ainda é tudo o que você tem

Algumas requisições vêm antes de existir qualquer chave ou conta: o formulário de cadastro, o de login,
o de "esqueci minha senha". Ali o endereço, com todos os defeitos, é a única coisa a contar, e ele
costuma ser combinado com uma contagem por **alvo**: por e-mail em que se tenta entrar, para que mil
endereços adivinhando a senha de uma pessoa ainda sejam um contador só. A aula 10 trata da senha em
si, e a última seção desta aula volta às tentativas de login.

O `limits.py` responde a uma requisição sem chave válida com `401` e não conta nada, para manter o
programa curto. Na frente de uma API de verdade essas requisições também são limitadas, por endereço,
pelo motivo acima: uma enxurrada de requisições sem chave continua sendo uma enxurrada.
