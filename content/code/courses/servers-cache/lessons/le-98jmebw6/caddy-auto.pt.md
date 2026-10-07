---
title: O Caddy faz tudo isso sozinho
version: 1
---

Tudo o que esta aula fez à mão, o certbot, o webroot, o hook, o timer, o redirecionamento, é o que o
Caddy faz por padrão para todo site cujo endereço é um nome de domínio. A aula 1 desligou isso com
`http://`. Aqui fica ligado, apontado para o Pebble com duas opções globais que um servidor de verdade
deixaria de fora:

```
ana@web:~$ cat /etc/caddy/Caddyfile
{
	acme_ca https://localhost:14000/dir
	acme_ca_root /etc/pebble/api.crt
	email ana@ipelivros.example
}

ipelivros.example, www.ipelivros.example {
	root * /var/www/ipe
	file_server
	reverse_proxy /api/* 127.0.0.1:8001 127.0.0.1:8002
}
```

O bloco do site não tem certificado, porta nem redirecionamento. `reverse_proxy` com dois endereços é
o upstream inteiro da aula 2. Pare o Nginx, que está com as portas 80 e 443, e suba o Caddy:

```
ana@web:~$ sudo systemctl stop nginx && sudo systemctl start caddy && sleep 6 && systemctl is-active caddy
active
ana@web:~$ sudo journalctl -u caddy --no-pager -o cat | grep -o '"msg":"[^"]*"' | grep -iE 'certif|challenge|obtain|authoriz' | uniq
"msg":"enabling automatic TLS certificate management"
"msg":"started background certificate maintenance"
"msg":"obtaining certificate"
"msg":"trying to solve challenge"
"msg":"successfully downloaded available certificate chains"
"msg":"certificate obtained successfully"
"msg":"successfully downloaded available certificate chains"
"msg":"certificate obtained successfully"
```

Dentro dos seis segundos daquele `sleep`, o Caddy registrou uma conta, resolveu um desafio para cada
um dos dois nomes e instalou os dois certificados, e os serve:

```
ana@web:~$ curl -sS https://ipelivros.example/api/books/3 -o /dev/null -w '%{http_code}\n'
200
ana@web:~$ echo | openssl s_client -connect ipelivros.example:443 -servername ipelivros.example 2>/dev/null | openssl x509 -noout -issuer -dates
issuer=CN = Pebble Intermediate CA 6e3a58
notBefore=Oct  7 03:40:01 2026 GMT
notAfter=Jan  5 03:40:00 2027 GMT
ana@web:~$ curl -sI http://ipelivros.example/css/site.css | grep -E 'HTTP|Location'
HTTP/1.1 308 Permanent Redirect
Location: https://ipelivros.example/css/site.css
```

`308 Permanent Redirect` é o jeito do Caddy de mandar HTTP para HTTPS, a mesma ideia do `301` do
Nginx com uma diferença: um `308` manda o cliente repetir a requisição com o mesmo método e o mesmo
corpo, enquanto os navegadores transformam em `GET` um `POST` que encontra um `301`.

O Caddy também renova sozinho, sem nada para instalar. **Essa é a troca:** os padrões estão certos e
há menos para esquecer, e em compensação os certificados moram no diretório de dados do próprio
Caddy, geridos do jeito dele. Uma equipe que roda Nginx para todo o resto mantém o certbot; uma equipe
começando um serviço pequeno do zero tem uma coisa a menos para errar com o Caddy.

A aula termina com o Nginx de volta no comando, porque o resto do curso se apoia nele:

```
ana@web:~$ sudo systemctl stop caddy && sudo systemctl start nginx && systemctl is-active nginx
active
```
