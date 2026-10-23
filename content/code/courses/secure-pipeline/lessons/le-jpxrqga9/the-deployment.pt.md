---
title: O Deployment do linkbox, campo por campo
version: 1
---

As recusas da seção anterior listaram o que o perfil restricted quer. **Cada campo que ele pediu é uma
das flags da aula 9 com outro nome**, e o manifesto abaixo define todos, mais os dois lugares graváveis
de que o linkbox precisa e um limite de memória. A aula 25 de `kubernetes` passou pelo security
context num serviço próprio; aqui cada campo está ligado à execução que mostrou por que ele está ali.

### O token, que não está no repositório

O linkbox lê o token de administração de `LINKBOX_TOKEN`, desde a aula 6. No cluster ele vem de um
Secret, e o Secret é criado por um comando, a partir de bytes aleatórios, e nunca escrito num
arquivo:

```
ana@vm:~/linkbox$ kubectl create secret generic linkbox -n linkbox --from-literal=token="$(head -c 18 /dev/urandom | base64)"
secret/linkbox created
```

**Nada em `k8s/` contém o token**, só o nome do Secret. O arquivo pode ser commitado, revisado e
examinado pelo gitleaks da aula 6 sem nada a achar. O Secret mora no armazenamento do próprio
cluster, codificado em base64 e não cifrado, a menos que o cluster seja configurado para cifrá-lo em
repouso, e as regras de acesso da aula 23 de `kubernetes` o protegem; a aula 17 troca um token de
longa duração como este por um emitido a cada necessidade.

### O manifesto

Salve como `k8s/linkbox.yaml`:

```schooling-example
{"language": "yaml", "file": "k8s/linkbox.yaml", "parts": [{"code": "# linkbox in its own namespace, which Pod Security Admission holds to the\n# restricted profile: a pod that could run as root, escalate or keep a\n# capability is refused before it is scheduled.\napiVersion: v1\nkind: Namespace\nmetadata:\n  name: linkbox\n  labels:\n    pod-security.kubernetes.io/enforce: restricted\n    pod-security.kubernetes.io/enforce-version: latest", "note": "O namespace carrega a própria regra. `enforce: restricted` faz o Pod Security Admission recusar aqui qualquer pod que quebre o perfil restricted; `enforce-version: latest` julga pelo perfil da versão do próprio Kubernetes do cluster."}, {"code": "---\napiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: linkbox\n  namespace: linkbox\nspec:\n  replicas: 1\n  selector:\n    matchLabels:\n      app: linkbox\n  template:\n    metadata:\n      labels:\n        app: linkbox\n    spec:", "note": "O Deployment: uma réplica do linkbox, achada pelo rótulo."}, {"code": "      automountServiceAccountToken: false", "note": "Nenhum token da API do Kubernetes é montado no pod. O linkbox nunca fala com a API, então um token ali seria só algo para roubar; a aula 23 de `kubernetes` trata do que um token desses consegue fazer."}, {"code": "      securityContext:\n        runAsNonRoot: true\n        seccompProfile:\n          type: RuntimeDefault", "note": "Configurações do pod inteiro. `runAsNonRoot` faz o kubelet se recusar a iniciar um contêiner cujo usuário seja 0, a checagem que a aula 9 disse que o `USER` de uma imagem não consegue fazer. `RuntimeDefault` é o filtro seccomp padrão do runtime de contêiner, o que a aula 9 viu recusar uma chamada, nomeado explicitamente porque o perfil restricted exige."}, {"code": "      containers:\n        - name: linkbox\n          image: localhost:5000/linkbox:main", "note": "A imagem que o pipeline enviou, pelo nome que a regra de admissão desta aula confere."}, {"code": "          ports:\n            - containerPort: 8000\n          env:\n            - name: LINKBOX_TOKEN\n              valueFrom:\n                secretKeyRef:\n                  name: linkbox\n                  key: token", "note": "O token vem de um Secret chamado `linkbox`, criado com `kubectl` e nunca escrito no repositório."}, {"code": "          securityContext:\n            allowPrivilegeEscalation: false\n            readOnlyRootFilesystem: true\n            capabilities:\n              drop: [\"ALL\"]", "note": "As flags da aula 9, como campos. `allowPrivilegeEscalation: false` liga o `no_new_privs`; o sistema de arquivos é somente leitura; toda capability é removida."}, {"code": "          resources:\n            requests:\n              cpu: 50m\n              memory: 64Mi\n            limits:\n              memory: 128Mi", "note": "Um request é o que o scheduler reserva; um limit é o teto. 128Mi é cerca de três vezes os 39 MiB que a aula 9 mediu. Não há limite de CPU: um limite baixo demais aparece como latência e não como erro, como a aula 19 de `kubernetes` mediu."}, {"code": "          volumeMounts:\n            - name: tmp\n              mountPath: /tmp\n            - name: data\n              mountPath: /data\n      volumes:\n        - name: tmp\n          emptyDir: {}\n        - name: data\n          emptyDir: {}", "note": "Os dois lugares graváveis, como volumes `emptyDir`: os dois `tmpfs` da aula 9, aqui no disco do nó e apagados junto com o pod."}, {"code": "---\napiVersion: v1\nkind: Service\nmetadata:\n  name: linkbox\n  namespace: linkbox\nspec:\n  selector:\n    app: linkbox\n  ports:\n    - port: 80\n      targetPort: 8000", "note": "O Service dá aos pods um endereço estável dentro do cluster, porta 80 para a 8000 do contêiner."}]}
```

