---
title: Quantos hosts cabem numa faixa
version: 1
---

A pergunta que um plano mais faz é quantas máquinas uma faixa comporta. A resposta vem só dos bits de
host. **Um prefixo de comprimento n deixa h = 32 − n bits de host, que dão 2^h endereços, e 2^h − 2 deles
são para hosts**, porque os endereços de rede e de broadcast estão ocupados. O `/25` do sales1 tem 7 bits
de host: 2^7 = 128 endereços e 126 hosts, o `Hosts/Net: 126` com que esta aula começou.

O erro comum é parar em 2^h. Um `/26` tem 64 endereços e só 62 máquinas. O segundo erro vem um passo
depois: numa LAN, um desses 62 é a própria interface do roteador, então um `/26` são 62 endereços para
61 PCs, impressoras e telefones, mais o gateway.

Do `/24` até o menor:

| prefixo | máscara | bits de host | endereços | hosts |
|---|---|---|---|---|
| `/24` | 255.255.255.0 | 8 | 256 | 254 |
| `/25` | 255.255.255.128 | 7 | 128 | 126 |
| `/26` | 255.255.255.192 | 6 | 64 | 62 |
| `/27` | 255.255.255.224 | 5 | 32 | 30 |
| `/28` | 255.255.255.240 | 4 | 16 | 14 |
| `/29` | 255.255.255.248 | 3 | 8 | 6 |
| `/30` | 255.255.255.252 | 2 | 4 | 2 |
| `/31` | 255.255.255.254 | 1 | 2 | 2, num enlace ponto a ponto |
| `/32` | 255.255.255.255 | 0 | 1 | 1, um único host |

**Cada bit a mais divide a faixa ao meio.** No sentido contrário, cada bit a menos a dobra: um `/23` tem
512 endereços, um `/22` tem 1024, um `/20` tem 4096 e um `/16` tem 65.536.

As três últimas linhas merecem as suas saídas. O enlace entre o r1 e o r2 neste laboratório é um `/30`:

```
ana@sales1:~$ ipcalc -b 10.20.32.224/30
Address:   10.20.32.224         
Netmask:   255.255.255.252 = 30 
Wildcard:  0.0.0.3              
=>
Network:   10.20.32.224/30      
HostMin:   10.20.32.225         
HostMax:   10.20.32.226         
Broadcast: 10.20.32.227         
Hosts/Net: 2                     Class A, Private Internet

```

Quatro endereços: `.224` a rede, `.227` o broadcast, e dois hosts no meio. O r1 tem `.225` e o r2 tem
`.226`. **Um enlace entre dois roteadores precisa de exatamente dois endereços**, e um `/30` dá
exatamente dois, ao custo de quatro. Esse custo é o motivo de existir o próximo prefixo:

```
ana@sales1:~$ ipcalc -b 10.20.32.224/31
Address:   10.20.32.224         
Netmask:   255.255.255.254 = 31 
Wildcard:  0.0.0.1              
=>
Network:   10.20.32.224/31      
HostMin:   10.20.32.224         
HostMax:   10.20.32.225         
Hosts/Net: 2                     Class A, Private Internet, PtP Link RFC 3021

```

Um `/31` tem dois endereços e o ipcalc chama os dois de hosts, sem linha `Broadcast` nenhuma e com a
nota `PtP Link RFC 3021`. A RFC 3021 (2000) abriu a exceção: **num enlace ponto a ponto, onde não há para
quem fazer broadcast além da outra ponta, um `/31` pode usar os dois endereços**. Isso corta pela metade
o custo em endereços de cada enlace entre roteadores, e a maioria dos roteadores aceita; numa LAN não
sobraria espaço para mais nada, e ninguém o usa assim.

```
ana@sales1:~$ ipcalc -b 10.20.32.10/32
Address:   10.20.32.10          
Netmask:   255.255.255.255 = 32 
Wildcard:  0.0.0.0              
=>
Hostroute: 10.20.32.10          
Hosts/Net: 1                     Class A, Private Internet

```

Um `/32` é um endereço só, e o ipcalc o chama de `Hostroute`. Ninguém monta uma LAN de um, mas o `/32`
está em todo lugar no roteamento: uma rota para exatamente uma máquina, um endereço de loopback num
roteador que outros roteadores alcançam, um único endereço numa regra de firewall.

Escolher um tamanho é ler a tabela de trás para a frente. **Conte as máquinas, some uma para o gateway e
pegue a menor faixa cujo número de hosts seja pelo menos esse.** Uma LAN de 50 máquinas precisa de 51
endereços: um `/27` comporta 30, pouco, e um `/26` comporta 62, então é um `/26`. A aula 13 faz isso para
um plano inteiro, com várias LANs de tamanhos diferentes dentro de um bloco, e põe a maior primeiro, por
um motivo que ela explica.
