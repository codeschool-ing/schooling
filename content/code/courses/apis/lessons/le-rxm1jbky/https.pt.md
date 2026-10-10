---
title: HTTPS com uma autoridade só sua
version: 1
---

**HTTPS é HTTP dentro de TLS, e o TLS faz dois trabalhos: cifra a conversa e prova ao cliente que o
servidor é aquele que ele pediu.** O segundo trabalho é o que as pessoas esquecem, e quem o faz é um
certificado: uma chave pública e uma lista de nomes, assinadas por uma autoridade em que o cliente já
confia.

A ideia de que HTTPS só importa na página de login não sobrevive às lições 7 a 9. Todas elas terminam
com um segredo viajando em toda requisição: uma senha na autenticação Basic, um token, um cookie de
sessão. Eis o que a autenticação Basic põe no fio, e o que qualquer um que leia esses bytes recupera
dele:

```
ana@api:~/shelf$ curl -sv -u ana:correct-horse localhost:8000/v1/books/1 2>&1 | grep -i '^> authorization'
> Authorization: Basic YW5hOmNvcnJlY3QtaG9yc2U=
ana@api:~/shelf$ echo YW5hOmNvcnJlY3QtaG9yc2U= | base64 -d; echo
ana:correct-horse
```

Base64 é um jeito de escrever bytes como texto, não uma cifra, e o segundo comando não precisa de
chave. Sobre HTTP simples, esse cabeçalho atravessa toda rede entre o cliente e o servidor exatamente
como impresso, em toda requisição. **Sobre HTTPS o mesmo cabeçalho fica dentro da cifra**, e quem
observa descobre que servidor foi contatado e quanto foi enviado, mas não o quê.

## Uma autoridade só sua

Uma autoridade pública só assina certificados para nomes da internet pública, e uma VM chamada `api`
não tem nenhum. Então o laboratório cria a própria autoridade, uma CA, e faz com que ela assine um
certificado para o servidor. Todo passo é `openssl`, que a lição 1 instalou. Crie um diretório para os
arquivos, dentro de `~/shelf`, e entre nele com `cd tls`:

```
ana@api:~/shelf$ mkdir tls
```

Depois, a autoridade: uma chave privada e um certificado que assina a si mesmo, válido por trinta
dias. O `-----` é tudo o que o `openssl req` imprime quando nada dá errado:

```
ana@api:~/shelf/tls$ openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -noenc -days 30 -subj '/CN=shelf lab CA' -keyout ca.key -out ca.crt
-----
```

A chave do próprio servidor, e uma requisição de assinatura de certificado, que leva a chave pública
do servidor até a autoridade:

```
ana@api:~/shelf/tls$ openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -noenc -subj '/CN=localhost' -keyout server.key -out server.csr
-----
```

**Os nomes para os quais o certificado vale vão em `subjectAltName`.** Os navegadores conferem essa
lista e ignoram o `CN` do assunto, então um certificado sem ela é recusado por todo navegador atual.
Este vale para o nome `localhost` e o endereço `127.0.0.1`:

```
ana@api:~/shelf/tls$ printf 'subjectAltName = DNS:localhost, IP:127.0.0.1\n' > server.ext
ana@api:~/shelf/tls$ openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 30 -extfile server.ext -out server.crt
Certificate request self-signature ok
subject=CN = localhost
```

O certificado nomeia o assunto, a autoridade que o assinou e os dois nomes que cobre:

```
ana@api:~/shelf/tls$ openssl x509 -in server.crt -noout -subject -issuer -ext subjectAltName
subject=CN = localhost
issuer=CN = shelf lab CA
X509v3 Subject Alternative Name: 
    DNS:localhost, IP Address:127.0.0.1
```

Os dois arquivos `.key` são os segredos. Quem tem o `server.key` pode se passar por este servidor, e
quem tem o `ca.key` pode criar um certificado para qualquer nome, e tudo o que confia no `ca.crt` vai
acreditar nele. Deixe-os legíveis só por você:

```
ana@api:~/shelf/tls$ chmod 600 ca.key server.key; ls -l
total 28
-rw-rw-r-- 1 ana ana 587 Oct 10 01:23 ca.crt
-rw------- 1 ana ana 241 Oct 10 01:23 ca.key
-rw-rw-r-- 1 ana ana  41 Oct 10 01:23 ca.srl
-rw-rw-r-- 1 ana ana 599 Oct 10 01:23 server.crt
-rw-rw-r-- 1 ana ana 355 Oct 10 01:23 server.csr
-rw-rw-r-- 1 ana ana  45 Oct 10 01:23 server.ext
-rw------- 1 ana ana 241 Oct 10 01:23 server.key
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 275\" role=\"img\" aria-label=\"A chave da CA assina o certificado do servidor. O servidor guarda server.key e server.crt e apresenta o certificado. O curl guarda ca.crt, confere a assinatura com ele e confere se o nome pedido está no subjectAltName. Sem ca.crt, ou com um nome fora da lista, o curl recusa.\"><defs><marker id=\"l13-tls-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ca.key</text><text x=\"120.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">guardada em segredo, assina</text><rect x=\"20\" y=\"120\" width=\"200\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ca.crt</text><text x=\"120.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pública, entregue aos clientes</text><rect x=\"270\" y=\"20\" width=\"200\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">server.crt</text><text x=\"370.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">DNS:localhost, IP:127.0.0.1</text><rect x=\"270\" y=\"120\" width=\"200\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">server.key</text><text x=\"370.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">guardada em segredo, pelo secure.py</text><rect x=\"520\" y=\"70\" width=\"180\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">curl --cacert ca.crt</text><line x1=\"220\" y1=\"50\" x2=\"268\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l13-tls-ah)\"></line><text x=\"244.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">assina</text><line x1=\"370\" y1=\"80\" x2=\"370\" y2=\"120\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"470\" y1=\"70\" x2=\"518\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l13-tls-ah)\"></line><text x=\"494\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">apresenta</text><line x1=\"120\" y1=\"180\" x2=\"120\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"120\" y1=\"198\" x2=\"610\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"610\" y1=\"198\" x2=\"610\" y2=\"132\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l13-tls-ah)\"></line><text x=\"360\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">confia</text><text x=\"360\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">O curl confere duas coisas: a assinatura leva a uma CA em que ele confia, e o nome pedido está na lista.</text><text x=\"360\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Se uma falhar, a conexão termina antes de um byte de HTTP ser enviado.</text></svg>", "caption": "Quem assina o quê e quem confia em quem. As duas chaves nunca saem da máquina que as criou; os dois certificados são públicos."}
```

