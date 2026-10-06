---
title: O que um pod em execução vê quando o ConfigMap muda
version: 1
---

A loja vai fechar no domingo, então a Ana muda o arquivo de saudação e a variável de saudação, os dois
do jeito declarativo: gerar o objeto, depois aplicá-lo.

```
Closed for stocktaking on Sunday.
```

```
ana@laptop:~/shop$ kubectl create configmap shop-files --from-file=greeting=greeting.txt --dry-run=client -o yaml | kubectl apply -f -
Warning: resource configmaps/shop-files is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
configmap/shop-files configured
ana@laptop:~/shop$ kubectl create configmap shop-config --from-literal=GREETING="Ana's new shop" --from-literal=CURRENCY=BRL --dry-run=client -o yaml | kubectl apply -f -
Warning: resource configmaps/shop-config is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
configmap/shop-config configured
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- shop/config
GREETING=Ana's shop
/etc/shop/greeting: Welcome back. Orders placed before 18:00 ship today.
```

Os dois ConfigMaps dizem `configured`. Os avisos são sobre o `kubectl create` de antes, que não
guardou cópia do arquivo para o `apply` comparar (lição 7), e aqui não fazem mal. **E a loja em
execução continua dizendo exatamente o que dizia antes**, a variável e o arquivo.

## O arquivo acompanha, com o tempo

O script continuou perguntando até o arquivo mudar, e mediu: **cerca de 86 segundos**. Então:

```
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- shop/config
GREETING=Ana's shop
/etc/shop/greeting: Closed for stocktaking on Sunday.
```

O arquivo agora diz `Closed for stocktaking on Sunday`, sem ninguém reiniciar nada. O kubelet atualiza
os ConfigMaps montados no próprio ritmo, por padrão em cerca de um minuto mais o tempo que o cache dele
leva para perceber, então um atraso de um ou dois minutos é normal e nada promete que seja menor. **A
variável não mudou, e nunca vai mudar neste container**: uma variável de ambiente é copiada para dentro
de um processo quando ele sobe, e nenhum processo em lugar nenhum pode ter o ambiente mudado de fora.

## A variável acompanha um pod novo

```
ana@laptop:~/shop$ kubectl rollout restart deployment/shop
deployment.apps/shop restarted
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- shop/config
GREETING=Ana's new shop
/etc/shop/greeting: Closed for stocktaking on Sunday.
```

O `rollout restart` troca os pods por novos, do mesmo modelo, como uma atualização faria, e o container
novo subiu com `GREETING=Ana's new shop`. Então uma mudança de configuração precisa de uma de duas
coisas: **um programa que relê os arquivos**, ou **um rollout**. Fazer um rollout a cada mudança de
ConfigMap é comum a ponto de o Kustomize da lição 38 poder dar a cada versão de um ConfigMap um nome
com o hash do conteúdo, para que uma mudança gere um nome novo, que muda o modelo, que inicia um
rollout sozinho.

## Um ConfigMap que não pode mudar

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prices-2026-10
immutable: true
data:
  shipping: "19.90"
```

```
ana@laptop:~/shop$ kubectl apply -f frozen.yaml
configmap/prices-2026-10 created
ana@laptop:~/shop$ kubectl patch configmap prices-2026-10 -p '{"data":{"shipping":"0.00"}}'
The ConfigMap "prices-2026-10" is invalid: data: Forbidden: field is immutable when `immutable` is set
```

**`immutable: true` transforma o ConfigMap num fato.** O API server se recusa a editar os dados dele; o
único jeito de mudá-lo é apagá-lo e criar outro, que é o mesmo que fazer uma versão nova com nome novo.
Não custa nada para ler e o kubelet para de observá-lo em busca de mudanças, o que importa num cluster
com milhares de pods, e some o caso em que o arquivo de um pod em execução muda por baixo dele sem
aviso.
