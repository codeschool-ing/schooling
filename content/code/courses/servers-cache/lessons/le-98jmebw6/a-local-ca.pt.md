---
title: Uma autoridade certificadora sua, para treinar
version: 1
---

O Pebble está no repositório do Ubuntu, e o `lab.sh install` o pôs no seu servidor. Ele precisa de
três coisas antes de rodar: um certificado para a própria API, que é HTTPS como todo servidor ACME; um
arquivo de configuração pequeno; e uma unidade do systemd para mantê-lo rodando.

O certificado da API é autoassinado, feito exatamente como o da seção anterior, para o nome
`localhost`, porque é ali que o `certbot` vai alcançá-lo:

```
ana@web:~$ sudo mkdir -p /etc/pebble && cd /etc/pebble && sudo openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 365 -subj "/CN=Lab ACME API" -addext "subjectAltName=DNS:localhost" -keyout api.key -out api.crt 2>&1; ls
-----
api.crt
api.key
```

```json
{
  "pebble": {
    "listenAddress": "127.0.0.1:14000",
    "managementListenAddress": "127.0.0.1:15000",
    "certificate": "/etc/pebble/api.crt",
    "privateKey": "/etc/pebble/api.key",
    "httpPort": 80,
    "tlsPort": 443,
    "ocspResponderURL": "",
    "externalAccountBindingRequired": false,
    "certificateValidityPeriod": 7776000
  }
}
```

Três destas linhas são escolhas que vale ler. **`httpPort: 80`** manda o Pebble conferir desafios
HTTP-01 na porta 80, onde a Let's Encrypt confere e onde o Nginx já responde; o padrão do Pebble é
5002, para uma suíte de testes não precisar de root. **`certificateValidityPeriod`** é 7.776.000
segundos, noventa dias, para bater com o que a Let's Encrypt emite. E os dois endereços de escuta
ficam em `127.0.0.1`, então nada de fora desta máquina consegue pedir nada ao Pebble.

```ini
[Unit]
Description=Pebble, Let's Encrypt's ACME server for testing
After=network.target

[Service]
Environment=PEBBLE_VA_NOSLEEP=1 PEBBLE_WFE_NONCEREJECT=0
ExecStart=/usr/bin/pebble -config /etc/pebble/pebble.json
User=nobody

[Install]
WantedBy=multi-user.target
```

As duas variáveis de ambiente desligam duas coisas que o Pebble faz de propósito para testar
clientes: uma pausa aleatória de até quinze segundos antes de cada validação, e a recusa de uma parte
das requisições válidas para ver se o cliente tenta de novo. As duas são úteis para quem escreve um
cliente ACME e só atrasam quem está aprendendo a usar um. Ele roda como `nobody`, que só consegue ler
a chave da API porque as permissões deixam; num servidor de verdade, uma chave legível por todo
usuário seria um defeito. Suba e peça o **diretório** dele, a única URL que um cliente ACME precisa
conhecer:

```
ana@web:~$ sudo chmod 644 /etc/pebble/api.key && sudo systemctl daemon-reload && sudo systemctl start pebble && sleep 1 && systemctl is-active pebble
active
ana@web:~$ curl -s --cacert /etc/pebble/api.crt https://localhost:14000/dir | jq .
{
  "keyChange": "https://localhost:14000/rollover-account-key",
  "meta": {
    "externalAccountRequired": false,
    "termsOfService": "data:text/plain,Do%20what%20thou%20wilt"
  },
  "newAccount": "https://localhost:14000/sign-me-up",
  "newNonce": "https://localhost:14000/nonce-plz",
  "newOrder": "https://localhost:14000/order-plz",
  "revokeCert": "https://localhost:14000/revoke-cert"
}
```

Cada passo do protocolo é uma URL dessa lista. Os nomes são piadas do próprio Pebble; o diretório da
Let's Encrypt tem as mesmas chaves com URLs mais sóbrias.

## A raiz em que ninguém confia ainda

O Pebble gera uma raiz e uma intermediária novas **toda vez que sobe**, e publica a raiz na porta de
gerenciamento. Busque-a e grave onde o Ubuntu procura raízes extras:

```
ana@web:~$ curl -s --cacert /etc/pebble/api.crt https://localhost:15000/roots/0 | sudo tee /usr/local/share/ca-certificates/pebble-root.crt | openssl x509 -noout -subject
subject=CN = Pebble Root CA 435937
```

O número depois do nome é aleatório, e é assim que se distinguem duas raízes do Pebble. Nada confia
nela ainda; a seção depois da próxima manda esta máquina confiar. Esse é o passo que não tem
equivalente com a Let's Encrypt, cujas raízes já estão em `/etc/ssl/certs` em todo sistema, e é o
motivo de um certificado do Pebble só funcionar na máquina que escolheu confiar nele.
