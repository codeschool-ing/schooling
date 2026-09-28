---
title: "Caminhos privados: alcançar coisas sem passar pela internet"
version: 1
---

Tudo até aqui sai da VPC pelo internet gateway, direto ou através de um NAT gateway. Três tipos de
tráfego têm uma saída melhor, e cada um é assunto próprio nos cursos de cada fornecedor; o que você
precisa aqui é reconhecê-los e saber para que serve cada um.

## Endpoints, para os serviços do próprio provedor

Uma instância privada que grava no armazenamento de objetos do provedor (aula 5) sairia, por padrão,
pelo NAT gateway até o endereço público do serviço de armazenamento, pagando a cobrança de
processamento da seção de NAT em cada gigabyte para alcançar um serviço na mesma região. **Um endpoint
é um caminho privado da VPC até um serviço do provedor.** A AWS tem dois tipos. Um gateway endpoint é uma rota na
tabela da sub-rede que aponta as faixas de endereço do serviço para o endpoint; existe para S3 e
DynamoDB, sem custo. Um interface endpoint é uma interface de rede com endereço privado na sua própria
sub-rede, para a maioria dos outros serviços, cobrado por hora e por gigabyte.
O Private Google Access do Google Cloud e os private endpoints do Azure atendem à mesma necessidade. Um
job de backup que copia terabytes para o armazenamento de objetos toda noite é o caso em que a
diferença aparece na fatura.

## Peering, entre duas VPCs

**O VPC peering liga duas VPCs** para que as instâncias de cada uma alcancem a outra por endereço
privado, com uma rota nas tabelas de cada lado apontando a faixa da outra para o peering. É o caso para
o qual a primeira seção desta aula preparou: as faixas não podem se sobrepor. Na AWS um peering também
não é transitivo. Se A tem peering com B e B com C, A ainda não alcança C através de B: precisa de um
peering próprio. Passando de um punhado de VPCs, os provedores oferecem um hub ao qual toda VPC se
liga, que na AWS é o transit gateway.

## Uma VPN ou um link dedicado, até o escritório

A nuvem híbrida da aula 2 precisa de um caminho entre a VPC e uma rede que é sua. **Uma VPN
site-to-site** é um túnel cifrado pela internet entre um gateway do lado do provedor e um roteador no
escritório: rápida de montar e limitada pela qualidade da internet no dia. Um link dedicado é um
circuito privado das suas instalações, ou de um data center onde você aluga espaço, até a rede do
provedor: AWS Direct Connect, Azure ExpressRoute, Google Cloud Interconnect. Leva semanas para ser
contratado e dá banda e latência previsíveis. Os dois exigem que a faixa do escritório e a da VPC sejam
diferentes, e é por isso que a escolha da primeira seção foi feita com a faixa do escritório na mão.

Como cada um é configurado, quanto custa e onde estão seus limites é assunto de `aws-foundations`,
`azure-foundations` e `gcp-foundations`; como são protegidos é assunto de `cloud-security`.
