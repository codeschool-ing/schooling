---
title: IP: o endereço que muda de lugar
---

O **endereço IP** diz onde a máquina está na rede — e, como um endereço postal, ele descreve uma posição, não um objeto. Levar o notebook para outra rede troca o IP dele.

O IPv4 tem quatro números de 0 a 255 (`192.168.0.10`) e são só 4,3 bilhões de combinações, que acabaram. O IPv6 resolve com 128 bits (`2001:db8::1`) — espaço que não acaba em nenhum cenário previsível.

Enquanto isso, faixas **privadas** (`10.x.x.x`, `172.16–31.x.x`, `192.168.x.x`) são reutilizadas dentro de cada rede local e não existem na internet. O roteador faz a tradução (NAT) — é por isso que sua máquina se enxerga como `192.168.0.10` e um site vê o IP público do seu provedor.
