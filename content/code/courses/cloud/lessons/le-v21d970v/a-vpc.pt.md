---
title: "Uma VPC: uma rede sua dentro da deles"
version: 1
---

A imagem que quase todo mundo traz é a de que uma máquina na nuvem fica na internet, do jeito que um
servidor num data center ficava num endereço público com um cabo para o mundo. Não fica. Uma máquina
virtual da aula 4 está ligada a uma rede, e **essa rede é você quem define**: os endereços, como ela
se divide, o que pode sair e o que pode entrar. O provedor chama isso de **virtual private cloud**,
uma VPC. O Azure chama a mesma coisa de virtual network, ou VNet, e o Google Cloud de VPC network.

Ela é privada num sentido preciso. O provedor opera uma rede física enorme, e a VPC de cada cliente é
recortada dela em software. Dois clientes podem usar `10.0.0.0/16` dentro das suas VPCs, na mesma
região, nos mesmos racks, e nenhum vê um pacote do outro. Nada chega a uma máquina da sua VPC vindo de
fora a menos que você tenha construído um caminho para isso, e o resto desta aula são esses
caminhos: a rota para um internet gateway, um NAT gateway, um balanceador de carga, um peering.

**Uma VPC vive numa região** na AWS e no Azure, e abrange as zonas dessa região (a aula 9 é o que é
uma zona, e por que ela importa). O Google Cloud é a exceção que vale conhecer: a VPC network dele é
global, e só as sub-redes pertencem a uma região.

## Os endereços são escolha sua

Quando você cria uma VPC, dá a ela uma faixa de endereços. Ninguém na internet vai vê-los, então eles
saem das três faixas reservadas para redes privadas pela RFC 1918, as mesmas que o roteador da sua
casa distribui:

| faixa | primeiro endereço | último endereço |
|---|---|---|
| `10.0.0.0/8` | `10.0.0.0` | `10.255.255.255` |
| `172.16.0.0/12` | `172.16.0.0` | `172.31.255.255` |
| `192.168.0.0/16` | `192.168.0.0` | `192.168.255.255` |

::: track networks-infra
Você viu essa notação em `networks-addressing`, e a próxima seção é a parte dela que uma VPC usa, com
o vocabulário do provedor por cima: leia como revisão, e vá devagar onde ela chega aos endereços que
um provedor guarda para si.
:::

::: track *
O número depois da barra é o tamanho do bloco, lido ao contrário: quanto menor ele é, maior o bloco.
A próxima seção é como lê-lo, e é toda a divisão em sub-redes de que este curso precisa.
:::

Uma escolha comum é um `/16` tirado de `10.0.0.0/8`, como `10.0.0.0/16`: grande o bastante para
dividir em muitas sub-redes, pequeno o bastante para dar uma faixa diferente a cada VPC.

## Por que a escolha importa no dia em que você liga duas redes

**Duas redes cujas faixas se sobrepõem não podem ser ligadas.** Não é "ligadas mal": um peering entre
duas VPCs, ou uma VPN de uma VPC para o escritório (a costura híbrida da aula 2), é recusado ou fica
inútil, porque um roteador que recebe um pacote para `10.0.5.9` tem de decidir de que lado está esse
endereço, e com faixas sobrepostas ele está dos dois.

O caso é real. Toda região da AWS dá a cada conta uma **VPC padrão**, criada para você, e a faixa dela
é `172.31.0.0/16` em toda conta e toda região. Dois times que construíram cada um na sua VPC padrão têm
duas redes com a mesma faixa, e no dia em que alguém pede que elas conversem, a resposta é uma
migração.

Então a escolha é feita uma vez, cedo, com uma lista na mão: a faixa do escritório, toda outra VPC que
você tem ou vai ter, a rede de qualquer parceiro a que você possa se ligar. Dê a cada uma a sua, por
exemplo `10.0.0.0/16` para produção, `10.1.0.0/16` para homologação e algo bem longe das duas para o
escritório. **Na AWS a faixa com que uma VPC foi criada não pode ser mudada** depois; dá para
acrescentar outras faixas, e só. Errar não custa nada no primeiro dia, e é exatamente por isso que se
erra.
