---
title: Uma conferência que roda dentro do convidado
version: 1
---

Conferir as portas um comando por vez é fácil de errar e chato de repetir, então aqui vai um script
curto que tenta cada uma de dentro do convidado e diz o que achou. Cada linha é **um comando que só dá
certo quando a porta está aberta**:

```schooling-example
{"language": "bash", "parts": [{"code": "#!/usr/bin/env bash\n# Run inside a lab guest, with the host's address on the lab network.\nhost=${1:?usage: check.sh HOST_ADDRESS}", "note": "O endereço do host entra como argumento, `10.20.0.1` na labnet. O `${1:?...}` para o script com a linha de uso se ele faltar."}, {"code": "check() {\n  if \"${@:2}\" >/dev/null 2>&1; then echo \"$1: OPEN\"; else echo \"$1: closed\"; fi\n}", "note": "**Toda conferência é um comando que só dá certo se a porta estiver aberta.** O primeiro argumento é o nome a imprimir, o resto é o comando. A saída dele vai fora; só conta se deu certo."}, {"code": "check \"a route out of the lab\"  ip route get 10.0.0.50", "note": "Pergunta à tabela de rotas do próprio convidado um caminho para um endereço da rede de verdade, a impressora do escritório. Sem linha `default via`, não há nenhum."}, {"code": "check \"the host's ssh\"          nc -z -w 3 \"$host\" 22\ncheck \"the host's port 8000\"    nc -z -w 3 \"$host\" 8000", "note": "O `nc -z` só bate na porta: conecta e desliga na hora. O `-w 3` desiste depois de três segundos, que é como um pacote descartado parece visto de dentro."}, {"code": "check \"a shared folder\"         grep -qE \" (9p|virtiofs) \" /proc/mounts", "note": "Os dois tipos de pasta compartilhada da aula 12, procurados na lista de sistemas de arquivos montados do convidado. Não o `findmnt -t 9p,virtiofs`: ele sai com sucesso mesmo quando não acha nada, então a conferência diria OPEN em todo convidado."}, {"code": "check \"a clipboard agent\"       pgrep -x \"spice-vdagent|VBoxClient\"", "note": "Os programas que levam a área de transferência compartilhada dentro do convidado: o agente do SPICE, para o QEMU, e o do próprio VirtualBox. Sem nenhum dos dois rodando, nada passa a área de transferência para dentro ou para fora."}]}
```

Rodado no client antes de qualquer mudança:

```
ana@client:~$ bash check.sh 10.20.0.1
a route out of the lab: closed
the host's ssh: OPEN
the host's port 8000: OPEN
a shared folder: closed
a clipboard agent: closed
```

O caminho para fora está fechado e não há pasta compartilhada nem agente de área de transferência,
porque este laboratório nunca os teve. As duas portas para dentro do host estão **OPEN**, como a seção
anterior achou à mão. Essa é a lista do que consertar.

Uma conferência assim vale ser guardada pelo mesmo motivo do snapshot da aula 14: **da próxima vez que o
laboratório mudar, basta um comando para saber se uma porta abriu de novo.**
