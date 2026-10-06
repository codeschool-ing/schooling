---
title: Uma release, as revisões e o rollback
version: 1
---

Instalar um chart cria uma **release**: um nome, os objetos renderizados, e um registro do que foi
instalado.

```
ana@laptop:~/shop$ helm install shop shop-chart
NAME: shop
LAST DEPLOYED: Tue Oct  6 18:05:37 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
TEST SUITE: None
ana@laptop:~/shop$ helm list
NAME	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART     	APP VERSION
shop	default  	1       	2026-10-06 18:05:37.112905566 -0300 -03	deployed	shop-0.1.0	1.0        
```

```
ana@laptop:~/shop$ kubectl get deployment,service -l app.kubernetes.io/instance=shop
NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/shop   2/2     2            2           1s
ana@laptop:~/shop$ kubectl get secret -l owner=helm
NAME                         TYPE                 DATA   AGE
sh.helm.release.v1.shop.v1   helm.sh/release.v1   1      1s
```

**O Deployment apareceu e o Service não**, porque o template do Service não carrega rótulo nenhum,
então um seletor em `app.kubernetes.io/instance` não o encontra. Nada está quebrado, o Service existe,
mas toda ferramenta que acha os objetos de uma release por rótulo vai perdê-lo. A correção é dar a
todo template os mesmos rótulos, o que os charts costumam fazer com um template auxiliar compartilhado.
Este chart foi escrito à mão para esta lição, e a omissão foi mantida porque é a mais comum.

O último comando mostra onde o Helm guarda o registro: um Secret por revisão, no namespace da release,
com o chart renderizado e os valores. Não existe servidor do Helm; o cluster é o banco de dados.

## Upgrade e histórico

```
ana@laptop:~/shop$ helm upgrade shop shop-chart --set image.tag=1.1 --set replicas=3
Release "shop" has been upgraded. Happy Helming!
NAME: shop
LAST DEPLOYED: Tue Oct  6 18:05:38 2026
NAMESPACE: default
STATUS: deployed
REVISION: 2
DESCRIPTION: Upgrade complete
TEST SUITE: None
ana@laptop:~/shop$ helm get values shop
USER-SUPPLIED VALUES:
image:
  tag: "1.1"
replicas: 3
ana@laptop:~/shop$ kubectl get deployment shop -o jsonpath="{.spec.template.spec.containers[0].image} {.spec.replicas}"; echo
shop:1.1 3
```

`helm get values` mostra só o que foi passado na linha de comando, não os padrões, e é a primeira
coisa a conferir quando uma release se comporta diferente do chart.

```
ana@laptop:~/shop$ helm history shop
REVISION	UPDATED                 	STATUS    	CHART     	APP VERSION	DESCRIPTION     
1       	Tue Oct  6 18:05:37 2026	superseded	shop-0.1.0	1.0        	Install complete
2       	Tue Oct  6 18:05:38 2026	deployed  	shop-0.1.0	1.0        	Upgrade complete
```

## Rollback

```
ana@laptop:~/shop$ helm rollback shop 1
Rollback was a success! Happy Helming!
ana@laptop:~/shop$ kubectl get deployment shop -o jsonpath="{.spec.template.spec.containers[0].image} {.spec.replicas}"; echo
shop:1.0 2
ana@laptop:~/shop$ helm history shop
REVISION	UPDATED                 	STATUS    	CHART     	APP VERSION	DESCRIPTION     
1       	Tue Oct  6 18:05:37 2026	superseded	shop-0.1.0	1.0        	Install complete
2       	Tue Oct  6 18:05:38 2026	superseded	shop-0.1.0	1.0        	Upgrade complete
3       	Tue Oct  6 18:05:40 2026	deployed  	shop-0.1.0	1.0        	Rollback to 1   
```

**De volta à 1.0 e a duas réplicas, como revisão 3.** Um rollback não rebobina o histórico; ele
instala os valores e templates de uma revisão antiga como uma revisão nova, então o registro fica
completo. O Deployment por baixo fez um rolling update comum, o da lição 35, em cada direção.

## O mesmo chart, duas vezes

```
ana@laptop:~/shop$ helm install shop-staging shop-chart --set greeting=staging
NAME: shop-staging
LAST DEPLOYED: Tue Oct  6 18:05:42 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
TEST SUITE: None
ana@laptop:~/shop$ helm list
NAME        	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART     	APP VERSION
shop        	default  	3       	2026-10-06 18:05:40.841301695 -0300 -03	deployed	shop-0.1.0	1.0        
shop-staging	default  	1       	2026-10-06 18:05:42.414062852 -0300 -03	deployed	shop-0.1.0	1.0        
ana@laptop:~/shop$ helm uninstall shop-staging
release "shop-staging" uninstalled
ana@laptop:~/shop$ kubectl get deployment
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
shop   2/2     2            2           6s
```

Uma segunda release do mesmo chart, com nome e saudação próprios, viveu ao lado da primeira sem tocá-la,
porque todo nome nos templates vem da release. Desinstalá-la removeu os objetos e os Secrets de
histórico dela, e deixou `shop` em paz.

| comando | faz |
|---|---|
| `helm template` | renderiza, não toca em nada |
| `helm install NOME CHART` | renderiza e cria a revisão 1 |
| `helm upgrade NOME CHART --set …` | renderiza com valores novos, cria a revisão seguinte |
| `helm history NOME` | lista as revisões |
| `helm rollback NOME N` | reaplica a revisão N como uma revisão nova |
| `helm uninstall NOME` | apaga os objetos e o histórico |

Charts também são como a maior parte do software de terceiros é instalada em clusters, a partir de
repositórios públicos. Isso é cômodo e é confiança: um chart pode criar qualquer objeto que quem o
instala tem permissão de criar, então ele merece a mesma leitura que qualquer outro código que você
roda, e o `helm template` é como lê-lo.
