---
title: Nginx, e um site seu
version: 1
---

O Nginx está instalado e parado. Subi-lo, e pedir ao systemd que o suba a cada boot, é um comando, e
o `status` mostra então o que subiu:

```
ana@web:~$ sudo systemctl enable --now nginx
Synchronizing state of nginx.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable nginx
Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service → /usr/lib/systemd/system/nginx.service.
ana@web:~$ systemctl status nginx --no-pager --lines 0
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: enabled)
     Active: active (running) since Wed 2026-10-07 00:11:20 -03; 36ms ago
       Docs: man:nginx(8)
    Process: 224 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
    Process: 225 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
   Main PID: 227 (nginx)
        CPU: 16ms
     CGroup: /system.slice/nginx.service
             ├─227 "nginx: master process /usr/sbin/nginx -g daemon on; master_process on;"
             ├─228 "nginx: worker process"
             ├─229 "nginx: worker process"
             ├─230 "nginx: worker process"
             └─231 "nginx: worker process"
```

**São cinco processos, e não são cinco cópias da mesma coisa.** O primeiro é o **mestre** (*master*):
roda como root, lê a configuração e abre a porta, e nunca responde a uma requisição. Os outros quatro
são os **workers**, um por processador porque a configuração diz `worker_processes auto`, e são eles
que atendem. Todos seguram o socket de escuta, e por isso o `ss` lista cinco donos para a porta 80:

```
ana@web:~$ sudo ss -ltnp 'sport = :80'
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      511          0.0.0.0:80        0.0.0.0:*    users:(("nginx",pid=231,fd=5),("nginx",pid=230,fd=5),("nginx",pid=229,fd=5),("nginx",pid=228,fd=5),("nginx",pid=227,fd=5))
ana@web:~$ curl -sI http://localhost/
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
Date: Wed, 07 Oct 2026 03:11:20 GMT
Content-Type: text/html
Content-Length: 10671
Last-Modified: Wed, 07 Oct 2026 03:10:42 GMT
Connection: keep-alive
ETag: "6ac5b832-29af"
Accept-Ranges: bytes
```

Essa página é o marcador de lugar do Ubuntu, servido pelo site padrão a partir de `/var/www/html`.

## Onde a configuração mora

Tudo o que o Nginx faz é decidido por `/etc/nginx/nginx.conf` e pelos arquivos que ele inclui. Sem
os comentários, o arquivo principal é curto:

```
ana@web:~$ grep -Ev '^\s*(#|$)' /etc/nginx/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;
error_log /var/log/nginx/error.log;
include /etc/nginx/modules-enabled/*.conf;
events {
	worker_connections 768;
}
http {
	sendfile on;
	tcp_nopush on;
	types_hash_max_size 2048;
	include /etc/nginx/mime.types;
	default_type application/octet-stream;
	ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;
	access_log /var/log/nginx/access.log;
	gzip on;
	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;
}
```

Três coisas nele decidem a maior parte do que vem a seguir. A configuração é feita de **blocos
aninhados**: diretivas em `http { }` valem para todo site, e um site é um bloco `server { }` lá
dentro. A última linha inclui todo arquivo de `sites-enabled`. E `user www-data` é a conta com que
os workers rodam, por isso um arquivo que eles precisam ler tem de ser legível por `www-data`.

`sites-available` guarda o arquivo de um site e `sites-enabled` guarda um link simbólico para ele.
**Habilitar um site é criar o link, e desabilitar é apagar o link**, então o arquivo em si nunca se
perde quando um site é desligado. Essa convenção é do Debian e do Ubuntu; o Nginx em si só conhece a
linha `include`, e outras distribuições põem cada site em `conf.d/`.

## Um bloco server para a livraria

A vitrine estática da loja está em `/var/www/ipe`. Este é o site inteiro:

```
ana@web:~$ cat /etc/nginx/sites-available/ipelivros
server {
    listen 80;
    server_name ipelivros.example www.ipelivros.example;

    root /var/www/ipe;
    index index.html;

    access_log /var/log/nginx/ipelivros.access.log;
    error_log  /var/log/nginx/ipelivros.error.log;
}
```

`listen` é a porta. `server_name` é a lista de nomes a que esse bloco responde, o que o próximo
trecho testa. `root` é o diretório ao qual o caminho da requisição é acrescentado, então
`/css/site.css` vira `/var/www/ipe/css/site.css`. `index` é o arquivo enviado quando o caminho aponta
para um diretório. E cada site ganha os próprios logs, o que se paga na primeira vez que dois sites
dividem um servidor.

Habilite, teste a configuração e recarregue:

```
ana@web:~$ sudo ln -s ../sites-available/ipelivros /etc/nginx/sites-enabled/ipelivros
ana@web:~$ sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
ana@web:~$ sudo systemctl reload nginx
ana@web:~$ curl -s http://ipelivros.example/ | head -4
<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
```

**`nginx -t` antes de todo reload** é o hábito que esta aula mais quer que você guarde, e a última
seção mostra do que ele protege. Um arquivo volta com o tamanho, o tipo e dois validadores,
`Last-Modified` e `ETag`, que são o assunto da aula 5:

```
ana@web:~$ curl -sI http://ipelivros.example/css/site.css
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
Date: Wed, 07 Oct 2026 03:11:22 GMT
Content-Type: text/css
Content-Length: 237
Last-Modified: Tue, 01 Sep 2026 13:00:00 GMT
Connection: keep-alive
ETag: "6a96cc50-ed"
Accept-Ranges: bytes
```

## Como o Nginx escolhe um site

A mesma máquina, a mesma porta, o mesmo arquivo, e três respostas:

```
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost/css/site.css
404
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: www.ipelivros.example' http://localhost/css/site.css
200
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' http://ipelivros.example/nothing-here
404
```

**O site é escolhido pelo cabeçalho `Host`, não pelo endereço.** `localhost` não bate com nenhum dos
`server_name` da livraria, então a requisição vai para o **servidor padrão** (*default server*), o
site do pacote cuja raiz é `/var/www/html`, e esse diretório não tem `css/site.css`. Mandar `Host:
www.ipelivros.example` para o mesmo endereço escolhe a livraria. É assim que uma máquina com um
endereço serve centenas de sites, e é também por isso que uma requisição ao IP puro de um servidor
cai no site que for o padrão. A aula 4 faz esse padrão recusar em vez de responder.

O último `404` é o comum: o site certo, e nenhum arquivo com esse nome dentro da raiz dele.
