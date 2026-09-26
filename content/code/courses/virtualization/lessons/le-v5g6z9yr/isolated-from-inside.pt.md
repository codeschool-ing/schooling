---
title: Isolada, vista de dentro
version: 1
---

O convidado isolado:

```
ana@vmi:~$ ip -br addr show enp1s0; ip route
enp1s0           UP             10.10.10.37/24 metric 100 fe80::5054:ff:fe6a:fd82/64 
10.10.10.0/24 dev enp1s0 proto kernel scope link src 10.10.10.37 metric 100 
10.10.10.1 dev enp1s0 proto dhcp scope link src 10.10.10.37 metric 100 
ana@vmi:~$ curl -sS -m 5 http://10.0.0.50/
curl: (7) Failed to connect to 10.0.0.50 port 80 after 6 ms: Couldn't connect to server
ana@vmi:~$ nc -zv -w 3 10.10.10.1 53
Connection to 10.10.10.1 53 port [tcp/domain] succeeded!
```

A vmi tem `10.10.10.37` do DHCP do libvirt, e a tabela de rotas dela **não tem linha `default via`** nenhuma:
ela conhece a própria rede e nada além. A impressora está fora de alcance, e tudo o mais fora de
`10.10.10.0/24` também. É o que um laboratório quer para uma máquina que não pode tocar em nada de
verdade, como um alvo quebrado de propósito, aula 14.

Mas uma coisa da lista respondeu: **`10.10.10.1` porta 53, o host.** Uma rede isolada é isolada do
mundo, não do host: o host tem endereço nela, o servidor DHCP e DNS do libvirt escuta ali, e escuta
também qualquer outra coisa que o host rode em todo endereço. Para a maioria dos laboratórios tudo bem;
para um convidado rodando algo em que você não confia, é uma porta para a única máquina que guarda todas as outras. A
aula 15 a fecha.

O quarto modo da tabela, **interna** ou **privada**, tira até isso: uma rede sem endereço para o host,
onde os convidados só se alcançam entre si. Ela também não tem DHCP, então todo convidado nela precisa
de um endereço definido à mão.
