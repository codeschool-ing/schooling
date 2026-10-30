---
title: Quanto uma instância custa num mês
version: 1
---

**Uma instância do Cloud SQL é cobrada por coisas que rodam o tempo todo e por uma que cresce**: as
vCPUs e a memória, por hora, consulte alguém ou não; o disco, pelos GiB que você define, cheio ou não;
e os backups, pelos GiB que guardam. Não há cobrança por consulta nem por linha, o oposto do BigQuery
das aulas 13 e 14, e isso quer dizer que um banco parado custa exatamente o que custa um ocupado.

**No Enterprise, a máquina não tem preço de máquina.** A página de preços imprime um preço por
vCPU-hora e um preço por GiB-hora de memória, e uma instância de 2 vCPU e 8 GiB paga dois do primeiro
e oito do segundo. Para `southamerica-east1`, de cloud.google.com/sql/pricing, lido em 2026-10-30, em
USD:

| | por vCPU-hora | por GiB-hora de memória |
|---|---|---|
| Enterprise | 0,062 | 0,0105 |
| Enterprise, alta disponibilidade | 0,1239 | 0,021 |
| Enterprise Plus, série N2 | 0,0805 | 0,0137 |
| Enterprise Plus, N2, alta disponibilidade | 0,1611 | 0,0273 |

| armazenamento e o resto | preço |
|---|---|
| SSD | 0,255 por GiB-mês, 0,51 com alta disponibilidade |
| HDD | 0,135 por GiB-mês, 0,27 com alta disponibilidade |
| backups | 0,12 por GiB-mês usado |
| `db-f1-micro`, núcleo compartilhado, 0,6 GiB | 0,0158 por hora |
| licença do SQL Server, Standard | 0,13 por núcleo-hora, no mínimo 4 núcleos |
| licença do SQL Server, Enterprise | 0,47 por núcleo-hora, no mínimo 4 núcleos |

## Um mês são 730 horas

Os valores mensais da página de preços são os por hora vezes 730, que são 365 dias vezes 24 horas
divididos por 12, e todo preço deste curso usa o mesmo mês. Cinco instâncias que a Quitanda poderia
rodar, com o preço calculado por um programa curto o bastante para ler inteiro.

`sqlcost.py`:

```python
"""A month of five Cloud SQL instances in southamerica-east1, from the pricing page."""
HOURS = 730                       # the month every Google pricing table uses

# USD, cloud.google.com/sql/pricing, southamerica-east1, read 2026-10-30
ENTERPRISE = {'cpu': 0.062, 'gib': 0.0105, 'ha_cpu': 0.1239, 'ha_gib': 0.021}
PLUS_N2 = {'cpu': 0.0805, 'gib': 0.0137, 'ha_cpu': 0.1611, 'ha_gib': 0.0273}
SSD, SSD_HA = 0.255, 0.51         # per GiB-month
MICRO = 0.0158                    # db-f1-micro, per hour, shared core
SQLSERVER_STANDARD = 0.13         # licence, per core-hour, at least 4 cores


def machine(price, cpu, gib, ha=False):
    if ha:
        return (cpu * price['ha_cpu'] + gib * price['ha_gib']) * HOURS
    return (cpu * price['cpu'] + gib * price['gib']) * HOURS


def show(name, compute, disk):
    print(f'{name:<44}{compute:>9,.2f}{disk:>8,.2f}{compute + disk:>10,.2f}')


print(f'{"a month, 730 hours":<44}{"machine":>9}{"disk":>8}{"total":>10}')
show('db-f1-micro, 10 GiB, PostgreSQL', MICRO * HOURS, 10 * SSD)
show('Enterprise, 2 vCPU 8 GiB, 100 GiB', machine(ENTERPRISE, 2, 8), 100 * SSD)
show('the same, high availability', machine(ENTERPRISE, 2, 8, ha=True), 100 * SSD_HA)
show('Enterprise Plus, 2 vCPU 16 GiB, 100 GiB', machine(PLUS_N2, 2, 16), 100 * SSD)
show('Enterprise, 2 vCPU 8 GiB, SQL Server Std',
     machine(ENTERPRISE, 2, 8) + max(2, 4) * SQLSERVER_STANDARD * HOURS, 100 * SSD)
```

