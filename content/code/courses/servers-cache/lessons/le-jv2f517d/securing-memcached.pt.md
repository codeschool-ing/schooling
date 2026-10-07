---
title: Mantendo o Memcached privado
version: 1
---

**O Memcached confia em quem alcança a porta dele.** O protocolo de texto não tem usuário nem senha a não
ser que se ligue um, então qualquer um que conecte lê toda chave cujo nome souber, sobrescreve qualquer
uma e esvazia o cache inteiro com `flush_all`. A defesa é que ninguém além da aplicação consiga
conectar:

```
ana@web:~$ printf 'stats settings\r\n' | nc -q1 127.0.0.1 11211 | grep -E ' (tcpport|udpport|inter|auth_enabled_ascii|item_size_max) '
STAT tcpport 11211
STAT udpport 0
STAT inter 127.0.0.1
STAT auth_enabled_ascii no
STAT item_size_max 1048576
ana@web:~$ sudo ss -ltnup | grep -E 'Local|11211' | sed 's/ *$//'
Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
tcp   LISTEN 0      1024       127.0.0.1:11211      0.0.0.0:*    users:(("memcached",pid=1769,fd=26))
```

As configurações do Ubuntu são as seguras: TCP só em 127.0.0.1, e **UDP desligado**, `udpport 0`. O UDP
vem desligado por padrão desde a versão 1.5.6, depois que servidores Memcached abertos na internet foram
usados em 2018 para inundar terceiros com respostas a pequenas requisições forjadas, cada resposta
milhares de vezes maior que a requisição. Um Memcached que precisa atender outras máquinas escuta num
endereço privado, atrás de um firewall que só admite os servidores da aplicação, e mantém o UDP
desligado.

O protocolo de texto também pode pedir uma senha, lida de um arquivo. A própria ajuda do Memcached ainda
marca a opção como experimental:

```
ana@web:~$ echo 'shop:Ipe-2026-cache-only' | sudo tee /etc/memcached-auth >/dev/null && sudo chown memcache: /etc/memcached-auth && sudo chmod 600 /etc/memcached-auth
ana@web:~$ echo '-Y /etc/memcached-auth' | sudo tee -a /etc/memcached.conf && sudo systemctl restart memcached
-Y /etc/memcached-auth
ana@web:~$ printf 'get book:7\r\n' | nc -q1 127.0.0.1 11211
CLIENT_ERROR unauthenticated
ana@web:~$ printf 'set auth 0 0 24\r\nshop Ipe-2026-cache-only\r\nset book:7 0 0 1\r\n1\r\nget book:7\r\n' | nc -q1 127.0.0.1 11211
STORED
STORED
VALUE book:7 0 1
1
END
```

Com `-Y`, uma conexão precisa primeiro mandar um `set auth` com um usuário e uma senha do arquivo como
dados; antes disso, todo comando é recusado como `unauthenticated`. **A senha atravessa a rede em texto
claro**, então ela barra um vizinho numa rede privada que conecta por engano e não detém um que consiga
ler o tráfego. Para isso existe o TLS, `-Z`, que o build do Ubuntu inclui. E o reinício que ligou a senha
esvaziou o cache de novo, coisa fácil de esquecer na primeira vez que acontece em produção.

O resto do curso não faz login no Memcached, então tire a senha de novo:

```sh
sudo sed -i '/^-Y /d' /etc/memcached.conf && sudo systemctl restart memcached && sudo rm -f /etc/memcached-auth
```
