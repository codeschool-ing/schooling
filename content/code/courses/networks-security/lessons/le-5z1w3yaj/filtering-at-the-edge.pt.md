---
title: Recusando origens que não podem ser verdade
version: 1
---

Duas verificações, postas em uma chain `prerouting` para que rodem antes do roteamento e antes que
qualquer regra em `forward` possa ser enganada:

```
root@fw:~# cat antispoof.nft
table ip filter {
  chain prerouting {
    type filter hook prerouting priority filter; policy accept;
    iifname "eth0" ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } counter drop comment "private sources never arrive from the internet"
    fib saddr . iif oif missing counter drop comment "the source must be reachable back through the interface it came in on"
  }
}
root@fw:~# nft -f antispoof.nft
```

A primeira é uma lista: **faixas privadas nunca chegam da internet**, porque ninguém na internet pode
ser alcançado nelas. A mesma lista, chamada de *bogons*, costuma incluir também as faixas de
documentação, a faixa de loopback e endereços ainda não alocados a ninguém; o laboratório usa faixas de
documentação para a sua própria internet, então elas não podem estar na lista dele.

A segunda é geral e não precisa de lista. `fib saddr . iif oif missing` pergunta à tabela de
roteamento: **para alcançar a origem deste pacote, que interface eu usaria?** Se nenhuma rota leva de
volta pela interface por onde o pacote entrou, a origem não está onde diz estar, e o pacote é
descartado. Isso é a **filtragem por caminho reverso** (*reverse path filtering*).

O mesmo pedido forjado, e depois um honesto:

```
ana@remote:~$ curl -s -m2 --interface 192.168.20.99 https://www.example.com/; echo "exit $?"
exit 28
ana@remote:~$ curl -s -m2 https://www.example.com/
orders service: ok
root@fw:~# nft list chain ip filter prerouting | grep counter
		iifname "eth0" ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } counter packets 2 bytes 120 drop comment "private sources never arrive from the internet"
		fib saddr . iif oif missing counter packets 0 bytes 0 drop comment "the source must be reachable back through the interface it came in on"
```

O `SYN` forjado e a sua retransmissão, 2 pacotes, foram descartados pela primeira regra antes que
qualquer coisa atrás do `fw` os visse. O pedido honesto, vindo do próprio endereço do `remote`, foi
atendido como sempre.

## A chave do próprio kernel

O Linux tem a filtragem por caminho reverso embutida, por interface, como um `sysctl`:

```
root@fw:~# sysctl net.ipv4.conf.all.rp_filter net.ipv4.conf.eth0.rp_filter
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.eth0.rp_filter = 0
```

`0` é desligado, que é o que o `fw` tem. `1` é **estrito**, a mesma verificação da regra `fib`: a
resposta precisa sair pela interface por onde o pacote chegou. `2` é **frouxo**: qualquer rota de
volta serve, o que só pega origens sem rota nenhuma. O estrito é o correto para um firewall como este,
em que cada rede fica atrás de exatamente uma interface. Ele é errado onde o tráfego legitimamente
entra por um caminho e sai por outro, como com dois provedores de internet, e ali um filtro estrito
descarta clientes de verdade. A regra do `nft` tem a vantagem de estar escrita, contada e comentada no
mesmo lugar que o resto da política.
