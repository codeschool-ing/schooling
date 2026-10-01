---
title: "Nuvem privada: um datacenter ainda não é uma"
version: 1
---

Uma empresa tem uma sala de servidores rodando um hipervisor, algumas centenas de máquinas virtuais
neles, e um slide que diz *nossa nuvem privada*. Pode ser uma. Na maioria das vezes, é **um datacenter
virtualizado**, e a diferença não está no hardware. Está em as cinco características da aula 1
valerem ou não.

Pegue o arranjo de costume, em que o desenvolvedor que precisa de uma máquina abre um chamado e um
administrador a cria dois dias depois, e compare com as cinco:

| característica | o datacenter virtualizado com fila de chamados |
|---|---|
| autoatendimento sob demanda | não: uma pessoa aprova e monta cada máquina |
| acesso amplo pela rede | sim: ele é alcançado pela rede da empresa |
| agrupamento de recursos | sim: o cluster de hipervisores divide seus hosts entre as equipes |
| elasticidade rápida | não: a capacidade muda quando alguém agenda o trabalho |
| serviço medido | raramente: ninguém sabe dizer qual equipe usou quanto |

Duas de cinco. A virtualização entregou o agrupamento, e **agrupamento é só uma característica**. A
mesma sala vira nuvem privada quando uma equipe consegue chamar uma API ou usar um portal e ter uma
máquina em minutos, sem ninguém aprovando cada uma. O pool precisa crescer e encolher sob demanda,
dentro do hardware que tem. E o uso precisa ser medido por equipe, mesmo que ninguém seja cobrado e
os números só entrem num relatório. Essa última prática se chama *showback*, em oposição ao *chargeback*, que
fatura a equipe.

## Do que ela é feita

O software que transforma uma sala de servidores em nuvem privada é uma pilha com uma API na frente:
recebe pedidos, acha um host com espaço, cria a máquina, o disco e a rede, e registra quem pediu. O
**OpenStack** é a pilha de código aberto mais conhecida. Pilhas montadas sobre produtos da
**VMware** são uma escolha comercial comum, sobretudo onde a empresa já virtualizava com eles. As
duas dão às equipes da organização algo que, do lado delas, parece o IaaS da aula 1.

## Na empresa, ou hospedada

A NIST deixa a nuvem privada ficar em qualquer lugar, e os dois arranjos são comuns:

- na empresa (on-premises): o prédio da própria organização, a equipe dela, o hardware dela;
- hospedada: hardware dedicado a um só cliente no datacenter de um provedor ou de uma empresa de
  colocation, muitas vezes operado por esse provedor sob contrato.

As duas são privadas no sentido que importa: as cargas de uma só organização naquele hardware. A
versão hospedada tira da empresa o prédio, a energia e muitas vezes a operação. Não tira o teto.

## O teto é o que você comprou

Elasticidade numa nuvem privada é **elasticidade dentro de um pool fixo**. Se o pool tem 400 núcleos e
o lote de fim de mês quer 600, o portal responde com uma recusa ou uma fila, por melhor que seja a
automação. Mais capacidade é um pedido de compra, uma entrega e um dia montando rack, coisa medida em
semanas e não em minutos.

Então a empresa dimensiona a nuvem privada para o pico, mais o crescimento esperado até a próxima compra,
mais uma margem de folga, e a maior parte disso fica ociosa fora do pico. **Capacidade ociosa é o
preço do controle**, e ela é paga quer alguém a use, quer não. Uma região pública tem a mesma capacidade ociosa,
espalhada entre todos os clientes; essa divisão é exatamente do que a nuvem privada abre mão.

Isso não faz dela um erro. Os motivos que se sustentam são específicos: dados ou regras que proíbem
hardware compartilhado, cargas tão estáveis que a margem ociosa fica pequena, sistemas na empresa que
precisam estar a poucos metros, e hardware e gente que a empresa já tem. A seção sobre repatriação
põe números no segundo desses; os outros estão na tabela do fim da aula.
