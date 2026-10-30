---
title: Workers secundários, Spot, autoescala e o que roda no boot
version: 1
---

**Um worker secundário é o único papel que um cluster pode perder sem perder nada além de tempo**,
e é por isso que é o papel que o Dataproc deixa você preencher com máquinas mais baratas. A seção
anterior ordenou os papéis pelo que a perda de cada um custa; esta põe preços por trás dessa ordem,
faz o cluster crescer e encolher sozinho e instala o que um job precisa em toda máquina enquanto ela
liga. Nada disso foi rodado contra o Google, porque aqui não há Dataproc. O que rodou foi a própria
descrição das opções pela linha de comando, que não precisa de rede:

```
ana@laptop:~/gcp$ gcloud dataproc clusters create --help | grep -A2 -- '--secondary-worker-type=TYPE; default'
          --secondary-worker-type=TYPE; default="preemptible"]
        [--stop-expiration-time=STOP_EXPIRATION_TIME
          | --stop-max-age=STOP_MAX_AGE]
--
         --secondary-worker-type=TYPE; default="preemptible"
            The type of the secondary worker group. TYPE must be one of:
            preemptible, non-preemptible, spot.
```

**Três tipos, e o padrão é o que o Google pode tomar de volta.** A primeira ocorrência é a sinopse,
onde a opção aparece entre as vizinhas; a segunda é a entrada da própria opção. Um grupo secundário
criado sem `--secondary-worker-type` é preemptivo, então um cluster que pede workers secundários
recebe máquinas retomáveis, a menos que diga o contrário.

## Preemptivas, Spot e não preemptivas

**VMs preemptivas e Spot são a capacidade sobrando do Compute Engine, vendida abaixo do preço padrão
e tomada de volta quando o Google precisa dela**, com uns trinta segundos de aviso. As duas diferem
num ponto que importa para um cluster: uma VM preemptiva é parada depois de no máximo 24 horas,
aconteça o que acontecer, e uma VM Spot não tem esse limite, então um cluster de longa duração com
secundários Spot fica com eles até a capacidade ser pedida em outro lugar. Os preços Spot variam,
diz a página de preços do Compute Engine, e podem mudar até uma vez por dia, e é por isso que o
programa de preços desta aula não tem linha para eles.

**Secundários não preemptivos são VMs padrão que continuam sem HDFS.** Custam o mesmo que um worker
primário e servem a um cluster que quer crescer e encolher rápido: um secundário entra ou sai no
tempo que uma máquina leva para ligar ou parar, porque nenhum bloco precisa ser movido antes.

A ordem dos papéis é a regra. **Os workers secundários podem ser Spot, porque perder um custa
tempo.** Os primários devem ser VMs padrão, porque perder um custa blocos do HDFS, e o master sempre
deve ser, porque perdê-lo encerra o cluster. Aqui está o cluster da seção anterior com quatro
secundários Spot. **Ele não foi rodado aqui.**

```sh
gcloud dataproc clusters create quitanda-spark \
  --region=southamerica-east1 \
  --image-version=2.2-debian12 \
  --master-machine-type=n2-standard-4 --master-boot-disk-size=100GB \
  --num-workers=2 --worker-machine-type=n2-standard-4 --worker-boot-disk-size=100GB \
  --num-secondary-workers=4 --secondary-worker-type=spot
```

No Google Cloud, um secundário retomado é recriado quando a capacidade volta, e o YARN entrega as
tarefas que ele rodava às máquinas que sobraram. **O job continua, mais devagar, e termina.** O que
ele não aguenta é um cluster em que a maior parte do trabalho está em máquinas que podem ir embora
todas de uma vez: se a capacidade Spot da zona acaba, um cluster de dois primários e quarenta
secundários vira um cluster de dois, e um job de duas horas vira um bem mais longo. Um grupo
secundário dimensionado como uma parte do trabalho, e não como a maior parte dele, mantém o pior
caso limitado.

## Autoescala: uma política que o cluster segue

**Uma política de autoescala é um recurso separado para o qual um cluster aponta**, e ela decide
quantos workers o cluster deve ter a partir do que o YARN informa: a memória que o trabalho pendente
está pedindo e a memória que ninguém está usando. Ela é escrita como arquivo. Salve isto como
`autoscaling.yaml`:

