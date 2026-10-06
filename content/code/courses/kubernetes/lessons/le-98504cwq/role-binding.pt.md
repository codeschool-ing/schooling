---
title: Uma Role diz o quê, um RoleBinding diz quem
version: 1
---

**O acesso é concedido por dois objetos, e mantê-los separados é o desenho.** Uma Role é uma lista de
regras, cada uma nomeando grupos de API, recursos e verbos. Um RoleBinding prende uma Role a um ou
mais sujeitos: usuários, grupos ou ServiceAccounts. A mesma Role pode ser ligada ao pipeline hoje e a
um segundo pipeline amanhã sem ser copiada.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployer
  namespace: shop
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: deployer
  namespace: shop
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: deployer
subjects:
- kind: ServiceAccount
  name: deployer
  namespace: shop
```

A primeira regra cobre Deployments, que vivem no grupo de API `apps`; a segunda cobre pods, que vivem
no grupo principal, escrito como a string vazia `""`. **`pods/log` é um sub-recurso e precisa ser
nomeado à parte**: permissão para ler um pod não inclui permissão para ler os logs dele. Os verbos são
os da própria API: `get` lê um objeto, `list` e `watch` leem muitos, `create`, `update` e `patch`
escrevem. Não há `delete` nesta lista, de propósito.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dentro do namespace shop, três objetos. No meio, um RoleBinding chamado deployer. Uma seta marcada subjects aponta para a esquerda, para a ServiceAccount deployer. Uma seta marcada roleRef aponta para a direita, para a Role deployer, cujas regras permitem get, list, watch, create, update e patch em deployments do grupo apps, e get, list e watch em pods e pods/log. Embaixo: tudo que nenhuma regra nomeia é recusado.\"><defs><marker id=\"rbac-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"175\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"36\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">namespace: shop</text><rect x=\"40\" y=\"80\" width=\"170\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ServiceAccount</text><text x=\"125.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">deployer</text><rect x=\"270\" y=\"80\" width=\"140\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"340.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">RoleBinding</text><text x=\"340.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">deployer</text><rect x=\"470\" y=\"56\" width=\"214\" height=\"112\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"577.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Role deployer</text><text x=\"577.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">deployments (apps):</text><text x=\"577.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">get list watch create</text><text x=\"577.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">update patch</text><text x=\"577.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pods, pods/log: get list watch</text><path d=\"M270 112 L212 112\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rbac-ah-amber)\"></path><text x=\"241\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">subjects</text><path d=\"M410 112 L468 112\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rbac-ah-amber)\"></path><text x=\"439\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">roleRef</text><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Tudo que nenhuma regra nomeia é recusado.</text></svg>", "caption": "O binding é o único objeto que conhece os dois lados. Apague-o, e a conta e a role continuam existindo, e não concedem nada."}
```

```
ana@laptop:~/shop$ kubectl apply -f deployer-role.yaml
role.rbac.authorization.k8s.io/deployer created
rolebinding.rbac.authorization.k8s.io/deployer created
ana@laptop:~/shop$ TOKEN=$(kubectl create token deployer -n shop --duration=10m); curl -s --cacert ca.crt -H "Authorization: Bearer $TOKEN" $(cat server.txt)/api/v1/namespaces/shop/pods | head -n 6
{
  "kind": "PodList",
  "apiVersion": "v1",
  "metadata": {
    "resourceVersion": "708"
  },
```

O mesmo `curl`, com um token novo, agora recebe um `PodList` de volta. O namespace está vazio, então
a lista também está; o que importa é que o API server respondeu em vez de recusar.

## Perguntar antes de depender disso

`kubectl auth can-i` é o jeito mais rápido de conferir uma concessão sem escrever um cliente:

```
ana@laptop:~/shop$ kubectl auth can-i create deployments -n shop --as=system:serviceaccount:shop:deployer
yes
ana@laptop:~/shop$ kubectl auth can-i delete deployments -n shop --as=system:serviceaccount:shop:deployer
no
ana@laptop:~/shop$ kubectl auth can-i get secrets -n shop --as=system:serviceaccount:shop:deployer
no
ana@laptop:~/shop$ kubectl auth can-i list pods -n default --as=system:serviceaccount:shop:deployer
no
ana@laptop:~/shop$ kubectl auth can-i create pods/exec -n shop --as=system:serviceaccount:shop:deployer
no
```

Cada resposta segue da Role e de nada mais. Criar um Deployment é permitido. Apagar um não é, porque
`delete` não está nos verbos. Secrets nunca foram mencionados. O namespace `default` fica fora do
binding, **porque um RoleBinding só concede dentro do próprio namespace.** E `pods/exec` é um
sub-recurso que ninguém nomeou, então abrir um shell num pod é recusado, mesmo que ler o pod seja
permitido.

`--list` imprime tudo o que a identidade pode fazer no namespace:

```
ana@laptop:~/shop$ kubectl auth can-i --list -n shop --as=system:serviceaccount:shop:deployer | head -n 8
Resources                                       Non-Resource URLs                      Resource Names   Verbs
selfsubjectreviews.authentication.k8s.io        []                                     []               [create]
selfsubjectaccessreviews.authorization.k8s.io   []                                     []               [create]
selfsubjectrulesreviews.authorization.k8s.io    []                                     []               [create]
deployments.apps                                []                                     []               [get list watch create update patch]
pods/log                                        []                                     []               [get list watch]
pods                                            []                                     []               [get list watch]
clustertrustbundles.certificates.k8s.io         []                                     []               [get list watch]
```

As nossas duas regras estão ali, nas linhas quatro a seis. As linhas em volta vêm de roles a que toda
identidade autenticada está ligada, como o direito de fazer sobre si mesma estas mesmas perguntas.

## Agindo como a conta

`--as` funciona em todo comando do `kubectl`, não só no `can-i`. Isso se chama personificação, e é em
si uma permissão: o administrador a tem, o pipeline não.

```
ana@laptop:~/shop$ kubectl --as=system:serviceaccount:shop:deployer -n shop create deployment shop --image=shop:1.0
deployment.apps/shop created
ana@laptop:~/shop$ kubectl --as=system:serviceaccount:shop:deployer -n shop delete deployment shop
Error from server (Forbidden): deployments.apps "shop" is forbidden: User "system:serviceaccount:shop:deployer" cannot delete resource "deployments" in API group "apps" in the namespace "shop"
```

**O create funcionou e o delete foi recusado, com a mesma forma de mensagem do `curl` de antes.** Um
pipeline com esta Role consegue publicar uma versão nova, e não consegue remover a aplicação por
engano nem em nome de mais ninguém. Isso é o menor privilégio na prática: comece do nada, e conceda os
verbos que o trabalho de fato usa.
