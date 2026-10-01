---
title: "Sobreposições: duas sub-redes reivindicando um endereço"
version: 1
---

Duas sub-redes se **sobrepõem** quando algum endereço pertence às duas. Com uma máscara só para tudo,
é difícil fazer isso sem querer, porque pedaços iguais ou coincidem ou não se tocam. Com VLSM, um
dígito errado numa máscara faz isso, e nada reclama.

Dois blocos desse tipo não se sobrepõem pela metade. Um bloco CIDR começa num múltiplo do seu próprio
tamanho, então **dois blocos ou não compartilham nada, ou um deles contém o outro por inteiro**. Isso
torna uma sobreposição fácil de descrever e fácil de procurar: um prefixo mais longo dentro de um mais
curto, num cabo diferente.

Aqui está uma sendo criada. Alguém, acrescentando um segundo endereço à interface de operações do r1,
digita /25 quando queria outra coisa. O comando não imprime nada, o que no Linux quer dizer que
funcionou:

```
root@r1:~# ip addr add 10.20.32.130/25 dev eth3
root@r1:~# ip route
default via 10.20.32.226 dev eth0 
10.20.32.0/25 dev eth1 proto kernel scope link src 10.20.32.1 
unreachable 10.20.32.0/24 
10.20.32.128/26 dev eth2 proto kernel scope link src 10.20.32.129 
10.20.32.128/25 dev eth3 proto kernel scope link src 10.20.32.130 
10.20.32.192/27 dev eth3 proto kernel scope link src 10.20.32.193 
10.20.32.224/30 dev eth0 proto kernel scope link src 10.20.32.225 
```

O r1 agora tem `10.20.32.128/25 dev eth3` na tabela, ao lado das sub-redes do plano. Em seguida vem o
teste que seria feito no dia, e ele passa:

```
root@r1:~# ip route get 10.20.32.140
10.20.32.140 dev eth2 src 10.20.32.129 uid 0 
    cache 
root@r1:~# ip route get 10.20.32.180
10.20.32.180 dev eth2 src 10.20.32.129 uid 0 
    cache 
ana@hq1:~$ ping -c 1 -W 1 10.20.32.140
PING 10.20.32.140 (10.20.32.140) 56(84) bytes of data.
64 bytes from 10.20.32.140: icmp_seq=1 ttl=62 time=1.42 ms

--- 10.20.32.140 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 1.424/1.424/1.424/0.000 ms
```

Tanto 10.20.32.140 quanto 10.20.32.180 continuam saindo pela eth2, o cabo da engenharia, e o eng1
responde ao ping. O motivo é a regra em que a seção anterior se apoiou: **quando várias rotas contêm
um endereço, vence a de prefixo mais longo**, e o /26 da engenharia é mais longo que o novo /25. Todo
endereço coberto pelas sub-redes do plano continua indo para onde o plano diz.

O ipcalc diz quanto o novo prefixo cobre:

```
ana@hq1:~$ ipcalc -b 10.20.32.130/25
Address:   10.20.32.130         
Netmask:   255.255.255.128 = 25 
Wildcard:  0.0.0.127            
=>
Network:   10.20.32.128/25      
HostMin:   10.20.32.129         
HostMax:   10.20.32.254         
Broadcast: 10.20.32.255         
Hosts/Net: 126                   Class A, Private Internet

```

**Do 10.20.32.128 ao 10.20.32.255**: a metade de cima inteira do bloco. Ele contém o /26 da
engenharia, que está em outro cabo; o /27 de operações, no mesmo; o enlace com o r2; e o espaço
livre. E o novo endereço do r1, 10.20.32.130, fica dentro da faixa da engenharia, do .129 ao .190.

É exatamente por isso que uma sobreposição é perigosa. **Ela não falha quando é criada; falha
depois**, e em outro lugar. A captura para aqui, mas a tabela acima basta para ler o que ela deixou
armado. Um endereço do espaço livre, como 10.20.32.250, antes só batia com o /24 `unreachable` e era
recusado; agora bate com o /25, que é mais longo, então o r1 o procuraria no cabo de operações. Se o
/26 da engenharia algum dia fosse removido ou digitado errado, o /25 levaria em silêncio todo o
tráfego da engenharia para o cabo errado. E o .130 agora é endereço do próprio r1, então um PC da
engenharia que recebesse o .130 de uma pessoa ou de um pool veria o seu tráfego terminar no r1.

Alguns sistemas de roteador recusam um endereço que se sobrepõe a uma sub-rede já presente em outra
interface; o Linux, como mostra a saída vazia, não recusa. **A proteção é o plano**: cada sub-rede
anotada, e cada nova conferida contra a lista antes de ser digitada. Desfazer esta é o mesmo comando
com `del` no lugar de `add`.
