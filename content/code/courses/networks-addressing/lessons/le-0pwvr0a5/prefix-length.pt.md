---
title: /27, uma máscara escrita como contagem
version: 1
---

Escrever `255.255.255.224` toda vez é lento e fácil de errar, e como uma máscara é uma sequência de uns
seguida de zeros, um número a descreve por inteiro: quantos uns ela tem. **O comprimento do prefixo,
escrito depois de uma barra, é o número de uns da máscara.** `10.20.32.200/27` quer dizer o endereço
`10.20.32.200` com uma máscara de 27 uns. O ipcalc imprime as duas formas lado a lado, o que faz dele
um bom lugar para treinar a conversão. A LAN do ops1:

```
ana@sales1:~$ ipcalc -b 10.20.32.200/27
Address:   10.20.32.200         
Netmask:   255.255.255.224 = 27 
Wildcard:  0.0.0.31             
=>
Network:   10.20.32.192/27      
HostMin:   10.20.32.193         
HostMax:   10.20.32.222         
Broadcast: 10.20.32.223         
Hosts/Net: 30                    Class A, Private Internet

```

`Netmask: 255.255.255.224 = 27`. Para converter à mão, divida 27 em octetos inteiros e um resto: 27 é
24 + 3, então três octetos de 255 e depois um octeto com três uns, `11100000`, que é 128 + 64 + 32 = 224.
No sentido contrário, conte os uns: 255 são oito, 224 são três, então 8 + 8 + 8 + 3 = 27.

Os valores que vale saber de cor são os nove que um octeto pode ter, da seção anterior, junto com
quantos uns cada um tem:

| uns no octeto | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|---|
| valor do octeto | 0 | 128 | 192 | 224 | 240 | 248 | 252 | 254 | 255 |

Então `/26` é `255.255.255.192`, `/20` é `255.255.240.0` (16 + 4: dois octetos inteiros e quatro uns), e
`/12` é `255.240.0.0`. **Qualquer prefixo está a dois números da sua máscara: quantos octetos inteiros,
e qual dos nove valores vem depois deles.**

A notação da barra tem nome, **CIDR**, *Classless Inter-Domain Routing*, e chegou em 1993 para
substituir as classes da aula 8. Antes dela, a máscara vinha implícita nos primeiros bits do endereço e
ninguém precisava escrevê-la. Depois dela, a máscara podia cair em qualquer bit, então passou a viajar
com o endereço para todo lado: nas configurações, nas tabelas de rotas, nos anúncios que os roteadores
fazem uns aos outros. A classe que ainda aparece no fim desta saída, `Class A`, descreve `10.x` pelas
regras antigas e não diz nada sobre este `/27`.

**Uma rota também tem prefixo**, como o endereço de uma interface, e foi ali que o CIDR mais fez
diferença. Neste laboratório o r1 guarda as três LANs como três rotas
separadas, `10.20.32.0/25`, `10.20.32.128/26` e `10.20.32.192/27`, enquanto o r2, acima dele, guarda uma
rota só, `10.20.32.0/24`, que cobre as três. Um prefixo mais curto no lugar de vários mais longos se
chama sumarização, e a aula 13 a monta e mostra quanto ela custa.

Uma última leitura do prefixo, fácil de esquecer: **um prefixo mais longo é uma rede menor**. Um `/27`
tem mais uns que um `/24`, então sobram menos bits para hosts, e ele tem menos endereços. Quando uma
tabela de rotas tem duas rotas que contêm um destino, o roteador usa a de prefixo mais longo, porque
ela é a mais específica das duas. A aula 14 lê essa regra numa tabela de verdade.
