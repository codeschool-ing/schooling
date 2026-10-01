---
title: Sub-redes iguais, necessidades desiguais
version: 1
---

A aula 12 cortou um bloco em sub-redes com uma máscara só, então todo pedaço saiu do mesmo tamanho.
Isso funciona quando as redes têm o mesmo tamanho, e as de verdade quase nunca têm. **VLSM**
(*Variable Length Subnet Masking*, máscaras de tamanho variável) é a ideia simples de dar a cada
sub-rede a máscara que cabe nela, e esta aula planeja, monta e quebra uma.

A empresa do laboratório desta aula tem um bloco, 10.20.32.0/24, e quatro redes para colocar nele:

| rede | hosts de que precisa |
|---|---|
| vendas | 100 |
| engenharia | 50 |
| operações | 20 |
| o enlace entre os roteadores r1 e r2 | 2 |

O primeiro impulso é o que a aula 12 ensinou: quatro redes, então corte o /24 em quatro pedaços
iguais. Dois bits da parte de host vão para o número da sub-rede, o que deixa um /26. Isto é o que
cabe num desses pedaços:

```
ana@hq1:~$ ipcalc -b 10.20.32.0/26
Address:   10.20.32.0           
Netmask:   255.255.255.192 = 26 
Wildcard:  0.0.0.63             
=>
Network:   10.20.32.0/26        
HostMin:   10.20.32.1           
HostMax:   10.20.32.62          
Broadcast: 10.20.32.63          
Hosts/Net: 62                    Class A, Private Internet

```

**62 hosts por sub-rede**, e esse número decide tudo. Vendas precisa de 100, então vendas não cabe, e
nenhum rearranjo a faz caber enquanto todo pedaço for um /26. Enquanto isso, as outras três recebem
62 cada uma, precisem ou não:

| rede | precisa | um /26 dá | sobra sem uso |
|---|---|---|---|
| vendas | 100 | 62 | não cabe |
| engenharia | 50 | 62 | 12 |
| operações | 20 | 62 | 42 |
| enlace r1–r2 | 2 | 62 | 60 |

O enlace é o pior deles. **Um cabo entre dois roteadores tem exatamente duas pontas, e um /26 gasta
62 endereços de host com ele**, então 60 ficam numa faixa que ninguém nunca vai usar, e não podem ser
emprestados a mais ninguém, porque pertencem àquela sub-rede.

Fixe a máscara para o outro lado e não fica melhor. Com um /25 em tudo, vendas cabe, com espaço para
126, mas um /24 só comporta dois /25, e as redes são quatro. Quatro /25 são 512 endereços, o dobro do
bloco que a empresa tem. **Uma máscara única ou deixa a maior rede sem espaço ou desperdiça o bloco
com as menores**, e com estas quatro necessidades faz as duas coisas, conforme o lado para onde se
arredonda.

Então cada sub-rede ganha o seu tamanho: um /25 para vendas, um /26 para engenharia, um /27 para
operações e um /30 para o enlace, que ocupam 228 dos 256 endereços e deixam o resto num pedaço só
para depois. A próxima seção é o método que chega nesses quatro, e o ipcalc faz a mesma aritmética
para conferir.

Uma condição vem com as máscaras variáveis, e ela é de roteamento, não de aritmética. **Um roteador
que aprende uma rota precisa aprender a máscara junto**, ou não consegue distinguir um /26 de um /27
que começa em outro endereço. Todo protocolo de roteamento em uso hoje leva a máscara com cada rota.
A primeira versão do RIP não levava, e por isso não podia ser usada com VLSM; a aula 16 trata do RIP
e dos protocolos ao lado dele.
