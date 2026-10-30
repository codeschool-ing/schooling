---
title: Tamanhos, os limites que crescem com eles e a família B
version: 1
---

Um tamanho parece um ajuste de qualidade, pequeno para teste e grande para produção. **Dentro de
uma série, um tamanho é só uma quantidade**: cada degrau acima dobra as vCPUs e a memória e mantém a
proporção. O que muda de fato com o tamanho é tudo o que o nome deixa de fora, os limites de disco e
de rede, e uma família vende o processador de um jeito totalmente diferente.

## O dobro, e os limites ao lado

Todos os tamanhos da série Dsv5, a série do padrão da CLI, com os limites que a Microsoft publica
para cada um na página da série, lida em 30 de outubro de 2026 e não medida aqui:

| tamanho | vCPUs | GiB | discos de dados | IOPS de disco | MBps de disco | rede em Mbps |
| --- | --- | --- | --- | --- | --- | --- |
| `Standard_D2s_v5` | 2 | 8 | 4 | 3.750 | 85 | 12.500 |
| `Standard_D4s_v5` | 4 | 16 | 8 | 6.400 | 145 | 12.500 |
| `Standard_D8s_v5` | 8 | 32 | 16 | 12.800 | 290 | 12.500 |
| `Standard_D16s_v5` | 16 | 64 | 32 | 25.600 | 600 | 12.500 |
| `Standard_D32s_v5` | 32 | 128 | 32 | 51.200 | 865 | 16.000 |
| `Standard_D48s_v5` | 48 | 192 | 32 | 76.800 | 1.315 | 24.000 |
| `Standard_D64s_v5` | 64 | 256 | 32 | 80.000 | 1.735 | 30.000 |
| `Standard_D96s_v5` | 96 | 384 | 32 | 80.000 | 2.600 | 35.000 |

As colunas de disco valem para Premium SSD sem o cache do host. A memória fica em 4 GiB por vCPU do
começo ao fim, e os degraus dobram até 32 vCPUs e depois vão para 48, 64 e 96.

**Os limites de disco crescem com o tamanho, e o limite de rede dos tamanhos pequenos não.** Uma
`D2s_v5` pode ter quatro discos de dados e fica presa a 3.750 IOPS somando todos eles, sejam quais
forem os discos que você comprar; uma `D8s_v5` pode ter dezesseis e fazer 12.800. A lição 3 dá a
cada disco um limite próprio, e um programa recebe o menor entre o limite do disco e o da máquina.
Um banco de dados lento num tamanho pequeno pode estar esperando nesse teto com o processador quase
parado, e a correção é subir um tamanho, não comprar um disco mais rápido.

A coluna de rede corre ao contrário: os quatro menores tamanhos dividem os mesmos 12.500 Mbps. Esse
número é um teto e não uma promessa. As notas da tabela da Microsoft dizem que os limites superiores
não são garantidos e servem de orientação, e a vazão que uma máquina recebe de fato depende do
tráfego em volta dela.

## Duas pequenas ou uma grande

Com a tabela de preços fora de alcance, use um valor ilustrativo, não do Azure: 0,10 USD por hora
para uma `D2s_v5`. Se o valor acompanha as vCPUs, que é o que conferir na tabela real antes de
confiar nisso, uma `D4s_v5` sai por 0,20. Num mês de 730 horas são 73 USD e 146 USD, então duas
`D2s_v5` custam o que custa uma `D4s_v5`. A escolha entre elas deixa então de ser sobre dinheiro.
Uma máquina maior roda uma cópia do programa com mais folga; duas menores sobrevivem à perda de
qualquer uma e deixam um grupo crescer em passos menores, que é para isso que servem os scale sets
da lição 4.

## vCPUs restritas: os processadores que você não licencia

Alguns softwares são licenciados por núcleo de processador: um banco de dados comercial é o caso
comum, e o SQL Server é o que a documentação da Microsoft cita. Um banco de dados muitas vezes
precisa de um tamanho grande pela memória e pelos limites de disco e usa só algumas das vCPUs, e
toda vCPU que ele recebeu conta na licença. **Um tamanho restrito mantém a memória, os discos e o
I/O de um tamanho e desliga a maioria das vCPUs dele.**

O exemplo daquela página: a `Standard_E32s_v5` tem 32 vCPUs, 256 GiB, 32 discos e 80.000 IOPS. A
`Standard_E32-16s_v5` e a `Standard_E32-8s_v5` têm a mesma memória, os mesmos discos e IOPS com 16 e
8 vCPUs ativas. A Microsoft cobra por elas o preço do tamanho original, então a máquina custa o
mesmo e a economia está na licença. Com uma licença ilustrativa de 100 USD por vCPU por mês, que não
é o preço de fornecedor nenhum, o banco na `E32s_v5` deve 3.200 USD por mês e na `E32-8s_v5` deve
800.

A CLI oferece também a mesma ideia por máquina, nos tamanhos que a suportam, como duas opções do
`az vm create`:

