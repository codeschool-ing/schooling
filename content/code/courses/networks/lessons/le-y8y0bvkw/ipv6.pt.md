---
title: A outra versão do IP
version: 1
---

Tudo até aqui foi **IPv4**: endereços de 32 bits, escritos como quatro números. Existem uns quatro
bilhões deles, muito menos que os dispositivos que querem um, e esse é o motivo real de o NAT existir. O
**IPv6** é o substituto: endereços de 128 bits, escritos como oito grupos de quatro dígitos
hexadecimais, com a maior sequência de grupos zerados abreviada para `::`. `2001:db8::80` é um, da
faixa reservada para documentação.

O que muda para o suporte é menos do que os endereços sugerem:

- As camadas são as mesmas. O IPv6 é a camada de internet; TCP, UDP e todo protocolo de aplicação rodam
  sobre ele sem mudança.
- Não há ARP. O IPv6 encontra os vizinhos com mensagens ICMPv6, e o `ip -6 neigh` mostra a tabela.
- Não há necessidade de NAT. Todo dispositivo pode ter um endereço público próprio, então é um firewall,
  e não a tradução de endereços, que impede conexões de entrar sem convite.
- A maioria das redes hoje roda **as duas ao mesmo tempo**, *dual stack*, e um programa tenta IPv6
  primeiro quando um nome tem endereço IPv6. Uma falha que afeta só o IPv6 parece um site lento para
  começar, quando um programa que não testa os dois em paralelo espera o IPv6 falhar antes de tentar
  o IPv4.

**O laboratório não tem IPv6 nenhum**: a máquina em que ele roda foi montada sem, e o `strace` da seção
03 mostrou um programa descobrindo isso. A aula 4 mostra o registro `AAAA`, que guarda um endereço IPv6
no DNS, e o endereçamento em si é assunto do curso networks-addressing.
