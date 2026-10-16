---
title: Sealed Secrets
version: 1
---

**O Sealed Secrets cifra um Secret com uma chave que só um cluster tem.** Um controlador roda no
cluster e guarda a metade privada de um par de chaves; qualquer um pode buscar a metade pública e
cifrar com ela. O que entra no Git é um `SealedSecret`, um objeto cujos valores só aquele
controlador decifra, e o controlador o transforma num Secret comum ao lado dele. O repositório é
aberto a todo mundo que o lê, e mesmo assim o token não é.

O `kubeseal` é a metade de linha de comando, e se instala como as outras ferramentas:

```
ana@laptop:~/setup$ ARCH=$(dpkg --print-architecture)
ana@laptop:~/setup$ curl -fsSLO https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.40.0/kubeseal-0.40.0-linux-$ARCH.tar.gz
ana@laptop:~/setup$ curl -fsSL https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.40.0/sealed-secrets_0.40.0_checksums.txt | grep " kubeseal-0.40.0-linux-$ARCH.tar.gz$" | sha256sum --check
kubeseal-0.40.0-linux-amd64.tar.gz: OK
ana@laptop:~/setup$ tar -xzf kubeseal-0.40.0-linux-$ARCH.tar.gz kubeseal && sudo install -m 0755 kubeseal /usr/local/bin/ && rm kubeseal kubeseal-0.40.0-linux-$ARCH.tar.gz
ana@laptop:~/setup$ kubeseal --version
kubeseal version: 0.40.0
```

O controlador é infraestrutura do cluster, não uma aplicação, então vai num diretório próprio,
`infrastructure/`. A release publica o controlador como um arquivo de manifestos simples, que entra
no repositório como está: a versão passa a ser a que um commit revisado diz, e atualizá-la é um pull
request como outro qualquer.

```
ana@laptop:~/fleet$ git switch --quiet -c sealed-secrets
ana@laptop:~/fleet$ mkdir -p infrastructure/sealed-secrets
ana@laptop:~/fleet$ curl -fsSLo infrastructure/sealed-secrets/controller.yaml https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.40.0/controller.yaml
ana@laptop:~/fleet$ grep -c '^kind:' infrastructure/sealed-secrets/controller.yaml
11
ana@laptop:~/fleet$ git add infrastructure clusters && git commit --quiet -m "sealed-secrets: the controller, 0.40.0"
ana@laptop:~/fleet$ kubectl -n kube-system get deployment sealed-secrets-controller
NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
sealed-secrets-controller   1/1     1            1           34s
```

Onze objetos: o Deployment do controlador, o tipo `SealedSecret`, dois Services e os papéis e
vínculos de que ele precisa. O Flux aplica o diretório com mais um Kustomization em `clusters/lab/`.
Este é o `clusters/lab/sealed-secrets.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: sealed-secrets
  namespace: flux-system
spec:
  interval: 10m
  path: ./infrastructure/sealed-secrets
  prune: true
  wait: true
  timeout: 3m
  sourceRef:
    kind: GitRepository
    name: flux-system
```

## Selando um token

O `kubeseal` precisa da chave pública do controlador. Ele pode perguntar ao controlador toda vez,
mas uma cópia num arquivo deixa você selar numa máquina que não alcança o cluster, e deixa claro
qual chave você está usando:

```
ana@laptop:~/fleet$ kubeseal --fetch-cert > ~/setup/sealed-secrets.pem
ana@laptop:~/fleet$ openssl x509 -in ~/setup/sealed-secrets.pem -noout -subject -enddate
subject=
notAfter=Oct 13 00:45:52 2036 GMT
```

Sem subject, e um certificado válido por dez anos, o que diz menos do que parece: o controlador cria
uma **chave nova a cada trinta dias** e guarda todas as antigas, então selos novos usam a chave mais
nova e os antigos continuam abrindo. Busque o certificado de novo de vez em quando; um selo feito
com um mais antigo continua funcionando.

Selar é um pipe: entra o YAML de um Secret, feito com `--dry-run=client` para que nada seja criado,
e sai um SealedSecret. O token nunca toca um arquivo em claro:

