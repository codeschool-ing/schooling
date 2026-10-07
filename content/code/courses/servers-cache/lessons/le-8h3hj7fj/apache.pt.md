---
title: Apache, e dois servidores numa porta
version: 1
---

O Apache é o mais antigo dos três e ainda roda uma grande parte da web, boa parte dela em hospedagem
compartilhada, onde cada cliente controla o próprio diretório. Suba-o com o Nginx rodando:

```
ana@web:~$ sudo systemctl start apache2
Job for apache2.service failed because the control process exited with error code.
See "systemctl status apache2.service" and "journalctl -xeu apache2.service" for details.
ana@web:~$ sudo journalctl -u apache2 --no-pager -o cat | grep -E "AH0|Address"
AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerName' directive globally to suppress this message
(98)Address already in use: AH00072: make_sock: could not bind to address 0.0.0.0:80
AH00015: Unable to open logs
```

**`Address already in use` na porta 80 é o erro que você mais vai encontrar em todo este assunto**, e
ele quer dizer exatamente o que diz: uma porta pertence a um programa por vez, e o Nginx está com ela.
A linha `AH00558` acima dela é só um aviso sobre o nome da máquina e aparece em toda subida; a linha
que importa é a `AH00072`. Dois servidores web numa máquina ou usam portas diferentes, ou um fica na
frente do outro, que é a aula 2.

Nesta aula o Apache fica com a porta 8080. A configuração dele é dividida do jeito Debian, como a do
Nginx: `ports.conf` diz quais portas abrir, e cada site é um **virtual host** em `sites-available`,
ligado com `a2ensite`, que cria o mesmo tipo de link da convenção do Nginx.

```
ana@web:~$ sudo sed -i 's/^Listen 80$/Listen 8080/' /etc/apache2/ports.conf
ana@web:~$ cat /etc/apache2/sites-available/ipelivros.conf
<VirtualHost *:8080>
    ServerName ipelivros.example
    ServerAlias www.ipelivros.example
    DocumentRoot /var/www/ipe

    ErrorLog ${APACHE_LOG_DIR}/ipelivros-error.log
    CustomLog ${APACHE_LOG_DIR}/ipelivros-access.log combined
</VirtualHost>
ana@web:~$ sudo a2dissite 000-default && sudo a2ensite ipelivros
Site 000-default disabled.
To activate the new configuration, you need to run:
  systemctl reload apache2
Enabling site ipelivros.
To activate the new configuration, you need to run:
  systemctl reload apache2
ana@web:~$ sudo apachectl configtest
AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerName' directive globally to suppress this message
Syntax OK
ana@web:~$ sudo systemctl start apache2
ana@web:~$ curl -sI http://ipelivros.example:8080/css/site.css
HTTP/1.1 200 OK
Date: Wed, 07 Oct 2026 03:11:23 GMT
Server: Apache/2.4.58 (Ubuntu)
Last-Modified: Tue, 01 Sep 2026 13:00:00 GMT
ETag: "ed-65a6b7f0fb400"
Accept-Ranges: bytes
Content-Length: 237
Vary: Accept-Encoding
Content-Type: text/css
```

As peças correspondem às do Nginx quase uma a uma: `ServerName` e `ServerAlias` são o `server_name`,
`DocumentRoot` é o `root`, e `apachectl configtest` é o `nginx -t`. A resposta difere em dois
detalhes que vale notar agora. O `ETag` do Apache é feito do tamanho e da data de modificação do
arquivo num formato próprio, então o mesmo arquivo tem uma etiqueta diferente em cada servidor, o que
importa no dia em que dois servidores diferentes respondem por um nome. E o Apache acrescenta
`Vary: Accept-Encoding` porque está pronto para comprimir, o que a aula 5 explica.

## Módulos e processos

O Apache quase não faz nada sozinho; praticamente todo recurso é um **módulo** carregado na subida, e
`a2enmod` e `a2dismod` os ligam e desligam do jeito que `a2ensite` faz com sites. A primeira dúzia
habilitada nesta máquina:

```
ana@web:~$ ls /etc/apache2/mods-enabled/ | head -12
access_compat.load
alias.conf
alias.load
auth_basic.load
authn_core.load
authn_file.load
authz_core.load
authz_host.load
authz_user.load
autoindex.conf
autoindex.load
deflate.conf
```

O jeito como o Apache trata conexões também é um módulo, o **módulo de multiprocessamento** ou MPM, e
só um pode estar carregado:

```
ana@web:~$ a2query -M
event
```

`event` é o padrão do Ubuntu: poucos processos, cada um com muitas threads, e uma thread separada
que vigia as conexões keep-alive ociosas para que elas não ocupem um worker. O `prefork`, mais
antigo, roda um processo de uma thread só por conexão. Ainda é o que você ganha com o `mod_php`, o
módulo de PHP que não tolera threads, e é por isso que um Apache antigo podia ficar sem memória com
umas poucas centenas de visitantes.

## O que só o Apache faz

Arquivos **`.htaccess`** deixam um diretório carregar a própria configuração, lida pelo Apache a cada
requisição que passa por ele. Em hospedagem compartilhada, onde o cliente não pode editar os arquivos
do servidor, esse é o propósito inteiro. Num servidor que você controla é um custo: toda requisição
procura um em cada diretório do caminho. O Apache do Ubuntu não os permite em lugar nenhum por padrão
(`AllowOverride None`), e um servidor seu deve continuar assim.
