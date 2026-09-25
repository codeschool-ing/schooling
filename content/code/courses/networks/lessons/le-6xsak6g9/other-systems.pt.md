---
title: O nslookup, e o DNS no Windows e no macOS
version: 1
---

O `nslookup` é mais antigo que o `dig` e está em todo sistema, inclusive no Windows, e por isso é a
ferramenta que mandam você usar num atendimento. No laptop do laboratório:

```
ana@laptop:~$ nslookup www.example.com
Server:         198.51.100.53
Address:        198.51.100.53#53

Non-authoritative answer:
Name:   www.example.com
Address: 192.0.2.81
Name:   www.example.com
Address: 2001:db8:10::80

ana@laptop:~$ nslookup -type=mx example.com
Server:         198.51.100.53
Address:        198.51.100.53#53

Non-authoritative answer:
example.com     mail exchanger = 10 mail.example.com.

Authoritative answers can be found from:
```

**`Non-authoritative answer`** é o jeito do `nslookup` de dizer o que a seção 05 disse com o `aa`
ausente: isto veio do cache de um resolver, não do servidor da própria zona. Ele imprimiu os dois
endereços, o `A` e o `AAAA`. O `-type=mx` pede outro tipo de registro, como o segundo argumento do
`dig`.

No Windows e no macOS, o cache que mais importa num atendimento é o da própria máquina:

```sh
nslookup www.example.com                      # Windows and macOS, as above
ipconfig /displaydns                          # Windows: what this PC has cached
ipconfig /flushdns                            # Windows: forget it all
Resolve-DnsName www.example.com -Type MX      # Windows PowerShell: dig's closest cousin
Clear-DnsClientCache                          # Windows PowerShell: the same flush
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder   # macOS: flush
C:\Windows\System32\drivers\etc\hosts                # Windows: the hosts file
```

**Nenhum deles foi rodado para esta aula.** O `ipconfig /flushdns` no Windows, e os dois comandos
juntos no Mac, esvaziam o cache local depois de uma mudança, e esse é o passo que as pessoas esquecem:
limpar o resolver não adianta nada para um PC que ainda guarda a própria cópia pelo resto do TTL. O
`Resolve-DnsName` é a ferramenta do PowerShell mais próxima do `dig`, e mostra o TTL e a seção de onde
veio cada registro.
