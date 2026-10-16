---
title: "EKS Pod Identity: o mesmo resultado, sem o provedor"
version: 1
---

O IRSA funciona, e tem um custo contínuo que aparece quando há vários clusters. **Cada cluster
precisa do seu próprio provedor OIDC do IAM, e todo role que uma carga de trabalho usa em vários
clusters precisa de uma declaração de confiança por cluster.** Leve o redimensionador para um
cluster novo durante uma atualização e alguém precisa editar antes a política de confiança do role
dele. Uma política de confiança também tem tamanho limitado, 2.048 caracteres por padrão, então um
role compartilhado por muitos clusters fica sem espaço. O **EKS Pod Identity**, que a AWS lançou no
fim de 2023, mantém o resultado e muda o lugar da decisão: o role confia num serviço da AWS, e a
ligação entre uma service account e um role vira um registro no EKS chamado **associação**.

## Um role que confia no EKS, uma vez só

Aqui está a política de confiança inteira de um role do Pod Identity. Compare com o `trust.json` de
duas seções atrás; o que falta é justamente o ponto:

```schooling-example
{"language": "json", "file": "pod-trust.json", "parts": [{"code": "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Effect\": \"Allow\",\n      \"Principal\": {\n        \"Service\": \"pods.eks.amazonaws.com\"\n      },\n", "note": "**O principal é um serviço, não um emissor.** O mesmo arquivo serve a todos os clusters da conta, então um cluster novo não exige mudança aqui, nem provedor OIDC nenhum."}, {"code": "      \"Action\": [\n        \"sts:AssumeRole\",\n        \"sts:TagSession\"\n      ]\n    }\n  ]\n}\n", "note": "`sts:TagSession` deixa o EKS marcar cada sessão com o cluster, o namespace e a service account a que ela se destina. Não há condição nomeando uma service account: essa escolha passou para a associação."}]}
```

Salve como `~/aws/pod-trust.json`, sem as notas, e crie o role. Depois peça ao EKS que o associe à
service account, que é a chamada que substitui tanto o provedor OIDC quanto a anotação:

```
ana@laptop:~/aws$ aws iam create-role --role-name photos-pod-identity --assume-role-policy-document file://pod-trust.json --query Role.Arn
"arn:aws:iam::123456789012:role/photos-pod-identity"
ana@laptop:~/aws$ aws eks create-pod-identity-association --cluster-name shop --namespace shop --service-account photos --role-arn arn:aws:iam::123456789012:role/photos-pod-identity

aws: [ERROR]: An error occurred (404) when calling the CreatePodIdentityAssociation operation: <!doctype html>
<html lang=en>
<title>404 Not Found</title>
<h1>Not Found</h1>
<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try again.</p>
```

**O role é do moto, e o 404 também: o moto 5.2.3 não implementa associações do Pod Identity.** A
página HTML é o framework web dele dizendo que não tem rota para o pedido, e na AWS o mesmo comando
devolve a associação, com um id. O que vem a seguir vem da documentação da AWS e não foi executado
contra o EKS. Uma associação nomeia quatro coisas: o cluster, o namespace, a service account e o
role. Não há nada a anotar no Kubernetes nem nada a criar no IAM por cluster; um cluster novo usa o
mesmo role com mais uma associação.

## O agente em todo nó

A outra metade mora nos nós. O Pod Identity precisa do **EKS Pod Identity Agent**, um add-on do EKS
que roda como DaemonSet, um pod por nó na própria rede do nó, escutando em `169.254.170.23`, porta
80. Quando um pod com uma service account associada é criado, o EKS acrescenta duas variáveis aos
contêineres dele, e elas apontam o SDK para outro lugar:

- **`AWS_CONTAINER_CREDENTIALS_FULL_URI`**, `http://169.254.170.23/v1/credentials`, o agente;
- **`AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE`**, um token de service account para a audiência
  `pods.eks.amazonaws.com`, projetado no pod como o do IRSA.

O SDK envia um GET para esse endereço com o token no cabeçalho `Authorization`. O agente repassa o
token para a API EKS Auth, `AssumeRoleForPodIdentity`, que o confere e devolve credenciais do role
associado, e o agente as entrega de volta. É o mesmo mecanismo de credenciais de contêiner que o ECS
usa há muito tempo para dar à task o seu role, e por isso todo SDK atual já o entende.

Dá para assistir a essa conversa no seu laptop, com um substituto do agente pequeno o bastante para
ler. Salve como `~/aws/agent.py`:

