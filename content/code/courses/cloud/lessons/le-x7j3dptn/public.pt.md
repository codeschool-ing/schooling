---
title: "Nuvem pública: estranhos no mesmo hardware"
version: 1
---

Uma nuvem pública está aberta a qualquer um que consiga se cadastrar e pagar. O provedor é dono dos
prédios, das máquinas e da rede, e **as suas cargas dividem tudo isso com as cargas de outros
clientes**. A máquina virtual que você sobe numa região pública roda num servidor físico que, naquele
momento, quase certamente está rodando máquinas de outra pessoa. É o agrupamento de recursos da aula
1 visto da cadeira do cliente, e tem nome: **multi-tenancy**, ou multilocação. Um *tenant*, um
inquilino, é um cliente, e multi-tenant quer dizer muitos deles num mesmo hardware.

A imagem errada é que dividir o hardware é dividir os dados, como se o vizinho no mesmo servidor
pudesse abrir o seu disco ou ler os seus pacotes. Manter os inquilinos separados é o produto central
do provedor, e isso é feito em duas camadas.

## Duas camadas de isolamento

A primeira camada é **o hipervisor**, o software que roda máquinas virtuais num host físico. Ele dá a
cada convidado sua própria fatia de memória, seus próprios discos virtuais e sua própria interface de
rede, e recusa qualquer tentativa de um convidado alcançar outro. A aula 4 trata das máquinas
virtuais em si; aqui basta saber que a fronteira entre dois inquilinos no mesmo host é software que o
provedor escreve e corrige.

A segunda camada é **software acima da máquina**. Toda requisição à API do provedor é conferida contra
a identidade que a fez, então as suas credenciais abrem os seus recursos e os de mais ninguém (aula
7). A rede de cada cliente é uma rede privada própria, que não carrega tráfego de ou para a de outro
cliente a menos que um deles ligue as duas de propósito (aula 6).

A fronteira é forte e não é mágica. Em janeiro de 2018 os ataques chamados Spectre e Meltdown
mostraram que um programa conseguia deduzir memória que nunca teve permissão de ler, pelo jeito como
os processadores executam adiantado a instrução em que estão. Os provedores corrigiram hosts e
hipervisores em toda a frota. Para clientes que não podem dividir hardware de jeito nenhum, os
provedores vendem opções dedicadas a um preço maior — a AWS as chama de Dedicated Instances e
Dedicated Hosts —, o que transforma a multi-tenancy numa configuração que se paga para desligar.

## O que você ganha

O primeiro ganho é **capacidade que você nunca comprou**. Cem máquinas por uma hora custam o mesmo que
uma máquina por cem horas, porque o preço de tabela é por hora de uso. Ao preço público de uma
`t3.medium` em `sa-east-1`, 0,06720 USD por hora, cem delas durante uma hora de teste de carga dão
6,72 USD, e depois somem.

Vêm junto serviços que ninguém montaria para uma empresa só: bancos de dados gerenciados, um serviço
de DNS com servidores pelo mundo, regiões em vários continentes. E o prédio, a energia, a
refrigeração e a troca do hardware passam a ser problema do provedor.

## O que você entrega

- a escolha de hardware e de lugar: você escolhe uma região e um tipo de máquina, não um rack nem um
  fornecedor;
- as regras: preços, cotas e a vida útil de um serviço são definidos pelo provedor, no calendário
  dele, para todos os clientes de uma vez;
- vizinhos previsíveis: um host dividido com outros inquilinos pode entregar menos do que entregou
  ontem, porque hoje eles estão ocupados;
- uma saída gratuita: dados saindo do provedor são **cobrados por gigabyte**, e a seção sobre a
  emenda calcula quanto.

E a linha da aula 1 continua valendo. O provedor protege o hardware e o hipervisor; as permissões,
as regras de rede e o bucket deixado legível para o mundo são seus, quantos inquilinos o host tiver.