```
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o "\-\-v-cpus-[a-z-]* : [^.]*\."
--v-cpus-available : Specify the number of vCPUs available.
--v-cpus-per-core : Specify the ratio of vCPU to physical core.
```

`--v-cpus-available` define quantas vCPUs a máquina mantém. `--v-cpus-per-core 1` desliga a segunda
thread de cada núcleo, então um tamanho com hyper-threading entrega núcleos inteiros e metade das
vCPUs. A Microsoft documenta as duas como sem custo extra: a máquina é cobrada como o tamanho
completo.

## A família B: uma parte do processador e créditos para o resto

A família B é a única série em que uma vCPU não é sua o tempo todo. Ela vem em três séries, `Bsv2`
em Intel, `Basv2` em AMD e `Bpsv2` em Ampere Altra, que é Arm. Cada tamanho tem um **desempenho base
de CPU**, uma porcentagem da máquina inteira que ela pode usar para sempre, e **créditos** que pagam
qualquer coisa acima disso. Abaixo da base ela acumula créditos; acima, gasta. Os números da
Microsoft para quatro tamanhos da `Bsv2`:

| tamanho | vCPUs | GiB | base | créditos no início | acumulados por hora | o máximo que guarda |
| --- | --- | --- | --- | --- | --- | --- |
| `Standard_B2ts_v2` | 2 | 1 | 20% | 60 | 24 | 576 |
| `Standard_B2ls_v2` | 2 | 4 | 30% | 60 | 36 | 864 |
| `Standard_B2s_v2` | 2 | 8 | 40% | 60 | 48 | 1.152 |
| `Standard_B4s_v2` | 4 | 16 | 40% | 120 | 96 | 2.304 |

A `Basv2` e a `Bpsv2` têm os mesmos números, tamanho a tamanho. A base é uma parte da máquina
inteira, numa escala de 0 a 100% que a Microsoft adotou em 2024. Páginas mais antigas usavam de 0
até o número de vCPUs vezes 100%, então um artigo antigo que dá à `B2s_v2` uma base de 80% quer dizer
os mesmos 40% desta tabela.

A Microsoft dá a conta numa fórmula só, créditos acumulados por minuto:

`(base × vCPUs − CPU usada × vCPUs) / 100`

**Um crédito é uma vCPU a 100% por um minuto**, e é a isso que a fórmula se reduz. Uma `B2s_v2` ociosa
acumula (40 × 2 − 0) / 100 = 0,8 crédito por minuto, que são os 48 por hora da tabela, e o máximo
que ela guarda, 1.152, são exatamente 24 horas disso.

Três casos da loja, numa `B2s_v2`:

- O servidor de staging durante a noite, a 10%: (80 − 20) / 100 = 0,6 crédito por minuto
  acumulado, 36 por hora. Dez horas tranquilas acumulam 360.
- Um teste de carga contra ele, as duas vCPUs a 100%: (80 − 200) / 100 = −1,2 por minuto, 72
  gastos por hora. Um saldo cheio de 1.152 dura 16 horas; os 360 de uma noite duram 5 horas; os 60
  créditos com que uma máquina nova começa duram 50 minutos.
- A API de pedidos num dia movimentado, a 70% constantes: (80 − 140) / 100 = −0,6 por minuto, 36
  por hora, e um saldo cheio dura 32 horas.

**Quando os créditos acabam, a máquina fica presa à base** até acumular mais. Para uma `B2s_v2`
isso são 40% da máquina, oito décimos de uma vCPU, e a API de pedidos que usava o equivalente a 1,4
vCPU agora tem de caber em 0,8. A documentação da Microsoft não descreve outro desfecho, e não há
nada a escolher sobre isso quando a máquina é criada:

```
ana@laptop:~/azure$ az vm create --help | grep -ci credit
0
```

A ajuda do `az vm create` não menciona créditos nem uma vez. O saldo só é visível enquanto a máquina
roda, como as métricas *CPU Credits Remaining* e *CPU Credits Consumed* no Azure Monitor, que as
lições 8 a 13 do `azure-operations` montam. Nada neste notebook ganha ou gasta um crédito, então **o
que esta seção diz sobre créditos vem da documentação da Microsoft e não foi executado.**

## Burstable ou fixa

A `B2s_v2` e a `D2s_v5` têm o mesmo formato, 2 vCPUs e 8 GiB, e a Microsoft descreve a série Bsv2
como de baixo custo. O que o preço menor tira de você é o processador acima de 40%. **Para uma
máquina que fica ociosa, isso é uma pechincha**: um servidor de staging, um jump host, uma
ferramenta interna usada algumas vezes por dia, qualquer coisa cuja média fique abaixo da base. Para
uma máquina que passa o dia útil acima da base, o saldo só adia o momento em que ela é contida, e um
tamanho fixo teria rodado o mesmo trabalho a toda velocidade. O teste é a CPU média ao longo de uma
semana típica contra a base da tabela, medida e não chutada.
