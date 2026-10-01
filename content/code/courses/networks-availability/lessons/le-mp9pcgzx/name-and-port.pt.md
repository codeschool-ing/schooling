---
title: Um nome, uma porta, uma página
version: 1
---

## O nome

Com o gateway corrigido, a falha seguinte chega pelo nome:

```
ana@laptop:~$ curl -sS -m 10 http://www.example.com/
curl: (6) Could not resolve host: www.example.com
```

Erro 6 desta vez, `Could not resolve host`. **O curl nem tentou conectar**, porque não tinha endereço a
que se conectar. A pergunta é se o laptop não alcança o servidor DNS ou se está perguntando ao servidor
errado, e dividir para conquistar responde com o endereço do servidor:

```
ana@laptop:~$ ping -c 1 192.0.2.53
PING 192.0.2.53 (192.0.2.53) 56(84) bytes of data.
64 bytes from 192.0.2.53: icmp_seq=1 ttl=62 time=0.337 ms

--- 192.0.2.53 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.337/0.337/0.337/0.000 ms
ana@laptop:~$ dig +time=2 +tries=1 www.example.com | grep -E "timed out|status"
;; communications error to 192.0.2.54#53: timed out
ana@laptop:~$ dig @192.0.2.53 +short www.example.com
192.0.2.80
ana@laptop:~$ cat /etc/resolv.conf
nameserver 192.0.2.54
```

O servidor DNS do laboratório, `ns` em `192.0.2.53`, responde ao ping. Um `dig` simples, que pergunta a
qualquer servidor que o laptop tenha configurado, **informa a quem perguntou**: `192.0.2.54`, que nunca
respondeu. A mesma pergunta feita a `192.0.2.53` com `@` recebe `192.0.2.80`, a resposta certa. Então a
rede está bem e o DNS está bem, e o laptop está perguntando a um endereço onde ninguém escuta. O
`/etc/resolv.conf` diz isso numa linha. A correção é essa linha, ou o que a escreve naquela máquina: uma
concessão DHCP, o NetworkManager, o systemd-resolved.

O `grep` por `status` não imprimiu nada, e isso também é informação. Um servidor que responde, mesmo que
seja para dizer que um nome não existe, produz uma linha de status; **nenhuma linha de status quer dizer
nenhuma resposta**.

## A porta

```
ana@laptop:~$ curl -sS http://192.0.2.21/
curl: (7) Failed to connect to 192.0.2.21 port 80 after 0 ms: Couldn't connect to server
ana@laptop:~$ ping -c 1 192.0.2.21
PING 192.0.2.21 (192.0.2.21) 56(84) bytes of data.
64 bytes from 192.0.2.21: icmp_seq=1 ttl=62 time=0.073 ms

--- 192.0.2.21 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.073/0.073/0.073/0.000 ms
```

As mesmas palavras da falha do gateway, `Couldn't connect to server`, **depois de 0 ms em vez de 3057**.
Uma conexão recusada na hora quer dizer que uma máquina recebeu o SYN e respondeu com um reset, que é o
que o TCP faz numa porta onde ninguém escuta. Um firewall configurado para rejeitar em vez de descartar
faz o mesmo, então o ping, que prova que a máquina está de pé, não encerra a questão. A próxima pergunta
vai para o próprio web1:

```
ana@web1:~$ ss -tln
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      4096         0.0.0.0:5201      0.0.0.0:*          
ana@web1:~$ ss -tln
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      511          0.0.0.0:80        0.0.0.0:*          
LISTEN 0      4096         0.0.0.0:5201      0.0.0.0:*          
```

A primeira listagem tem um único ouvinte, na porta 5201, o servidor `iperf3` que a aula 22 usa, e **nada
na 80**: o nginx tinha parado. A segunda listagem foi tirada depois que ele foi iniciado de novo, fora da
tela, e `0.0.0.0:80` voltou. **Uma pergunta de camada 4 se resolve no servidor, não no cliente.** O
`ss -tln` lista o que está escutando, e leva um segundo.

## A página

```
ana@laptop:~$ curl -sS -o /dev/null -w "%{http_code}\n" http://192.0.2.21/reports/
404
```

**Um 404 é um sucesso da rede.** Um nome foi resolvido, uma rota entregou, uma porta aceitou a conexão, e
um programa leu o pedido e respondeu. Todo teste que uma ferramenta de rede sabe fazer passou. O que
sobra é uma URL que não existe, uma página que mudou de lugar ou um servidor configurado para procurar no
diretório errado, e essas são perguntas para quem cuida da aplicação, com o log dela aberto. Dizer "a
rede está bem, o web1 respondeu 404 para `/reports/`" economiza a hora que eles gastariam provando isso.

Cinco respostas até aqui, pelo que o cliente disse:

| o que o cliente disse | depois de | camada | o que resolveu |
|---|---|---|---|
| nada: nem resposta nem erro | — | 1 e 2 | `ip -br link`, `ethtool` |
| `Couldn't connect to server` | 3057 ms | 3 | `ip route`, `ip neigh` |
| `Could not resolve host` | — | DNS | `dig`, depois `dig @192.0.2.53` |
| `Couldn't connect to server` | 0 ms | 4 | `ss -tln` no servidor |
| `404` | — | 7 | o log da própria aplicação |
