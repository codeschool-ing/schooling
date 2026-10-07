---
title: Uma identidade para uma máquina
version: 1
---

O proxy precisa provar quem é. Ele tem um **certificado de cliente** (*client certificate*), emitido
pela CA da empresa do mesmo jeito que a aula 12 emitiu o de um servidor:

```
root@www:~# openssl x509 -in tls/www-client.crt -noout -subject -issuer -dates -ext extendedKeyUsage
subject=CN = www-client
issuer=O = Example Corp, CN = Example Corp Issuing CA
notBefore=Sep 28 00:00:00 2026 GMT
notAfter=Dec 28 00:00:00 2026 GMT
X509v3 Extended Key Usage: 
    TLS Web Client Authentication
```

`CN = www-client`, emitido pela CA emissora, válido por três meses, com um uso estendido de chave
(*extended key usage*) de **autenticação de cliente**: ele pode provar uma identidade a um servidor e
não pode ser usado para rodar um. A chave privada nunca sai de `www`. Apresentado à mão:

```
root@www:~# curl -sS --resolve app.corp.example.com:8443:192.168.20.10 --cert tls/www-client.crt --key tls/www-client.key https://app.corp.example.com:8443/health
status: ok
```

`status: ok`. Em seguida a configuração do proxy muda para alcançar a aplicação por TLS, verificando o
certificado da aplicação e também apresentando o seu. Em `/etc/nginx/sites-enabled/shop` no `www`,
todo `proxy_pass http://192.168.20.10:8080;` vira as sete linhas impressas abaixo, de `proxy_pass` a
`proxy_ssl_certificate_key`, e `nginx -s reload` as põe em vigor:

```
root@www:~# grep -m1 -A8 "location / {" /etc/nginx/sites-enabled/shop | sed "s/^ *//"
location / {
proxy_pass https://192.168.20.10:8443;
proxy_ssl_name app.corp.example.com;
proxy_ssl_server_name on;
proxy_ssl_verify on;
proxy_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt;
proxy_ssl_certificate /root/tls/www-client.crt;
proxy_ssl_certificate_key /root/tls/www-client.key;
proxy_set_header Host $host;
```

**As duas pontas agora provam quem são**: `proxy_ssl_verify` confere que o servidor é mesmo
`app.corp.example.com`, e `proxy_ssl_certificate` apresenta `www-client` em troca. Isso é **TLS
mútuo** (*mutual TLS*, mTLS). Ele também fecha a brecha que a aula 3 deixou aberta: o trecho da DMZ
até os servidores trafegava em claro, e agora é cifrado. Da internet, passando por tudo isso:

```
ana@remote:~$ curl -s https://www.example.com/health
status: ok
```

O cliente não percebe nada. Entre o proxy e a aplicação, a requisição agora carrega a identidade do
proxy, provada com uma chave que a rede não tem como fornecer.

**Identidades de máquina têm um problema difícil, que é a distribuição.** Todo serviço precisa de uma
chave e de um certificado, renovados antes de expirar e revogados quando o serviço é desativado. Fazer
isso à mão para dois serviços foi o que este laboratório fez; fazer para duzentos é a razão de existirem
as malhas de serviço (*service meshes*) e a automação de certificados, com validades medidas em horas,
para que a revogação (aula 12) importe menos.