`autoscaling.yaml`:

```yaml
workerConfig:
  minInstances: 2
  maxInstances: 2
secondaryWorkerConfig:
  minInstances: 0
  maxInstances: 20
basicAlgorithm:
  cooldownPeriod: 2m
  yarnConfig:
    scaleUpFactor: 1.0
    scaleDownFactor: 1.0
    gracefulDecommissionTimeout: 1h
```

**Os primários ficam fixos em dois e só os secundários se movem**, entre nenhum e vinte. É o formato
mais comum: as máquinas que guardam o HDFS ficam paradas, e as que só somam processadores vêm e vão.
`cooldownPeriod` é quanto a política espera entre duas decisões, para que o cluster não cresça e
encolha a cada tarefa que passa. `scaleUpFactor` e `scaleDownFactor` dizem quanto da diferença
fechar numa decisão, aqui toda ela. `gracefulDecommissionTimeout` é quanto tempo um worker sendo
removido pode continuar rodando as tarefas que já tem antes de ser tirado de qualquer jeito, para que
um cluster encolhendo termine o trabalho em vez de abandoná-lo.

Importar a política e apontar um cluster para ela são dois comandos. **Nenhum dos dois foi rodado
aqui.**

```sh
gcloud dataproc autoscaling-policies import quitanda-nightly \
  --source=autoscaling.yaml --region=southamerica-east1
gcloud dataproc clusters update quitanda-spark \
  --autoscaling-policy=quitanda-nightly --region=southamerica-east1
```

**Autoescala é para um cluster cujo trabalho muda de tamanho**: um compartilhado por vários jobs, ou
um cluster de longa duração com uma noite cheia e um dia calmo. Um cluster criado para um job de
tamanho conhecido fica melhor dimensionado na criação, porque toda decisão de escala espera o YARN
informar uma falta primeiro, e um cluster que começa pequeno e cresce passou os primeiros minutos
curto.

## Ações de inicialização: o que toda máquina roda ao ligar

**Uma ação de inicialização é um script no Cloud Storage que o Dataproc roda em toda máquina de um
cluster novo**, como root, depois que o software da imagem está pronto e antes de o cluster aceitar
jobs. É por ela que uma biblioteca, um agente ou um arquivo de configuração chega às máquinas, e é
uma das coisas que o Dataflow, sem máquinas suas para mexer, faz de outro jeito: lá a biblioteca vai
no próprio contêiner do pipeline ou nos requisitos dele. Salve esta como `install-libs.sh`:

`install-libs.sh`:

```sh
#!/bin/bash
set -euo pipefail
ROLE=$(/usr/share/google/get_metadata_value attributes/dataproc-role)
python3 -m pip install -q holidays==0.105
if [[ "$ROLE" == 'Master' ]]; then
  echo 'master only: nothing else to do for this cluster'
fi
```

A biblioteca é a que o job noturno precisaria para saber quais dias são feriados no Brasil, e ela vai
para toda máquina porque qualquer executor pode rodar o código que a chama. **A checagem de papel é
como um script faz coisas diferentes em máquinas diferentes**: o Dataproc escreve o papel de cada
máquina nos metadados dela, e um script que deve rodar uma vez por cluster, como um que cria um banco
de dados, roda só no master.

O script vai para um bucket, e o cluster é criado com o nome dele. **Não rodado aqui:**

```sh
gcloud storage cp install-libs.sh gs://quitanda-raw-prod/jobs/install-libs.sh
gcloud dataproc clusters create quitanda-spark --region=southamerica-east1 \
  --initialization-actions=gs://quitanda-raw-prod/jobs/install-libs.sh \
  --initialization-action-timeout=10m
```

**Uma ação de inicialização que falha derruba o cluster**, e esse é o comportamento útil: um cluster
sem a biblioteca aceitaria o job e o derrubaria às três da manhã, em vez de na criação. Dez minutos é
o tempo limite padrão, e cada minuto dele é cobrado em toda máquina, porque as máquinas estão ligadas
enquanto o script roda. Um script que baixa e compila por vinte minutos é motivo para montar uma
imagem própria com a biblioteca já nela, para que o custo seja pago uma vez e não em todo cluster.
