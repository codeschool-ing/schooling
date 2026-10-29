---
title: Um certificado seu, para um nome seu
version: 1
---

**Cada passo que um host dá para servir um site por HTTPS pode ser dado no seu computador, com uma
diferença: a autoridade que assina é sua, então só os programas que você avisa confiam nela.** Essa
diferença é toda a lição desta seção, porque é a que um navegador impõe.

## Uma autoridade e um certificado

O `openssl`, que todo Linux e todo Mac têm, faz as duas metades. Primeiro uma autoridade: uma chave e um
certificado assinado por ela mesma que diz *eu sou a Planner lab CA*. Depois uma chave para o site, um
pedido citando `planner.test`, e a assinatura da autoridade nele. As chaves são chaves de curva elíptica,
na curva P-256, o tipo que a maioria dos certificados da web usa hoje:

```
ana@dev:~$ mkdir -p ~/tls && cd ~/tls
ana@dev:~/tls$ openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out ca.key
ana@dev:~/tls$ openssl req -x509 -key ca.key -out ca.crt -days 30 -subj "/CN=Planner lab CA"
ana@dev:~/tls$ openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out planner.key
ana@dev:~/tls$ openssl req -new -key planner.key -out planner.csr -subj "/CN=planner.test"
ana@dev:~/tls$ openssl x509 -req -in planner.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out planner.crt -days 30 -extfile <(printf "subjectAltName=DNS:planner.test")
Certificate request self-signature ok
subject=CN = planner.test
ana@dev:~/tls$ openssl x509 -in planner.crt -noout -subject -issuer -ext subjectAltName
subject=CN = planner.test
issuer=CN = Planner lab CA
X509v3 Subject Alternative Name: 
    DNS:planner.test
```

O último comando leu o certificado de volta: emitido **para** `planner.test`, **pela** autoridade do
laboratório, e válido **para** o único nome nos subject alternative names dele. Trinta dias é de
propósito; uma autoridade de laboratório cuja chave fica numa pasta pessoal não deve durar mais que o
laboratório.

## Servindo

Construa o planner e inicie o host crescido com o certificado, na porta 8443:

```
ana@dev:~/planner$ CERT=~/tls/planner.crt KEY=~/tls/planner.key node host.mjs dist 8443
serving dist on https://127.0.0.1:8443, and redirecting http://127.0.0.1:8080
```

`planner.test` não existe em lugar nenhum, então o `curl` é informado de onde ele mora com `--resolve`,
que prende um nome a um endereço por um comando sem tocar em configuração nenhuma. Peça a página como um
estranho pediria, e depois como alguém que confia na autoridade do laboratório:

```
ana@dev:~/planner$ curl -sS --resolve planner.test:8443:127.0.0.1 https://planner.test:8443/ -o /dev/null
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
ana@dev:~/planner$ curl -sS --cacert ~/tls/ca.crt --resolve planner.test:8443:127.0.0.1 https://planner.test:8443/ -o /dev/null -w '%{http_code}\n'
200
ana@dev:~/planner$ curl -sS --cacert ~/tls/ca.crt https://127.0.0.1:8443/ -o /dev/null
curl: (60) SSL: no alternative certificate subject name matches target host name '127.0.0.1'
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

Três respostas, e cada uma é também a do navegador:

- **sem a autoridade, recusado**: o `curl` não conseguiu ligar o certificado a nenhuma autoridade em que
  confia. Um navegador mostra aqui um aviso de página inteira, e esse aviso é a resposta certa: um
  certificado que qualquer um consegue fazer não prova nada para quem não o fez.
- **com a autoridade, um 200**.
- **com a autoridade mas o nome errado**, `127.0.0.1` em vez de `planner.test`, recusado de novo. O
  certificado é válido, e é para outro nome, que é exatamente o que um certificado existe para pegar.

Navegadores guardam a própria lista de autoridades confiáveis, e acrescentar a do laboratório a ela é o
que uma ferramenta como o `mkcert` automatiza para desenvolvimento local. Esse passo não foi executado
para este curso; o `curl --cacert` mostrou a mesma confiança sem mudar nada no computador.

## HTTP, redirecionado

O host crescido também responde HTTP simples na porta 8080, e só com um redirecionamento:

```
ana@dev:~/planner$ curl -sI --resolve planner.test:8080:127.0.0.1 http://planner.test:8080/course/git
HTTP/1.1 308 Permanent Redirect
location: https://planner.test:8443/course/git
Date: Fri, 23 Oct 2026 23:04:15 GMT
Connection: keep-alive
Keep-Alive: timeout=5
```

**308, Permanent Redirect**, para o mesmo caminho por HTTPS. É o que os quatro hosts fazem na porta 80
quando um domínio tem certificado, e a maioria faz sem ser pedida. Um navegador que já viu o site uma vez
pode pular essa primeira requisição sem criptografia quando o site manda um cabeçalho
`Strict-Transport-Security`; esse cabeçalho, e os outros que um site deve mandar, são a aula 8 de
front-quality.

Pare o servidor com Ctrl-C. A pasta `~/tls` guarda a chave privada de uma autoridade: apague-a quando esta
aula terminar, as próximas seções não precisam dela.
