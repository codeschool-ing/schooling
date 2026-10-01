---
title: Uma instância é uma fatia da máquina de outra pessoa
version: 1
---

A imagem que a maioria das pessoas traz para a primeira instância é a de um servidor num rack com o
nome delas: um computador inteiro, alugado em vez de comprado. **Essa imagem está errada justamente
na parte que importa.** Uma instância é uma máquina virtual, e ela roda num host físico que o
provedor possui, opera e compartilha, no caso comum com outros clientes de quem você nunca vai ouvir
falar.

Entre o hardware e cada instância em cima dele fica um **hipervisor**, o software (e, nos hosts mais
novos, hardware dedicado) cujo único trabalho é dividir a máquina. Ele entrega a cada convidado
algumas threads de processador e uma quantidade fixa de memória, dá a ele placas de rede e discos
virtuais, e o impede de ver ou tocar os convidados ao lado. Cada instância dá boot no próprio sistema
operacional e não consegue saber, de dentro, quantos vizinhos tem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um host físico operado pelo provedor. Quatro espaços ficam sobre um hipervisor: a sua instância, duas instâncias de outros clientes e capacidade livre. Abaixo do hipervisor está o hardware. Uma linha tracejada marca onde termina o que você vê.\"><defs><marker id=\"host-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"12\" width=\"688\" height=\"278\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"30\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">um host físico no data center do provedor</text><rect x=\"36\" y=\"48\" width=\"150\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"111\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">sua instância</text><text x=\"111\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">vCPU  vCPU</text><text x=\"111\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SO e programas próprios</text><rect x=\"202\" y=\"48\" width=\"150\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"277\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">outro cliente</text><text x=\"277\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">vCPU  vCPU</text><text x=\"277\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SO e programas próprios</text><rect x=\"368\" y=\"48\" width=\"150\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"443\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">outro cliente</text><text x=\"443\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">vCPU  vCPU</text><text x=\"443\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SO e programas próprios</text><rect x=\"534\" y=\"48\" width=\"150\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"609\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">ainda não alugado</text><path d=\"M28 158 L692 158\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"36\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o que você vê e administra</text><text x=\"36\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o que o provedor opera e você nunca vê</text><rect x=\"36\" y=\"184\" width=\"648\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">hipervisor: divide a máquina e isola os convidados</text><rect x=\"36\" y=\"230\" width=\"648\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">CPUs, memória, placas de rede, discos locais</text></svg>", "caption": "Uma instância é uma fatia da máquina de outra pessoa. Tudo acima da linha tracejada você vê e configura; o hipervisor e o hardware abaixo dela são do provedor, e os vizinhos ao seu lado também."}
```

Os nomes mudam e a coisa não. A AWS chama de instância EC2, o Google Cloud de instância de VM, o
Azure de máquina virtual, a DigitalOcean de Droplet e a Hetzner de cloud server. Esta aula usa as
palavras da AWS porque a tabela de preços que o curso cita é da AWS; tudo o que ela diz sobre a forma
vale para os outros.

## O que decorre do desenho

**Você aluga uma fatia, e para de pagar quando a devolve.** Como o host é compartilhado, o provedor
consegue vender duas threads e oito gibibytes em vez de um servidor inteiro, e cobrar pelo tempo em
que você fica com eles. A AWS cobra uma instância Linux sob demanda por segundo, com mínimo de um
minuto. Uma instância desligada às seis da tarde não custa nada de processador durante a noite, coisa
que um servidor no seu próprio rack nunca fez.

**O hardware não é seu para consertar, nem para guardar.** Quando um host apresenta defeito ou
precisa de manutenção, o provedor avisa que o host da sua instância vai ser aposentado, e parar e
iniciar a instância a coloca em outro host. Ninguém vai até um rack por você, e ninguém pergunta se o
programa que você deixou rodando naquele host guardava algo importante nele. É por isso que a segunda
metade desta aula dedica tanto tempo a máquinas que se pode jogar fora.

**Onde começa a sua responsabilidade é a linha tracejada.** A aula 1 desenhou isso para o IaaS: o
provedor opera o prédio, o hardware e o hipervisor, e você opera o sistema operacional e tudo o que
está em cima dele. Aplicar patches no kernel de uma instância é trabalho seu, exatamente como seria
numa máquina embaixo da sua mesa. Manter os vizinhos fora da sua memória é trabalho do provedor.

**Os vizinhos existem.** Eles ficam isolados pelo hipervisor, que é a fronteira de segurança sobre a
qual todo o arranjo se apoia, e na maioria dos tipos de instância o provedor reserva as threads pelas
quais você paga, para que um vizinho ocupado não as tome. A exceção é a família burstable da próxima
seção, que é barata justamente porque compartilha mais. Quando uma regra ou um contrato exige que
nenhum outro cliente rode no mesmo hardware, os provedores vendem hosts dedicados, a um preço que
mostra quanto do desconto vinha do compartilhamento.

## Do que uma instância é feita

Desmonte o desenho e uma instância são quatro coisas que você escolhe, mais uma que o provedor
escolhe:

| você escolhe | o que decide |
|---|---|
| uma imagem | o disco de onde ela dá boot: um sistema operacional e o que foi instalado nele |
| um tipo de instância | quantas threads de processador e quanta memória |
| um lugar na rede | em que rede ela fica e que regras de firewall a protegem |
| os discos | o que ela guarda, e se isso sobrevive à instância |

O host em que ela cai é escolha do provedor, e ninguém diz qual é. As próximas quatro seções tratam
das linhas uma a uma, e as últimas quatro perguntam o que acontece quando há muitas instâncias em vez
de uma.
