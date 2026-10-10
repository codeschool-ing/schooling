---
title: Um cluster num script
version: 1
---

O Kafka chega como um conjunto de programas e nenhuma opinião sobre como rodá-los. Um nó precisa de
um arquivo de configuração, de um diretório que seja dele, de uma **formatação** única desse
diretório e de um comando que o inicie; três nós precisam de tudo isso três vezes, com portas que
não colidam e uma lista de quem vota nas eleições do cluster. Digitar isso à mão é como um
laboratório acaba num estado que ninguém consegue explicar, então o curso faz com um script, que
você salva agora e usa em todas as lições depois desta.

Salve isto como `~/work/cluster.sh`:

```schooling-example
{
  "language": "sh",
  "file": "cluster.sh",
  "parts": [
    {
      "code": "#!/usr/bin/env bash\n# cluster.sh: a Kafka cluster of one or three nodes, all on this machine.\n#\n#   cluster.sh new 1      a fresh cluster of one node (deletes the old one)\n#   cluster.sh new 3      a fresh cluster of three nodes\n#   cluster.sh start      start every node, and wait until each one answers\n#   cluster.sh stop       stop every node, cleanly\n#   cluster.sh status     which nodes are running\n#   cluster.sh kill N     stop node N without warning, as a crash would\n#   cluster.sh start N    start node N on its own\n#\n# Node N takes client connections on port 9091+N and talks to the other\n# nodes' controllers on 9191+N. Everything it stores is under ~/kafka-data/nodeN.\nset -euo pipefail\n\nKAFKA=$HOME/kafka\nDATA=$HOME/kafka-data\n",
      "note": "O modo de uso, que também é o que o script imprime quando chamado sem nada. **O nó N escuta em 9091+N**, então um cluster de um nó é o conhecido `localhost:9092`."
    },
    {
      "code": "nodes() { ls -d \"$DATA\"/node* 2>/dev/null | sed 's/.*node//' | sort -n; }\npid_of() { pgrep -f \"^[^ ]*java .*kafka-data/node$1/server.properties\" || true; }\nanswers() { (exec 3<>\"/dev/tcp/localhost/$1\") 2>/dev/null; }\n",
      "note": "Três ajudantes pequenos. Um nó é achado pelo arquivo de configuração na sua linha de comando, e **\"responde\" quer dizer que algo aceita uma conexão na porta dele**, que é o único teste de que um servidor está pronto e não só iniciado."
    },
    {
      "code": "new() {\n  local n=$1 voters=\"\" i id\n  case $n in 1|3) ;; *) echo \"new: 1 or 3 nodes, not $n\" >&2; exit 2 ;; esac\n  if [ -n \"$(pgrep -f \"^[^ ]*java .*kafka-data/node\" || true)\" ]; then\n    echo \"new: the cluster is running; cluster.sh stop first\" >&2; exit 1\n  fi\n  for i in $(seq 1 \"$n\"); do voters+=\"${voters:+,}$i@localhost:$((9191 + i))\"; done\n  rm -rf \"$DATA\"\n  id=$(\"$KAFKA\"/bin/kafka-storage.sh random-uuid)",
      "note": "`new` se recusa a rodar com um cluster vivo, e depois apaga os dados antigos. `controller.quorum.voters` lista os nós que votam no estado do cluster, e todo nó precisa receber a mesma lista."
    },
    {
      "code": "  for i in $(seq 1 \"$n\"); do\n    mkdir -p \"$DATA/node$i\"\n    cat > \"$DATA/node$i/server.properties\" <<CONF\nprocess.roles=broker,controller\nnode.id=$i\ncontroller.quorum.voters=$voters\nlisteners=PLAINTEXT://localhost:$((9091 + i)),CONTROLLER://localhost:$((9191 + i))\nadvertised.listeners=PLAINTEXT://localhost:$((9091 + i))\ncontroller.listener.names=CONTROLLER\ninter.broker.listener.name=PLAINTEXT\nlistener.security.protocol.map=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT\nlog.dirs=$DATA/node$i/log\nnum.partitions=1\ndefault.replication.factor=$n\noffsets.topic.replication.factor=$n\ntransaction.state.log.replication.factor=$n\ntransaction.state.log.min.isr=1\nshare.coordinator.state.topic.replication.factor=$n\nshare.coordinator.state.topic.min.isr=1\ngroup.initial.rebalance.delay.ms=0\nCONF",
      "note": "Um arquivo de configuração por nó. **Cada nó é ao mesmo tempo um broker, que guarda dados, e um controller, que mantém os metadados do cluster**; a lição 5 separa os dois papéis. Os fatores de replicação acompanham o tamanho do cluster, para que os tópicos que o Kafka cria para si sobrevivam à perda de um nó quando há três."
    },
    {
      "code": "    \"$KAFKA\"/bin/kafka-storage.sh format -t \"$id\" -c \"$DATA/node$i/server.properties\" >/dev/null\n  done\n  echo \"new: $n node(s), cluster id $id\"\n}\n",
      "note": "**Formatar grava o id do cluster no diretório do nó.** Um nó se recusa a iniciar num diretório nunca formatado, e a entrar num cluster cujo id é diferente do seu."
    },
    {
      "code": "start_one() {\n  local i=$1\n  [ -f \"$DATA/node$i/server.properties\" ] || { echo \"node $i: does not exist\" >&2; exit 1; }\n  if [ -n \"$(pid_of \"$i\")\" ]; then echo \"node $i: already running\"; return; fi\n  if answers $((9091 + i)); then\n    echo \"node $i: port $((9091 + i)) is taken by another program\" >&2; exit 1\n  fi\n  LOG_DIR=\"$DATA/node$i/logs\" KAFKA_HEAP_OPTS=\"-Xms512m -Xmx512m\" \\\n    \"$KAFKA\"/bin/kafka-server-start.sh -daemon \"$DATA/node$i/server.properties\"\n}\n",
      "note": "Um nó que já está rodando é deixado em paz, e **uma porta que outro ocupa é recusada antes de o Java iniciar**, porque senão o nó falharia dez segundos depois com o motivo enterrado no log. Cada nó ganha 512 MB de heap, o bastante para um laboratório e uma fração do que um broker de produção recebe. Os logs dele vão para `~/kafka-data/nodeN/logs`."
    },
    {
      "code": "wait_for() {\n  local i=$1 t\n  for t in $(seq 1 60); do\n    if answers $((9091 + i)); then echo \"node $i: up on localhost:$((9091 + i))\"; return; fi\n    if [ -z \"$(pid_of \"$i\")\" ]; then\n      echo \"node $i: stopped while starting; the reason is in $DATA/node$i/logs/server.log\" >&2\n      exit 1\n    fi\n    sleep 1\n  done\n  echo \"node $i: not answering after 60 seconds\" >&2; exit 1\n}\n",
      "note": "Iniciar não é o mesmo que estar pronto. O script espera pela porta e, **se o processo morrer antes, diz onde está o motivo** em vez de esperar um minuto por nada."
    },
    {
      "code": "case ${1:-} in\n  new)    new \"${2:-}\" ;;\n  start)\n    if [ -n \"${2:-}\" ]; then start_one \"$2\"; wait_for \"$2\"; exit; fi\n    [ -n \"$(nodes)\" ] || { echo \"start: no cluster; cluster.sh new 1 first\" >&2; exit 1; }\n    for i in $(nodes); do start_one \"$i\"; done\n    for i in $(nodes); do wait_for \"$i\"; done ;;\n  stop)\n    for i in $(nodes); do\n      p=$(pid_of \"$i\"); [ -n \"$p\" ] || continue\n      kill \"$p\"\n      while kill -0 \"$p\" 2>/dev/null; do sleep 1; done\n      echo \"node $i: stopped\"\n    done ;;\n  kill)\n    p=$(pid_of \"${2:?kill which node?}\")\n    [ -n \"$p\" ] || { echo \"node $2: not running\" >&2; exit 1; }\n    kill -9 \"$p\"; echo \"node $2: killed\" ;;\n  status)\n    [ -n \"$(nodes)\" ] || { echo \"no cluster; cluster.sh new 1 makes one\"; exit; }\n    for i in $(nodes); do\n      if [ -z \"$(pid_of \"$i\")\" ]; then echo \"node $i: stopped\"\n      elif answers $((9091 + i)); then echo \"node $i: up on localhost:$((9091 + i))\"\n      else echo \"node $i: starting\"; fi\n    done ;;\n  *) sed -n '2,13p' \"$0\" | sed 's/^# \\{0,1\\}//'; exit 2 ;;\nesac",
      "note": "Os comandos. `stop` manda o sinal educado e espera cada nó terminar de gravar; `kill` manda `-9`, que é o que um corte de energia parece para o nó, e a lição 5 o usa de propósito."
    }
  ]
}
```

