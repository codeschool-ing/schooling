---
title: As linhas que ninguém espera
version: 1
---

As pessoas estimam o que escolheram: as máquinas, o banco de dados, o armazenamento. As linhas que
surpreendem são **as que vieram com o desenho sem terem sido escolhidas**, e as que continuam crescendo
depois que todo mundo parou de olhar. A estimativa da seção anterior já traz três delas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A estimativa de 298,64 USD por mês desenhada como uma barra por linha, da maior para a menor. Escolhidas no desenho: 2 x t3.medium 98.11, horas do load balancer 24.82, 2 x 30 GB gp3 9.12, S3 Standard 200 GB 8.10. Vieram com o desenho: 500 GB de saída 75.00, horas do NAT gateway 67.89, 3 endereços IPv4 públicos 10.95, NAT gateway 50 GB 4.65. As linhas que vieram com o desenho somam 158,49, mais da metade da conta.\"><defs><marker id=\"bill-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"14\" height=\"12\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"42\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">escolhidas quando o desenho foi feito</text><rect x=\"300\" y=\"16\" width=\"14\" height=\"12\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"322\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">vieram com o desenho, sem escolha</text><text x=\"20\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2 x t3.medium</text><rect x=\"230\" y=\"48\" width=\"382.6\" height=\"16\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"620.6\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">98.11</text><text x=\"20\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">500 GB out</text><rect x=\"230\" y=\"78\" width=\"292.5\" height=\"16\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"530.5\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">75.00</text><text x=\"20\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">NAT gateway, hours</text><rect x=\"230\" y=\"108\" width=\"264.8\" height=\"16\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"502.8\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">67.89</text><text x=\"20\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">load balancer, hours</text><rect x=\"230\" y=\"138\" width=\"96.8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"334.8\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">24.82</text><text x=\"20\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3 public IPv4 addresses</text><rect x=\"230\" y=\"168\" width=\"42.7\" height=\"16\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"280.7\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10.95</text><text x=\"20\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2 x 30 GB gp3</text><rect x=\"230\" y=\"198\" width=\"35.6\" height=\"16\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"273.6\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">9.12</text><text x=\"20\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">S3 Standard, 200 GB</text><rect x=\"230\" y=\"228\" width=\"31.6\" height=\"16\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"269.6\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">8.10</text><text x=\"20\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">NAT gateway, 50 GB</text><rect x=\"230\" y=\"258\" width=\"18.1\" height=\"16\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"256.1\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">4.65</text><path d=\"M230 40 L230 282\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"20\" y=\"302\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">total: 298,64 USD por mês, sem impostos</text><text x=\"20\" y=\"322\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">as linhas marcadas: 158,49, mais da metade da conta</text></svg>", "caption": "A estimativa da seção anterior, uma barra por linha. Mais da metade dela, 158,49 de 298,64, são linhas que ninguém escolheu: chegaram com uma sub-rede privada, um load balancer e usuários na internet."}
```

## Dados que saem

O tráfego **para dentro** do provedor é gratuito: a linha `in from the internet` da tabela é 0.0000. O
tráfego **para fora**, para a internet, custa 0.1500 por GB em São Paulo, depois que os primeiros 100 GB do mês da conta,
que são gratuitos, acabam. A
assimetria é proposital, e quer dizer que o que um desenho envia aos usuários é um custo que cresce com o
sucesso dele. Uma página de download que serve um instalador de 2 GB a 500 pessoas por mês envia 1.000
GB, que são 150,00 USD, mais do que as duas máquinas da estimativa juntas.

## O NAT gateway

Um NAT gateway, da aula 6, deixa máquinas em sub-redes privadas saírem. **Ele é cobrado duas vezes**:
0.0930 por hora por existir, que são os 67,89 da estimativa, e 0.0930 por gigabyte que processa, nos dois
sentidos. A segunda cobrança vem além de qualquer cobrança de saída pelos mesmos bytes.

O caso caro é o tráfego que nem precisava sair. Se as máquinas leem os 200 GB de imagens do S3 através
do NAT gateway, são 18,60 USD por mês de processamento por tráfego entre dois serviços do mesmo provedor
na mesma região. O **gateway endpoint para o S3** da aula 6 leva esse tráfego por um caminho privado e
não tem cobrança por hora nem por GB, então as mesmas leituras não custam nada a mais.

## Endereços IPv4 públicos, em uso ou não

Desde fevereiro de 2024 a AWS cobra por todo endereço IPv4 público, inclusive os ligados aos load
balancers e NAT gateways dela. A lista de preços diz isso com as próprias palavras:

@@CAP:ipv4@@

Um endereço custa o mesmo fazendo alguma coisa ou não. A 0.0050 por hora, um endereço é 3,65 USD por
mês e **43,80 USD por ano**: 0.0050 × 8.760 horas. É pouco até você contar quantos são. Um Elastic IP
reservado para uma máquina que depois foi apagada continua cobrando como ocioso, e o mesmo vale para
cada endereço de uma conta de teste que ninguém abre desde o ano passado.

## O que sobrevive a uma exclusão

Apagar uma máquina não apaga tudo o que ela usava. Um volume raiz criado com a instância vai junto com
ela por padrão, mas **um volume ligado depois sobrevive à instância por padrão**, e o mesmo vale para
cada snapshot já tirado. Nada num volume sem máquina parece errado numa lista de volumes. Um volume gp3
de 100 GB esquecido custa 15,20 por mês, que são 182,40 por ano por um disco que ninguém lembra de ter
ligado. Os snapshots dele custam 0.0680 por GB-mês a mais, enquanto existirem.

## Tráfego entre zonas

A aula 9 pôs as duas máquinas em duas zonas para que uma sobrevivesse à falha da outra. O tráfego entre
zonas é cobrado a 0.0100 por GB **em cada sentido**: uma vez ao sair de uma zona e outra ao entrar na
outra, então 0,02 por gigabyte que atravessa. Uma réplica de banco de dados na segunda zona que recebe 2
TB de alterações por mês custa 40,00 só pela travessia. É o preço da disponibilidade que a aula 9
comprou, e é certo pagá-lo; errado é não saber que ele está lá.

## Logs guardados para sempre

Um log group no CloudWatch Logs, o serviço de logs da AWS, é criado com retenção de nunca expirar, e
fica assim até alguém mudar. Armazenamento que ninguém apaga é uma linha que cresce todo mês sem que
ninguém decida nada. Uma aplicação que grava 50 GB de logs por mês no S3 Standard guarda 1.200 GB depois
de dois anos, o que custa 48,60 por mês a essa altura; a soma dessas vinte e quatro contas mensais é
607,50. **Uma regra de retenção é uma decisão de custo**, escrita uma vez, e as regras de ciclo de vida
da aula 5 são como ela é escrita para um bucket.

Nenhuma dessas linhas é uma pegadinha. Cada uma está na lista de preços, e cada uma decorre de uma
unidade da tabela do começo desta aula. O que as torna surpresas é que o desenho as produziu sem que
ninguém as escolhesse, e é por isso que uma estimativa as lista e uma olhada mensal na conta as confere.
