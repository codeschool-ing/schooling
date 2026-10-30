---
title: Um cluster, uma primária e um read pool
version: 1
---

**Um banco do AlloyDB é primeiro um cluster e depois instâncias.** O cluster é o recurso regional que
é dono do armazenamento, dos backups, da rede pela qual é alcançado e da senha do usuário `postgres`.
As instâncias são as máquinas que rodam o motor sobre esse armazenamento, e há exatamente dois tipos:
uma **primária**, que recebe escritas, e quantos **read pools** se queira, que recebem só leituras. A
linha de comando tem o vocabulário inteiro no seu laptop, na ajuda, mesmo que nada no seu laptop possa
responder a ela:

```
ana@laptop:~/gcp$ gcloud alloydb instances create --help | sed -n '/^     --instance-type/,/zones in a region/p'
     --instance-type=INSTANCE_TYPE
        Specifies instance type. INSTANCE_TYPE must be one of:

         PRIMARY
            PRIMARY instances support read and write operations.
         READ_POOL
            READ_POOL instances support read operations only. Each read pool
            instance consists of one or more homogeneous nodes. * Read pool of
            size 1 can only have zonal availability. * Read pools with node
            count of 2 or more can have regional availability (nodes are
            present in 2 or more zones in a region).
```

**`PRIMARY` e `READ_POOL` são a lista inteira.** Não há terceiro tipo para escolher, nenhuma instância
"standby" para criar e nenhuma "réplica" no vocabulário do próprio AlloyDB: o standby pertence à
primária, e as réplicas são os nós de um read pool. As duas últimas linhas da ajuda já dizem algo
sobre disponibilidade, e a próxima parte desta seção é o que elas querem dizer.

## A primária, zonal ou regional

**Uma instância primária é um nó ou dois, e `--availability-type` decide qual.** `ZONAL` é um nó numa
zona, sem failover automático. `REGIONAL` é dois nós em duas zonas da região: o ativo, que atende as
conexões, e um standby, que não atende nada até o ativo falhar. A página de preços diz isso com todas
as letras, "A high availability primary instance uses two nodes", e cada nó é cobrado. Como o standby
lê o mesmo armazenamento que o nó ativo, um failover passa a escrita adiante sem mover dados, e
`gcloud alloydb instances failover` é o comando que o ensaia de propósito. O acordo de nível de
serviço do AlloyDB promete 99,99% para uma primária regional; a aritmética do que isso permite é a da
aula 7, e vale aqui sem mudança.

**A máquina é dimensionada pelos processadores, e a memória vem junto.** O tamanho é `--cpu-count`, e
a ajuda diz o que cada número significa:

```
ana@laptop:~/gcp$ gcloud alloydb instances create --help | sed -n '/^     --cpu-count/,/288\./p'
     --cpu-count=CPU_COUNT
        Whole number value indicating how many vCPUs the machine should
        contain. If the instance does not have a machine-type, the vCPU count
        will be used to determine the machine type where each vCPU corresponds
        to an N2 high-mem machine:
        (https://cloud.google.com/compute/docs/general-purpose-machines#n2_machine_types).
        where CPU_COUNT can be one of: 2, 4, 8, 16, 32, 64, 96, 128. If the
        instance has a machine-type, cpu-count must have the same value as the
        vCPU count in the machine-type. Eg: if machine-type is
        c4a-highmem-4-lssd, cpu-count must be 4. CPU_COUNT must be one of: 1,
        2, 4, 8, 14, 16, 22, 32, 44, 48, 64, 72, 88, 96, 128, 144, 192, 288.
```

**Uma máquina N2 high-memory tem 8 GiB de memória por vCPU**, que é a definição dessa família no
Compute Engine e não algo que o AlloyDB acrescenta: `--cpu-count=8` são 8 vCPUs e 64 GiB. A segunda
lista de números, até 288, é para as outras séries de máquina nomeadas por `--machine-type`, como a
C4A, que roda no Axion, o processador Arm do Google. A página de preços cobra N2 e C4A na mesma tarifa
por vCPU e por GiB, e a última seção desta aula usa essa tarifa.

