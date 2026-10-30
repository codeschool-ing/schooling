---
title: Para que serve o App Service, ao lado do Container Apps e do AKS
version: 1
---

O App Service é fácil de arquivar como o jeito antigo de hospedar um site no Azure, o de antes dos
contêineres, mantido para aplicações que ninguém mudou ainda. A loja é o contraexemplo: o contêiner
da lição 7, sem mudança, roda nele, e as duas últimas seções deram a ele uma cópia de staging e uma
versão nova sem interrupção. **O que o App Service vende é um número fixo de máquinas para
aplicações web, alugadas por instância, com a maquinaria de lançamento já construída.** O Container
Apps, lição 8, vende réplicas que vêm e vão com o tráfego. O AKS, lição 11, vende um cluster
Kubernetes cujas máquinas você dimensiona e paga. Os três podem rodar a mesma imagem, e a escolha
entre eles é uma escolha sobre como a conta se comporta e quanto da plataforma a equipe opera. Esta
seção é lida da documentação da Microsoft e das lições anteriores; não tem nada para rodar.

## O que um plano dá

**Máquinas que ficam.** As instâncias de um plano rodam com ou sem alguém chamando, e com
`alwaysOn` o app nelas continua carregado. Sem ele, diz a documentação, um app é descarregado depois
de 20 minutos sem requisição, e quem chama em seguida paga pelo aquecimento. Uma aplicação web com
clientes o dia todo, num fuso horário, é o caso a que isso serve. A conta é o número de instâncias
vezes as horas, fácil de prever e fácil de ler.

**A maquinaria de lançamento.** Slots, o swap com aquecimento, o swap com prévia e uma volta atrás
que é mais um swap vêm embutidos do tier Standard para cima, sem custo extra. O Container Apps tem o
equivalente em revisões e pesos de tráfego, lição 8, e o AKS tem o que a equipe instalar e mantiver
para isso.

**Recursos de que uma aplicação web precisa e que ninguém quer construir.** Domínios personalizados
com certificados, incluindo certificados gerenciados gratuitos do Basic para cima; login embutido,
que a documentação chama de autenticação do App Service; Always On; backups; WebJobs para trabalho
em segundo plano ao lado do app; e implantação a partir de código, com o runtime da Microsoft, para
uma equipe que ainda não tem Dockerfile. Um contêiner é opcional no App Service, enquanto nos outros
dois é o ponto de partida.

## O que ele custa

**O plano é pago quando está ocioso.** Não existe escalar até zero num tier dedicado. O autoscale,
a partir do Standard, e o escalonamento automático, no Premium v2 a v4, somam instâncias sob carga e
as tiram depois, mas um plano nunca fica sem nenhuma, e a noite em São Paulo é cobrada como a
tarde. Uma revisão no Container Apps com mínimo de zero não custa nada enquanto ninguém a chama,
lição 8, e esse é o motivo mais forte para a loja ficar lá se as noites dela são vazias.

**Slots dividem as máquinas da produção.** A figura da seção 02 é o custo além da economia. Um teste
de carga no staging roda nas instâncias de que a produção está servindo. Uma equipe que quer o
staging em máquinas próprias dá a ele um plano próprio, e aí um swap deixa de ser possível, porque um
swap é entre slots de um mesmo app.

**Um app, uma porta, uma escala.** O App Service manda HTTP para uma porta do contêiner,
`WEBSITES_PORT`. No Linux um app também pode levar até nove contêineres sidecar ao lado do
principal, dividindo a rede dele e escalando com ele, o que serve a um agente de telemetria ou a um
cache. Vários serviços que chamam uns aos outros e escalam cada um pelos próprios eventos são aquilo
para que um ambiente do Container Apps foi construído.

**Menos controles por baixo.** Não há API do Kubernetes, nem nó para entrar, nem escolha de como se
comporta o balanceador de carga na frente. Para uma aplicação web essa é a barganha. Para uma carga
que precisa de um scheduler, de rede personalizada por serviço ou de um operador do ecossistema
Kubernetes, é a razão de o AKS existir.

## Os quatro, lado a lado

| | Container Instances, lição 7 | App Service, esta lição | Container Apps, lição 8 | AKS, lição 11 |
| --- | --- | --- | --- | --- |
| o que você aluga | um grupo, por segundo | as instâncias de um plano, enquanto existirem | réplicas, por segundo, ou nós dedicados | VMs de nó, mais o tier do plano de controle |
| ocioso | um grupo parado não custa nada | as instâncias do plano, a noite toda | nada, com mínimo de zero | os nós continuam rodando |
| uma versão nova | um reinício no lugar | um swap entre slots, aquecido antes | uma revisão nova, tráfego por peso | o que o cluster roda: um rolling update por padrão |
| vários serviços | um grupo | um app por serviço, em planos divididos | apps num ambiente, numa rede só | tudo que o Kubernetes consegue descrever |
| o que a equipe opera | quase nada | o tamanho e o número do plano | o ambiente e as regras de escala | o cluster, as atualizações e os add-ons dele |

**Leia a segunda linha primeiro.** Para um serviço que atende clientes o dia todo, a linha do ocioso
custa pouco em qualquer coluna; para um que fica quieto metade do dia, ela decide a maior parte da
conta. A lição 21 põe o perfil real de requisições da loja contra os quatro com aritmética, e é lá o
lugar de decidir com números. Aqui a decisão é sobre o formato.

## Para a loja

A API de pedidos se encaixa bem no App Service. Os clientes dela chegam ao longo do dia, e ela é uma
aplicação web numa porta só. O que a equipe queria na lição 7, uma versão nova sem interrupção e um
caminho de volta, é um swap e um segundo swap. Um plano `P1v3` de duas instâncias, redundante entre
zonas, a carrega, o slot de staging não custa nada além da capacidade que ocupa, e os desenvolvedores
testam no endereço do slot antes de cada versão. O site administrativo pode dividir o plano enquanto
continuar pequeno.

O relatório noturno de vendas e a exportação financeira não são trabalho de App Service. Um plano
cobrado o dia todo por um job que roda dez minutos por noite é o formato errado; eles continuam os
grupos de contêineres da lição 7, ou viram jobs do Container Apps. E no dia em que a loja se dividir
em vários serviços que chamam uns aos outros, escalam pelo tamanho de uma fila e querem ficar quietos
à noite, ela terá crescido para o que a lição 8 descreve. A imagem vai junto sem mudança: `shop:1.1`
é a mesma imagem num laptop, num slot, numa revisão e num pod.
