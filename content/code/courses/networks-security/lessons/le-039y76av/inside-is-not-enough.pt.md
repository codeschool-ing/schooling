---
title: Estar dentro não basta
version: 1
---

A aplicação ganha uma porta de entrada que verifica identidade, e as máquinas precisam de identidades
para mostrar a ela. Salve este script ao lado do `nslab.sh` e rode-o quando o laboratório estiver de
pé:

```schooling-example
{"language": "sh", "file": "identities.sh", "parts": [{"code": "#!/bin/bash\n# identities.sh: lesson 20's certificates, issued from the lab's CA.\nset -euo pipefail\ncd /lab/ca\nmk() {  # mk NAME EXTENSIONS START END SAN\n  openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj \"/CN=$1\" -keyout \"$1.key\" -out \"$1.csr\" 2>/dev/null\n  { sed -n \"/^\\[$2\\]/,/^\\[/p\" ca.cnf | sed '$d'; if [ -n \"$5\" ]; then echo \"subjectAltName = $5\"; fi; } > \"$1.ext\"\n  openssl ca -batch -config ca.cnf -cert issuing.crt -keyfile issuing.key -extfile \"$1.ext\" -extensions \"$2\" -startdate \"$3\" -enddate \"$4\" -in \"$1.csr\" -out \"$1.crt\" -notext 2>/dev/null\n}\nmk app.corp.example.com server 20260928000000Z 20261228000000Z DNS:app.corp.example.com\nmk www-client client 20260928000000Z 20261228000000Z \"\"\nmk www-client-old client 20260601000000Z 20260831000000Z \"\"", "note": "Três certificados emitidos pela CA emissora da empresa, com datas fixas, como a aula 12 emitiu um: `app.corp.example.com` para o listener TLS da aplicação, `www-client` para o proxy provar quem é, e um certificado de cliente antigo do proxy, que expirou em 31 de agosto de 2026. Rode-o no seu próprio computador, depois do `nslab.sh up`, com `sudo bash identities.sh`."}, {"code": "mkdir -p /lab/app/root/tls /lab/www/root/tls\ncat app.corp.example.com.crt issuing.crt > /lab/app/root/tls/app.crt; cp app.corp.example.com.key /lab/app/root/tls/app.key\ncat issuing.crt root.crt > /lab/app/root/tls/clients-ca.crt\ncp www-client.crt www-client.key www-client-old.crt www-client-old.key /lab/www/root/tls/\nchmod 600 /lab/app/root/tls/*.key /lab/www/root/tls/*.key", "note": "Cada um vai para a máquina que o usa, com a sua chave, em `/root/tls`. O `app` recebe também os dois certificados de CA contra os quais vai conferir os clientes."}]}
```

Em `app`, o nginx então escuta na 8443 com TLS e **exige um certificado de cliente** assinado pela CA
da empresa, e, entre os válidos, admite só o do proxy. O arquivo abaixo é o `/root/nginx-app.conf`
de lá:

```
root@app:~# cat nginx-app.conf
pid /var/log/lab/nginx.pid;
error_log /var/log/lab/nginx-error.log;
events {}
http {
    log_format who "$remote_addr $ssl_client_s_dn $ssl_client_verify $request_uri $status";
    access_log /var/log/lab/nginx-access.log who;
    server {
        listen 192.168.20.10:8443 ssl;
        server_name app.corp.example.com;
        ssl_certificate     /root/tls/app.crt;
        ssl_certificate_key /root/tls/app.key;
        ssl_protocols TLSv1.3;
        ssl_client_certificate /root/tls/clients-ca.crt;
        ssl_verify_client on;
        ssl_verify_depth 2;
        location / {
            if ($ssl_client_s_dn != "CN=www-client") { return 403; }
            proxy_pass http://192.168.20.10:8080;
        }
    }
}
root@app:~# nginx -c /root/nginx-app.conf -t 2>&1 | tail -1; nginx -c /root/nginx-app.conf
nginx: configuration file /root/nginx-app.conf test is successful
```

Leia o bloco `server` das linhas de segurança para baixo. `ssl_client_certificate` nomeia as CAs cujos
certificados de cliente são aceitáveis, a CA emissora e a raiz. `ssl_verify_client on` torna um
certificado válido obrigatório: sem certificado, sem conexão. E o `if` dentro do location é a metade
da autorização: um certificado válido não basta, ele precisa ser **`CN=www-client`**. O log de acesso
registra, para cada requisição, o sujeito do certificado e se a verificação teve sucesso.

O firewall muda para acompanhar. A porta nova é liberada em direção aos servidores a partir de qualquer zona, e as
duas regras antigas para a 8080 são removidas, de modo que a aplicação não pode mais ser alcançada sem
passar pela verificação de identidade:

```
root@fw:~# nft insert rule ip filter forward index 2 oifname eth3 ip daddr 192.168.20.10 tcp dport 8443 ct state new accept comment '"the application over TLS: identity decides, not the network"'
root@fw:~# nft -a list chain ip filter forward | grep "dport 8080" | grep -o "comment.*"
comment "staff use the application" # handle 10
comment "the proxy reaches the application" # handle 14
root@fw:~# nft delete rule ip filter forward handle 10; nft delete rule ip filter forward handle 14
root@fw:~# nft list chain ip filter forward | grep -E "dport (8080|8443)" | sed "s/^\t*//"
oifname "eth3" ip daddr 192.168.20.10 tcp dport 8443 ct state new accept comment "the application over TLS: identity decides, not the network"
```

Agora o `laptop`, ainda na LAN da equipe, ainda liberado pelo firewall para a 8443:

```
ana@laptop:~$ curl -sS --resolve app.corp.example.com:8443:192.168.20.10 https://app.corp.example.com:8443/admin/ | grep -o "<title>.*</title>"
<title>400 No required SSL certificate was sent</title>
ana@laptop:~$ probe app:8080
app:8080               blocked
```

**`400 No required SSL certificate was sent`.** O firewall deixou a conexão passar, e a aplicação a
recusou mesmo assim, porque o `laptop` não conseguiu provar quem era. A porta antiga está bloqueada.
Esta é a ideia inteira no seu menor tamanho: a rede permitiu o pacote, e **a identidade decidiu**.
