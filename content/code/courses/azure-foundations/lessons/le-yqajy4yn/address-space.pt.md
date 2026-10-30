---
title: Uma rede virtual é um intervalo de endereços numa região
version: 1
---

**Uma rede virtual, uma VNet na abreviação do próprio Azure, é um intervalo de endereços privados que
pertence a uma assinatura e mora numa região.** As máquinas colocadas nela recebem endereços desse
intervalo, conversam entre si sem ninguém abrir porta nenhuma, e não conversam com nada de fora até
alguém abrir. Ela é o chão em que toda lição de rede deste curso pisa, e não carrega tráfego nenhum
por conta própria: é um conjunto de regras sobre quais endereços existem e para onde vai um pacote
destinado a cada um.

Três propriedades decidem quase tudo o que vem depois:

- **Ela é regional, e cobre todas as zonas da sua região.** A `vnet-shop-prod` mora em
  `brazilsouth`, e uma sub-rede dela está disponível nas zonas 1, 2 e 3 ao mesmo tempo. Um desenho que
  espalha máquinas por três zonas não precisa de três sub-redes para isso, e esse é o primeiro ponto
  em que o Azure difere do desenho que outras nuvens fazem.
- **O intervalo é seu para escolher, entre os privados.** A Microsoft recomenda os três blocos da RFC
  1918, `10.0.0.0/8`, `172.16.0.0/12` e `192.168.0.0/16`, e aceita o espaço compartilhado da RFC
  6598, `100.64.0.0/10`. Alguns intervalos são recusados de saída, entre eles `168.63.129.16/32`, o
  endereço em que o DNS e as verificações de saúde do próprio Azure respondem dentro de toda rede.
- **O intervalo pode crescer.** Intervalos de endereços podem ser acrescentados a uma VNet, e
  removidos, depois que ela existe; uma sub-rede pode ser redimensionada enquanto nada estiver
  implantado nela. Ficar sem endereços é um incômodo e não uma reconstrução, desde que o novo
  intervalo não colida com nada.

## A única regra cara de quebrar

**Duas redes que algum dia vão ser ligadas não podem se sobrepor.** Ligar quer dizer peering, o
assunto da lição 20, ou uma VPN ou um circuito privado até um escritório, a lição 23. Em todos os
casos cada lado precisa saber que um endereço pertence ao outro, e um endereço que existe dos dois
lados não pertence a nenhum. O Azure recusa o peering; o roteador do escritório simplesmente manda os
pacotes para o lugar errado.

O plano da loja dá a cada rede um bloco próprio de `10.0.0.0/8` e deixa o escritório fora dele:

| rede | intervalo | onde |
|---|---|---|
| `vnet-shop-hub` | `10.0.0.0/16` | `shop-shared`: o firewall, os gateways, lições 18 e 23 |
| `vnet-shop-prod` | `10.20.0.0/16` | `shop-prod`: a própria loja |
| `vnet-shop-staging` | `10.30.0.0/16` | `shop-staging`: as versões antes de irem ao ar |
| o escritório | `192.168.0.0/16` | São Paulo, ligado na lição 23 |

Conferir sobreposições num plano é aritmética, e o módulo `ipaddress` do Python faz isso. Crie o
diretório da lição e pergunte se o intervalo de produção colide com cada um dos outros, e com o
`10.0.0.0/8` inteiro:

```sh
mkdir -p ~/azure/vnet && cd ~/azure/vnet
```

```
ana@laptop:~/azure/vnet$ for n in 10.0.0.0/16 10.30.0.0/16 192.168.0.0/16 10.0.0.0/8; do python3 -c "import ipaddress as i, sys; print(sys.argv[1], i.ip_network('10.20.0.0/16').overlaps(i.ip_network(sys.argv[1])))" $n; done
10.0.0.0/16 False
10.30.0.0/16 False
192.168.0.0/16 False
10.0.0.0/8 True
```

A última linha é a armadilha que a tabela evita. **Um `/8` contém todo `/16` que começa com `10.`**,
então um escritório que anuncia o `10.0.0.0/8` inteiro porque "a gente usa endereços 10-ponto" se
sobrepõe a toda rede que a loja vai construir no Azure. Peça ao escritório os intervalos que ele usa
de verdade, antes da primeira VNet, porque depois um dos dois vai ter de ser renumerado.

## Criando uma, e o que o laboratório pode dizer

Uma VNet é um recurso de `Microsoft.Network`, criado num grupo de recursos:

```
ana@laptop:~/azure/vnet$ az network vnet create --name vnet-shop-prod --resource-group rg-shop-prod --address-prefixes 10.20.0.0/16
ERROR: Please run 'az login' to setup account.
```

**Não foi criada**, como todo pedido ao Resource Manager neste laboratório. Com uma conta, o comando
responde com a rede nova em JSON, o seu `addressSpace` e uma lista vazia de sub-redes, e não custa
nada: uma VNet e as suas sub-redes são gratuitas. O que custa é o que você põe nelas e aquilo a que
você as liga, que as lições 18 a 23 precificam. A seção depois da próxima escreve a mesma rede em
Bicep, onde o laboratório pelo menos consegue conferir o formato.
