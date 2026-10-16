---
title: A que um selo está preso
version: 1
---

**Um SealedSecret é selado para um nome e um namespace, não só para um cluster.** O nome e o
namespace entram na cifragem, então o controlador decifra o `bulletin-token` em `staging` e nada
mais. Isso é de propósito: sem isso, quem pudesse criar objetos em algum namespace copiaria o
SealedSecret do staging para lá e o controlador lhe entregaria o token.

Copiá-lo para a produção mostra a recusa. Isto é feito direto contra o cluster, como experimento, e
desfeito no fim:

```
ana@laptop:~/fleet$ sed 's/namespace: staging/namespace: production/' apps/bulletin/staging/token.yaml | kubectl apply -f -
sealedsecret.bitnami.com/bulletin-token created
ana@laptop:~/fleet$ kubectl -n production get sealedsecret bulletin-token
NAME             AGE
bulletin-token   5s
ana@laptop:~/fleet$ kubectl -n production get events --field-selector involvedObject.name=bulletin-token -o custom-columns=REASON:.reason,MESSAGE:.message
REASON            MESSAGE
ErrUnsealFailed   Failed to unseal: no key could decrypt secret (token)
ana@laptop:~/fleet$ kubectl -n production delete sealedsecret bulletin-token
sealedsecret.bitnami.com "bulletin-token" deleted from production namespace
```

O SealedSecret foi criado, e nada saiu dele. **O controlador se recusou a abri-lo**, e diz isso num
evento, `ErrUnsealFailed`, com o motivo: nenhuma chave dele decifra um valor selado para outro
namespace. Nenhum Secret apareceu na produção.

Então **cada ambiente ganha seu próprio selo**, e em geral seu próprio token, que é o que a produção
recebe na próxima seção, com outra ferramenta. O `kubeseal --scope` pode afrouxar a amarração para
só o namespace, ou para o cluster inteiro, para um valor que é de fato o mesmo em todo lugar; é uma
decisão a deixar escrita, porque aumenta quem pode ler o segredo.

## A chave que ninguém pode perder

O selo dura o quanto duram as chaves privadas do controlador, e elas moram no cluster:

```
ana@laptop:~/fleet$ kubectl -n kube-system get secrets -l sealedsecrets.bitnami.com/sealed-secrets-key
NAME                      TYPE                DATA   AGE
sealed-secrets-keylcjp5   kubernetes.io/tls   2      76s
```

Uma chave até agora, criada quando o controlador subiu pela primeira vez, guardada como um Secret
comum do tipo `kubernetes.io/tls` em `kube-system`. A cada trinta dias outra se junta a ela.

**Se o cluster se perde, essas chaves se perdem com ele**, e todo SealedSecret do repositório vira
um arquivo que ninguém abre. Um cluster reconstruído a partir do Git, que é a promessa do GitOps,
começaria com chaves novas e falharia em todo selo. Então as chaves têm backup, fora do cluster e
fora do Git: `kubectl get secrets -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml` as
escreve, e esse arquivo vai para onde a empresa guarda o material mais sensível que tem, porque ele
abre todo segredo que o cluster já selou. Aplicá-lo num cluster novo e reiniciar o controlador deixa
o controlador novo abrir os selos antigos.

A outra saída é selar de novo: guardar o texto em claro em outro lugar e selá-lo de novo para o
cluster novo. O que já é uma pista do que a terceira família de respostas faz.
