---
title: "Troncos: várias VLANs num cabo"
version: 1
---

**Um tronco (*trunk*) é uma porta que pertence a várias VLANs ao mesmo tempo e marca cada quadro
com a VLAN a que ele pertence**, para que o switch do outro lado ponha cada quadro de volta na VLAN
certa. É o mesmo cabo de antes; o que muda é o acordo entre as duas pontas sobre o que os quadros
nele significam.

No sw1, a p24 entra nas VLANs 10 e 20:

```
root@sw1:~# bridge vlan add dev p24 vid 10
root@sw1:~# bridge vlan add dev p24 vid 20
root@sw1:~# bridge vlan show dev p24
port              vlan-id  
p24               1 PVID Egress Untagged
                  10
                  20
```

Compare as palavras com as de uma porta de acesso. Não há `pvid` nem `untagged` na 10 nem na 20,
então os quadros dessas VLANs saem da p24 **com tag**, levando o número da VLAN com eles. A VLAN 1
continua lá como `PVID Egress Untagged`: este tronco leva uma VLAN sem tag e duas com tag. A VLAN sem
tag de um tronco tem um nome e um conjunto de erros próprios, e ganha a seção depois da próxima. A
p24 do sw2 recebeu os mesmos dois comandos, que a aula não repete.

Os dois departamentos agora alcançam a outra metade, pelo mesmo cabo:

```
ana@pc1:~$ ping -c 2 -q 10.20.10.23
PING 10.20.10.23 (10.20.10.23) 56(84) bytes of data.

--- 10.20.10.23 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 0.946/3.571/6.196/2.625 ms
ana@pc2:~$ ping -c 2 -q 10.20.20.24
PING 10.20.20.24 (10.20.20.24) 56(84) bytes of data.

--- 10.20.20.24 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1004ms
rtt min/avg/max/mdev = 0.886/2.277/3.668/1.391 ms
```

Dois enviados e dois recebidos, na VLAN 10 do pc1 ao pc3 e na VLAN 20 do pc2 ao pc4. A separação
continua: um broadcast do pc1 cruza o tronco marcado como VLAN 10, e o sw2 o entrega só às suas
portas da VLAN 10. A última seção põe uma máquina na VLAN 20 e mostra que ela não ouve nada.

**Um tronco só leva as VLANs de que é membro.** Na bridge do Linux essa lista é explícita, e a VLAN
30 não cruzaria a p24 até alguém adicioná-la nas duas pontas. Alguns switches comerciais começam ao
contrário, permitindo toda VLAN num tronco até que alguém diga outra coisa; escrever a lista à mão
faz uma VLAN existir só onde ela devia existir, e uma tempestade de broadcast numa VLAN fica fora dos
cabos que não têm por que levá-la.

Troncos aparecem onde um cabo tem de servir mais de uma VLAN. Entre switches, como aqui. Entre um
switch e um roteador que roteia entre VLANs, que é a aula 22. Entre um switch e um servidor rodando
máquinas virtuais de VLANs diferentes, onde o próprio software do servidor tira os tags. E entre um
switch e um ponto de acesso Wi-Fi que oferece uma rede para a equipe e outra para visitantes, cada
uma mapeada na sua VLAN — o laboratório não tem rádio, então esse último é descrito e não executado.

Um aviso sobre a palavra. A maioria dos fabricantes chama isto de tronco, e a Cisco o configura com
`switchport mode trunk`. **Alguns fabricantes, entre eles os switches da HP, chamam isto de porta
com tag (*tagged*) e usam "trunk" para dois cabos agrupados em um**, que este curso chama de
agregação de enlaces na aula 21. Quando um documento de outro fabricante disser trunk, confira qual
dos dois ele quer dizer antes de seguir.