```
ana@laptop:~/gcp$ python3 sqlcost.py
a month, 730 hours                            machine    disk     total
db-f1-micro, 10 GiB, PostgreSQL                 11.53    2.55     14.08
Enterprise, 2 vCPU 8 GiB, 100 GiB              151.84   25.50    177.34
the same, high availability                    303.53   51.00    354.53
Enterprise Plus, 2 vCPU 16 GiB, 100 GiB        277.55   25.50    303.05
Enterprise, 2 vCPU 8 GiB, SQL Server Std       531.44   25.50    556.94
```

**A micro é para desenvolvimento, e mais nada.** Um núcleo compartilhado e 0,6 GiB de memória rodam as
migrações e os testes contra um motor de verdade, e 14,08 por mês é menos do que o tempo de qualquer um
discutindo isso. Ela não é coberta pelo SLA do Cloud SQL, e não é onde moram os pedidos da Quitanda.

**A instância Enterprise dá 177,34**: 2 × 0,062 + 8 × 0,0105 = 0,208 por hora, 151,84 por mês, e
25,50 do disco. É a instância das seções anteriores.

**Alta disponibilidade é quase exatamente o dobro**, a máquina e o disco, porque é uma segunda máquina
com um segundo disco em outra zona, mantida em sincronia com a primeira. A aula 7 é o que a segunda
cópia compra, e é a linha em que os 354,53 precisam ser defendidos.

**O Enterprise Plus custa mais por vCPU e muito mais por memória**, e vem com o dobro de memória por
vCPU: 2 × 0,0805 + 16 × 0,0137 = 0,3802 por hora. Os 303,05 compram o SLA, a manutenção mais curta e os
logs mais longos da tabela das edições, e 16 GiB em vez de 8; se um banco precisa da memória é uma
questão do conjunto de trabalho dele, não da edição.

**A licença é a maior parte da conta do SQL Server.** As mesmas 2 vCPU e 8 GiB da linha Enterprise, e
depois quatro núcleos de licença Standard a 0,13 por hora, porque a Microsoft licencia no mínimo quatro
núcleos por instância, tenha a instância quantos tiver: 0,52 por hora de licença contra 0,208 da
máquina, 556,94 contra 177,34. A página de preços acrescenta que uma instância com alta
disponibilidade paga uma licença, não duas, já que só uma máquina roda o motor de cada vez.

## O que mais cai na conta

**O armazenamento é o que você define, não o que você usa**, e com o aumento automático ligado, o que
você define só sobe. Aloque para o próximo ano e defina o teto.

**Os backups são cobrados pelo que guardam**, a 0,12 o GiB-mês. A aula 7 diz quantos são mantidos e por
quanto tempo. A referência de `--retained-transaction-log-days` traz um aviso que cabe aqui: onde os
logs para recuperação a um ponto no tempo ficam no disco da instância, mais dias deles é mais disco.

**Uma versão principal antiga custa a mais.** A tabela "Extended support" da página de preços cobra, em
São Paulo, 0,105 por vCPU-hora nos dois primeiros anos depois do fim do suporte padrão de uma versão e
0,21 no terceiro, além da instância. Para a instância Enterprise acima, com as 2 vCPU dela, um ano de
atraso numa atualização é:

```
ana@laptop:~/gcp$ python3 -c 'print(round(2 * 0.105 * 730, 2))'
153.3
```

**153,30 por mês em cima de 177,34**, quase o dobro. A atualização da primeira seção, a que o Google
não faz por você, tem um preço por não ser feita.

**Um endereço IP público que não está em uso é cobrado por hora**, 0,015 nesta região, e a saída de
dados de uma instância tem o preço da rede da aula 5, por onde os bytes vão.

**Uma instância parada continua pagando o disco.** Definir `--activation-policy=never` com
`gcloud sql instances patch` para a máquina e a cobrança por hora dela, e o disco, os backups e os
endereços reservados continuam cobrando. Para uma instância necessária só no horário comercial, pará-la
à noite compensa; para uma necessária daqui a um mês, uma exportação para um bucket e uma exclusão
compensam mais.

**Um compromisso é o outro jeito de pagar menos**: um desconto por uso comprometido de um ou três
anos, que a página de preços imprime ao lado de todo preço, 0,0465 em vez de 0,062 por vCPU-hora por
um ano em São Paulo. É uma decisão sobre o negócio mais do que sobre o banco, a aula 13 de
`gcp-foundations` o lê na fatura, e nenhum dos preços desta aula inclui um.
