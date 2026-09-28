---
title: HTTPS na frente
version: 1
---

Um navegador, e quem avalia, esperam `https://`. O **Caddy** é um servidor web que obtém e renova
certificados sozinho, e a configuração inteira do loanbook tem quatro linhas:

```
ana@srv:~/loanbook$ cat deploy/Caddyfile
loans.lab {
        tls internal
        reverse_proxy 127.0.0.1:8000
}
ana@srv:~/loanbook$ sudo cp deploy/Caddyfile /etc/caddy/Caddyfile
ana@srv:~/loanbook$ sudo systemctl enable --now caddy
Created symlink /etc/systemd/system/multi-user.target.wants/caddy.service → /usr/lib/systemd/system/caddy.service.
```

`loans.lab` é o nome a que ele responde. `reverse_proxy` entrega toda requisição ao container na porta 8000.
E `tls internal` diz ao Caddy para emitir o certificado da **sua própria autoridade local**, porque
`loans.lab` não é um domínio de verdade e nenhuma autoridade pública emitiria um para ele. Na internet, essa
linha some, última seção.

Do laptop, depois de dizer a ele onde fica `loans.lab`, a primeira requisição falha:

```
ana@laptop:~$ echo '10.20.0.20 loans.lab' | sudo tee -a /etc/hosts
10.20.0.20 loans.lab
ana@laptop:~$ curl -sS https://loans.lab/healthz
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

Essa falha está certa. O certificado é assinado por uma autoridade de que o laptop nunca ouviu falar, e o
`curl` se recusa a confiar nele, que é exatamente o que deve acontecer com um certificado desconhecido. A
correção é fazer o laptop confiar nessa autoridade, de propósito, instalando o certificado raiz dela:

```
ana@laptop:~$ ssh srv sudo cat /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt > lab-root.crt
ana@laptop:~$ openssl x509 -in lab-root.crt -noout -subject -enddate
subject=CN = Caddy Local Authority - 2026 ECC Root
notAfter=Aug  5 06:59:27 2036 GMT
ana@laptop:~$ sudo cp lab-root.crt /usr/local/share/ca-certificates/loans-lab-root.crt
ana@laptop:~$ sudo update-ca-certificates
Updating certificates in /etc/ssl/certs...
rehash: warning: skipping ca-certificates.crt,it does not contain exactly one certificate or CRL
1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
ana@laptop:~$ curl -sS https://loans.lab/healthz
{"ok": true}
ana@laptop:~$ curl -sS https://loans.lab/api/items | python3 -m json.tool | head -12
[
    {
        "id": 8,
        "name": "Conference speaker",
        "loan": null
    },
    {
        "id": 6,
        "name": "Document camera",
        "loan": {
            "borrower": "Dora Okafor",
            "lent_on": "2026-09-26",
```

O `openssl` mostra no que se vai confiar antes de confiar: a raiz local do Caddy, válida por dez anos. O
`update-ca-certificates` a acrescenta à lista do sistema, e daí em diante a mesma requisição dá certo, em
HTTPS, com os dados de exemplo. Num celular de verdade ou em outro notebook você instalaria o mesmo arquivo,
e é isso que faz um laboratório com HTTPS se comportar como o real.