O jeito mais seguro de colocar o arquivo intacto na máquina virtual é abrir um editor lá, `nano
~/work/cluster.sh`, colar e salvar com Ctrl+O e Ctrl+X. Depois torne-o executável, crie um cluster de
um nó e suba-o:

```
ubuntu@stream:~/work$ chmod +x cluster.sh
ubuntu@stream:~/work$ ./cluster.sh new 1
new: 1 node(s), cluster id F0yZgBT0Stq_QLv6aODcIA
ubuntu@stream:~/work$ ./cluster.sh start
node 1: up on localhost:9092
```

O primeiro comando não imprime nada, que é o jeito do Linux dizer que funcionou. `new` leva alguns
segundos, porque cada `kafka-storage.sh` inicia uma máquina virtual Java; `start` leva mais alguns,
porque o nó relê os próprios metadados antes de abrir a porta.

**O id do cluster é novo a cada `new`**, então o seu é outra string. O resto deve bater. Rode
`status` sempre que não tiver certeza do que está rodando:

```
ubuntu@stream:~/work$ ./cluster.sh status
node 1: up on localhost:9092
```

## O que está no disco agora

`new` criou um diretório por nó, e o nó está escrevendo nele desde que subiu:

```
ubuntu@stream:~/work$ ls ~/kafka-data/node1 ~/kafka-data/node1/log
/home/ubuntu/kafka-data/node1:
log
logs
server.properties

/home/ubuntu/kafka-data/node1/log:
__cluster_metadata-0
bootstrap.checkpoint
cleaner-offset-checkpoint
log-start-offset-checkpoint
meta.properties
recovery-point-offset-checkpoint
replication-offset-checkpoint
```

`server.properties` é a configuração que o script gerou, `logs` guarda o que o nó diz sobre si
mesmo, e `log` é onde os dados ficam. Os dois nomes diferem por uma letra e significam coisas
diferentes, um costume antigo do Kafka: **`log` são os dados, porque o Kafka guarda um tópico como
um log**, que é o assunto da lição 2. `__cluster_metadata-0` é o log do próprio controller, onde
todo tópico que você cria e todo nó que entra fica anotado. `meta.properties` guarda o id do
cluster.

Uma coisa para saber antes de parar no fim do dia: **o cluster não sobe sozinho** quando a máquina
virtual sobe. Depois de reiniciar, `./cluster.sh start` o traz de volta, com tudo o que tinha
guardado.
