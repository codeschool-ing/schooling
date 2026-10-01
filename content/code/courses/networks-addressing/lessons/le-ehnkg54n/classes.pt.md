---
title: As classes A, B e C, e por que ninguém planeja com elas
version: 1
---

Até 1993, os primeiros bits de um endereço decidiam onde terminava a sua parte de rede. Ninguém
escolhia máscara: um endereço que começava com o bit 0 tinha 8 bits de rede, um que começava com 10
tinha 16, e um que começava com 110 tinha 24. Esse esquema se chama **endereçamento com classes**
(*classful*), e a internet deixou de usá-lo há mais de trinta anos. Ainda vale conhecê-lo por dois
motivos: as ferramentas ainda o imprimem, e as pessoas ainda dizem "uma classe C" quando querem dizer
um /24.

| classe | primeiros bits | primeiro octeto | parte de rede | para que servia |
|---|---|---|---|---|
| A | `0` | 0 a 127 | 8 bits, `/8` | 126 redes enormes |
| B | `10` | 128 a 191 | 16 bits, `/16` | redes médias |
| C | `110` | 192 a 223 | 24 bits, `/24` | redes pequenas |
| D | `1110` | 224 a 239 | nenhuma | grupos multicast |
| E | `1111` | 240 a 255 | nenhuma | reservada |

As faixas do primeiro octeto saem dos primeiros bits. Um endereço classe B começa com `10`, então seu
primeiro octeto vai de `10000000` (128) a `10111111` (191). **A classe se lê no primeiro octeto, e dá
para fazer de cabeça**: 172 está entre 128 e 191, então 172.16.5.4 é classe B.

O `ipcalc` ainda imprime a classe. Aqui, num endereço classe B:

```
ana@pc1:~$ ipcalc -b 172.16.5.4
Address:   172.16.5.4           
Netmask:   255.255.255.0 = 24   
Wildcard:  0.0.0.255            
=>
Network:   172.16.5.0/24        
HostMin:   172.16.5.1           
HostMax:   172.16.5.254         
Broadcast: 172.16.5.255         
Hosts/Net: 254                   Class B, Private Internet

```

Olhe a máscara. **Sem máscara informada, este ipcalc assume `/24` para qualquer endereço**, diga a
classe o que disser, e a saída mostra `Class B` ao lado de uma rede `/24`. Um roteador que seguisse
as regras das classes teria lido 172.16.5.4 como parte de 172.16.0.0/16. A classe virou um rótulo
que a calculadora deduz dos primeiros bits, e não decide mais nada. O mesmo comando em 10.1.2.3 e em
192.168.1.1 imprimiu `Class A` e `Class C`, cada um ao lado do mesmo `/24`.

As classes caíram porque os tamanhos dão saltos. Uma rede classe C tem 254 hosts, uma classe B tem
65.534 e uma classe A tem 16.777.214, sem nada no meio. Uma organização com 300 máquinas era grande
demais para uma C, então recebia uma B e deixava mais de 65.000 endereços sem uso. As redes classe B
começaram a faltar no início dos anos 1990, e a alternativa, distribuir várias redes classe C, punha
uma rota separada para cada uma em todo roteador da internet. **O CIDR (*Classless Inter-Domain
Routing*, 1993) deixou a máscara cair em qualquer bit**, e a organização com 300 máquinas recebe um
`/23` de 510 hosts; a aula 12 é a aritmética disso.

A classe D é a exceção que continua valendo. Os endereços de 224 a 239 são grupos **multicast**: um
pacote mandado a um deles é entregue a toda máquina que entrou no grupo, e a mais ninguém. O ipcalc
num deles:

```
ana@pc1:~$ ipcalc -b 224.0.0.5
Address:   224.0.0.5            
Netmask:   255.255.255.0 = 24   
Wildcard:  0.0.0.255            
=>
Network:   224.0.0.0/24         
HostMin:   224.0.0.1            
HostMax:   224.0.0.254          
Broadcast: 224.0.0.255          
Hosts/Net: 254                   Class D, Multicast

```

`Class D, Multicast` está certo. As linhas `HostMin`, `HostMax` e `Broadcast` acima não fazem
sentido: um endereço multicast é um grupo, sem hosts dentro, e a calculadora aplicou a aritmética de
um `/24` mesmo assim, porque foi o que lhe pediram. **Uma ferramenta calcula o que lhe pedem; ela não
sabe se a pergunta faz sentido.** O próprio 224.0.0.5 é o grupo que os roteadores OSPF usam para
conversar entre si, e a aula 16 é sobre o OSPF.

A classe E, de 240 para cima, ficou reservada para uso futuro e nunca foi distribuída. O que sobrevive
das classes no dia a dia é sobretudo vocabulário, e as faixas de primeiro octeto dos blocos privados
da próxima seção.
