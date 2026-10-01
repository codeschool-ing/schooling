---
title: Um caminho para dentro: redirecionamento de portas
version: 1
---

Toda conexão até aqui começou dentro do escritório. A outra direção é a que o NAT não resolve sozinho:
**uma conexão que começa lá fora só tem o endereço público como alvo, e nada na tabela do r1 diz que
máquina de dentro deve recebê-la.**

Tente pelo lado do provedor. Primeiro o isp ganha uma rota para a rede privada do escritório pelo r1. Um provedor real nunca teria essa rota; ela está aqui para mostrar que o endereço não é o único obstáculo. Depois o isp pede a página web do srv, diretamente e pelo endereço público:

```
root@isp:~# ip route add 10.20.10.0/24 via 203.0.113.2
root@isp:~# curl -s -m 4 http://10.20.10.10/; echo "exit status $?"
exit status 28
root@isp:~# curl -s -m 4 http://203.0.113.2:8080/; echo "exit status $?"
exit status 7
```

As duas falham, por motivos diferentes, e o exit status diz qual. `28` é o código do curl para timeout:
o pedido para `10.20.10.10` chegou ao r1, e a chain de encaminhamento do r1, cuja política é `drop`,
descartou-o, já que nenhuma regra permite uma conexão da eth1 para a eth0. O firewall respondeu não
respondendo. `7` é o código do curl para falha ao conectar: o pedido para `203.0.113.2:8080` era para o
próprio r1, o r1 não tem nada na porta 8080, e o kernel dele recusou na hora — a mesma recusa que a
aula 5 encontrou na porta 8000.

**O redirecionamento de portas, ou NAT de destino, é uma regra que diz: o que chega nesta porta pública
vai para aquele endereço e porta de dentro.** No r1 ele exige uma chain, uma regra e uma permissão:

```
root@r1:~# nft add chain ip nat prerouting "{ type nat hook prerouting priority dstnat; }"
root@r1:~# nft add rule ip nat prerouting iifname "eth1" tcp dport 8080 dnat to 10.20.10.10:80
root@r1:~# nft insert rule inet filter forward ct status dnat accept
```

- o primeiro comando cria uma chain `prerouting` na tabela `nat`. Ela roda quando o pacote chega, antes
  de o r1 decidir para onde mandá-lo, que é o momento em que o destino precisa mudar;
- o segundo é o redirecionamento em si: chegando pela `eth1`, TCP para a porta `8080`, trocar o destino
  para `10.20.10.10:80`;
- o terceiro deixa essas conexões passarem pelo firewall: `ct status dnat` casa com qualquer conexão
  cujo destino foi traduzido, e o `insert` põe a regra no topo da chain de encaminhamento, antes do
  descarte.

Do isp, o endereço público agora responde:

```
root@isp:~# curl -s -m 4 http://203.0.113.2:8080/
served by srv
```

`served by srv`: a página veio do servidor de dentro. A tabela do r1 mostra a tradução:

```
root@r1:~# conntrack -L -p tcp --dport 8080
conntrack v1.4.8 (conntrack-tools): 1 flow entries have been shown.
tcp      6 119 TIME_WAIT src=203.0.113.1 dst=203.0.113.2 sport=40940 dport=8080 src=10.20.10.10 dst=203.0.113.1 sport=80 dport=40940 [ASSURED] mark=0 use=1
```

O isp conectou em `203.0.113.2` porta `8080`, e o r1 espera a resposta de `10.20.10.10` porta `80`.
Desta vez foi o destino que se reescreveu, e na volta o r1 reescreve a origem da resposta para que ela
pareça vir de 203.0.113.2:8080. O srv viu a conexão chegar do endereço real do isp, `203.0.113.1`,
porque nada reescreveu a origem. O conjunto completo de regras, com o redirecionamento:

```
root@r1:~# nft list ruleset
table ip nat {
	chain postrouting {
		type nat hook postrouting priority srcnat; policy accept;
		oifname "eth1" masquerade
	}

	chain prerouting {
		type nat hook prerouting priority dstnat; policy accept;
		iifname "eth1" tcp dport 8080 dnat to 10.20.10.10:80
	}
}
table inet filter {
	chain forward {
		type filter hook forward priority filter; policy drop;
		ct status dnat accept
		ct state established,related counter packets 52 bytes 3603 accept
		iifname "eth0" oifname "eth1" counter packets 7 bytes 444 accept
		counter packets 4 bytes 240 comment "everything else: dropped"
	}
}
```

A tabela `nat` agora tem duas chains, uma para cada sentido da tradução. Na `inet filter`, os
contadores guardam a história: 4 pacotes chegaram à última regra e foram descartados, entre eles as
tentativas em 10.20.10.10 que deram timeout, enquanto 52 pacotes de conexões estabelecidas passaram.

**Um redirecionamento abre um serviço para a internet inteira**, então é uma decisão, não um ajuste.
Redirecione só as portas que o serviço precisa, para a única máquina que as serve; mantenha essa
máquina atualizada, porque qualquer um agora a alcança; e, quando os clientes forem conhecidos, ponha
os endereços deles na regra. Uma porta pública fora do padrão, como a 8080, não esconde nada — os
scanners tentam todas as portas. E roteadores domésticos que abrem portas a pedido de dispositivos de
dentro, pelo UPnP, tomam a mesma decisão sem ninguém tomá-la, que é o motivo para desligar isso onde
nada precisa.
