---
title: Quem está perguntando
version: 1
---

O API server trata toda requisição na mesma ordem. **Primeiro ele autentica: descobre quem mandou a
requisição. Depois ele autoriza: decide se essa identidade pode fazer essa coisa em particular.** Uma
requisição que falha no primeiro passo é um 401; uma que passa por ele e falha no segundo é um 403. O
RBAC, controle de acesso baseado em papéis, é o segundo passo, e é o assunto desta lição.

Comece pela identidade que você vem usando desde o início:

```
ana@laptop:~/shop$ kubectl auth whoami
ATTRIBUTE                                           VALUE
Username                                            kubernetes-admin
Groups                                              [kubeadm:cluster-admins system:authenticated]
Extra: authentication.kubernetes.io/credential-id   [X509SHA256=ef21c7d51d53537947c3ffce2489c735a4e8bb5a66a20f081dae87b6e3f324a0]
ana@laptop:~/shop$ kubectl get clusterrolebinding kubeadm:cluster-admins -o custom-columns=ROLE:.roleRef.name,SUBJECT:.subjects[0].name
ROLE            SUBJECT
cluster-admin   kubeadm:cluster-admins
```

`kubectl auth whoami` pergunta ao API server o que ele concluiu sobre você. A resposta veio do
certificado de cliente no seu kubeconfig: o usuário `kubernetes-admin`, no grupo
`kubeadm:cluster-admins`. **Não existe objeto de usuário por trás desse nome.** O Kubernetes não guarda
pessoas. Uma pessoa é o nome que um certificado ou o token de um provedor de identidade carrega, e o
RBAC concede coisas a esses nomes. O segundo comando mostra a concessão que fez todas as lições
anteriores funcionarem: um ClusterRoleBinding que dá ao grupo a ClusterRole `cluster-admin`, que pode
fazer qualquer coisa, em qualquer lugar.

## Uma identidade para um programa

Programas recebem outro tipo de identidade, e esta É um objeto. Uma **ServiceAccount** vive num
namespace, e o API server emite tokens para ela. Um pipeline de deploy é o caso clássico: ele precisa
mudar Deployments num namespace e nada mais.

```
ana@laptop:~/shop$ kubectl create namespace shop
namespace/shop created
ana@laptop:~/shop$ kubectl create serviceaccount deployer -n shop
serviceaccount/deployer created
ana@laptop:~/shop$ kubectl auth can-i list pods -n shop --as=system:serviceaccount:shop:deployer
no
```

`kubectl auth can-i` faz ao autorizador uma pergunta de sim ou não, e `--as` a faz em nome de outra
identidade. A conta nova não pode nem listar pods. **Nada foi negado explicitamente; nada foi
concedido, e o RBAC não tem outro padrão.**

Para ver a recusa do jeito que um pipeline a veria, o próximo comando pede um token e chama a API
direto com `curl`. Antes da captura, o certificado da CA do cluster e o endereço do API server foram
salvos em `ca.crt` e `server.txt`, que é como o `curl` confere que está falando com o servidor de
verdade.

```
ana@laptop:~/shop$ TOKEN=$(kubectl create token deployer -n shop --duration=10m); curl -s --cacert ca.crt -H "Authorization: Bearer $TOKEN" $(cat server.txt)/api/v1/namespaces/shop/pods | head -n 8
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "pods is forbidden: User \"system:serviceaccount:shop:deployer\" cannot list resource \"pods\" in API group \"\" in the namespace \"shop\"",
  "reason": "Forbidden",
  "details": {
```

**A autenticação funcionou**: a mensagem cita `system:serviceaccount:shop:deployer`, que é como uma
ServiceAccount aparece para o RBAC, como `system:serviceaccount:<namespace>:<nome>`. A recusa veio do
segundo passo, e diz exatamente o que faltou: o verbo `list`, o recurso `pods`, o grupo de API `""`, o
namespace `shop`. Esses quatro são a forma que toda regra de RBAC tem.

O token de `kubectl create token` dura dez minutos aqui, porque `--duration=10m` pediu isso. Uma vida
curta é o ponto: um token que vaza no log de um pipeline vale muito pouco dez minutos depois.
