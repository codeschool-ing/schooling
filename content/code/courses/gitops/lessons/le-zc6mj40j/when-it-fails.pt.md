---
title: Quando falha
version: 1
---

**Quando o operador não consegue ler o cofre, o Secret fica com o último valor.** Ele não o apaga
nem o esvazia, então os pods seguem com o que tinham; o que para é a próxima mudança. É o padrão
certo, e significa que uma falha aqui é silenciosa a menos que alguém olhe.

## Um caminho que não é o permitido

O ExternalSecret apontou para `bulletin/prod` em vez de `bulletin/production`, um erro de digitação
do tipo que passa num pull request. Aplicado direto no cluster como experimento; o Flux devolve a
versão do repositório na passada seguinte:

```
ana@laptop:~/fleet$ kubectl -n production patch externalsecret bulletin-token --type merge -p '{"spec":{"data":[{"secretKey":"token","remoteRef":{"key":"bulletin/prod","property":"token"}}]}}'
externalsecret.external-secrets.io/bulletin-token patched
ana@laptop:~/fleet$ kubectl -n production get externalsecret bulletin-token
NAME             STORETYPE     STORE   REFRESH INTERVAL   STATUS              READY
bulletin-token   SecretStore   vault   1m                 SecretSyncedError   False
ana@laptop:~/fleet$ kubectl -n production get externalsecret bulletin-token -o jsonpath='{.status.conditions[0].message}'; echo
could not get secret data from provider
ana@laptop:~/fleet$ kubectl -n external-secrets logs deployment/external-secrets --since=2m | grep bulletin-token | tail -n 1 | jq -c "{msg, error}"
{"msg":"Reconciler error","error":"error processing spec.data[0] (key: bulletin/prod), err: cannot read secret data from Vault: Error making API request.\n\nURL: GET http://vault:8200/v1/secret/data/bulletin/prod\nCode: 403. Errors:\n\n* 1 error occurred:\n\t* permission denied\n\n"}
ana@laptop:~/fleet$ curl -s localhost:8081 | grep token
token: sha256:b92fc7e037ca
```

`SecretSyncedError`, e a mensagem da condição só diz que o provedor não entregou os dados. **O
motivo está no log do operador**: o Vault respondeu `403 permission denied` para
`secret/data/bulletin/prod`, porque a política da aula 9 nomeia `bulletin/production` e nada mais. O
pod continua mostrando `b92fc7e037ca`, o último valor que o Secret teve.

## Um cofre selado

O Vault reinicia, e ninguém o destranca:

```
ana@laptop:~/fleet$ docker restart vault
vault
ana@laptop:~/fleet$ kubectl -n production get secretstore,externalsecret
NAME                                    AGE     STATUS   CAPABILITIES   READY
secretstore.external-secrets.io/vault   3m27s   Valid    ReadWrite      True

NAME                                                STORETYPE     STORE   REFRESH INTERVAL   STATUS              READY
externalsecret.external-secrets.io/bulletin-token   SecretStore   vault   1m                 SecretSyncedError   False
ana@laptop:~/fleet$ kubectl -n external-secrets logs deployment/external-secrets --since=1m | grep bulletin-token | tail -n 1 | jq -c "{msg, error}"
{"msg":"Reconciler error","error":"error processing spec.data[0] (key: bulletin/production), err: unable to log in to auth method: unable to log in with Kubernetes auth: Error making API request.\n\nURL: PUT http://vault:8200/v1/auth/kubernetes/login\nCode: 503. Errors:\n\n* Vault is sealed"}
ana@laptop:~/fleet$ curl -s localhost:8081 | grep token
token: sha256:b92fc7e037ca
ana@laptop:~/fleet$ vault operator unseal $(jq -r '.unseal_keys_b64[0]' ~/vault-init.json) | grep '^Sealed'
Sealed                  false
```

O SecretStore continua dizendo `Valid`: ele foi conferido quando foi criado e é conferido de novo no
próprio ritmo, então um cofre que caiu há um minuto pode parecer saudável. Quem está em erro é o
ExternalSecret, e o log do operador tem o motivo: o login no Vault voltou `503` e `Vault is sealed`.
O pod manteve o valor o tempo todo, e destrancar o Vault pôs tudo de volta.

| o que aparece | onde | o que significa |
|---|---|---|
| `SecretSyncedError`; `403` e `permission denied` no log | o status do ExternalSecret, o log do operador | o cofre respondeu e recusou aquele caminho; com a política do Vault nomeando um caminho só, um erro de digitação aparece como recusa |
| `SecretSyncedError`; `unable to log in` e `Vault is sealed` no log | o status do ExternalSecret, o log do operador | o operador não conseguiu entrar, e o resto da linha diz por quê: aqui, um Vault selado |

**Observe o status, não os pods.** Um ExternalSecret que parou de sincronizar há uma semana parece
igual a um que está bem até o dia em que o valor precisa mudar. O Flux informa a saúde dos objetos
que aplicou, então um Kustomization com `wait: true` transforma um ExternalSecret que continua sem
`Ready` numa reconciliação com falha quando o timeout passa, e a aula 12 transforma falhas assim em
notificações.
