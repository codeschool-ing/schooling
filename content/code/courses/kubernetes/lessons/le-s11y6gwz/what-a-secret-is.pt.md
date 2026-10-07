---
title: O que é um Secret, e o que o base64 não é
version: 1
---

**A crença mais comum sobre Secrets é que os valores são criptografados, porque parecem embaralhados.**
Eles são codificados. O base64 escreve quaisquer bytes usando 64 caracteres imprimíveis, para que uma
chave binária ou uma senha com caracteres estranhos caibam num campo JSON ou YAML; ele não tem chave e
não esconde nada. A senha usada aqui é inventada para esta aula e não abre nada:

```
ana@laptop:~/shop$ kubectl create secret generic db --from-literal=user=shop --from-literal=password=lab-only-7Hq2
secret/db created
ana@laptop:~/shop$ kubectl get secret db
NAME   TYPE     DATA   AGE
db     Opaque   2      0s
ana@laptop:~/shop$ kubectl get secret db -o jsonpath="{.data}"; echo
{"password":"bGFiLW9ubHktN0hxMg==","user":"c2hvcA=="}
ana@laptop:~/shop$ kubectl get secret db -o jsonpath="{.data.password}" | base64 -d; echo
lab-only-7Hq2
```

`bGFiLW9ubHktN0hxMg==` é a senha, e o `base64 -d` a devolve sem chave nenhuma. **Quem consegue ler o
objeto consegue ler o valor**, então a proteção de um Secret nunca é a codificação. O que um Secret
compra é tudo o que fica em volta do valor: o Kubernetes sabe que ele é sensível, então ele pode ser
criptografado onde é guardado, mantido fora do `kubectl describe`, montado na memória em vez do disco
e ter regras de acesso próprias.

## Para dentro de um pod

Os dois caminhos de entrada são os mesmos de um ConfigMap:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: reader
spec:
  containers:
  - name: reader
    image: busybox:1.37
    command: ["sh", "-c", "sleep 3600"]
    env:
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: db
          key: user
    volumeMounts:
    - name: db
      mountPath: /run/secrets/db
      readOnly: true
  volumes:
  - name: db
    secret:
      secretName: db
      defaultMode: 0400
```

```
ana@laptop:~/shop$ kubectl apply -f shop.yaml
pod/reader created
ana@laptop:~/shop$ kubectl exec reader -- sh -c 'echo user is $DB_USER; ls -l /run/secrets/db/; mount | grep secrets/db'
user is shop
total 0
lrwxrwxrwx    1 root     root            15 Oct  6 17:15 password -> ..data/password
lrwxrwxrwx    1 root     root            11 Oct  6 17:15 user -> ..data/user
tmpfs on /run/secrets/db type tmpfs (ro,relatime,size=16480968k,noswap)
```

A variável está lá, e o volume mostra um arquivo por chave. Dois detalhes são diferentes de um
ConfigMap, e os dois são de propósito. **O volume é um `tmpfs`**, na memória do nó, então a senha nunca
é escrita no disco do nó. E `defaultMode: 0400` deixa os arquivos legíveis só pelo dono; a listagem
mostra os links, e os arquivos por trás de `..data` têm esse modo.

**Prefira o arquivo à variável para tudo o que importa.** Uma variável de ambiente vaza fácil por
acidente: é impressa por um relatório de falha que despeja o ambiente, herdada por todo processo filho
e legível em `/proc` por qualquer coisa que rode como o mesmo usuário. Um arquivo num `tmpfs` é lido
quando o programa decide lê-lo, e em nenhum outro lugar.
