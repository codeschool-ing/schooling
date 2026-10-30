---
title: A aritmética da disponibilidade
version: 1
---

Uma porcentagem perto de cem soa como "quase nunca fora do ar", e um acordo de nível de serviço soa
como a promessa de que as máquinas vão estar de pé. As duas leituras erram, e a aritmética é o que as
corrige. **99,9% de trinta dias são quarenta e três minutos**, que é um almoço inteiro para uma loja
que recebe pedidos na hora do almoço. E um SLA é uma promessa sobre dinheiro: o que a Microsoft
devolve em crédito quando uma porcentagem não é cumprida, medida do jeito que o contrato define.

## O que a Microsoft promete para uma máquina virtual

As porcentagens estão no *Service Level Agreement for Microsoft Online Services*, um documento que a
Microsoft publica para download e revisa com frequência. A edição de 1º de outubro de 2026, lida em
2026-10-30, dá estas para Virtual Machines e para o load balancer Standard na frente delas:

| arranjo | disponibilidade prometida |
|---|---|
| uma VM, Premium SSD no disco do sistema e Premium SSD, Premium SSD v2 ou Ultra Disk em todo disco de dados | 99,9% |
| uma VM, Standard SSD | 99,5% |
| uma VM, Standard HDD | 95% |
| duas ou mais VMs no mesmo conjunto de disponibilidade | 99,95% |
| duas ou mais VMs em duas ou mais zonas de uma região | 99,99% |
| um load balancer Standard servindo duas ou mais VMs saudáveis | 99,99% |

Uma máquina com discos de tipos diferentes fica com a porcentagem do seu disco mais fraco. O load
balancer Basic não tem SLA nenhum.

**Leia o que conta como indisponibilidade antes de confiar num número.** Para máquinas em várias
zonas, um minuto está fora quando não há conectividade com nenhuma delas na região, e um conjunto é
medido do mesmo jeito entre as suas máquinas. Uma máquina de duas morta por um dia não é
indisponibilidade no sentido do contrato, porque a outra respondeu. O contrato também deixa de fora
a manutenção anunciada com pelo menos cinco dias de antecedência, e tudo o que você mesmo iniciou,
como uma reinicialização ou uma operação de escala.

O que uma porcentagem descumprida compra é um **crédito de serviço**, uma parte das tarifas daquele
serviço no período. Para máquinas em várias zonas ele é de 10% abaixo de 99,99%, 25% abaixo de 99% e
100% abaixo de 95%, e só é pago mediante uma reclamação feita até 60 dias depois do incidente. Então
um SLA diz pelo que a Microsoft vai pagar. Com que frequência a sua loja fica inalcançável é você
quem calcula.

## Uma porcentagem, em minutos

Para uma máquina virtual, o contrato mede ao longo dos 30 dias até o primeiro dia do incidente,
inclusive, o que dá 30 × 24 × 60 = 43.200 minutos. Os minutos que uma porcentagem permite são o
resto:

indisponibilidade = 43.200 × (1 − disponibilidade)

A 99,95% isso dá 43.200 × 0,0005 = 21,6 minutos. A lição 11 mediu o mesmo tipo de promessa num mês
de 730 horas, o que dá um pouco mais, 21,9 minutos; a diferença é o período, e o contrato diz qual
período quer dizer. Cada nove acrescentado divide a folga por dez.

## Duas regras para juntar partes

Um pedido à loja atravessa várias partes, e as partes se arranjam de só dois jeitos.

**Em série, toda parte tem de responder, então as disponibilidades se multiplicam.** Um pedido chega
ao load balancer e depois a uma máquina atrás dele. Se o balanceador está de pé 99,99% do tempo e a
máquina 99,9%, os dois estão de pé no mesmo instante 0,9999 × 0,999 = 0,99890 do tempo, ou 99,89%.
**Uma corrente é sempre menos disponível do que o seu elo mais fraco**, e toda dependência
acrescentada a ela, um banco de dados, um provedor de pagamento, um nome de DNS, deixa o produto
menor.

**Em paralelo, qualquer cópia serve, então o que se multiplica é a chance de falhar.** Duas cópias,
cada uma de pé 99,9% do tempo, ficam cada uma fora 0,001 dele. As duas ficam fora juntas 0,001 ×
0,001 do tempo, se as suas falhas não tiverem nada a ver uma com a outra, e o par fica de pé no
resto:

