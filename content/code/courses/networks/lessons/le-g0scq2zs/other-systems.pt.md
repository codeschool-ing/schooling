---
title: A mesma escada no Windows e no macOS
version: 1
---

O método não muda com o sistema; os comandos, sim:

```sh
ipconfig /all                              # Windows: addresses, gateway and DNS servers of every adapter
ping -n 2 www.example.com                  # Windows: -n counts, where Linux uses -c
tracert -d www.example.com                 # Windows' traceroute
pathping -n www.example.com                # Windows: a route, then loss per hop, like mtr
nslookup -type=mx example.net              # Windows: the same nslookup
Test-NetConnection www.example.com -Port 443   # Windows PowerShell: is the port reachable?
netstat -ano                               # Windows: connections and listening ports, with process ids
arp -a                                     # Windows: the neighbour table
ipconfig /flushdns                         # Windows: forget cached DNS answers
netstat -rn                                # macOS: the routing table
lsof -nP -iTCP -sTCP:LISTEN                # macOS: what is listening
```

**Nenhum deles foi rodado para esta aula.** No Windows, o `ipconfig /all` é o degrau 1 e mostra o
gateway e os servidores DNS numa tela só. O `tracert` e o `pathping` são o traceroute e um mtr mais
lento, e o `Test-NetConnection` com `-Port` é o degrau 5 numa linha. O `netstat -ano` ainda é o `ss` do
Windows, e a última coluna dele, o id do processo, bate com a aba *Detalhes* do Gerenciador de Tarefas.
O Windows guarda um cache de DNS próprio, e o `ipconfig /flushdns` o limpa depois de uma mudança no DNS.

Um Mac tem `ping`, `traceroute`, `dig`, `nslookup` e `tcpdump` no Terminal. O Wireshark existe para os
três, e abre os arquivos pcap da seção 10 onde quer que tenham sido feitos.
