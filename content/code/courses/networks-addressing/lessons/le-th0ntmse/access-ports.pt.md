---
title: "Portas de acesso: uma VLAN, e o PC nem fica sabendo"
version: 1
---

Uma imagem comum é a de um PC "configurado para a VLAN 10". No caso de costume nada muda no PC.
**Uma porta de acesso pertence a uma VLAN, e a VLAN é uma propriedade da porta, não da máquina
ligada nela.** O PC manda um quadro Ethernet comum; o switch decide em que VLAN o quadro está pela
porta por onde ele chegou, e entrega quadros ao PC como quadros comuns de novo. Mude o cabo para
outra porta e o PC está em outra VLAN, com o mesmo endereço e a mesma configuração.

No sw1, a porta do pc1 vai para a VLAN 10 e a do pc2 para a VLAN 20:

```
root@sw1:~# bridge vlan add dev p1 vid 10 pvid untagged
root@sw1:~# bridge vlan add dev p2 vid 20 pvid untagged
root@sw1:~# bridge vlan del dev p1 vid 1
root@sw1:~# bridge vlan del dev p2 vid 1
```

Três palavras fazem o trabalho na primeira linha. `vid 10` torna a p1 membro da VLAN 10. `pvid` faz
da VLAN 10 aquela em que é colocado um quadro sem tag que chega na p1. `untagged` faz os quadros da
VLAN 10 saírem da p1 sem tag. **Membro, sem tag na entrada, sem tag na saída: isso é uma porta de
acesso**, e um switch Cisco diz isso como `switchport mode access` e `switchport access vlan 10`. As
duas linhas com `del` tiram a p1 e a p2 da VLAN 1; sem elas cada porta ficaria em duas VLANs, e uma
porta em duas VLANs não é mais uma porta de acesso.

O sw2 recebeu o mesmo tratamento, escrito como um laço: a p1 (pc3) na VLAN 10, e a p2 e a p3 (pc4 e
pc5) na VLAN 20. Depois, a tabela do sw1:

```
root@sw2:~# for p in p1; do bridge vlan add dev $p vid 10 pvid untagged; bridge vlan del dev $p vid 1; done
root@sw2:~# for p in p2 p3; do bridge vlan add dev $p vid 20 pvid untagged; bridge vlan del dev $p vid 1; done
root@sw1:~# bridge vlan show
port              vlan-id  
p1                10 PVID Egress Untagged
p2                20 PVID Egress Untagged
p24               1 PVID Egress Untagged
br0               1 PVID Egress Untagged
```

A p1 está na 10, a p2 na 20, e as duas são `PVID Egress Untagged` na sua VLAN. A p24, o cabo até o
sw2, não foi tocada e continua sozinha na VLAN 1. Agora o pc1 pinga o pc3, que está na mesma VLAN, na
outra ponta do laboratório:

```
ana@pc1:~$ ping -c 2 -W 1 -q 10.20.10.23
PING 10.20.10.23 (10.20.10.23) 56(84) bytes of data.

--- 10.20.10.23 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1021ms

```

**Dois enviados, nenhum recebido, e nada está quebrado no sentido de costume**: todo cabo está
ligado, toda interface está no ar, e os dois PCs estão na VLAN 10. Siga o quadro do pc1. Ele entra no
sw1 pela p1 e vai para a VLAN 10. O sw1 procura as portas da VLAN 10 por onde poderia mandar o
quadro, e a p1 é a única: a p24 está na VLAN 1. O quadro não tem para onde ir, e o switch o descarta.
**Uma VLAN só existe nas portas que são membros dela, e o cabo entre dois switches é uma porta em
cada ponta.**

Nada avisa sobre o descarte. Um switch trabalhando na camada 2 não tem mensagem de erro para mandar
— o ICMP, do curso de redes, é coisa de roteadores e hosts — então o PC vê exatamente o que veria se
o cabo estivesse cortado: perguntas sem resposta. Esse silêncio é o que torna lentos de achar os
defeitos de VLAN, e a aula 22 termina com uma lista de verificação construída em volta dele.

Há duas saídas. Uma é um cabo por VLAN entre os switches: p23 para a VLAN 10, p24 para a VLAN 20.
Funciona, e deixa de funcionar em escala, porque vinte VLANs entre dois switches custariam vinte
cabos e quarenta portas. A outra é um cabo que leva toda VLAN e diz, em cada quadro, a que VLAN ele
pertence. Isso é um tronco, e é a próxima seção.
