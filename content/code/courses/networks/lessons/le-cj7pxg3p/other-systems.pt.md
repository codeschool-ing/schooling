---
title: As mesmas perguntas no Windows e no macOS
version: 1
---

As camadas são as mesmas em todo sistema, e as perguntas também. Os comandos mudam:

```sh
ipconfig /all                 # Windows: addresses, MAC ("Physical Address"), gateway, DNS
arp -a                        # Windows and macOS: the neighbour table
route print                   # Windows: the routing table
Get-NetAdapter                # Windows PowerShell: link state and MAC, one line per card
Get-NetIPConfiguration        # Windows PowerShell: address, gateway and DNS together
Test-NetConnection 192.0.2.80 -Port 443   # Windows PowerShell: is that port open?
tracert 192.0.2.80            # Windows: traceroute
ifconfig en0                  # macOS: the card, its MAC ("ether") and address
netstat -rn                   # macOS: the routing table
```

**Nenhum deles foi rodado para esta aula**; o laboratório é Linux. Os que vale lembrar:

- O `ipconfig /all` é a primeira olhada no Windows: o MAC aparece como *Physical Address* (*Endereço
  Físico* em português), e os endereços, o gateway e os servidores de DNS ficam numa tela só. O
  `Get-NetIPConfiguration` é o mesmo no PowerShell.
- O `arp -a` imprime a tabela de vizinhos no Windows e no macOS, o `ip neigh` da seção 03.
- O `tracert` é o `traceroute` do Windows. Ele manda ICMP onde o `traceroute` do Linux manda UDP por
  padrão, então um firewall pode deixar um passar e barrar o outro. A aula 10 usa isso.
- O `Test-NetConnection` com `-Port` é o `nc -zv` do Windows: ele responde `TcpTestSucceeded : True`
  ou `False`.

No Mac, a placa de Wi-Fi costuma ser a `en0`, e o `ifconfig en0` mostra o MAC como `ether` e o
endereço IPv4 como `inet`. Os comandos mudam, e a leitura é a mesma: enlace, endereço, rota, porta,
nome.
