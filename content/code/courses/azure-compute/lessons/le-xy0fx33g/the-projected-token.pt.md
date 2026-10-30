---
title: O token projetado, que o Kubernetes já dá a um pod
version: 1
---

**O Kubernetes já consegue provar quem um pod é.** O API server dele assina tokens para service
accounts. Um volume projetado de token de service account pede ao kubelet um token com o público e
a duração que você escolher, o escreve num arquivo dentro do pod e o substitui antes que ele vença.
A workload identity é construída sobre esse arquivo. O pod recebe um token cujo público é
`api://AzureADTokenExchange`, quatro variáveis de ambiente que dizem onde está o token e para qual
identidade ele serve, e nada mais do Azure. Esta seção faz esse token no kind e lê o que há nele.

A imagem que as pessoas costumam trazer é a de que o AKS entrega ao pod uma credencial do Azure, ou
de que o webhook enfia um segredo nele. **Nenhuma das duas coisas acontece.** O que o pod tem é um
token do Kubernetes, assinado pelo cluster, que não vale nada no Azure até que o Entra ID o aceite
na troca do fim desta lição.

## O que você escreve, e o que o webhook acrescenta

Num cluster AKS com a workload identity ligada, você escreve duas coisas. A service account leva a
anotação `azure.workload.identity/client-id`, o client id da identidade gerenciada que o pod deve
assumir. O pod leva o rótulo `azure.workload.identity/use: "true"`. O AKS roda um **mutating
admission webhook**, um programa que o API server consulta enquanto um pod está sendo criado.
Quando ele vê um pod com esse rótulo, acrescenta o resto:

- **`AZURE_CLIENT_ID`**, copiado da anotação;
- **`AZURE_TENANT_ID`**, da anotação `azure.workload.identity/tenant-id` se a service account tiver
  uma, e do próprio tenant do cluster se não tiver;
- **`AZURE_AUTHORITY_HOST`**, o endereço do endpoint de entrada do Entra ID;
- **`AZURE_FEDERATED_TOKEN_FILE`**, o caminho do token;
- **um volume projetado** com um token de service account para o público
  `api://AzureADTokenExchange`, montado nesse caminho. Ele dura 3.600 segundos, a não ser que a
  anotação `azure.workload.identity/service-account-token-expiration` peça mais, até 86.400.

**Só um pod com o rótulo é tocado.** A documentação da Microsoft chama o rótulo de obrigatório: um
pod sem ele não é alterado, mesmo que a sua service account tenha a anotação. E o webhook age quando
um pod é criado, então mudar a anotação não faz nada a um pod que já está rodando até ele ser
reiniciado.

## O laboratório: kind, com o trabalho do webhook feito à mão

**O kind não roda webhook nenhum desses**, então o laboratório escreve à mão o que o webhook
acrescentaria, e depois lê o token que o Kubernetes produz para ele. Esse token é de verdade,
assinado pela chave do próprio cluster. O cluster tem a forma da lição 11 com um worker só, que é
tudo de que esta lição precisa. Salve como `cluster.yaml`:

```yaml
# cluster.yaml: one control plane and one worker
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri"]
    restrict_oom_score_adj = true
kubeadmConfigPatches:
- |
  kind: KubeletConfiguration
  failCgroupV1: false
nodes:
- role: control-plane
- role: worker
```

Os dois patches são necessários numa máquina com cgroup v1, como a lição 11 explicou; no cgroup v2,
que é o de toda distribuição atual e do Docker Desktop, eles não fazem mal. Crie o cluster e dê aos
nodes a imagem da loja da lição 7:

```
ana@laptop:~/azure$ kind create cluster --name shop --config cluster.yaml --quiet
ana@laptop:~/azure$ kubectl wait --for=condition=Ready nodes --all --timeout=120s
node/shop-control-plane condition met
node/shop-worker condition met
ana@laptop:~/azure$ kind load docker-image shop:1.0 --name shop
Image: "shop:1.0" with ID "sha256:ccce3de6a33ead4655a393bc31514eefb0e039d69d7ce27b8f1d9a0cbd6b019e" not yet present on node "shop-worker", loading...
Image: "shop:1.0" with ID "sha256:ccce3de6a33ead4655a393bc31514eefb0e039d69d7ce27b8f1d9a0cbd6b019e" not yet present on node "shop-control-plane", loading...
```

Agora o namespace, a service account e o pod. Salve isto como `orders.yaml`. Tudo de `env:` para
baixo é o que o webhook teria escrito, e os dois ids são os marcadores que a documentação da
Microsoft usa:

