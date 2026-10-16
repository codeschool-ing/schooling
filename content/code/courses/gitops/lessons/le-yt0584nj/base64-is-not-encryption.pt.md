---
title: Base64 não é criptografia
version: 1
---

O `bulletin` imprime `token: none` desde a aula 1. O programa procura um arquivo em `/secrets/token`
e, quando existe um, imprime o começo do SHA-256 dele em vez do valor, então a página prova qual
token um pod tem sem mostrá-lo. Esta aula dá um token para o staging e outro para a produção, e o
jeito óbvio de escrever um é um Secret:

```
ana@laptop:~/fleet$ kubectl -n staging create secret generic bulletin-token --from-literal=token=a-staging-token --dry-run=client -o yaml
apiVersion: v1
data:
  token: YS1zdGFnaW5nLXRva2Vu
kind: Secret
metadata:
  name: bulletin-token
  namespace: staging
```

**O valor em `data` não está escondido; está codificado.** O base64 transforma bytes em letras para
que qualquer byte caiba num YAML, e se desfaz com um comando e nenhuma chave:

```
ana@laptop:~/fleet$ kubectl -n staging create secret generic bulletin-token --from-literal=token=a-staging-token --dry-run=client -o jsonpath='{.data.token}' | base64 -d; echo
a-staging-token
```

Um Secret do Kubernetes é um ConfigMap com outro nome e um pouco mais de cuidado em volta: o
`kubectl describe` não o imprime, ele pode ser legível por menos gente que um ConfigMap, e o API
server pode cifrá-lo no etcd. Nada disso ajuda quando o YAML está no Git, onde **quem lê o
repositório lê o token**, assim como todo clone, todo fork, todo backup e todo laptop que já fez
checkout dele. Apagar o arquivo depois também não ajuda: o commit que o acrescentou continua lá, e o
histórico da aula 2 é justamente a coisa que nunca esquece.

Então o YAML de um Secret nunca entra no repositório como está. O resto desta aula é sobre o que
entra no lugar.
