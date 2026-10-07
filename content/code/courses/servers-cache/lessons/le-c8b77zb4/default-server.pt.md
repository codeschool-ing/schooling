---
title: Recusando nomes que você não serve
version: 1
---

A aula 1 mostrou que uma requisição cujo `Host` não bate com nenhum `server_name` vai para o **servidor
padrão**. Nesta máquina, ele ainda é o site do pacote do Ubuntu na porta 80, e na porta 443 é a
livraria, porque é o único site escutando ali:

```
ana@web:~$ ls /etc/nginx/sites-enabled/
default
ipelivros
ana@web:~$ curl -s http://127.0.0.1/ | grep -o '<title>.*</title>'
<title>Apache2 Ubuntu Default Page: It works</title>
ana@web:~$ curl -sk https://127.0.0.1/ | grep -o '<title>.*</title>'
<title>Ipê Livros</title>
ana@web:~$ curl -sk -o /dev/null -w '%{http_code}\n' -H 'Host: anything.example' https://127.0.0.1/
200
```

Três respostas que não deviam ter sido dadas. A porta 80 serviu uma página que o pacote do Apache
deixou em `/var/www/html`, o que conta a um desconhecido quais pacotes estão instalados. A porta 443
serviu **a livraria a uma requisição que a pediu pelo endereço IP**, e de novo a uma requisição por um
nome que não tem nada a ver com ela. Scanners varrem a internet por endereço, então o que responde ali
é o que eles indexam; e um site que responde a qualquer `Host` pode ser posto atrás do nome de domínio
de outra pessoa, um truque para tomar emprestada a reputação de um site.

Um bloco que pega tudo e recusa o que não tem nome em outro lugar:

```
ana@web:~$ cat /etc/nginx/sites-available/catch-all
# Requests for a name this server does not serve: refuse them.
server {
    listen 80 default_server;
    listen 443 ssl default_server;
    server_name _;

    ssl_reject_handshake on;   # no certificate is shown to a stranger
    return 444;                # close the connection without an answer
}
ana@web:~$ sudo rm /etc/nginx/sites-enabled/default && sudo ln -s ../sites-available/catch-all /etc/nginx/sites-enabled/catch-all
```

`return 444` é um código próprio e fora do padrão do Nginx: fecha a conexão sem mandar nada.
`ssl_reject_handshake on` faz o mesmo um passo antes, durante o handshake TLS, para o servidor nem
mostrar o certificado, cujos nomes contariam ao desconhecido quais sites moram ali. Por isso o bloco
não precisa de certificado próprio.

```
ana@web:~$ curl -sS http://127.0.0.1/
curl: (52) Empty reply from server
ana@web:~$ curl -sSk https://127.0.0.1/
curl: (35) OpenSSL/3.0.13: error:0A000458:SSL routines::tlsv1 unrecognized name
ana@web:~$ curl -sS -o /dev/null -w '%{http_code}\n' https://ipelivros.example/
200
```

`Empty reply from server` na porta 80, um alerta `unrecognized name` na 443, e a livraria, pedida pelo
nome, sem mudança. **Todo servidor com mais de um site deve ter este bloco**, e um servidor com um
site só também, para as requisições que não pedem aquele site pelo nome.
