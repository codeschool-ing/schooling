---
title: Em ponte, visto do escritório
version: 1
---

O convidado em ponte:

```
ana@vmb:~$ ip -br addr show enp1s0; ip route | head -1
enp1s0           UP             10.0.0.135/24 metric 100 fe80::5054:ff:fe70:310e/64 
default via 10.0.0.1 dev enp1s0 proto dhcp src 10.0.0.135 metric 100 
ana@vmb:~$ curl -sS http://10.0.0.50/
office printer: ready
ana@host:~$ tail -1 /var/log/office-http.log
10.0.0.135 - - [25/Sep/2026 21:14:31] "GET / HTTP/1.1" 200 -
ana@host:~$ sudo ip netns exec printer curl -sS -m 5 -o /dev/null -w "%{http_code}\n" http://$(getent hosts vmb | cut -d" " -f1)/
200
ana@host:~$ sudo cat /run/office-dhcp.leases
1790424636 52:54:00:70:31:0e 10.0.0.135 ubuntu ff:56:50:4d:98:00:02:00:00:ab:11:d6:1a:b5:4d:2c:a5:67:4a
```

A vmb recebeu **`10.0.0.135` do DHCP do escritório**, e o último comando é o próprio arquivo de concessões do
escritório com ela dentro. O caminho dela para fora é o roteador do escritório. O log da impressora
nomeia o próprio endereço da vmb, e a impressora alcançou o servidor web da vmb e recebeu `200`. Para
todo mundo na rede do escritório, a vmb é **mais um computador**.

É o que um convidado servidor precisa, e tem consequências que vale dizer antes de alguém pôr um
convidado de laboratório em ponte numa rede de verdade:

- **Fica exposto como um computador de verdade.** Tudo o que ele roda é alcançável por todos naquela
  rede, então precisa do mesmo cuidado que um: atualizações, firewall, nada de senha padrão.
- **Pode atrapalhar a rede.** Um convidado que roda o próprio servidor DHCP, o que um convidado de
  laboratório em teste pode fazer, distribui endereços errados para o escritório inteiro.
- **Precisa de um endereço do escritório.** Numa rede com número fixo de endereços, ou onde todo
  aparelho precisa ser cadastrado, um convidado em ponte é um pedido ao dono da rede, não uma
  configuração.
- **O Wi-Fi muitas vezes recusa.** Um ponto de acesso sem fio espera um MAC por cliente, e um convidado
  em ponte é um segundo; o VirtualBox e o VMware contornam isso, e a ponte simples do libvirt normalmente
  nem consegue ser unida a uma placa Wi-Fi.
