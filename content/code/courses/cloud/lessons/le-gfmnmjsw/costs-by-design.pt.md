---
title: Toda decisão de desenho é uma decisão de custo
version: 1
---

Esta aula tratou o custo como algo a estimar, acompanhar e explicar. A maior parte dele é decidida
antes, **quando o desenho é feito**, por escolhas que as aulas 4 a 9 fizeram por outros motivos. Cada
uma delas tem um preço na tabela, e vê-las lado a lado é o que transforma o custo de uma surpresa mensal
numa propriedade que você escolhe.

| decisão | aula | o que a tabela diz, `sa-east-1` |
| --- | --- | --- |
| tamanho da máquina | 4 | `m7i.xlarge` custa 0.32130 por hora, exatamente o dobro de `m7i.large`, a 0.16065 |
| família de processador | 4 | `m7g.large`, em Arm, custa 0.13010 contra 0.16065: 19% menos pelo mesmo tamanho |
| tipo de armazenamento | 5 | um TB por um mês: EFS 570,00, gp3 152,00, S3 Standard 40,50 |
| classe de armazenamento | 5 | S3 Glacier Flexible Retrieval custa 0.00765 por GB-mês, cerca de um quinto do Standard |
| NAT ou endpoint | 6 | o processamento do NAT custa 0.0930 por GB; um gateway endpoint para o S3 não acrescenta nada |
| região | 9 | `t3.medium` custa 0.04160 em `us-east-1` e 0.06720 aqui |
| zonas | 9 | uma segunda zona dobra as máquinas e acrescenta 0,02 por GB que atravessa |
| funções ou máquinas | 8 | veja abaixo |

Nenhuma delas tem uma resposta certa só, e **cada economia é comprada com outra coisa**. Uma máquina
duas vezes maior custa o dobro, e só está certa quando as medições dizem que a menor está cheia. A máquina
Arm é mais barata e precisa de software compilado para Arm. O Glacier Flexible Retrieval custa cerca de
um quinto para guardar, e leva de minutos a horas para devolver os dados, e cobra por isso. A Virgínia é
mais barata na maior parte das linhas da tabela e fica a uma longa ida e volta de São Paulo, que é o
assunto da aula 9. Duas zonas custam mais que uma, e um desenho numa zona só cai junto com ela.

A última linha é o exemplo mais claro de um ponto de virada. Uma função com 512 MB rodando 100 ms por
requisição custa 0,20 por milhão de requisições mais 1.000.000 × 0,1 s × 0,5 GB × 0,0000166667 = 0,83 em
GB-segundos: cerca de 1,03 USD por milhão de requisições. Uma `t3.medium` custa 49,06 por mês, atenda o
que atender. **As duas se igualam em cerca de 47 milhões de requisições por mês**, umas dezoito por
segundo em média. Abaixo disso, as funções da aula 8 saem mais baratas, e muito mais baratas no lado
tranquilo. Acima, uma máquina ocupada o tempo todo ganha, e se uma `t3.medium` daria mesmo conta dessa
carga é uma pergunta para as medições da aula 4, não para a lista de preços.

## Onde isso cai no seu trabalho

::: track data dba
No seu trabalho, **armazenamento e movimentação de dados dominam a conta**, e as máquinas são a parte
menor. Um data warehouse cobrado pelos dados que cada consulta varre transforma uma consulta descuidada
numa linha da conta. Uma réplica em outra zona paga 0,02 por gigabyte de alterações que atravessa, todo
mês. Backups guardados por anos são GB-mês que nunca param de acumular. Releia as aulas 5 e 9 com a tabela ao lado. As linhas de
custo a vigiar são classes de armazenamento, retenção e tráfego entre zonas, e a maioria delas é
decidida no schema e na política de backup, não no tamanho da máquina.
:::

::: track devops cloud-engineering
No seu trabalho, **você é a pessoa que recebe o alerta**. Orçamentos, tags e a estimativa fazem parte de
toda mudança que você entrega, não são um relatório que outra pessoa lê. Um pull request que acrescenta
um NAT gateway acrescenta 67,89 por mês, e dizer isso na descrição faz parte da revisão. O curso `iac`
mostra o passo seguinte, em que o custo de uma mudança é estimado a partir do código antes de ser
aplicado, para que a conversa aconteça antes de o dinheiro ser gasto.
:::

::: track *
O que quer que você construa, **um custo é uma propriedade do desenho, como latência ou
disponibilidade**. Pode ser medido, pode ser estimado antes de qualquer coisa ser construída, e é
decidido pelos mesmos desenhos. Decida-o de propósito, anote o número que você espera e compare com o
que chegar.
:::

Esse é o curso. Agora você consegue olhar para um desenho e dizer o que cada parte dele entrega a um
provedor, onde roda, quem pode mexer nele, a que distância estão os usuários e quanto vai custar por
mês. E consegue ler essa última resposta numa lista de preços publicada em vez de acreditar na palavra
de alguém.