```yaml
# orders.yaml: the service account, and a pod with what the webhook would add
apiVersion: v1
kind: Namespace
metadata:
  name: shop
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: orders
  namespace: shop
  annotations:
    azure.workload.identity/client-id: 11112222-bbbb-3333-cccc-4444dddd5555
---
apiVersion: v1
kind: Pod
metadata:
  name: shop
  namespace: shop
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: orders
  containers:
  - name: shop
    image: shop:1.0
    imagePullPolicy: IfNotPresent
    env:
    - name: AZURE_CLIENT_ID
      value: 11112222-bbbb-3333-cccc-4444dddd5555
    - name: AZURE_TENANT_ID
      value: aaaabbbb-0000-cccc-1111-dddd2222eeee
    - name: AZURE_AUTHORITY_HOST
      value: https://login.microsoftonline.com/
    - name: AZURE_FEDERATED_TOKEN_FILE
      value: /var/run/secrets/azure/tokens/azure-identity-token
    volumeMounts:
    - name: azure-identity-token
      mountPath: /var/run/secrets/azure/tokens
      readOnly: true
  volumes:
  - name: azure-identity-token
    projected:
      sources:
      - serviceAccountToken:
          path: azure-identity-token
          audience: api://AzureADTokenExchange
          expirationSeconds: 3600
```

O caminho é o que a documentação da Microsoft dá como exemplo, e a mesma documentação adverte contra
escrevê-lo num aplicativo: quem o escolhe é o webhook, e ele pode mudar. Um programa que precisa do
token lê `AZURE_FEDERATED_TOKEN_FILE` e abre o caminho que ela indicar. Aplique o arquivo, espere o
pod, e liste o que há no ambiente dele:

```
ana@laptop:~/azure$ kubectl apply -f orders.yaml
namespace/shop created
serviceaccount/orders created
pod/shop created
ana@laptop:~/azure$ kubectl wait -n shop --for=condition=Ready pod/shop --timeout=120s
pod/shop condition met
ana@laptop:~/azure$ kubectl exec -n shop shop -- env | grep ^AZURE_ | sort
AZURE_AUTHORITY_HOST=https://login.microsoftonline.com/
AZURE_CLIENT_ID=11112222-bbbb-3333-cccc-4444dddd5555
AZURE_FEDERATED_TOKEN_FILE=/var/run/secrets/azure/tokens/azure-identity-token
AZURE_TENANT_ID=aaaabbbb-0000-cccc-1111-dddd2222eeee
ana@laptop:~/azure$ kubectl get mutatingwebhookconfigurations
No resources found
```

As quatro variáveis estão no contêiner, e o último comando mostra quem as pôs lá: ninguém. **No
kind, o rótulo e a anotação não são lidos por nada**: o cluster não tem mutating webhook nenhum, e
um mutating webhook é exatamente o que o AKS instala para fazer esse trabalho.

## Lendo o token

Leia o token como um programa no pod deve ler, pela variável, e guarde uma cópia no laptop:

```
ana@laptop:~/azure$ kubectl exec -n shop shop -- sh -c 'cat "$AZURE_FEDERATED_TOKEN_FILE"' > token
ana@laptop:~/azure$ wc -c token
1085 token
```

Um token como este é um JSON Web Token: três partes separadas por pontos, as duas primeiras JSON
codificado em base64url, a terceira uma assinatura. Este programa imprime as duas primeiras e deixa
a terceira em paz. Salve como `~/azure/decode.py`:

```schooling-example
{"language": "python", "file": "decode.py", "parts": [{"code": "# decode.py: the header and claims of a token, WITHOUT checking its signature\nimport base64\nimport json\nimport sys\nfrom datetime import datetime, timezone\n\n\n", "note": "Só a biblioteca padrão, então roda com o Python que toda máquina deste curso tem. A primeira linha avisa a quem achar o arquivo depois que ele não confere nada."}, {"code": "def part(text):\n    return json.loads(base64.urlsafe_b64decode(text + '=' * (-len(text) % 4)))\n\n\n", "note": "**base64url, com o preenchimento de volta.** Um token descarta o preenchimento `=` que o decodificador do Python quer, então a função acrescenta quantos o comprimento pede antes de decodificar o JSON."}, {"code": "header, claims, signature = open(sys.argv[1]).read().strip().split('.')\nprint('header:', json.dumps(part(header)))\nbody = part(claims)\nprint('claims:', json.dumps(body, indent=2))\n", "note": "As três partes. O cabeçalho cita o algoritmo e a chave que assinaram o token; as claims dizem para quem ele é e até quando."}, {"code": "for name in ('iat', 'exp'):\n    print(name, datetime.fromtimestamp(body[name], timezone.utc).isoformat())\nprint('lifetime:', body['exp'] - body['iat'], 'seconds')\nprint('signature:', len(signature), 'characters, not checked')\n", "note": "`iat` e `exp` são segundos desde 1970, impressos como datas em UTC. **A assinatura é contada e não conferida**: conferi-la exige a chave pública do cluster, e a próxima seção mostra onde ela é publicada."}]}
```

Rode-o sobre a cópia:

