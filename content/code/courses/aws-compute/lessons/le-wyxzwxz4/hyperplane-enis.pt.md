---
title: A interface na sua subnet, antes de 2019 e depois
version: 1
---

Para uma função ter um endereço na sua subnet, alguma coisa precisa estar naquela subnet segurando o
endereço: uma elastic network interface, o mesmo tipo de objeto que é a placa de rede de uma
instância EC2. **O que mudou em setembro de 2019 é de quem essa interface é e quando ela é feita**, e
o conselho "deixe o Lambda fora das VPCs" vem do arranjo de antes.

## Uma interface por ambiente

Até 2019, todo ambiente de execução de uma função numa VPC ganhava uma interface própria, e ganhava
durante o seu cold start. Criar uma interface e conectá-la levava segundos, muitas vezes dez ou mais,
e essa espera era somada a todo cold start de toda função numa VPC, além da fase init que a lição 17
mediu. Um pico que iniciava cinquenta ambientes criava cinquenta interfaces.

Esse arranjo falhava de três jeitos, e as equipes encontraram todos:

- **o cold start**, de segundos, exatamente nas requisições que chegavam durante um pico;
- **os endereços da subnet**, um por ambiente: uma subnet `/24` tem 251 endereços utilizáveis na
  AWS, e uma função que escalava para 300 ambientes nela simplesmente ficava sem, com as outras
  máquinas da subnet disputando os mesmos endereços;
- **a cota de interfaces da conta**, compartilhada com toda instância EC2 da região, que uma função
  escalando podia esgotar para todo o resto.

## Uma interface compartilhada por subnet e security group

Desde a mudança, o Lambda usa **interfaces Hyperplane**, construídas sobre a mesma virtualização de
rede que a AWS usa para NAT gateways e Network Load Balancers. Uma interface é criada para cada
combinação de subnet e security group que uma função cita, **quando a função é criada ou a
configuração de VPC dela muda**, e todo ambiente de execução da função naquela subnet chega à VPC
por ela. Funções que compartilham a mesma combinação de subnet e security group compartilham também
a interface. A interface vive na sua conta, na sua subnet, e o Lambda é o dono dela: ela aparece na
sua lista de interfaces de rede com o Lambda como solicitante, e você não consegue desconectá-la
nem apagá-la por conta própria.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dois painéis lado a lado. Antes de 2019: quatro ambientes de execução numa subnet, cada um com a própria interface de rede, criada durante o seu cold start. Desde 2019: os mesmos quatro ambientes ligados a uma única interface Hyperplane compartilhada para aquela subnet e aquele security group, criada quando a função é configurada.\"><defs><marker id=\"en-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"16\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Antes de 2019</text><text x=\"16\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma interface por ambiente</text><rect x=\"16\" y=\"52\" width=\"332\" height=\"196\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"28\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">subnet privada</text><rect x=\"28\" y=\"84\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"88\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ambiente 1</text><path d=\"M150 99 L212 99\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#en-ah)\"></path><rect x=\"216\" y=\"84\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"276\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">ENI própria</text><rect x=\"28\" y=\"124\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"88\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ambiente 2</text><path d=\"M150 139 L212 139\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#en-ah)\"></path><rect x=\"216\" y=\"124\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"276\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">ENI própria</text><rect x=\"28\" y=\"164\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"88\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ambiente 3</text><path d=\"M150 179 L212 179\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#en-ah)\"></path><rect x=\"216\" y=\"164\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"276\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">ENI própria</text><rect x=\"28\" y=\"204\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"88\" y=\"219\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ambiente 4</text><path d=\"M150 219 L212 219\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#en-ah)\"></path><rect x=\"216\" y=\"204\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"276\" y=\"219\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">ENI própria</text><text x=\"16\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">criada durante cada cold start</text><text x=\"16\" y=\"286\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">segundos por cold start, um endereço cada</text><text x=\"372\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Desde 2019</text><text x=\"372\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma interface por subnet e security group</text><rect x=\"372\" y=\"52\" width=\"332\" height=\"196\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"384\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">subnet privada</text><rect x=\"384\" y=\"84\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"444\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ambiente 1</text><path d=\"M506 99 L568 165\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#en-ah)\"></path><rect x=\"384\" y=\"124\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"444\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ambiente 2</text><path d=\"M506 139 L568 165\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#en-ah)\"></path><rect x=\"384\" y=\"164\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"444\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ambiente 3</text><path d=\"M506 179 L568 165\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#en-ah)\"></path><rect x=\"384\" y=\"204\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"444\" y=\"219\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ambiente 4</text><path d=\"M506 219 L568 165\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#en-ah)\"></path><rect x=\"572\" y=\"140\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"632\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">ENI Hyperplane</text><text x=\"632\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">compartilhada</text><text x=\"372\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">criada quando a função é configurada</text><text x=\"372\" y=\"286\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nada no cold start, poucos endereços</text></svg>", "caption": "O que mudou em 2019. Uma interface por ambiente fazia todo cold start numa VPC esperar a criação de uma, e gastava um endereço da subnet por ambiente. Uma interface Hyperplane é criada uma vez, quando a função é configurada, e todos os ambientes daquela subnet e daquele security group a compartilham."}
```

As consequências são o avesso das antigas. **Um cold start dentro de uma VPC não espera mais por
uma interface de rede**, porque a interface já estava lá antes da primeira requisição. Um pico de
trezentos ambientes usa os mesmos poucos endereços que usava para um. E o trabalho de criar a
interface foi para o deploy: na AWS uma função cuja configuração de VPC acabou de ser definida fica
no estado `Pending` enquanto as interfaces são criadas, o que pode levar um minuto ou mais, e as
invocações dela falham até ela ficar `Active`. Um pipeline de deploy que invoca uma função logo
depois de mudar as subnets dela deve esperar esse estado.

Mais dois comportamentos da documentação da AWS, e os dois surpreendem as equipes que nunca a
leram:

- **Uma função parada perde as interfaces.** Se uma função numa VPC não é invocada por algumas
  semanas, o Lambda recolhe as interfaces Hyperplane sem uso e marca a função como `Inactive`. A
  próxima invocação falha enquanto elas são recriadas e a função volta a `Active`. Um job mensal numa
  VPC encontra isso todo mês.
- **Apagar o security group ou a subnet espera pelo Lambda.** A interface continua existindo por um
  tempo depois que a função que a usava é apagada ou mudada, e o grupo ou a subnet em que ela está
  não pode ser apagado até o Lambda removê-la.

## O que o moto mostra disso, que é nada

O moto guarda a configuração e não cria interface nenhuma. A função da seção anterior está em duas
subnets com um security group, e na AWS isso são duas interfaces Hyperplane, uma por subnet. Peça ao
moto as interfaces de rede da conta:

```
ana@laptop:~/aws$ aws ec2 describe-network-interfaces --query "NetworkInterfaces[].NetworkInterfaceId"
[]
```

A lista está vazia. O moto registra o `VpcConfig` de uma função e não faz nada com ele, então as
interfaces, o estado `Pending` e o recolhimento das paradas são todos comportamento documentado da
AWS aqui, e nada disso foi executado. A próxima seção cria um interface endpoint, e ali o moto cria
interfaces nas subnets, o que deixa fácil ver a ausência acima ao lado dela.

**O custo que o título desta lição menciona é o cold start de antes de 2019, e ele acabou.** Uma
função numa VPC hoje inicia tão rápido quanto uma fora dela. O que sobra é o custo da saída, e esse
é cobrado.
