---
title: Entre zonas, regiões e continentes
version: 1
---

**Dentro do Google Cloud, para onde os bytes vão decide se custam alguma coisa.** Um bucket lido por
uma máquina, um cluster ou uma consulta na mesma localização manda seus bytes de graça, e só as
operações são cobradas. Um bucket lido de outra região paga por GiB, e a partir de São Paulo o preço
quase não muda com a distância. E uma peça de rede que muitos projetos têm, o Cloud NAT, cobra por
cada byte que carrega mesmo quando o destino é o bucket ao lado.

## Mesma localização: de graça

A página de preços do armazenamento lista os casos que não custam nada, e o primeiro é o que importa:
**dados que se movem dentro da mesma localização**. Um bucket em `southamerica-east1` lido por uma
máquina virtual em `southamerica-east1-b`, por um cluster Dataproc da aula 23 na mesma região, ou por um
dataset do BigQuery cuja localização é `southamerica-east1`, não manda bytes cobráveis. **Zonas não
contam**: a página diz com todas as letras que mover dados entre zonas de uma região é a mesma
localização.

Duas armadilhas moram dentro de "mesma localização". **Uma região não é a mesma localização que uma
multirregião**, mesmo quando a região fica dentro dela, então um bucket na multirregião `US` lido de
`us-east1` paga. E as localizações `US` e `EU` do BigQuery contam como `us-central1` e `europe-west4`,
o que importa para uma empresa brasileira no dia em que alguém cria um dataset em `US` porque um
tutorial fez isso, e é por isso que vale nomear a localização de um dataset toda vez que um é criado.

## Outra região: um preço definido por onde o bucket está

Para todo o resto dentro do Google Cloud, a página imprime uma matriz: a localização do bucket na
lateral, o destino no alto, um preço por GiB em cada célula. As linhas dela para três origens:

| bucket em → lido de | América do Norte | Europa | América Latina | Ásia |
|---|---|---|---|---|
| América do Norte | 0,02 | 0,05 | 0,14 | 0,08 |
| Europa | 0,05 | 0,02 | 0,14 | 0,08 |
| **América Latina** | **0,14** | **0,14** | **0,14** | **0,14** |

**Toda célula da linha da América Latina é 0,14.** Um bucket em São Paulo paga o mesmo para mandar um
GiB a Santiago que para mandá-lo a Iowa ou a Frankfurt, e essa é a linha mais cara da matriz. Uma
empresa na América do Norte paga 0,02 para mover dados entre duas regiões dela; uma empresa no Brasil
paga sete vezes isso, porque o preço é sobre a rede do Google a partir da América do Sul, e não sobre
os quilômetros.

O jurídico da Quitanda recebeu uma vez o pedido de uma cópia do lake de 5 TiB em `us-east1`, para um
parceiro que trabalha lá. A conta disso, e dos dois casos seguintes:

```
ana@laptop:~/gcp$ python3 -c 'print(round(5 * 1024 * 0.14, 2), round(2 * 1024 * 0.045, 2), round(500 * 0.01, 2))'
716.8 92.16 5.0
```

**A cópia dá 716,80, uma vez**, e cada mudança replicada depois dela paga a mesma tarifa. É também por
isso que este curso mantém os dados da Quitanda em `southamerica-east1`: os dados de uma empresa
brasileira muitas vezes precisam ficar, e movê-los é uma linha na conta além de uma questão jurídica.
O mesmo vale para um bucket birregional ou multirregional, em que o Google copia cada escrita para uma
segunda região e a página cobra isso como replicação entre regiões, por GiB escrito.

## Máquinas, zonas, e o NAT que cobra pelo bucket

**Um bucket não liga para zonas; duas máquinas ligam.** Tráfego entre máquinas virtuais em duas zonas
de uma região custa 0,01 o GiB na página de preços de rede, cobrado do projeto de quem manda, e a mesma
página cobra o tráfego para o Cloud SQL na mesma região como tráfego entre máquinas. O primário de um
banco numa zona e o standby dele em outra são o assunto da aula 7; uma aplicação na zona `a` que lê
500 GiB por mês de um banco na zona `b` é o terceiro número acima, 5,00.

**O Cloud NAT é onde um bucket na mesma região começa a custar dinheiro.** Uma máquina sem endereço
externo chega à internet por um gateway do Cloud NAT, que a aula 17 de `gcp-foundations` monta. Sem
mais nada configurado, ela chega ao Cloud Storage por ele também, porque `storage.googleapis.com` é um
endereço público. A página de preços de rede cobra do Cloud NAT 0,045 por GiB processado, nas duas
direções, em toda região, além de um preço por hora por máquina que o usa. Um job noturno numa máquina
privada que lê 2 TiB por mês do lake paga 92,16 por mês só de processamento do NAT, por bytes que nunca
saíram de São Paulo.

**O Private Google Access tira essa linha.** É uma configuração da sub-rede, sem cobrança própria, que
deixa máquinas sem endereço externo chegarem às APIs do Google direto pela rede do Google, e o tráfego
para o bucket deixa de passar pelo gateway do NAT. A mesma aula 17 o liga. É a mudança mais barata
desta aula e uma das mais esquecidas, porque nada quebra sem ela; a conta só fica maior.

Nada dessa rede existe no notebook. O fake-gcs-server responde em `localhost`, não há zonas para
cruzar nem gateway para pagar, e os números desta seção são as páginas de preços multiplicadas por
contagens.
