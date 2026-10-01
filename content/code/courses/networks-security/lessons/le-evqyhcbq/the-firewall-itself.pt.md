---
title: Proteger o próprio firewall
version: 1
---

A chain `forward` protege as zonas. A chain `input` protege o **`fw`**, e um firewall que pode ser
administrado de qualquer lugar está a uma senha de ser o firewall de outra pessoa. A chain de entrada
da base:

```
root@fw:~# nft list chain ip filter input
table ip filter {
	chain input {
		type filter hook input priority filter; policy drop;
		ct state established,related accept
		iifname "lo" accept
		iifname "eth4" ip saddr 192.168.99.0/24 tcp dport 22 ct state new accept comment "fw is administered from mgmt only"
	}
}
```

Política `drop`. As respostas às conexões do próprio `fw` e o tráfego na interface de loopback são
permitidos, e conexões novas só para SSH, só chegando pela interface de gestão, só a partir da faixa
de gestão. A partir da LAN da equipe e do `admin`:

```
ana@laptop:~$ ping -c1 -W1 192.168.10.1 | tail -2
1 packets transmitted, 0 received, 100% packet loss, time 0ms

ana@laptop:~$ probe fw:22
fw:22                  blocked
ana@admin:~$ probe fw:22
fw:22                  refused
```

O `laptop` não alcança a porta SSH do `fw`, e a partir do `admin` ela responde `refused`: a regra
deixou o pacote entrar e o `fw` não roda servidor SSH no laboratório. **A interface de gestão é a
única porta, e a porta dá numa sala que ninguém mobiliou ainda.**

## ICMP não é opcional

O ping do `laptop` ficou sem resposta, que é a política funcionando como foi escrita e não como se
pretendia. Descartar todo ICMP é um erro comum com custos reais:

| mensagem ICMP | o que quebra sem ela |
|---|---|
| destino inalcançável, incluindo *fragmentation needed* | a descoberta de MTU do caminho (*path MTU discovery*): pacotes grandes somem e as conexões travam no meio da transferência |
| tempo excedido | o `traceroute` não mostra nada depois deste salto |
| pedido e resposta de eco | o `ping`, a primeira ferramenta que qualquer um procura |

Erros sobre as conexões do próprio firewall já passam como `related`. Para o resto, uma regra que
permite os três tipos que importam, com um limite de taxa para que não possam ser usados para
inundar:

```
root@fw:~# nft list chain ip filter input | grep icmp
		icmp type { destination-unreachable, echo-request, time-exceeded } limit rate 10/second burst 5 packets accept comment "ping and the errors path discovery needs"
ana@laptop:~$ ping -c1 -W1 192.168.10.1 | tail -2
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.281/0.281/0.281/0.000 ms
```

**Permita ICMP de propósito e limite sua taxa**, em vez de descartá-lo e passar uma semana depurando
conexões travadas.
