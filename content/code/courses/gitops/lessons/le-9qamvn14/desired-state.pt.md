---
title: O estado desejado, por escrito
version: 1
---

**Um sistema GitOps começa com uma descrição do que deve estar rodando, em arquivos, no Git.** Não um
script que faz acontecer: uma descrição do resultado. Esta seção escreve essa descrição para o
`bulletin` no staging, aplica uma vez à mão e a guarda num repositório.

## Um arquivo

Crie uma pasta para o repositório com `mkdir -p ~/fleet/staging && cd ~/fleet`, e salve isto como
`~/fleet/staging/bulletin.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: staging
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bulletin
  namespace: staging
spec:
  replicas: 2
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
        image: localhost:5001/bulletin:1.0
        env:
        - name: MESSAGE
          value: Staging is open for testing.
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /
            port: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: bulletin
  namespace: staging
spec:
  type: NodePort
  selector:
    app: bulletin
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
```

Três objetos, na ordem em que precisam existir: o namespace, duas cópias da aplicação e um service
ao qual a porta 30080 do cluster leva. O curso `kubernetes` explica cada tipo. O que importa aqui é
que **nada no arquivo diz como sair do cluster como ele está e chegar ao cluster como descrito**. Ele
não diz "crie", nem "se existir, atualize". Ele diz o que deve ser verdade.

## Aplicado uma vez, à mão

```
ana@laptop:~/fleet$ kubectl apply -f staging/
namespace/staging created
deployment.apps/bulletin created
service/bulletin created
ana@laptop:~/fleet$ kubectl -n staging get pods
NAME                        READY   STATUS    RESTARTS   AGE
bulletin-59bd8fffb5-296kl   1/1     Running   0          1s
bulletin-59bd8fffb5-x2g4w   1/1     Running   0          1s
ana@laptop:~/fleet$ curl -s localhost:8080
```

O `curl localhost:8080` chegou a um dos dois pods pelo mapeamento de porta do arquivo do cluster, e
a página diz o que o manifesto disse: versão `1.0` e a mensagem do staging.

## Para dentro do Git

O arquivo já é o estado desejado. Pô-lo no Git o torna **versionado**: cada mudança ganha um autor,
uma data, uma mensagem e um caminho de volta. Um repositório remoto o torna **compartilhado**, para
que algo além do seu terminal consiga lê-lo. A aula 2 roda um servidor Git para isso; até lá, um
repositório bare no mesmo disco faz o papel do remoto. Se o Git nunca foi configurado nesta máquina,
dê a ele primeiro o seu nome e endereço, e faça de `main` o primeiro branch de todo repositório novo,
que é como este curso o chama:

```sh
git config --global user.name "Ana Lima"
git config --global user.email ana@example.org
git config --global init.defaultBranch main
```

Depois, o repositório, o remoto dele e o primeiro commit:

```
ana@laptop:~$ git init --quiet --bare ~/fleet.git
ana@laptop:~/fleet$ git init --quiet
ana@laptop:~/fleet$ git add staging/bulletin.yaml
ana@laptop:~/fleet$ git commit --quiet -m "staging: bulletin 1.0"
ana@laptop:~/fleet$ git remote add origin ~/fleet.git
ana@laptop:~/fleet$ git push --quiet -u origin main
ana@laptop:~/fleet$ git log --oneline
ab88607 staging: bulletin 1.0
```

`git init --bare` cria um repositório sem arquivos de trabalho, que é o que um servidor guarda. O
`~/fleet` envia para ele exatamente como enviaria para um servidor, e tudo o que clonar o
`~/fleet.git` recebe o mesmo histórico. O hash `ab88607` só será igual na sua máquina se o seu nome,
o seu endereço e a data do commit forem os mesmos da Ana, então espere um diferente.

Agora existe uma descrição do staging, e ela vive num lugar que guarda todas as versões dela. O que
falta é a parte que faz o cluster segui-la, e a próxima seção escreve uma.
