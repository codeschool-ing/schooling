---
title: Voltar atrás é um commit
version: 1
---

**As checagens pegam um manifesto malformado. Elas não pegam um que é válido e errado.** Uma tag de
imagem que não existe é um texto perfeitamente bom, e o `kubeconform` aprova. Esta seção faz o merge
exatamente disso, observa o que o cluster faz e desfaz do jeito GitOps.

## Uma mudança válida e errada

A Ana leva o staging para `bulletin:1.1`, que ninguém nunca construiu. A checagem passa, o Bruno
aprova, e entra:

```
ana@laptop:~/fleet$ git switch --quiet -c staging-1.1
ana@laptop:~/fleet$ git commit --quiet -am "staging: bulletin 1.1"
ana@laptop:~/fleet$ git push --quiet -u origin staging-1.1
remote: 
remote: Create a new pull request for 'staging-1.1':        
remote:   http://localhost:3000/ana/fleet/pulls/new/staging-1.1        
remote: 
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" -H "$JSON" -d '{"head": "staging-1.1", "base": "main", "title": "staging: bulletin 1.1", "body": "The new release, for QA."}' $API/pulls | jq .number
3
ana@laptop:~/fleet$ sh ~/setup/validate.sh $(git rev-parse HEAD)
Summary: 3 resources found in 1 file - Valid: 3, Invalid: 0, Errors: 0, Skipped: 0
validate: success
ana@laptop:~/fleet$ curl -s -H "$AS_BRUNO" -H "$JSON" -d '{"event": "APPROVED", "body": "Fine."}' $API/pulls/3/reviews | jq -r .state
APPROVED
ana@laptop:~/fleet$ curl -s -w "%{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '{"Do": "merge"}' $API/pulls/3/merge
200
```

O laço aplicou, e o deployment começou um rollout que não tem como terminar:

```
ana@laptop:~/fleet$ kubectl -n staging get pods
NAME                        READY   STATUS         RESTARTS   AGE
bulletin-54b57cfbcf-kdbfd   0/1     ErrImagePull   0          33s
bulletin-657dd4685b-9jd2v   1/1     Running        0          80s
bulletin-657dd4685b-nnltr   1/1     Running        0          65s
bulletin-657dd4685b-zhsk9   1/1     Running        0          79s
ana@laptop:~/fleet$ kubectl -n staging get deployment bulletin
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
bulletin   3/3     1            3           104s
ana@laptop:~/fleet$ curl -s localhost:8080
bulletin 1.0
message: Staging is ready for review.
token: none
```

**O staging continua no ar.** Uma atualização gradual sobe pods novos antes de tirar os antigos, e um
pod novo que nunca fica pronto nunca substitui nada. Os três pods da versão anterior continuam
servindo, e o `curl` ainda recebe resposta. Tudo o que deu errado está à vista: um pod em
`ErrImagePull`, e um deployment com uma réplica atualizada das três que pediu.

## O caminho de volta

A correção tentadora é `kubectl rollout undo`. Funciona, por uma passada do laço, e então o laço
aplica a `main` de novo e a imagem quebrada volta. **A correção tem de ir para onde está a verdade.**
O `git revert` cria um commit novo que desfaz um antigo, e ele passa pelo mesmo fluxo que qualquer
outra mudança:

```
ana@laptop:~/fleet$ git switch --quiet main && git pull --quiet
ana@laptop:~/fleet$ git switch --quiet -c revert-1.1
ana@laptop:~/fleet$ git revert --no-edit -m 1 HEAD
[revert-1.1 15f3ce9] Revert "Merge pull request 'staging: bulletin 1.1' (#3) from staging-1.1 into main"
 Date: Fri Oct 9 14:20:00 2026 -0300
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@laptop:~/fleet$ git push --quiet -u origin revert-1.1
remote: 
remote: Create a new pull request for 'revert-1.1':        
remote:   http://localhost:3000/ana/fleet/pulls/new/revert-1.1        
remote: 
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" -H "$JSON" -d '{"head": "revert-1.1", "base": "main", "title": "Revert staging to bulletin 1.0", "body": "1.1 was never built. Back to 1.0 until it is."}' $API/pulls | jq .number
4
ana@laptop:~/fleet$ sh ~/setup/validate.sh $(git rev-parse HEAD)
Summary: 3 resources found in 1 file - Valid: 3, Invalid: 0, Errors: 0, Skipped: 0
validate: success
ana@laptop:~/fleet$ curl -s -H "$AS_BRUNO" -H "$JSON" -d '{"event": "APPROVED", "body": "Yes, revert."}' $API/pulls/4/reviews | jq -r .state
APPROVED
ana@laptop:~/fleet$ curl -s -w "%{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '{"Do": "merge"}' $API/pulls/4/merge
200
```

A reversão passou pela checagem e pela revisão como qualquer mudança, porque é uma, e o laço devolveu
o cluster:

```
ana@laptop:~/fleet$ git switch --quiet main && git pull --quiet
ana@laptop:~/fleet$ kubectl -n staging get pods
NAME                        READY   STATUS    RESTARTS   AGE
bulletin-657dd4685b-9jd2v   1/1     Running   0          102s
bulletin-657dd4685b-nnltr   1/1     Running   0          87s
bulletin-657dd4685b-zhsk9   1/1     Running   0          101s
ana@laptop:~/fleet$ git log --oneline --first-parent -4
b53ba28 Merge pull request 'Revert staging to bulletin 1.0' (#4) from revert-1.1 into main
e702151 Merge pull request 'staging: bulletin 1.1' (#3) from staging-1.1 into main
3782a32 Merge pull request 'staging: three replicas' (#2) from three-replicas into main
e1e3fc8 Merge pull request 'staging: ready for review' (#1) from banner-v2 into main
```

O laço, esse tempo todo, aplicou cada merge na passada seguinte à chegada dele: as três réplicas, a
imagem quebrada e a reversão.

```
02:01:51 at 3782a32
deployment.apps/bulletin configured
02:02:07 at 3782a32
02:02:22 at e702151
deployment.apps/bulletin configured
02:02:38 at e702151
02:02:53 at e702151
02:03:09 at b53ba28
deployment.apps/bulletin configured
```

## Por que não reescrever o histórico

A outra correção tentadora é voltar a `main` para antes do merge ruim e forçar o push. A regra já
recusa, e com razão: **um histórico que pode ser reescrito não é um registro.** Depois de um revert,
o `git log` conta a história verdadeira, que a 1.1 entrou, foi aplicada, falhou e foi revertida, com
dois nomes e dois horários. Depois de um push forçado ele conta uma história em que nada aconteceu, e
os pods que quebraram nesse meio-tempo não têm explicação em lugar nenhum.
