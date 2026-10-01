---
title: Enviando só os seus próprios endereços
version: 1
---

A seção anterior protegeu a empresa de pacotes forjados que chegam. O mesmo filtro, apontado para o
outro lado, protege **todos os outros de pacotes forjados que saem**. Esse sentido tem nome,
**BCP 38**, a boa prática atual que pede a toda rede que descarte pacotes de saída cujo endereço de
origem não seja um dos seus. Se toda rede fizesse isso, os ataques de reflexão (a aula 6) não teriam
perguntas forjadas para enviar.

O `laptop` recebeu um segundo endereço que não pertence a ninguém no laboratório, `198.51.100.7`, e
tenta alcançar a internet com ele:

```
ana@laptop:~$ nc -z -v -w1 -s 198.51.100.7 203.0.113.50 443
nc: connect to 203.0.113.50 port 443 (tcp) timed out: Operation now in progress
root@fw:~# nft list chain ip filter prerouting | grep "fib saddr"
		fib saddr . iif oif missing counter packets 1 bytes 60 drop comment "the source must be reachable back through the interface it came in on"
```

A mesma regra `fib` o pegou: o `fw` não tem rota para `198.51.100.7` pela interface da LAN, então o
pacote não pode ter vindo da LAN honestamente, e o contador mostra 1 pacote descartado. Sem o endereço
forjado, o `laptop` alcança a mesma porta normalmente:

```
ana@laptop:~$ nc -z -v -w1 203.0.113.50 443
Connection to 203.0.113.50 443 port [tcp/https] succeeded!
```

**Uma máquina comprometida na LAN é o motivo realista para este filtro.** Um software que tomou conta
de um computador pode ser mandado a participar da inundação de outra pessoa, e origens forjadas são o
jeito como uma inundação se esconde. Uma rede que se recusa a enviá-las torna as próprias máquinas
inúteis para isso, e torna a tentativa visível em um contador sobre o qual alguém pode pôr um alerta.

Onde a rede esconde os endereços internos atrás de um único endereço público com NAT, a regra é mais
simples ainda: depois do NAT, a única origem legítima rumo à internet é aquele endereço.
