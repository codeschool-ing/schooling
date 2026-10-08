---
title: Renovação, e saber que ela aconteceu
version: 1
---

Um certificado de noventa dias é a promessa de que algo vai renová-lo em noventa dias. O certbot
guarda tudo de que precisa para isso num arquivo por certificado:

```
ana@web:~$ sudo cat /etc/letsencrypt/renewal/ipelivros.example.conf
# renew_before_expiry = 30 days
version = 2.9.0
archive_dir = /etc/letsencrypt/archive/ipelivros.example
cert = /etc/letsencrypt/live/ipelivros.example/cert.pem
privkey = /etc/letsencrypt/live/ipelivros.example/privkey.pem
chain = /etc/letsencrypt/live/ipelivros.example/chain.pem
fullchain = /etc/letsencrypt/live/ipelivros.example/fullchain.pem

# Options used in the renewal process
[renewalparams]
account = e5c02b0263be20818ae674d628c67786
server = https://localhost:14000/dir
authenticator = webroot
webroot_path = /var/www/ipe,
key_type = ecdsa
[[webroot_map]]
ipelivros.example = /var/www/ipe
www.ipelivros.example = /var/www/ipe
```

O servidor, a conta, o método e o webroot ficam lembrados, então uma renovação não precisa de
argumentos. A primeira linha, comentada, é o padrão: **um certificado é renovado quando faltam trinta
dias ou menos.** E o pacote do Ubuntu já instalou o que tenta duas vezes por dia:

```
ana@web:~$ systemctl list-timers certbot.timer --no-pager
NEXT                        LEFT LAST PASSED UNIT          ACTIVATES
Wed 2026-10-07 13:06:54 -03  12h -         - certbot.timer certbot.service

1 timers listed.
Pass --all to see loaded but inactive timers, too.
ana@web:~$ systemctl cat certbot.service --no-pager | grep ExecStart
ExecStart=/usr/bin/certbot -q renew --no-random-sleep-on-renew
```

Esse timer é o que torna o certificado automático. Se um dia for desligado, nada renova e nada
reclama até o certificado vencer.

## Recarregando o Nginx depois de uma renovação

O certbot grava arquivos novos e move os links, e o Nginx continua servindo o certificado antigo da
memória até ser recarregado. A correção é um **deploy hook**: um executável em
`/etc/letsencrypt/renewal-hooks/deploy/`, que o certbot roda depois de cada renovação bem-sucedida, e
só nesse caso.

```
ana@web:~$ sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx && sudo cat /etc/letsencrypt/renewal-hooks/deploy/reload-nginx
#!/bin/sh
# Run by certbot after every certificate it renews: load the new files.
systemctl reload nginx
```

## Testando antes de precisar

`--dry-run` passa por uma renovação inteira e não grava nada:

```
ana@web:~$ sudo REQUESTS_CA_BUNDLE=/etc/pebble/api.crt certbot renew --dry-run --server https://localhost:14000/dir --no-random-sleep-on-renew 2>&1
Saving debug log to /var/log/letsencrypt/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Processing /etc/letsencrypt/renewal/ipelivros.example.conf
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Simulating renewal of an existing certificate for ipelivros.example and www.ipelivros.example

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Congratulations, all simulated renewals succeeded: 
  /etc/letsencrypt/live/ipelivros.example/fullchain.pem (success)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

**Por padrão o `--dry-run` usa o servidor de staging da Let's Encrypt, diga o arquivo de renovação o
que disser**, para um teste nunca gastar os limites de produção. Aqui ele é apontado de volta para o
Pebble com `--server`, porque esta máquina não alcança a Let's Encrypt; num servidor de verdade você
deixa a opção de fora. `--no-random-sleep-on-renew` pula uma pausa de até alguns minutos que o certbot
acrescenta quando ninguém está olhando, para que um milhão de servidores não renovem todos no mesmo
segundo.

Um dry run prova que a CA emitiria. Não prova que o Nginx pega o resultado. Forçar uma renovação de
verdade uma vez, e conferir o certificado que o Nginx serve depois, prova:

```
ana@web:~$ sudo REQUESTS_CA_BUNDLE=/etc/pebble/api.crt certbot renew --force-renewal --no-random-sleep-on-renew 2>&1 | tail -n 6
Renewing an existing certificate for ipelivros.example and www.ipelivros.example

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Congratulations, all renewals succeeded: 
  /etc/letsencrypt/live/ipelivros.example/fullchain.pem (success)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
ana@web:~$ echo | openssl s_client -connect ipelivros.example:443 -servername ipelivros.example 2>/dev/null | openssl x509 -noout -serial -dates
serial=7BE40AC0AB995243
notBefore=Oct  7 03:39:59 2026 GMT
notAfter=Jan  5 03:39:58 2027 GMT
```

O certificado que o Nginx serviu depois foi assinado dez segundos depois do que o certbot recebeu
primeiro (compare o `notBefore` com o da seção sobre o certbot): um certificado novo, carregado pelo
hook. **Faça isso uma vez, no dia em que configurar**, porque a alternativa é descobrir em noventa
dias.

## Vigiando a data de fora

Automação falha em silêncio: uma mudança de firewall bloqueia a porta 80, um registro de DNS muda, o
timer é desligado numa atualização. Então algo deve vigiar a data sem depender de a renovação
funcionar. `openssl x509 -checkend` responde "isto vence em N segundos?" com um código de saída que um
script de monitoramento pode usar:

```
ana@web:~$ sudo openssl x509 -in /etc/letsencrypt/live/ipelivros.example/cert.pem -noout -checkend $((30*86400)); echo "exit $?"
Certificate will not expire
exit 0
ana@web:~$ sudo openssl x509 -in /etc/letsencrypt/live/ipelivros.example/cert.pem -noout -checkend $((100*86400)); echo "exit $?"
Certificate will expire
exit 1
ana@web:~$ openssl x509 -in /etc/ssl/ipelivros/self.crt -noout -checkend $((31*86400)); echo "exit $?"
Certificate will expire
exit 1
```

O certificado renovado tem mais de trinta dias e menos de cem. O autoassinado do começo desta aula,
feito para trinta dias, vence em trinta e um. Uma verificação que alerta com quatorze dias restantes,
rodada contra o certificado que o servidor **de fato está mandando** (pelo `openssl s_client`, como na
seção anterior) e não contra o arquivo no disco, pega cada uma das falhas acima com duas semanas para
consertar.