```schooling-example
{"language": "python", "file": "agent.py", "parts": [{"code": "import base64\nimport json\nfrom http.server import BaseHTTPRequestHandler, HTTPServer\n\nimport boto3\n\nROLE = 'arn:aws:iam::123456789012:role/photos-pod-identity'\nsts = boto3.client('sts')\n\n\n", "note": "Um substituto do agente, pequeno o bastante para ler. O `boto3` veio com o moto para o ambiente virtual, e encontra o moto pelo mesmo `AWS_ENDPOINT_URL` que a linha de comando."}, {"code": "def claims(token):\n    payload = token.split('.')[1]\n    return json.loads(base64.urlsafe_b64decode(payload + '=='))\n\n\n", "note": "Ele lê a parte do meio do token para imprimir a quem o token se destina. **Não verifica nada.** O agente de verdade nunca decodifica o token por conta própria: ele o envia para a API EKS Auth, que confere a assinatura."}, {"code": "class Agent(BaseHTTPRequestHandler):\n    def do_GET(self):\n        who = claims(self.headers['Authorization'])\n        print('token for', who['sub'], 'audience', who['aud'][0], flush=True)\n        c = sts.assume_role(RoleArn=ROLE, RoleSessionName='photos-pod')['Credentials']\n", "note": "O SDK dentro do pod envia o token no cabeçalho `Authorization` de um GET simples. O substituto então assume o role, que é o passo que o agente real pede ao EKS que faça por ele."}, {"code": "        body = json.dumps({\n            'AccessKeyId': c['AccessKeyId'],\n            'SecretAccessKey': c['SecretAccessKey'],\n            'Token': c['SessionToken'],\n            'Expiration': c['Expiration'].isoformat(),\n        })\n        self.send_response(200)\n        self.send_header('Content-Type', 'application/json')\n        self.end_headers()\n        self.wfile.write(body.encode())\n\n    def log_message(self, *args):\n        pass\n\n\n", "note": "A resposta é o JSON que todo SDK da AWS espera de um endpoint de credenciais de contêiner: as três partes de uma credencial temporária e quando ela expira. `log_message` só silencia a linha que o servidor imprimiria a cada pedido."}, {"code": "HTTPServer(('127.0.0.1', 8099), Agent).serve_forever()\n", "note": "O agente real escuta em `169.254.170.23`, porta 80, em todo nó. O substituto usa um endereço de loopback, que o SDK também aceita, e uma porta que ninguém mais quer."}]}
```

Rode-o num **segundo terminal**, depois das linhas com que todo terminal novo começa, como `python3
agent.py`; ele não imprime nada até alguém pedir. Depois, no terminal de trabalho, escreva um token
para a audiência do agente, defina as duas variáveis como o EKS faria, e tire as chaves de novo:

```
ana@laptop:~/aws$ python3 mktoken.py "$ISSUER" pods.eks.amazonaws.com > pod-token
ana@laptop:~/aws$ export AWS_CONTAINER_CREDENTIALS_FULL_URI=http://127.0.0.1:8099/v1/credentials
ana@laptop:~/aws$ export AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE=~/aws/pod-token
ana@laptop:~/aws$ unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "AROARZPUZDIKDGV27IZWU:photos-pod",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/photos-pod-identity/photos-pod"
}
```

E no terminal do agente:

```
token for system:serviceaccount:shop:photos audience pods.eks.amazonaws.com
```

A linha de comando não achou chaves nem variáveis de identidade web, viu as variáveis de contêiner,
perguntou ao endereço que elas indicavam e assinou a sua chamada com o que voltou. **A aplicação
nunca soube qual dos dois mecanismos lhe deu um role**, e é por isso que mudar uma carga de trabalho
do IRSA para o Pod Identity não exige mudança no código. O substituto decodifica o token só para
imprimi-lo; o agente de verdade nunca confia no conteúdo dele, e deixa a API EKS Auth conferir a
assinatura. Pare-o com Ctrl+C, e no terminal de trabalho remova as duas variáveis e exporte de novo
as chaves de teste.

## O que cada um dá a você

O Pod Identity também marca cada sessão que cria com a sua origem: `eks-cluster-name`,
`kubernetes-namespace`, `kubernetes-service-account`, `kubernetes-pod-name` e mais algumas. Uma
política de permissão pode testar essas tags, então um role pode deixar cada namespace ler só o seu
próprio prefixo de um bucket. O IRSA não tem nada comparável sem escrever um role por namespace.

| | IRSA | EKS Pod Identity |
| --- | --- | --- |
| a política de confiança nomeia | o emissor OIDC do cluster e uma service account | o serviço `pods.eks.amazonaws.com` |
| a cada cluster novo | um provedor OIDC, e uma declaração de confiança em cada role | uma associação por service account |
| ligação com a service account | uma anotação no Kubernetes | uma associação no EKS |
| no nó | nada | o add-on Pod Identity Agent |
| tags de sessão | nenhuma | cluster, namespace, service account, pod |
| funciona no Fargate | sim | não |

A última linha decide alguns clusters sozinha. **Pods no Fargate não podem usar o Pod Identity**,
porque não existe nó seu onde rodar o agente, então os perfis Fargate da aula 12 continuam com o
IRSA. O Pod Identity também precisa de um SDK recente o bastante para conhecer as variáveis de
credenciais de contêiner, o que pesa numa imagem antiga que ninguém reconstrói. Os dois chegam ao
mesmo lugar: um role por carga de trabalho, credenciais que expiram, nada guardado. E os dois ainda
dependem do limite de saltos da aula 7 para manter os pods longe do role do próprio nó, porque
nenhum deles impede que um pod capaz de alcançar o serviço de metadados da instância peça a ele.
