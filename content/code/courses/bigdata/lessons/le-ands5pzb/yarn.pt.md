---
title: YARN
version: 1
---

**O YARN, Yet Another Resource Negotiator, é um gerenciador de cluster que não sabe nada de MapReduce
nem de Spark.** Um *ResourceManager* mantém a lista de máquinas e decide quem recebe o quê. Um
*NodeManager* em cada máquina informa o que ela tem e inicia *contêineres*, um processo com uma
quantidade fixa de memória e de cores, quando mandam. Cada aplicação roda um *ApplicationMaster* no
seu primeiro contêiner, que pede mais contêineres ao ResourceManager e roda as suas tarefas neles. Os
papéis são os da aula 2, com outros nomes: o ResourceManager é o master do standalone, o NodeManager
o worker, e o ApplicationMaster é onde mora um driver Spark no modo cluster.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 306\" role=\"img\" data-fig=\"l12-yarn\" aria-label=\"Os papéis do YARN. Um cliente submete uma aplicação ao ResourceManager. O ResourceManager manda um NodeManager iniciar o primeiro contêiner da aplicação, o seu ApplicationMaster, que então pede mais contêineres ao ResourceManager e roda as suas tarefas neles, nos NodeManagers de outras máquinas.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">cliente</text><rect x=\"280.0\" y=\"24.0\" width=\"180.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">ResourceManager</text><text x=\"370.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">máquinas, filas</text><path d=\"M140.0 55.0 L278.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"209.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 submete</text><rect x=\"40.0\" y=\"140.0\" width=\"200.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">NodeManager</text><rect x=\"54.0\" y=\"172.0\" width=\"172.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ApplicationMaster</text><rect x=\"270.0\" y=\"140.0\" width=\"200.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">NodeManager</text><rect x=\"284.0\" y=\"180.0\" width=\"82.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">tarefa</text><rect x=\"374.0\" y=\"180.0\" width=\"82.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"415.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">tarefa</text><rect x=\"500.0\" y=\"140.0\" width=\"200.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">NodeManager</text><rect x=\"514.0\" y=\"180.0\" width=\"82.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">tarefa</text><rect x=\"604.0\" y=\"180.0\" width=\"82.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">tarefa</text><path d=\"M200.0 140.0 L300.0 86.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-amber)\"></path><text x=\"236.0\" y=\"104.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">2 pede contêineres</text><path d=\"M140 260 L140 284 L600 284\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M370.0 284.0 L370.0 262.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-amber)\"></path><path d=\"M600.0 284.0 L600.0 262.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-amber)\"></path><text x=\"484.0\" y=\"296.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">3 inicia tarefas</text></svg>", "caption": "O ResourceManager decide; o ApplicationMaster de cada aplicação pede e roda as suas tarefas.", "same": ["ApplicationMaster", "NodeManager", "ResourceManager"]}
```

O Hadoop 3.5.0, instalado na aula 3, já contém o YARN. A sua configuração são três arquivos em
`$HADOOP_HOME/etc/hadoop`, e um script desta aula os escreve e inicia os dois processos. Salve como
`~/big/yarn.sh`:

```schooling-example
{
  "language": "sh",
  "file": "yarn.sh",
  "parts": [
    {
      "code": "#!/bin/sh\n# A ResourceManager and one NodeManager on this machine, with two queues.\n#   sh yarn.sh setup    write the configuration (once)\n#   sh yarn.sh start    start the two processes\n#   sh yarn.sh stop     stop them\nset -e\nCONF=$HADOOP_HOME/etc/hadoop\n\n"
    },
    {
      "code": "yarn_site() {\n  cat <<END\n<configuration>\n  <property><name>yarn.resourcemanager.hostname</name><value>localhost</value></property>\n  <property><name>yarn.nodemanager.resource.memory-mb</name><value>6144</value></property>\n  <property><name>yarn.nodemanager.resource.cpu-vcores</name><value>4</value></property>\n  <property><name>yarn.scheduler.minimum-allocation-mb</name><value>256</value></property>\n  <property><name>yarn.nodemanager.aux-services</name><value>mapreduce_shuffle</value></property>\n  <property><name>yarn.log-aggregation-enable</name><value>true</value></property>\n  <property><name>yarn.nodemanager.vmem-check-enabled</name><value>false</value></property>\n  <property><name>yarn.nodemanager.disk-health-checker.max-disk-utilization-per-disk-percentage</name><value>98</value></property>\n  <property><name>yarn.nodemanager.env-whitelist</name><value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG,TZ,HADOOP_MAPRED_HOME</value></property>\n</configuration>\nEND\n}\n\n",
      "note": "**O NodeManager oferece 6 GB e 4 cores** desta máquina ao YARN, o que só é seguro com o cluster standalone parado, e o YARN os distribui em contêineres de pelo menos 256 MB. O serviço auxiliar é o shuffle do MapReduce, que roda dentro do NodeManager. A agregação de logs copia os logs de cada contêiner terminado para o HDFS, onde o `yarn logs` os acha. A checagem de memória virtual está desligada porque o Java 17 reserva muito mais espaço de endereços do que usa, e a checagem mataria contêineres bem dentro da sua memória. E um NodeManager se declara doente, e não roda nada, quando o seu disco passa de 90% de ocupação; a máquina em que isto foi gravado tinha passado disso, então a linha seguinte sobe o limite para 98%."
    },
    {
      "code": "mapred_site() {\n  cat <<END\n<configuration>\n  <property><name>mapreduce.framework.name</name><value>yarn</value></property>\n  <property><name>mapreduce.application.classpath</name><value>\\$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/*:\\$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*</value></property>\n  <property><name>yarn.app.mapreduce.am.resource.memory-mb</name><value>512</value></property>\n  <property><name>mapreduce.map.memory.mb</name><value>512</value></property>\n  <property><name>mapreduce.reduce.memory.mb</name><value>512</value></property>\n</configuration>\nEND\n}\n\n",
      "note": "**O MapReduce é mandado rodar no YARN** em vez do executor local, onde achar as próprias classes dentro de um contêiner, e quanta memória os seus contêineres pedem."
    },
    {
      "code": "capacity_scheduler() {\n  cat <<END\n<configuration>\n  <property><name>yarn.scheduler.capacity.root.queues</name><value>nightly,analysts</value></property>\n  <property><name>yarn.scheduler.capacity.root.nightly.capacity</name><value>70</value></property>\n  <property><name>yarn.scheduler.capacity.root.nightly.maximum-capacity</name><value>70</value></property>\n  <property><name>yarn.scheduler.capacity.root.analysts.capacity</name><value>30</value></property>\n  <property><name>yarn.scheduler.capacity.root.analysts.maximum-capacity</name><value>30</value></property>\n  <property><name>yarn.scheduler.capacity.maximum-am-resource-percent</name><value>0.5</value></property>\n</configuration>\nEND\n}\n\ncase \"$1\" in\n  setup)\n    yarn_site > $CONF/yarn-site.xml\n    mapred_site > $CONF/mapred-site.xml\n    capacity_scheduler > $CONF/capacity-scheduler.xml ;;\n  start)\n    yarn --daemon start resourcemanager\n    yarn --daemon start nodemanager ;;\n  stop)\n    yarn --daemon stop nodemanager\n    yarn --daemon stop resourcemanager ;;\nesac\n",
      "note": "**Duas filas sob a raiz**: `nightly` com 70% do cluster e `analysts` com 30%. O `maximum-capacity` limita `nightly` à sua parte, então, por mais que ela peça, os 30% dos analistas estão livres quando eles precisam. Um cluster com preempção deixa a fila grande pegar emprestada a parte ociosa e a toma de volta matando contêineres; este fica no simples."
    }
  ]
}
```

Escreva a configuração uma vez, inicie o YARN e pergunte o que ele tem:

```
ana@lab:~/big$ sh yarn.sh setup
ana@lab:~/big$ sh yarn.sh start
ana@lab:~/big$ yarn node -list 2>/dev/null
Total Nodes:1
         Node-Id	     Node-State	Node-Http-Address	Number-of-Running-Containers
       lab:38703	        RUNNING	         lab:8042	                           0
ana@lab:~/big$ mapred queue -list 2>/dev/null
======================
Queue Name : nightly 
Queue State : running 
Scheduling Info : Capacity: 70.0, MaximumCapacity: 70.0, CurrentCapacity: 0.0 
======================
Queue Name : analysts 
Queue State : running 
Scheduling Info : Capacity: 30.000002, MaximumCapacity: 30.000002, CurrentCapacity: 0.0 
```

**Um NodeManager com 6.144 MB e 4 cores, e duas filas que o dividem em 70 e 30.** As filas são a
promessa da aula 2: os analistas mantêm 30% por mais que a carga noturna peça. O `CurrentCapacity` é
quanto da sua parte cada fila está usando, nada ainda. O ResourceManager também responde na porta
8088, para um navegador e, em `/ws/v1/cluster`, como JSON.
