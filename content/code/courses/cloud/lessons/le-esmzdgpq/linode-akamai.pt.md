---
title: "Linode, hoje Akamai: máquinas ao lado de uma rede de entrega"
version: 1
---

O Linode começou em 2003 vendendo servidores virtuais Linux, três anos antes do EC2, o que o põe
entre as primeiras empresas a alugar uma máquina virtual a qualquer pessoa com um cartão. Durante a
maior parte da vida ele se pareceu com o que a DigitalOcean é hoje: uma lista curta de produtos, um
preço mensal por plano com transferência incluída, e clientes que eram, na maioria, desenvolvedores
e empresas pequenas.

**Em 2022 a Akamai o comprou**, e isso mudou a função dele.

## O que a Akamai acrescenta

A Akamai é uma das redes de entrega de conteúdo mais antigas. O negócio dela era, e é, um número
muito grande de servidores colocados perto dos usuários, dentro ou perto das redes dos provedores de
internet. Eles respondem a pedidos de sites e vídeos, para que o pedido não precise atravessar o
mundo. O que ela não tinha era um lugar para alugar uma máquina virtual comum. O Linode era esse
lugar.

Então o produto que se chamava Linode hoje é vendido **com o nome da Akamai, como a computação em
nuvem da Akamai**. O argumento dele é a combinação: máquinas virtuais, discos e bancos de dados num
conjunto de regiões, ao lado de uma rede de entrega que chega muito mais longe do que as regiões. Um
serviço de vídeo, por exemplo, pode manter as máquinas de codificação numa região e entregar os
arquivos prontos à rede de entrega na frente delas, com uma empresa só e numa fatura só.

O nome Linode não sumiu. Ele continua no endereço da API, na ferramenta de linha de comando
(`linode-cli`) e em boa parte da documentação, e as pessoas ainda dizem "um Linode" para uma das
máquinas virtuais. **Quando você ler Linode num lugar e nuvem da Akamai em outro, é o mesmo
produto.**

## A lista de produtos

É a lista curta de novo, com nomes próprios:

| o quê | o nome no Linode |
| --- | --- |
| uma máquina virtual | um Linode, com processadores compartilhados ou dedicados |
| discos de bloco | volumes de Block Storage |
| armazenamento de objetos | Object Storage, compatível com S3 |
| um balanceador de carga | um NodeBalancer |
| Kubernetes gerenciado | LKE, o Linode Kubernetes Engine |

Bancos de dados gerenciados e redes privadas ficam ao lado deles. O modelo de preço é o mesmo que a
DigitalOcean e a Hetzner compartilham: **um plano tem um preço mensal, com transferência incluída**,
e o valor por hora para de contar ao chegar a esse preço mensal. A Akamai publica os valores nas
próprias páginas, que este curso não capturou.

## Uma região em São Paulo

Dos três provedores menores do título desta aula, **o da Akamai é o que tem uma região em São
Paulo**. Para uma equipe brasileira que quer a lista curta e a conta simples, mas precisa das
máquinas no país por latência ou por lei, esse único fato pode decidir entre os três antes mesmo de
alguém olhar o preço.

Ele também mostra por que a lista de verificação no fim desta aula põe as regiões antes do preço.
Um provedor mais barato e em outro continente não é mais barato para um usuário que sente cada ida e
volta, e a aula 9 é onde essa viagem ganha um número.
