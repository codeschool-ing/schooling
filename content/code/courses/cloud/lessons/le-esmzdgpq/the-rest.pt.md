---
title: O resto do campo
version: 1
---

Seis nomes num título de aula deixam de fora a maior parte do mercado. Os provedores abaixo não são
versões menores das três grandes; **cada um existe por um motivo que um tipo particular de cliente
tem**, e conhecer o motivo basta para saber quando você vai encontrá-lo.

## Oracle Cloud Infrastructure

A nuvem da Oracle é mais forte onde a empresa já roda o **Oracle Database**, o que inclui muitos
bancos, seguradoras e governos. A Oracle vende ali o próprio banco como serviço gerenciado em várias
formas, entre elas um Autonomous Database que se ajusta e se atualiza sozinho. Ela vende também o
núcleo comum: máquinas virtuais, armazenamento em bloco e de objetos, redes, Kubernetes. Tem uma
região em São Paulo.

## IBM Cloud

A nuvem da IBM atende clientes que já dependem da IBM, e o fio que a costura é a **Red Hat**, que a
IBM comprou em 2019. O OpenShift da Red Hat, uma plataforma Kubernetes, roda na nuvem da IBM e nas
outras, e a IBM o vende como o jeito de rodar a mesma plataforma no data center da própria empresa e
na nuvem. É o arranjo híbrido da aula 2, vendido como produto.

## Alibaba Cloud

A Alibaba Cloud pertence ao grupo chinês Alibaba. Vende um catálogo na escala das hyperscalers. O motivo para estar nesta lista é a geografia: **uma empresa que precisa atender clientes na China continental** a encontra primeiro. Operar lá traz regras próprias, e um provedor de lá foi construído em torno delas.

## OVHcloud

A OVHcloud é francesa, fundada em 1999, e é o equivalente europeu mais próximo da Hetzner, em tamanho
maior: servidores dedicados, máquinas virtuais, armazenamento de objetos e uma lista crescente de
serviços gerenciados, em data centers que ela mesma constrói. O argumento dela para compradores
europeus é a **jurisdição**. Uma empresa europeia responde à lei europeia, enquanto as três
hyperscalers são empresas americanas, sujeitas à lei americana onde quer que estejam os data
centers. Para organizações que tratam isso como risco, essa é a decisão inteira. A aula 2 discutiu
por que a lei do lugar importa tanto quanto o lugar.

## Cloudflare

A Cloudflare é outro tipo de provedor, e está aqui para que você não procure nela a coisa errada.
**Você não aluga uma máquina virtual da Cloudflare.** Ela opera uma rede grande na frente dos
servidores de outras pessoas, protegendo e fazendo cache deles. Nessa rede ela roda o seu código na
borda (Workers, aula 8), guarda objetos (R2, compatível com S3 e sem cobrança pelos dados que saem
dele) e mantém bancos de dados pequenos. Plataformas como Vercel e Netlify ficam no mesmo nível,
acima das nuvens e não ao lado delas; a aula 8 também é delas.

## Provedores brasileiros

O Brasil tem provedores próprios. A **Magalu Cloud**, da varejista Magazine Luiza, é um deles. O
argumento de um provedor nacional é o mesmo que a Hetzner usa na Alemanha e a OVHcloud usa na França:
empresa local, lei local, dados no país, e uma fatura em reais em vez de dólares. Esse último ponto
não é pequeno. Uma fatura em dólares acompanha o câmbio, então o mesmo mês das mesmas máquinas custa
a uma empresa brasileira um valor diferente em reais a cada mês, mesmo sem nada mudar no preço de
tabela.

Os nomes importam menos que a pergunta por trás de cada parágrafo, e ela serve para qualquer
provedor que você encontrar: **por qual motivo ele existe, e esse motivo é o seu?**