## O read pool, um endereço e muitos nós

**Um read pool é uma instância com um endereço e até 20 nós atrás dele.** Uma aplicação se conecta ao
endereço do pool e as conexões são distribuídas entre os nós, então aumentar a capacidade de leitura é
mudar um número, `--read-pool-node-count`, em vez de criar réplicas e ensinar à aplicação o nome
delas. Todo nó de um pool tem o mesmo tamanho. Um pool de um nó só pode ser zonal, como a ajuda acima
diz, e um pool de dois ou mais espalha os nós por mais de uma zona, para que a perda de uma zona deixe
alguns deles respondendo.

**Um cluster pode ter mais de um pool**, e é assim que a Quitanda impede os analistas de deixar a loja
lenta. As páginas de catálogo do site e o histórico de pedidos leem de um pool dimensionado para o pico
da noite; a ferramenta de relatórios dos analistas lê de um segundo pool, maior, só dela. Os dois pools
leem o mesmo armazenamento, então nenhum acrescenta um gigabyte à conta, e um relatório pesado no
segundo nunca tira uma conexão do primeiro.

## Os comandos, não executados

**Três comandos montam o banco de pedidos da Quitanda**: o cluster, depois a primária, depois o read
pool. Estão como você os digitaria contra um projeto real. **Não foram executados aqui**: não há
AlloyDB neste laptop nem conta por trás deste curso, e por isso a saída deles não aparece.

```sh
gcloud alloydb clusters create quitanda-orders --region=southamerica-east1 \
  --network=default --password="$ALLOYDB_PASSWORD" --database-version=POSTGRES_16 \
  --enable-continuous-backup --continuous-backup-recovery-window-days=14
gcloud alloydb instances create quitanda-orders-primary --cluster=quitanda-orders \
  --region=southamerica-east1 --instance-type=PRIMARY --cpu-count=8 --availability-type=REGIONAL
gcloud alloydb instances create quitanda-orders-reads --cluster=quitanda-orders \
  --region=southamerica-east1 --instance-type=READ_POOL --cpu-count=8 --read-pool-node-count=2
```

**`--network` nomeia uma rede VPC, e as instâncias recebem endereços privados nela.** Uma instância do
AlloyDB é alcançada de dentro da rede por padrão, o que exige configurar antes o private services
access da rede, assunto de `gcp-foundations`; um endereço público é uma opção a ligar, não o padrão. A
senha vem de uma variável para não ficar no histórico do seu shell. `POSTGRES_16` é uma das versões
que a ajuda oferece, ao lado de 14, 15, 17 e 18.

**O backup contínuo é a base da recuperação para um ponto no tempo.** Com ele ligado, o AlloyDB guarda
o log pela janela de recuperação, aqui catorze dias, e pode restaurar o cluster em qualquer momento
dentro dela como um cluster novo, a mesma ideia da recuperação para um ponto no tempo do Cloud SQL na
aula 7. O armazenamento dele é cobrado na tarifa de backup da página de preços, que a última seção
desta aula lista e deixa fora dos totais.

**As flags são reais mesmo que as chamadas não sejam.** Toda flag desses três comandos aparece em
`gcloud alloydb … --help` neste laptop, que é a verificação possível sem conta, porque a linha de
comando recusa uma flag que não conhece antes de mandar qualquer coisa:

```
ana@laptop:~/gcp$ gcloud alloydb instances create quitanda-orders-reads --cluster=quitanda-orders --region=southamerica-east1 --instance-type=READ_POOL --cpu-count=8 --read-pool-nodes=2
ERROR: (gcloud.alloydb.instances.create) unrecognized arguments: --read-pool-nodes=2 (did you mean '--read-pool-node-count'?) 

To search the help text of gcloud commands, run:
  gcloud help -- SEARCH_TERMS
```

**`--read-pool-nodes` não é uma flag**, e a recusa diz qual é. O que ela não consegue verificar é
qualquer coisa que o Google responderia, se `southamerica-east1` tem capacidade para a máquina hoje,
ou se a rede tem private services access, e esses são os erros que uma primeira tentativa real
costuma encontrar.
