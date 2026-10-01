---
title: Por que a migração importa
version: 1
---

O IPv4 tem 4.294.967.296 endereços, como a aula 8 contou, e o mundo tem mais aparelhos que isso. O
estoque também não secou aos poucos. **A IANA, que distribui blocos de endereços aos cinco registros
regionais, entregou os últimos em 3 de fevereiro de 2011.** Os registros então se esgotaram um depois
do outro nos anos seguintes, a começar pela APNIC, da Ásia e do Pacífico, em abril de 2011. Desde
então, uma rede nova consegue endereços IPv4 comprando de quem tem sobrando, ou não consegue.

O que manteve o IPv4 funcionando é o NAT, assunto da aula 11: um escritório inteiro ou uma casa inteira
atrás de um endereço público. Quando nem isso bastou, os provedores puseram os clientes atrás de um
segundo NAT, deles, o NAT de operadora, com os endereços `100.64.0.0/10` que a aula 8 mostrou. Funciona,
e o custo é mais fácil de ver da outra ponta. Os dois pedidos abaixo foram do pc1 para o mesmo servidor
web, um por cada protocolo. Enquanto isso, o `tcpdump` no servidor web imprimia o primeiro pacote de
cada conexão e a sua resposta, e a saída dele saiu depois que os dois `curl` terminaram:

```
ana@pc1:~$ curl -s -4 -o /dev/null http://web/
ana@pc1:~$ curl -s -6 -o /dev/null http://web/
root@web:~# timeout 8 tcpdump -n -c 4 -i eth0 "tcp[tcpflags] & tcp-syn != 0 or (ip6 and ip6[53] & 2 != 0)"
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
07:48:41.138662 IP 203.0.113.2.41276 > 192.0.2.80.80: Flags [S], seq 1917333732, win 64240, options [mss 1460,sackOK,TS val 3433362736 ecr 0,nop,wscale 7], length 0
07:48:41.138902 IP 192.0.2.80.80 > 203.0.113.2.41276: Flags [S.], seq 382100392, ack 1917333733, win 65160, options [mss 1460,sackOK,TS val 965993147 ecr 3433362736,nop,wscale 7], length 0
07:48:42.279564 IP6 2001:db8:20:10:25:70ff:febc:29c6.35834 > 2001:db8:99::80.80: Flags [S], seq 1586092098, win 64800, options [mss 1440,sackOK,TS val 3988341105 ecr 0,nop,wscale 7], length 0
07:48:42.279904 IP6 2001:db8:99::80.80 > 2001:db8:20:10:25:70ff:febc:29c6.35834: Flags [S.], seq 1665686423, ack 1586092099, win 64260, options [mss 1440,sackOK,TS val 3136177618 ecr 3988341105,nop,wscale 7], length 0
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

As duas primeiras linhas são a conexão IPv4. O servidor web a viu chegar de **`203.0.113.2`, o endereço
de fora do r1, e não do pc1**: o roteador trocou a origem na saída, como faz com toda máquina do
escritório. Para este servidor, o pc1, o pc2 e o srv são todos o mesmo visitante. As duas últimas
linhas são a conexão IPv6, e ela veio de **`2001:db8:20:10:25:70ff:febc:29c6`, o próprio endereço do
pc1**, intacto. Ninguém traduziu nada.

(Mais uma diferença aparece nas opções. O handshake IPv4 ofereceu `mss 1460` e o IPv6 `mss 1440`: o
maior pedaço de dados que cada pacote leva, que é 1500 bytes menos os cabeçalhos, e o cabeçalho IPv6
tem 40 bytes contra 20 do IPv4.)

**Endereços sem tradução são o que o IPv6 devolve.** O log de um servidor identifica a máquina que se
conectou, e não o roteador na frente dela. Duas máquinas se alcançam direto quando os firewalls entre
elas permitem, que é o que chamadas, jogos e transferências de arquivos entre casas querem e o que o
NAT dificulta. Um roteador não tem tabela de traduções para manter, esgotar ou perder quando reinicia.
E um provedor não precisa de uma segunda camada de NAT para os clientes, uma camada que ele tem de
comprar, operar e registrar.

O que o IPv6 não traz é segurança por acidente. O NAT nunca foi projetado como firewall, mas agia como
um: nada de fora conseguia iniciar uma conexão com uma máquina de dentro, porque não havia endereço
para onde iniciá-la. **Com o IPv6 toda máquina tem um endereço alcançável, então o firewall precisa
dizer o que pode entrar**, e a seção anterior mostrou que o r1 deste laboratório não diz nada.

A migração é lenta porque nada a impõe num dia marcado: uma rede que funciona em IPv4 continua
funcionando. Ela acontece em etapas. Primeiro a pilha dupla, como neste escritório, para que tudo o
que é alcançável por IPv6 seja alcançado assim e o resto continue funcionando. Depois, em algumas
redes, só IPv6, com um tradutor na borda para os sites que ainda não têm endereço IPv6. Essa última
etapa, o NAT64, não foi executada neste laboratório. **A posição prática para quem opera uma rede hoje
é pilha dupla bem feita**: os dois protocolos endereçados, roteados, filtrados e testados, sem tratar
um como o de verdade e o outro como um extra.
