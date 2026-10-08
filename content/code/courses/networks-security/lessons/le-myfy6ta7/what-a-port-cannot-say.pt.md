---
title: O que um número de porta não consegue dizer
version: 1
---

O firewall da aula 1 julga **cabeçalhos**: endereços, protocolo, portas. A regra que todo escritório
escreve primeiro é alguma versão de "os funcionários podem navegar na web", e em termos de cabeçalho
isso quer dizer TCP para as portas 80 e 443. No seu laboratório esta aula começa com
`sudo bash nslab.sh reset`, e o conjunto de regras abaixo é o `edge.nft` no `fw`:

```
root@fw:~# cat edge.nft
flush ruleset
table ip filter {
  chain forward {
    type filter hook forward priority filter; policy drop;
    ct state established,related accept
    ct state invalid drop
    iifname "eth2" tcp dport { 80, 443 } ct state new accept comment "staff may browse"
    iifname "eth2" udp dport 53 ip daddr 192.0.2.53 ct state new accept
    iifname "eth1" ip saddr 192.0.2.80 ip daddr 192.168.20.10 tcp dport 8080 ct state new accept comment "the proxy reaches the application"
  }
}
root@fw:~# nft -f edge.nft
ana@laptop:~$ curl -s https://www.example.com/
orders service: ok
```

A última regra do conjunto deixa o proxy na DMZ chegar à aplicação, que é o assunto da aula 3. A
página carrega. Agora o mesmo laptop, a mesma regra, outra máquina na internet:

```
ana@laptop:~$ nc -w2 203.0.113.50 443 </dev/null
SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.19
ana@laptop:~$ nc -w2 203.0.113.50 22 </dev/null; echo "exit $?"
exit 1
```

**A porta 443 respondeu com a saudação de um servidor SSH.** O `remote` roda SSH na porta que um
firewall mantém aberta para HTTPS, e a regra deixou passar porque perguntou pela porta e por mais
nada. A porta 22, onde o SSH normalmente fica, está fechada, e isso não fez diferença nenhuma.

Um número de porta é uma convenção entre dois programas. O servidor escolhe em que porta escutar e o
cliente escolhe o que pedir, e **nada na rede confere se a porta 443 carrega HTTPS**. Então a regra
"liberar a 443" na verdade quer dizer "liberar qualquer programa que aceite usar a 443":

| na porta 443 | liberado por `tcp dport 443`? |
|---|---|
| um navegador buscando uma página | sim |
| uma sessão SSH para uma máquina lá fora | sim |
| um programa mandando arquivos para um serviço de armazenamento que ninguém aprovou | sim |
| um malware alcançando o servidor que lhe dá ordens | sim |

Nenhum desses é exótico, e o último é proposital: software de controle remoto usa
a 443 porque é a única porta que toda rede deixa aberta. Quem defende precisa de um
jeito de perguntar **o que está sendo dito de fato**, e isso significa ler além dos cabeçalhos.