```
ana@laptop:~/azure$ python3 decode.py token
header: {"alg": "RS256", "kid": "XRBr3pJmOiPXL-AaUkREEj_6qffoEunMXctRB_Mk3xs"}
claims: {
  "aud": [
    "api://AzureADTokenExchange"
  ],
  "exp": 1793395241,
  "iat": 1793391641,
  "iss": "https://kubernetes.default.svc.cluster.local",
  "jti": "3b5241e7-943b-47e7-a302-bfcf6f5ea867",
  "kubernetes.io": {
    "namespace": "shop",
    "node": {
      "name": "shop-worker",
      "uid": "acd5d609-1d06-4d2e-ab20-d595b16fb559"
    },
    "pod": {
      "name": "shop",
      "uid": "8af9702f-3b46-4a0e-899b-6e9f14355112"
    },
    "serviceaccount": {
      "name": "orders",
      "uid": "17ba2d40-24a0-4916-b08a-7f5629eb8281"
    }
  },
  "nbf": 1793391641,
  "sub": "system:serviceaccount:shop:orders"
}
iat 2026-10-30T20:20:41+00:00
exp 2026-10-30T21:20:41+00:00
lifetime: 3600 seconds
signature: 342 characters, not checked
```

Leia o resultado contra o pod que o produziu. `iss` é o emissor do cluster, o nome com que ele
assina; no kind é `https://kubernetes.default.svc.cluster.local`, e no AKS é uma URL pública da
próxima seção. `sub` é `system:serviceaccount:shop:orders`, o namespace e a service account, e é a
string contra a qual a confiança do lado do Azure vai ser escrita. `aud` é o público que o volume
pediu. `exp` menos `iat` dá os 3.600 segundos de `expirationSeconds`. Em `kubernetes.io` o cluster
diz mais do que o Entra ID vai olhar: o nome e o uid do pod, o node em que ele roda e o uid da service
account. Esse vínculo é o motivo de o API server deixar de aceitar o token de um pod apagado mesmo
antes de ele vencer. O cabeçalho traz `alg`, `RS256`, e um `kid`, o id da chave que o assinou.

**`decode.py` acreditou em cada palavra, e é exatamente para isso que ele nunca deve ser usado.**
Qualquer um escreve essas claims num arquivo. O que dá valor a este token é a assinatura, feita com
a chave privada do cluster, que só a chave pública do cluster confere. Conferi-la é trabalho de quem
recebe o token, o Entra ID nesta lição, e um programa que decodificasse o próprio token e confiasse
no resultado estaria confiando num bilhete que ele mesmo poderia ter escrito.

## O mesmo pod, um segundo token

O pod tem outro token, aquele que todo pod recebe para falar com o API server, no caminho em que o
Kubernetes sempre o monta. Decodifique-o também, e fique só com as linhas que diferem:

```
ana@laptop:~/azure$ kubectl exec -n shop shop -- cat /var/run/secrets/kubernetes.io/serviceaccount/token > api-token
ana@laptop:~/azure$ python3 decode.py api-token | grep -e kid -e '"aud"' -e '"https' -e '"sub"' -e warnafter -e lifetime
header: {"alg": "RS256", "kid": "XRBr3pJmOiPXL-AaUkREEj_6qffoEunMXctRB_Mk3xs"}
  "aud": [
    "https://kubernetes.default.svc.cluster.local"
  "iss": "https://kubernetes.default.svc.cluster.local",
    "warnafter": 1793395248
  "sub": "system:serviceaccount:shop:orders"
lifetime: 31536000 seconds
```

Mesmo emissor, mesmo sujeito, mesma chave de assinatura, então o mesmo cluster responde pela mesma
service account nos dois. **O que os separa é o público**: este é para o API server, o primeiro é
para o Entra ID, e quem confere o público recusa o do outro. É por isso que a confiança da próxima
seção cita um público além de um sujeito.

A duração também difere, e por um motivo que é do kind. O API server dele estende o token padrão
para um ano, para que clientes que nunca releem o arquivo continuem funcionando, e acrescenta
`warnafter`, o momento depois do qual um uso do token é registrado como velho. A documentação do AKS
diz que essa extensão fica desligada a partir do Kubernetes 1.30, então no AKS este token também
dura cerca de uma hora.

## Duração e rotação

Um token pode ser curto, mas não curto demais. Pedir diretamente ao API server um de cinco minutos,
que é o que o kubelet faz para o volume, recebe uma recusa:

```
ana@laptop:~/azure$ kubectl create token orders -n shop --audience api://AzureADTokenExchange --duration 5m
error: failed to create token: TokenRequest.authentication.k8s.io "" is invalid: spec.expirationSeconds: Invalid value: 300: may not specify a duration less than 10 minutes
```

**Dez minutos é o piso, e o kubelet mantém o arquivo fresco acima dele.** A documentação do
Kubernetes diz que ele pede um token novo quando o antigo passa de 80% da sua duração, ou de 24
horas, e o escreve por cima do arquivo. Para os 3.600 segundos acima, isso acontece cerca de 48
minutos depois de o token ser emitido; esta transcrição não esperou por isso. O que vem daí é um
dever do aplicativo e não do Kubernetes: ler o arquivo de novo cada vez que precisar de um token,
porque uma cópia guardada na memória vence no horário marcado. As bibliotecas Azure Identity fazem
isso por você.

Deixe o cluster rodando: a próxima seção pede a ele as suas chaves.
