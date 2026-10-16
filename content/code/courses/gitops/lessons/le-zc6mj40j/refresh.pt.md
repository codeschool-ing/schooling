---
title: O valor muda, o commit não
version: 1
---

**O ExternalSecret lê o Vault a cada minuto**, então um valor novo no Vault chega ao cluster sem
nada mudar no Git. Um token novo é posto no Vault:

```
ana@laptop:~/fleet$ kubectl -n production get pods -o name
pod/bulletin-55bcbd4ddb-5swsk
pod/bulletin-55bcbd4ddb-8dz75
pod/bulletin-55bcbd4ddb-d56sj
ana@laptop:~/fleet$ vault kv put secret/bulletin/production token=$(openssl rand -hex 16) | grep -E "^(version|created_time)"
created_time       2026-10-16T03:52:57.270537885Z
version            2
ana@laptop:~/fleet$ curl -s localhost:8081
bulletin 1.1
message: Welcome to the bulletin.
pod: bulletin-55bcbd4ddb-5swsk
token: sha256:b92fc7e037ca
ana@laptop:~/fleet$ kubectl -n production get pods -o name
pod/bulletin-55bcbd4ddb-5swsk
pod/bulletin-55bcbd4ddb-8dz75
pod/bulletin-55bcbd4ddb-d56sj
ana@laptop:~/fleet$ vault kv get -field=token secret/bulletin/production | sha256sum | cut -c1-12
b92fc7e037ca
```

Versão 2 da entrada, e o pod mostra a impressão digital dela, `b92fc7e037ca`, que é o que o Vault
guarda agora. Os três pods têm os nomes que tinham antes da mudança.

Dois atrasos se somam, e vale conhecer os dois antes de um incidente. O operador percebe na próxima
atualização, em até o `refreshInterval`. Depois o kubelet atualiza o arquivo em todo pod que monta o
Secret, na próxima sincronização, que por padrão leva cerca de um minuto. **Nenhum pod reiniciou**:
o nome na linha `pod:` não mudou. Um programa que lê o arquivo a cada pedido, como o `bulletin`, vê
o valor novo; um programa que o leu uma vez ao subir fica com o antigo até reiniciar, e isso é uma
propriedade do programa, não do operador. Variáveis de ambiente são o pior caso: elas ficam fixas
quando o contêiner sobe, diga o Secret o que disser depois.

O que o Git registra é que a produção lê `bulletin/production` do Vault, a cada minuto. Qual era o
valor às três da tarde, e quem o mudou, está no histórico do Vault e no log de auditoria dele, que a
aula 12 liga.
