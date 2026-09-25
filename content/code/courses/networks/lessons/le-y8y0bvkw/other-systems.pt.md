---
title: Testando o MTU no Windows e no macOS
version: 1
---

O teste da seção 06 é o que se roda quando uma falha se parece com a da seção 07, e todo sistema
consegue rodá-lo:

```sh
ping -f -l 1472 192.0.2.80                     # Windows: -f forbids fragmenting, -l is the size
netsh interface ipv4 show subinterfaces        # Windows: the MTU of each interface
ping -D -s 1472 192.0.2.80                     # macOS: -D forbids fragmenting
networksetup -getMTU en0                       # macOS: the MTU of the Wi-Fi card
```

**Nenhum deles foi rodado para esta aula.** As opções mudam e a ideia não: proíba a fragmentação e
encontre o maior tamanho que recebe resposta. No Windows, a flag de não fragmentar é `-f` e o tamanho é
`-l`; num Windows em inglês, um pacote grande demais para algum enlace do caminho responde
`Packet needs to be fragmented but DF set.` No macOS, a flag é
`-D` e o tamanho é `-s`, como no Linux.

O número a lembrar é a diferença: **o maior tamanho de dados que funciona, mais 28, é o MTU do
caminho**. 1472 quer dizer 1500 e um caminho Ethernet saudável; 1464 quer dizer 1492 e uma linha PPPoE
em algum ponto do caminho.
