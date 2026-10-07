---
title: O que o servidor diz sobre si mesmo
version: 1
---

Endurecer um servidor web é, na maior parte, dois hábitos: **dizer menos sobre si, e recusar mais do
que você não foi feito para responder.** Nenhum dos dois torna seguro um programa vulnerável. Os dois
tornam o servidor mais difícil de mapear, e um servidor mapeado é o primeiro a ser atacado quando uma
vulnerabilidade da versão dele é publicada. Esta aula aplica os dois à livraria, uma configuração por
vez, e cada uma é conferida de fora antes e depois.

Comece pelo que o servidor anuncia a qualquer um que pergunte:

```
ana@web:~$ curl -sI https://ipelivros.example/ | grep -i ^server
Server: nginx/1.24.0 (Ubuntu)
ana@web:~$ curl -s https://ipelivros.example/nothing-here | grep -i nginx
<hr><center>nginx/1.24.0 (Ubuntu)</center>
```

**A versão exata, em toda resposta e em toda página de erro.** No dia em que uma falha no Nginx 1.24
for publicada, todo scanner da internet consegue listar os servidores que a têm perguntando uma vez.
Esconder a versão não remove a falha, e um atacante determinado muitas vezes adivinha uma versão pelo
comportamento; o que some é a lista de graça.

A loja também se anuncia, na própria porta:

```
ana@web:~$ curl -sI http://localhost:8001/healthz | grep -i ^server
Server: ipe-shop/1.0
ana@web:~$ curl -sI https://ipelivros.example/api/books/1 | grep -iE "^(server|x-served-by)"
Server: nginx/1.24.0 (Ubuntu)
X-Served-By: shop1
```

Pelo Nginx, o `Server: ipe-shop/1.0` da loja some, trocado pelo do próprio Nginx. **Um proxy não
repassa o cabeçalho `Server` da aplicação por padrão**, um benefício silencioso de ter um; cabeçalhos
como o `X-Served-By`, que a loja inventou, passam sem mudança, e a última seção desta aula volta à
questão de se esse deveria passar.

O Ubuntu traz a linha que esconde a versão, comentada:

```
ana@web:~$ sudo sed -i 's/# server_tokens off;/server_tokens off;/' /etc/nginx/nginx.conf && grep -n server_tokens /etc/nginx/nginx.conf
21:	server_tokens off;
ana@web:~$ curl -sI https://ipelivros.example/ | grep -i ^server
Server: nginx
ana@web:~$ curl -s https://ipelivros.example/nothing-here | grep -i nginx
<hr><center>nginx</center>
```

`nginx` sem número, no cabeçalho e na página de erro. Uma linha em `http { }` cobre todo site.

**O que uma resposta não deve carregar, como lista para conferir no seu servidor:** um número de versão
em `Server` ou em `X-Powered-By`; um stack trace ou a página de depuração de um framework num erro;
listagens de diretório (`autoindex`, desligado por padrão no Nginx); e nomes ou endereços internos em
cabeçalhos ou redirecionamentos. Cada um deles é informação pela qual um atacante, de outro jeito,
teria de trabalhar.
