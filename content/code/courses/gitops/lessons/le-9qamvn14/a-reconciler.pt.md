---
title: Um reconciliador que cabe numa tela
version: 1
---

**O Argo CD e o Flux são programas grandes, e no centro deles há um laço pequeno o bastante para
escrever em shell.** Escrevê-lo primeiro é o jeito mais rápido de ver para que servem os programas
grandes, e depois quais recursos deles são esse laço bem feito. Salve isto como
`~/setup/reconcile.sh`:

```sh
#!/bin/sh
# A reconciler in a dozen lines: fetch what Git says, apply it, wait, again.
# Usage: sh reconcile.sh REPOSITORY DIRECTORY
repo=$1 dir=$2 work=$HOME/.reconcile
[ -d "$work/.git" ] || git clone --quiet "$repo" "$work"
while true; do
  git -C "$work" pull --quiet --ff-only
  echo "$(date +%T) at $(git -C "$work" rev-parse --short HEAD)"
  kubectl apply -f "$work/$dir" | grep -v unchanged
  sleep 15
done
```

Ele mantém um clone próprio em `~/.reconcile`, separado do `~/fleet` onde você edita. **Ele lê só o
que foi enviado**, nunca os seus arquivos de trabalho, que é a mesma regra que um controlador de
verdade segue: o que está no seu disco e não está no repositório não existe. A cada quinze segundos
ele puxa, imprime o commit em que está e aplica a pasta; o `grep -v unchanged` esconde os objetos que
já combinavam, então o laço só imprime uma linha quando mudou alguma coisa.

## Rodando

Abra um segundo terminal para ele, porque ele não para até você apertar `Ctrl+C`:

```sh
sh ~/setup/reconcile.sh ~/fleet.git staging
```

De volta ao primeiro terminal, mude a mensagem no `staging/bulletin.yaml` para `Staging has the new
banner.` e envie:

```
ana@laptop:~/fleet$ git diff | grep '^[-+] '
-          value: Staging is open for testing.
+          value: Staging has the new banner.
ana@laptop:~/fleet$ git commit --quiet -am "staging: new banner"
ana@laptop:~/fleet$ git push --quiet
ana@laptop:~/fleet$ curl -s localhost:8080
bulletin 1.0
message: Staging has the new banner.
token: none
```

E isto foi o que o segundo terminal imprimiu enquanto isso:

```
ana@laptop:~$ sh ~/setup/reconcile.sh ~/fleet.git staging
01:59:27 at ab88607
01:59:42 at 9e1d64a
deployment.apps/bulletin configured
```

A saída conta a história. No começo o laço está em `ab88607` e não muda nada, porque o cluster já
combina. Na passada depois do push ele está em `9e1d64a` e relata
`deployment.apps/bulletin configured`: o template mudou, então o Kubernetes começou um rollout. Segundos depois o `curl` recebe
a mensagem nova de um pod novo.

**Ninguém rodou `kubectl` contra o cluster para publicar essa mudança.** Você enviou um commit, e o
laço, que tem as credenciais, o encontrou e aplicou. Essa inversão é o segundo e o terceiro dos
quatro princípios numa imagem só: o estado desejado é puxado, e o puxar nunca para.