Duas escolhas merecem uma frase a mais que uma nota. **O namespace está no mesmo arquivo que o
Deployment**, com o rótulo do Pod Security, então a regra viaja com a aplicação e um cluster novo
ganha os dois com um `kubectl apply`. E **o `runAsNonRoot` é conferido contra a imagem**: o kubelet lê
o `USER` numérico que a imagem declara, 65532 aqui, e se recusa a iniciar um contêiner cujo usuário
seja 0. Uma imagem que nomeasse o usuário por nome em vez de número também seria recusada, porque o
kubelet não consegue saber por um nome se é root.

### Aplique

```
ana@vm:~/linkbox$ kubectl apply -f k8s/linkbox.yaml
Warning: resource namespaces/linkbox is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
namespace/linkbox configured
deployment.apps/linkbox created
service/linkbox created
ana@vm:~/linkbox$ kubectl rollout status deployment/linkbox -n linkbox --timeout=120s
Waiting for deployment "linkbox" rollout to finish: 0 of 1 updated replicas are available...
deployment "linkbox" successfully rolled out
ana@vm:~/linkbox$ kubectl get pods -n linkbox
NAME                       READY   STATUS    RESTARTS   AGE
linkbox-56f7558485-dtb2v   1/1     Running   0          4s
```

**Um pod, rodando.** O aviso acima dele é sobre o namespace, que a seção anterior criou com
`kubectl create` e não a partir deste arquivo: o `kubectl apply` guarda uma nota do que aplicou por
último em cada objeto que gerencia, não achou nenhuma no namespace e a acrescentou. Daqui em diante o
arquivo é a fonte do namespace, rótulos incluídos. Pergunte ao processo o que ele tem, com a mesma
linha de Python da aula 9:

```
ana@vm:~/linkbox$ status='import re; print("".join(l for l in open("/proc/1/status") if re.match("(Uid|Cap|NoNewPrivs|Seccomp)", l)), end="")'
ana@vm:~/linkbox$ kubectl exec -n linkbox deployment/linkbox -- python3 -c "$status"
Uid:	65532	65532	65532	65532
CapInh:	0000000000000000
CapPrm:	0000000000000000
CapEff:	0000000000000000
CapBnd:	0000000000000000
CapAmb:	0000000000000000
NoNewPrivs:	1
Seccomp:	2
Seccomp_filters:	1
ana@vm:~/linkbox$ kubectl exec -n linkbox deployment/linkbox -- python3 -c "print(open('/proc/mounts').read(), end='')" | grep -E ' (/|/tmp|/data) ' | sed -E 's/,(lower|upper|work)dir=[^, ]*//g'
overlay / overlay ro,relatime,uuid=on 0 0
/dev/vda /tmp ext4 rw,relatime,discard,no_prefetch_block_bitmaps,resv_strict,resuid=65534,resgid=65534 0 0
/dev/vda /data ext4 rw,relatime,discard,no_prefetch_block_bitmaps,resv_strict,resuid=65534,resgid=65534 0 0
```

**O mesmo status do contêiner de staging da aula 9**: usuário 65532, conjunto limite vazio,
`NoNewPrivs` 1, seccomp filtrando. A tabela de montagens mostra a raiz somente leitura e os dois
volumes graváveis, como diretórios no próprio disco do nó, e por isso aparecem como `/dev/vda`. Uma diferença em relação ao Docker: um `emptyDir` mora no disco do nó, e não em
memória, a menos que seja declarado com `medium: Memory`, e não leva a opção `noexec` que o `tmpfs`
do Docker tinha.

### E ele responde

O Service é alcançável de dentro do cluster. O `kubectl port-forward` empresta a ele uma porta da sua
máquina enquanto estiver rodando:

```
ana@vm:~/linkbox$ token=$(kubectl get secret linkbox -n linkbox -o jsonpath='{.data.token}' | base64 -d)
ana@vm:~/linkbox$ curl -s -X POST -H "X-Token: $token" -d url=https://example.org/handbook http://127.0.0.1:8080/links
{"code":"PhiNBQ"}
ana@vm:~/linkbox$ curl -s -o /dev/null -w "%{http_code}\n" -X POST -d url=https://example.org/handbook http://127.0.0.1:8080/links
401
```

**201 com o token do Secret, 401 sem ele.** A aplicação se comporta exatamente como na rede de
staging da aula 4; só mudou o jeito de iniciá-la, e toda restrição da aula 9 veio junto.

Os dados, porém, estão num `emptyDir`, e vão embora quando o pod vai. Isso é honesto para um cluster
de estudo e errado para produção, onde `/data` seria um PersistentVolumeClaim; e SQLite num volume
quer dizer uma réplica só, e é por isso que o Deployment diz `replicas: 1`.
