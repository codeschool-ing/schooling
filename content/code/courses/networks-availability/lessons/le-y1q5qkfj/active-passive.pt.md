---
title: Ativo-passivo com keepalived e HAProxy
version: 1
---

Cada balanceador roda dois programas. **O HAProxy faz o balanceamento**: aceita uma conexão no endereço
público, escolhe um servidor web e repassa a requisição. **O keepalived decide qual balanceador fica com o
endereço público**, exatamente como decidia qual roteador ficava com o gateway na aula 15. Os dois
balanceadores têm configurações idênticas do HAProxy, `/etc/haproxy/haproxy.cfg`. Escreva-a com
`sudo nano` em `lb1` e de novo em `lb2`:

```schooling-example
{"language": "conf", "file": "haproxy.cfg", "parts": [{"code": "global\n    log stdout format raw local0\n    stats socket /run/haproxy.sock mode 600 level admin", "note": "O HAProxy registra o log na saída padrão, que o laboratório mandou para `/run/haproxy.log`, e abre um socket de administração; o `show stat` fala com ele na seção sobre health checks."}, {"code": "defaults\n    mode http\n    log global\n    option httplog\n    timeout connect 2s\n    timeout client 10s\n    timeout server 10s", "note": "Todo proxy abaixo fala HTTP e registra cada requisição no formato HTTP do HAProxy. Os timeouts: dois segundos para conectar a um servidor, dez para um cliente ou um servidor dizer alguma coisa."}, {"code": "frontend www\n    bind 192.0.2.80:80\n    bind 192.0.2.81:80\n    default_backend web", "note": "O lado público. Escuta em `192.0.2.80`, o endereço que o keepalived move, e em `.81`, que a última seção usa. Os dois balanceadores têm este mesmo arquivo."}, {"code": "frontend health\n    bind 127.0.0.1:8404\n    monitor-uri /health", "note": "Uma página que o próprio HAProxy responde, só no loopback: `/health` devolve `200` enquanto o processo estiver vivo. O keepalived a pede a cada segundo."}, {"code": "backend web\n    balance roundrobin\n    option httpchk GET /\n    server web1 192.0.2.21:80 check inter 1s fall 2 rise 2\n    server web2 192.0.2.22:80 check inter 1s fall 2 rise 2\n    server web3 192.0.2.23:80 check inter 1s fall 2 rise 2", "note": "Os três servidores web, um de cada vez. Cada um é verificado com `GET /` a cada segundo; dois checks falhos seguidos tiram um servidor, dois bons o trazem de volta."}]}
```

Um detalhe deixa o balanceador passivo pronto. O HAProxy em `lb2` está rodando e mandado escutar em
`192.0.2.80`, um endereço que `lb2` não tem, e o Linux normalmente recusa isso. Ligar
`net.ipv4.ip_nonlocal_bind` nos dois balanceadores é o que faz o Linux aceitar:
`sudo sysctl -w net.ipv4.ip_nonlocal_bind=1`, digitado em `lb1` e em `lb2`. **O
reserva já está escutando quando o endereço chega**, então um failover é só a metade do keepalived; nada
precisa ser iniciado.

O keepalived em `lb1` é a configuração da aula 15 com um acréscimo, um script que verifica o balanceador em
vez de um cabo. Escreva o `/etc/keepalived/keepalived.conf` de `lb1` com o que o `cat` imprime aqui:

```
ana@lb1:~$ cat /etc/keepalived/keepalived.conf
global_defs {
    enable_script_security
    script_user root
}
vrrp_script haproxy_alive {
    script "/usr/bin/curl -sf -o /dev/null http://127.0.0.1:8404/health"
    interval 1
    fall 2
    rise 2
}
vrrp_instance www_a {
    state BACKUP
    interface eth0
    virtual_router_id 80
    priority 150
    advert_int 1
    virtual_ipaddress {
        192.0.2.80/24
    }
    track_script {
        haproxy_alive
    }
}
```

O `vrrp_script` roda `curl` contra a página `/health` do HAProxy a cada segundo. `fall 2` quer dizer que
duas falhas seguidas põem a instância em `FAULT`, que abre mão do endereço; `rise 2` quer dizer que dois
sucessos a trazem de volta. `curl -sf` sai com 0 quando a página responde e com um código de erro quando
não responde, e esse código de saída é tudo o que o keepalived lê. `lb2` recebe o mesmo arquivo com
`priority 100`.

Os dois programas rodam em segundo plano, cada um gravando o log no `/run` do próprio balanceador. Inicie
o HAProxy nos dois balanceadores:

```sh
sudo sh -c 'setsid haproxy -db -f /etc/haproxy/haproxy.cfg >> /run/haproxy.log 2>&1 &'
```

Depois o keepalived, primeiro em `lb2` e cerca de um segundo depois em `lb1`:

```sh
sudo sh -c 'setsid keepalived -n -l -f /etc/keepalived/keepalived.conf -p /run/keepalived.pid -r /run/vrrp.pid >> /run/keepalived.log 2>&1 &'
```

## Rodando

Com os dois iniciados, `lb1` fica com o endereço público e `lb2` só com o próprio:

```
ana@lb1:~$ ip -br addr show eth0
eth0@if1314      UP             192.0.2.11/24 192.0.2.80/24 
ana@lb2:~$ ip -br addr show eth0
eth0@if1316      UP             192.0.2.12/24 
ana@laptop:~$ dig +short www.example.com
192.0.2.80
ana@laptop:~$ for i in 1 2 3 4 5 6; do curl -s http://www.example.com/; done
served by web1
served by web2
served by web3
served by web1
served by web2
served by web3
ana@lb1:~$ tail -n 3 /run/haproxy.log
203.0.113.2:41868 [28/Sep/2026:18:11:44.448] www web/web1 0/0/0/0/0 200 206 - - ---- 1/1/0/0/0 0/0 "GET / HTTP/1.1"
203.0.113.2:41880 [28/Sep/2026:18:11:44.455] www web/web2 0/0/0/0/0 200 206 - - ---- 1/1/0/0/0 0/0 "GET / HTTP/1.1"
203.0.113.2:41882 [28/Sep/2026:18:11:44.461] www web/web3 0/0/0/0/0 200 206 - - ---- 1/1/0/0/0 0/0 "GET / HTTP/1.1"
ana@lb2:~$ tail -n 3 /run/haproxy.log
```

O nome resolve para `192.0.2.80`, o endereço que muda de lugar, então o laptop nunca fica sabendo qual
balanceador respondeu. Seis requisições foram para os três servidores em rodízio, e o log de `lb1` tem as
três últimas. Cada linha do log se lê da esquerda para a direita como o cliente, a hora em que a requisição
chegou, o frontend, o backend e o servidor escolhido, cinco timers em milissegundos, todos 0 aqui, o status
`200` e os 206 bytes enviados. O cliente é `203.0.113.2`, que é o endereço público de `hq`: o laptop está
atrás do NAT da matriz.

**O log de `lb2` não imprimiu nada.** Ele está rodando, com os mesmos checks configurados, e não serviu uma
única requisição. Essa é a metade passiva do ativo-passivo, e é a máquina que precisa funcionar
perfeitamente no único dia em que ninguém a viu funcionar.
