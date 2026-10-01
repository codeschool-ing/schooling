---
title: Uma identidade em cada porta
version: 1
---

Depois que uma porta abre, o switch sabe algo que nenhuma regra de firewall até aqui sabia: **quem** está
por trás de um endereço. O hostapd guarda isso por cliente:

```
root@sw:~# hostapd_cli -p /root/hostapd-ctrl -i p1 sta 52:54:00:a8:0a:1e | grep -E "^flags|UserName|ReAuthPeriod|eap_type_sta"
flags=[AUTHORIZED]
dot1xAuthReAuthPeriod=3600
dot1xAuthSessionUserName=newpc.corp.example.com
last_eap_type_sta=13 (TLS)
```

`dot1xAuthSessionUserName` é a identidade que se autenticou. `dot1xAuthReAuthPeriod=3600` quer dizer que
o switch pergunta de novo a cada hora. O hostapd também pode verificar revogação, com a opção
`check_crl`, que a configuração deste laboratório não liga. Com ela, um certificado revogado às nove para
de funcionar até as dez no máximo, e ninguém mexe no switch. É a verificação contínua da aula 21, feita
pela porta.

O script de controle gravou o mesmo fato em um log:

```
root@sw:~# cat /var/log/lab/ports.log
2026-09-28T18:33:59-0300 p1 52:54:00:a8:0a:1e open newpc.corp.example.com
```

Uma linha liga um horário, uma porta e um endereço MAC a um nome. Cruzada com as concessões (*leases*) do
servidor DHCP, que ligam o endereço MAC a um endereço IP, ela responde à pergunta que o log de um firewall
sozinho não responde: de qual pessoa era a máquina `192.168.10.30` às 18:33. Esse cruzamento é a base do
recurso de **identidade de usuário** (*user identity*) de um NGFW, da aula 2: o firewall aprende com o
sistema de autenticação qual usuário tem qual endereço, e uma regra pode então dizer `finance` em vez de
uma sub-rede.

A saída também fica registrada. O laptop faz logoff, como faria ao desligar:

```
root@newpc:~# wpa_cli -p /root/wpa-ctrl -i eth0 logoff
OK
root@sw:~# nft list set netdev ports authorised
table netdev ports {
	set authorised {
		type ifname . ether_addr
	}
}
root@sw:~# cat /var/log/lab/ports.log
2026-09-28T18:33:59-0300 p1 52:54:00:a8:0a:1e open newpc.corp.example.com
2026-09-28T18:34:11-0300 p1 52:54:00:a8:0a:1e closed
ana@newpc:~$ ping -c 2 -W 1 192.168.10.1
PING 192.168.10.1 (192.168.10.1) 56(84) bytes of data.

--- 192.168.10.1 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1031ms
```

O par saiu do conjunto, o log ganhou a segunda linha e a porta está fechada de novo. Uma porta que
continuasse aberta depois que o dono saiu seria exatamente a sessão da aula 21 que sobreviveu à sua
política.

Dois cuidados acompanham esse log:

- **São dados pessoais.** Um registro de qual pessoa estava em qual mesa, e quando, é exatamente o que a
  lei de proteção de dados pede que uma empresa justifique, guarde por um prazo declarado e depois apague.
  A aula 23 decide o que vale a pena guardar e por quanto tempo.
- **Uma identidade não é uma verificação de saúde.** O 802.1X prova que a máquina tem um certificado
  válido. Não prova que a máquina está atualizada ou livre de malware. A **avaliação de postura**
  (*posture assessment*), em que o sistema de NAC também confere o estado do dispositivo antes de escolher
  a VLAN, é a camada que acrescenta isso. Esta aula a cita para que a diferença fique clara, e
  não a constrói.