disponibilidade de n cópias = 1 − (1 − a)ⁿ = 1 − 0,001² = 0,999999

São seis noves com duas máquinas de três, e é bom demais, por um motivo que a fórmula esconde na
sua premissa. **Ela só é verdade se as duas cópias nunca falharem pelo mesmo motivo.** Duas máquinas
num host falham juntas; duas num rack, duas num datacenter, duas rodando a mesma versão ruim,
também. Domínios de falha e zonas existem para deixar a premissa mais perto da verdade, e nenhum
deles a deixa inteiramente verdadeira. O contrato também não a supõe: duas máquinas num conjunto têm
a promessa de 99,95%, não de 99,9999%.

## O programa

Aqui está a aritmética como programa, para que os números abaixo tenham sido calculados e não
digitados. Salve-o como `availability.py`. Ele não precisa de nada além do próprio Python, e o
`python3` que a lição 1 instalou o executa:

```schooling-example
{"language": "python", "file": "availability.py", "parts": [{"code": "# availability.py\nPERIOD = 30 * 24 * 60  # minutes in the 30 days a VM's SLA is measured over\n\n\ndef downtime(availability):\n    return PERIOD * (1 - availability)\n\n\n", "note": "O período sobre o qual o contrato mede uma máquina virtual, em minutos, e os minutos que uma disponibilidade deixa de fora dele. A disponibilidade é escrita como fração, `0.999`, para que a aritmética abaixo não precise dividir por cem."}, {"code": "def serial(*parts):\n    total = 1.0\n    for part in parts:\n        total *= part\n    return total\n\n\n", "note": "**Em série, multiplique.** Toda parte tem de estar de pé no mesmo instante."}, {"code": "def redundant(part, copies):\n    return 1 - (1 - part) ** copies\n\n\n", "note": "**Em paralelo, um menos o produto das falhas.** `1 - part` é a parte do tempo em que uma cópia está fora; elevado a `copies`, todas estão fora juntas, o que só é verdade se nunca falharem pelo mesmo motivo."}, {"code": "print('promise    minutes down in 30 days')\nfor promise in (0.95, 0.995, 0.999, 0.9995, 0.9999):\n    print(f'{promise:<9.2%}  {downtime(promise):8.2f}')\n\n", "note": "A tabela de conversão, para as cinco porcentagens da tabela do contrato. `:.2%` imprime uma fração como porcentagem com duas casas."}, {"code": "balancer = 0.9999\npaths = {\n    'one VM, Premium SSD': serial(balancer, 0.999),\n    'availability set': serial(balancer, 0.9995),\n    'two zones': serial(balancer, 0.9999),\n}\nprint()\nfor name, total in paths.items():\n    print(f'{name:<20} {total:.4%}  {downtime(total):6.2f} min')\n\n", "note": "A API de pedidos da loja em cada arranjo: o load balancer Standard em série com o que está atrás dele. Os números são os do contrato, lido em 2026-10-30."}, {"code": "print()\nboth = redundant(0.999, 2)\nprint(f'two VMs that never fail together: {both:.4%}  {downtime(both):.2f} min')\n", "note": "A resposta da fórmula para duas máquinas de 99,9%, que nenhum arranjo dentro de uma região tem prometida."}]}
```

Execute-o:

```
ana@laptop:~/azure$ python3 availability.py
promise    minutes down in 30 days
95.00%      2160.00
99.50%       216.00
99.90%        43.20
99.95%        21.60
99.99%         4.32

one VM, Premium SSD  99.8900%   47.52 min
availability set     99.9400%   25.92 min
two zones            99.9800%    8.64 min

two VMs that never fail together: 99.9999%  0.04 min
```

Três coisas para ler nele. A tabela é a conversão para guardar de cabeça: 43,2 minutos a 99,9%, 21,6
a 99,95%, 4,32 a 99,99%, e 36 horas aos 95% de uma máquina sozinha em Standard HDD. Os três caminhos
são o que as promessas somam para a API de pedidos da loja, contado o balanceador: 47,52 minutos
para uma máquina, 25,92 para um conjunto de disponibilidade, 8,64 para duas zonas. E a última linha,
duas máquinas que nunca falham juntas, com 0,04 minuto, é o número que ninguém promete, porque não
existem duas máquinas numa região que não dividam nada.
