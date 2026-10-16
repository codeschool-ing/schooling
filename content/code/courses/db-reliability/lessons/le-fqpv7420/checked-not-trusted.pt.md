---
title: Um runbook conferido, em vez de acreditado
version: 1
---

Um runbook se deteriora de um jeito particular: os passos continuam se lendo bem enquanto as coisas
que eles citam mudam. Um servidor é renomeado, uma porta muda, um standby é aposentado, e a página
continua mandando conectar nele. A cura é a que este curso aplica a tudo: **verificar por máquina, com
calendário.**

Salve este runbook como `runbook.md`, com os seus próprios nomes onde forem diferentes. Ele está no
formato que esta lição descreveu, para o cluster que você montou nas lições 16 a 19. Uma linha nele
está desatualizada de propósito, do jeito que essas linhas costumam estar: sobra de um arranjo antigo
que ninguém removeu.

```localised
# Runbook: o banco de dados do shop

Comece aqui   ./status.sh  (o estado de tudo, agora)
Responsável   Ana; a escala de plantão quando ela não estiver
Último teste  ensaio do dia 16, seguido por outra pessoa

## Onde ficam as coisas
Escritas      127.0.0.1:5000  HAProxy, sempre o primário
Leituras      127.0.0.1:5001  HAProxy, as réplicas em rodízio
Nós           127.0.0.1:5441  127.0.0.1:5442  127.0.0.1:5443
Relatórios    127.0.0.1:5434  standby do time de relatórios
Consenso      etcd, localhost:2379

## 1. O líder morreu
Esperado      um novo líder em cerca de 30 s; pedidos falham nesse meio-tempo
Verificar     ./status.sh: um Leader, duas Replicas, a porta 5000 nele
Se não        patronictl -c ~/patroni/pg1.yml list, e veja o 3
Depois        deixe o nó morto desligado até saber a causa;
              ligue-o com: patroni ~/patroni/<node>.yml
Pronto quando o nó é de novo uma Replica em streaming
Avisar        o suporte no início; todo mundo ao terminar

## 2. Um nó não volta ao cluster
## 3. O etcd caiu: as escritas param
## 4. Linhas apagadas por engano: réplica atrasada, ou PITR
```

Depois, uma checagem que o lê. Todo endereço da forma `127.0.0.1:port` no arquivo é um banco de dados
ao qual alguém pode ser mandado conectar no meio da noite, então cada um é perguntado se responde, com
o `pg_isready`, a ferramenta do próprio PostgreSQL para exatamente essa pergunta:

```schooling-example
{"language": "sh", "file": "runbook-check.sh", "parts": [{"code": "#!/bin/sh\n# runbook-check.sh: does every database address in the runbook answer?\nstatus=0\nfor a in $(grep -o '127\\.0\\.0\\.1:[0-9]*' runbook.md | sort -u); do", "note": "Cada host:porta que o runbook cita, uma vez só."}, {"code": "  if pg_isready -q -t 3 -h \"${a%:*}\" -p \"${a#*:}\"; then\n    echo \"ok       $a\"\n  else\n    echo \"NO REPLY $a\"\n    status=1\n  fi\ndone", "note": "O pg_isready conecta e pergunta; -t 3 desiste depois de três segundos. Com -q ele não imprime nada, então o script escreve a própria linha."}, {"code": "exit $status", "note": "Sai com 1 quando algo não respondeu, para que um agendador possa transformar isso numa mensagem para o responsável pelo runbook."}]}
```

```
ana@vm:~$ ./runbook-check.sh; echo "exit $?"
ok       127.0.0.1:5000
ok       127.0.0.1:5001
NO REPLY 127.0.0.1:5434
ok       127.0.0.1:5441
ok       127.0.0.1:5442
ok       127.0.0.1:5443
exit 1
```

Cinco endereços respondem, e **um não**: o 5434, o standby que o time de relatórios foi orientado a
usar, das lições 11 a 15, e que o cluster das lições 16 a 19 substituiu. A checagem encontrou num
instante o que uma pessoa teria encontrado no pior instante possível, digitando o endereço da página e
se perguntando se o problema era ela. Rode-a pelo mesmo agendador do `lagcheck.sh` da lição 13, e
trate a falha dela do mesmo jeito: uma mensagem para o responsável pelo runbook, porque uma página
errada é um defeito, e não um erro de digitação.

Uma checagem como esta cobre endereços. Os **passos** são verificados do único jeito que passos podem
ser: por alguém que não seja o autor, seguindo-os, no ensaio da lição 23 e no ensaio de restauração da
lição 7, e corrigindo a página onde ela estava errada, no mesmo dia.