## O servidor, e um cliente que confere

Pare o `secure.py` com `Ctrl+C` e inicie-o no modo HTTPS, a partir de `~/shelf`:

```sh
python3 secure.py --tls
```

```
secure shelf on https://127.0.0.1:8443, pages allowed: http://localhost:8080
```

Perguntado sem saber da autoridade nova, o curl recusa, porque nada em que ele confia assinou o
certificado:

```
ana@api:~/shelf$ curl -sS https://localhost:8443/v1/books/1
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

Com o `ca.crt`, ele confere a assinatura, acha `localhost` na lista, e a requisição passa:

```
ana@api:~/shelf$ curl -sS --cacert tls/ca.crt https://localhost:8443/v1/books/1
{"id": 1, "title": "Dom Casmurro", "stock": 12}
```

E perguntado com um nome que o certificado não lista, ele recusa de novo, mesmo com a autoridade certa.
O `--resolve` manda o nome `shelf.test` para `127.0.0.1` sem consultar DNS nenhum:

```
ana@api:~/shelf$ curl -sS --cacert tls/ca.crt --resolve shelf.test:8443:127.0.0.1 https://shelf.test:8443/v1/books/1
curl: (60) SSL: no alternative certificate subject name matches target host name 'shelf.test'
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

**Nunca responda a esse erro desligando a verificação.** O `-k` do curl, o `verify=False` do Python e
os parentes deles em toda linguagem fazem o erro sumir removendo o segundo trabalho do TLS: a conexão
continua cifrada, até quem quer que tenha respondido. As respostas certas são as de cima: o
certificado da autoridade entregue ao cliente, ou um certificado que lista o nome.

O `openssl s_client` mostra a mesma verificação por dentro: a cadeia do certificado do servidor até a
autoridade, cada elo conferido, e a versão do TLS combinada:

```
ana@api:~/shelf$ openssl s_client -connect 127.0.0.1:8443 -CAfile tls/ca.crt </dev/null 2>&1 | grep -E '^depth|^verify|^New,|Verify return code'
depth=1 CN = shelf lab CA
verify return:1
depth=0 CN = localhost
verify return:1
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
Verify return code: 0 (ok)
```

Em produção a autoridade é pública, em geral a Let's Encrypt, que emite certificados
para um domínio que você controla a um programa no servidor que os renova sozinho. Uma CA privada como esta serve para um laboratório e para
serviços que só conversam entre si dentro de uma organização. E o processo que guarda o certificado
em geral não é a API: um proxy reverso como o nginx o guarda e passa HTTP simples para a API na mesma
máquina. Esse arranjo, a terminação de TLS, é assunto do curso `servers-cache`.

## HSTS

HTTPS sozinho deixa uma brecha: a primeira requisição. Alguém digita `shop.example` sem esquema, o
navegador tenta `http://`, e essa única requisição em texto puro pode ser respondida por qualquer um
na rede no meio do caminho. **O `Strict-Transport-Security` fecha a brecha a partir da segunda
visita.** Ele diz ao navegador para usar só HTTPS com esse host pelo número de segundos indicado, para
reescrever ele mesmo todo link `http://`, e para não dar ao usuário nenhum jeito de passar por cima de
um erro de certificado.

```
ana@api:~/shelf$ curl -si --cacert tls/ca.crt https://localhost:8443/v1/books/1 | grep -i '^strict'
Strict-Transport-Security: max-age=31536000
```

`max-age=31536000` é um ano. Duas regras vêm junto. O cabeçalho só é mandado sobre HTTPS, porque sobre
HTTP simples qualquer um no meio do caminho poderia removê-lo ou forjá-lo, e os navegadores o ignoram ali. O modo simples do `secure.py` não o manda, como toda transcrição antes desta seção mostra. E é uma promessa difícil de desfazer. Um navegador que o viu recusa HTTP simples por um ano, então um site de
verdade começa com poucos minutos e aumenta o número quando o HTTPS estiver comprovadamente funcionando
em todo lugar. `includeSubDomains` o estende a todo subdomínio, e `preload` pede aos navegadores que o
tragam embutido, o que fecha até a primeira visita. O curl só o aplica quando alguém pede, com
`--hsts` e um arquivo onde guardá-lo; o HSTS é uma defesa do navegador.
