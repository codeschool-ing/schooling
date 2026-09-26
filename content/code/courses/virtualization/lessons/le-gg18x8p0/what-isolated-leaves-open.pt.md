---
title: O que uma rede isolada deixa aberto
version: 1
---

O laboratório é a rede da aula 14, a `labnet`, com dois convidados nela, e a rede do escritório da aula
11 fazendo o papel da rede de verdade. Primeiro, a parede que já existe:

```
ana@host:~$ ip route get 10.0.0.50
10.0.0.50 dev lan0 src 10.0.0.1 uid 1000 
    cache 
ana@client:~$ ip route; ip route get 10.0.0.50
10.20.0.0/24 dev enp1s0 proto kernel scope link src 10.20.0.12 metric 100 
10.20.0.1 dev enp1s0 proto dhcp scope link src 10.20.0.12 metric 100 
RTNETLINK answers: Network is unreachable
ana@client:~$ curl -sS -m 5 http://server/
lab server: ok
```

O host alcança a impressora pela `lan0`. O client não tem linha `default via`, então para tudo fora de
`10.20.0.0/24` a resposta dele é **`Network is unreachable`**, decidida dentro do convidado antes de um
pacote sair. E os dois convidados continuam se alcançando, que é a razão de ser do laboratório.

Agora olhe o host a partir do mesmo convidado. Duas coisas no host escutam em **todo** endereço,
`0.0.0.0`: o servidor ssh, e um pequeno servidor web servindo uma pasta de notas, o tipo de coisa que
alguém liga por cinco minutos e esquece:

```
ana@host:~$ ss -tln | grep -E ":(22|8000) "
LISTEN 0      4096         0.0.0.0:22        0.0.0.0:*          
LISTEN 0      5            0.0.0.0:8000      0.0.0.0:*          
ana@client:~$ curl -sS -m 5 http://10.20.0.1:8000/todo.txt; nc -zv -w 3 10.20.0.1 22
renew the office printer's toner
Connection to 10.20.0.1 22 port [tcp/ssh] succeeded!
```

Os dois responderam. **Uma rede isolada é isolada do mundo, não do host**, como a aula 11 descobriu com
o DNS: o host tem um endereço nela, `10.20.0.1`, e tudo o que o host serve em todo endereço é servido ali
também. Para um convidado em que você só pratica, isso pode ser aceitável. Para um que roda algo em que
você não confia, é um caminho para a única máquina que guarda todas as outras.
