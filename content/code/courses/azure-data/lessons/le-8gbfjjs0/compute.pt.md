---
title: "Computação: quatro tipos, e o que ficou ligado"
version: 1
---

**O Databricks oferece quatro tipos de computação, e escolher entre eles é quase tudo o que um time
decide sobre a conta.** Os quatro rodam Spark, ou o motor SQL do Databricks, sobre as mesmas tabelas;
diferem em quem os usa, quanto tempo vivem e como são cobrados. Esta seção é ensinada a partir da
documentação do Databricks e da Microsoft e não foi executada.

## Clusters all-purpose

**Um cluster all-purpose é aquele em que as pessoas trabalham**: notebooks são ligados a ele, várias
pessoas podem dividi-lo, e ele roda até alguém pará-lo ou ele parar sozinho. Você escolhe as máquinas
do driver e dos workers, a versão do Databricks Runtime, que fixa a versão do Spark e das bibliotecas
em volta, e se o número de workers varia entre um mínimo e um máximo conforme a carga.

**A configuração mais importante dele é a auto termination**: o número de minutos ociosos depois dos
quais o cluster para sozinho. Um cluster all-purpose com auto termination desligada é o erro mais caro
da plataforma, um conjunto de máquinas cobrado a cada hora de cada noite porque alguém abriu um
notebook na sexta e foi para casa.

## Clusters de job

**Um cluster de job é criado para uma execução de um job e encerrado quando a execução termina.**
Ninguém liga um notebook a ele; as tarefas do job rodam nele e ele some. As DBUs dele são cobradas à
tarifa de jobs, que o Databricks precifica abaixo da tarifa all-purpose para as mesmas máquinas. **O
job noturno pertence a um cluster de job**: o notebook de limpeza da Quitanda da lição 20, rodado às
três da manhã por um job do Databricks ou pelo pipeline da lição 19, num cluster que existe pela meia
hora de que precisa.

## SQL warehouses

**Um SQL warehouse é computação só para SQL**, para analistas e para ferramentas de BI como o Power BI
que mandam SQL. Ele vem como classic, pro ou serverless, e escala acrescentando clusters quando as
consultas fazem fila, encolhendo quando param. Um warehouse também para sozinho depois de minutos
ociosos, e num serverless o Databricks mantém as máquinas quentes, então ele sobe em segundos em vez
de minutos. É a contraparte no Databricks dos pools SQL da lição 16 e do warehouse da lição 17.

## Computação serverless

**A computação serverless para notebooks e jobs roda na conta do Databricks, no plano de computação
serverless**, sobe em segundos e é cobrada só em DBUs, sem máquina virtual sua por trás. Você abre mão
de escolher máquinas e versões do runtime e de parte dos arranjos de rede da seção anterior, e deixa
de pagar minutos de partida e minutos ociosos. Para um time que roda alguns jobs curtos por noite, a
troca costuma ser boa; para um que roda clusters grandes o dia todo, a computação clássica que ele
controla pode custar menos.

## Dois jeitos de subir mais rápido

**Pools mantêm máquinas prontas.** Um pool guarda um número de máquinas virtuais ociosas; um cluster
que pega as máquinas de um pool sobe sem esperar o Azure criá-las. A documentação do Databricks diz
que máquinas ociosas num pool não são cobradas em DBUs, mas o Azure continua cobrando-as como
máquinas virtuais, então um pool troca um pouco de dinheiro por muito tempo de partida.

**Máquinas Spot custam menos e podem ser tomadas de volta.** Os workers podem ser máquinas virtuais
Spot do Azure, vendidas barato a partir de capacidade sobrando e despejadas quando o Azure precisa
delas; o Spark reexecuta as tarefas perdidas nos workers que restam. Um job que precisa terminar até as
seis da manhã mantém o driver numa máquina comum e usa Spot nos workers que pode perder.