```
ana@laptop:~/fleet$ git switch --quiet -c staging-token
ana@laptop:~/fleet$ TOKEN=$(openssl rand -hex 16)
ana@laptop:~/fleet$ kubectl -n staging create secret generic bulletin-token --from-literal=token=$TOKEN --dry-run=client -o yaml | kubeseal --cert ~/setup/sealed-secrets.pem -o yaml > apps/bulletin/staging/token.yaml
ana@laptop:~/fleet$ cat apps/bulletin/staging/token.yaml
---
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: bulletin-token
  namespace: staging
spec:
  encryptedData:
    token: AgDJGI2gmRdGrMT6nidqHUIuIPcYpdP7yiWFAqGCUfCBVVwh0FORv2gv31yZ65uXW33ui9B+j58hrcNJnQMQRg5GCDAHdsiJB1cv/aJOqKemPDNHIS7DAYRiLvS968tpVOsOdz/eGcAfF43kU/4rjY7KJosM9YzGWeRwwpIw2GZatKnaLgW5SUi72kPOW1bB1hDE35VPbtW9eN17EUxBbVPkLlDP3CcSI/ARCoD1qB4Eoe96CESkK/T9gq0pkBEfSatqqBKh7lqbwpg+rTCdmeULTFMpoI9zN5Pcqq6urZvTKexsb/mC8y/CCbv8tuuS9akSEYmUNhesD+Nej8KzsB5w026HaAJg+UKhY+CLjaZuVLAXtSqel1PYrhJJSnkMWPzCTFvaNZVjSVLMbvEW+VgI+y17VAiWHPagP758gHXNjOYxe0UN5UOa5NfuSoqGjjyGaU5MofzTh2lYmzyN8klMGJsoZODU1cBOdUu6rC8dKroyN3dEeLGLyOOFwY3KuF8fSwspKevB1ceAE4WNflIdEnQ+xgbyd5xAEveZTZIZ47O+4MthDG9EiALfFB0sWnWXm5Mns5sDuwoZAlsdzokY4Bb0grku2qiLJyohGDiVEYa/B90kaZAvLNMv2nXVxywVM6EtLgR3HuZVRWU0M6yDNlfgfylxj2EzCEu41Vxa7TK9R/1GVuIeXmvo07YdX7SKbPOeQzDQ1Ai7EUzKU5Zv7HNRryzsYlx/j76QgeXOHQ==
  template:
    metadata:
      name: bulletin-token
      namespace: staging
```

O `encryptedData` guarda o token, cifrado para a chave do controlador, e o `template` diz como vai
ser o Secret em que ele se transforma. **Este arquivo pode ser commitado**: qualquer um o lê, e só o
controlador deste cluster o abre.

O Deployment da base monta o Secret como arquivo em `/secrets/token`, que é onde o `bulletin`
procura, e o marca como **opcional**, para que um ambiente sem token ainda suba. Este é o
`apps/bulletin/base/deployment.yaml` agora:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bulletin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bulletin
  template:
    metadata:
      labels:
        app: bulletin
    spec:
      containers:
      - name: bulletin
        image: localhost:5001/bulletin
        envFrom:
        - configMapRef:
            name: bulletin
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /
            port: 8080
        volumeMounts:
        - name: token
          mountPath: /secrets
          readOnly: true
      volumes:
      - name: token
        secret:
          secretName: bulletin-token
          optional: true
```

O kustomization do staging lista o `token.yaml` entre os recursos, e o `clusters/lab/staging.yaml`
ganha duas linhas:

```yaml
  dependsOn:
  - name: sealed-secrets
```

Elas importam no dia em que o cluster for reconstruído a partir do repositório. Sem elas, o Flux
aplicaria o staging e o controlador ao mesmo tempo, o staging falharia por falta do tipo
`SealedSecret`, e só se recuperaria na tentativa seguinte. Com o `dependsOn`, o staging espera até o
Kustomization do controlador ficar pronto.

E o `validate.sh` encontra mais um tipo cujo esquema não é do Kubernetes, então o `SealedSecret`
entra na lista que ele pula:

```sh
sed -i 's/-skip HelmRelease,OCIRepository /-skip HelmRelease,OCIRepository,SealedSecret /' ~/setup/validate.sh
```

```
ana@laptop:~/fleet$ git diff | grep '^[-+] '
+        volumeMounts:
+        - name: token
+          mountPath: /secrets
+          readOnly: true
+      volumes:
+      - name: token
+        secret:
+          secretName: bulletin-token
+          optional: true
+  dependsOn:
+  - name: sealed-secrets
ana@laptop:~/fleet$ git add apps clusters && git commit --quiet -m "staging: a sealed token"
ana@laptop:~/fleet$ kubectl -n staging get sealedsecrets,secrets
NAME                                      AGE
sealedsecret.bitnami.com/bulletin-token   35s

NAME                    TYPE     DATA   AGE
secret/bulletin-token   Opaque   1      35s
ana@laptop:~/fleet$ curl -s localhost:8080
bulletin 1.2
message: Staging is built by Kustomize.
pod: bulletin-6b796f54fc-r8l9q
token: sha256:3dda1746e73e
ana@laptop:~/fleet$ printf %s "$TOKEN" | sha256sum | cut -c1-12
3dda1746e73e
```

O controlador abriu o SealedSecret e escreveu um Secret de mesmo nome ao lado. Os pods do staging
foram trocados, porque o Deployment da base mudou, e os novos montam o token: a impressão digital na
página é a do `$TOKEN`, calculada do seu lado a partir do valor que nunca passou em claro por lugar
nenhum.
