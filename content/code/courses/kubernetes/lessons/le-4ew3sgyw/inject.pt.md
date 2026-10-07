---
title: Variáveis e arquivos a partir de um objeto
version: 1
---

**Configuração embutida na imagem significa reconstruir para cada ambiente e para cada mudança de
ideia**, e uma imagem que difere entre teste e produção é uma imagem que nunca foi testada. Um
ConfigMap tira a configuração de dentro: a imagem fica igual em todo lugar, e cada cluster guarda o
próprio ConfigMap ao lado dela.

Dois ConfigMaps, feitos de dois jeitos. Valores digitados na linha de comando viram chaves:

```
ana@laptop:~/shop$ kubectl create configmap shop-config --from-literal=GREETING="Ana's shop" --from-literal=CURRENCY=BRL
configmap/shop-config created
```

Um arquivo vira uma chave cujo valor é o arquivo inteiro:

```
Welcome back. Orders placed before 18:00 ship today.
```

```
ana@laptop:~/shop$ kubectl create configmap shop-files --from-file=greeting=greeting.txt
configmap/shop-files created
ana@laptop:~/shop$ kubectl get configmaps
NAME               DATA   AGE
kube-root-ca.crt   1      19s
shop-config        2      1s
shop-files         1      1s
ana@laptop:~/shop$ kubectl get configmap shop-config -o yaml | head -n 6
apiVersion: v1
data:
  CURRENCY: BRL
  GREETING: Ana's shop
kind: ConfigMap
metadata:
```

`DATA` conta as chaves: duas em `shop-config`, uma em `shop-files`. O terceiro ConfigMap,
`kube-root-ca.crt`, é posto em todo namespace pelo próprio cluster e guarda o certificado que os pods
usam para conferir que estão falando com o API server verdadeiro. Guardado, um ConfigMap é só isto: um
mapa `data` de textos, sem tipo e sem estrutura além disso.

## Para dentro do pod

O Deployment lê os dois dos dois jeitos:

```schooling-example
{"language": "yaml", "file": "shop.yaml", "parts": [{"code": "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: shop\nspec:\n  replicas: 1\n  selector:\n    matchLabels:\n      app: shop\n  template:\n    metadata:\n      labels:\n        app: shop\n    spec:\n      containers:\n      - name: shop\n        image: shop:1.0\n", "note": "**Um Deployment comum de uma cópia**, com a mesma imagem de todas as lições até aqui. Nada na imagem sabe dos ConfigMaps."}, {"code": "        env:\n        - name: GREETING\n          valueFrom:\n            configMapKeyRef:\n              name: shop-config\n              key: GREETING\n", "note": "**Uma variável a partir de uma chave.** `GREETING` no container recebe o valor da chave `GREETING` de `shop-config`, lido quando o container sobe."}, {"code": "        envFrom:\n        - prefix: SHOP_\n          configMapRef:\n            name: shop-config\n", "note": "**Todas as chaves de uma vez**, cada uma como variável com `SHOP_` na frente: `SHOP_GREETING` e `SHOP_CURRENCY`. A loja não as imprime, então nada abaixo as mostra."}, {"code": "        volumeMounts:\n        - name: files\n          mountPath: /etc/shop\n          readOnly: true\n", "note": "**Onde os arquivos aparecem** no container: um arquivo por chave, em `/etc/shop`, somente leitura."}, {"code": "      volumes:\n      - name: files\n        configMap:\n          name: shop-files\n", "note": "**O volume é o ConfigMap.** Cada chave de `shop-files` vira um arquivo com esse nome, então `greeting` vira `/etc/shop/greeting`."}, {"code": "---\napiVersion: v1\nkind: Service\nmetadata:\n  name: shop\nspec:\n  selector:\n    app: shop\n  ports:\n  - port: 80\n    targetPort: 8080\n", "note": "**Um Service**, para o pod `probe` poder chamar `shop` pelo nome."}]}
```

O pod `probe` pede à loja a configuração dela:

```
ana@laptop:~/shop$ kubectl apply -f shop.yaml
deployment.apps/shop created
service/shop created
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- shop/config
GREETING=Ana's shop
/etc/shop/greeting: Welcome back. Orders placed before 18:00 ship today.
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- shop/
Ana's shop 1.0 on shop-6fbfb8588d-vdprj
```

**A variável veio de `shop-config` e o arquivo de `shop-files`**, e a imagem não conhece nenhum dos
dois: ela lê uma variável de ambiente e um caminho, como faria num laptop. A página inicial da loja
agora cumprimenta como `Ana's shop`, a mesma imagem que dizia `shop` em todas as lições anteriores.

| | como variável de ambiente | como arquivo num volume |
|---|---|---|
| escrito como | `env` com `configMapKeyRef`, ou `envFrom` | um volume `configMap` e um `volumeMount` |
| lido pelo programa | quando ele sobe, como qualquer variável | sempre que ele abre o arquivo |
| combina com | valores curtos: uma moeda, uma flag, uma URL | arquivos inteiros: uma configuração, um modelo, um certificado |
| um valor que muda depois | não é visto por um container em execução | aparece no arquivo, depois de um tempo |

A última linha é o que a próxima seção mede, porque é a diferença que causa incidentes. Um ConfigMap
também tem limite de tamanho, um mebibyte, porque é guardado no etcd com todos os outros objetos;
qualquer coisa maior pertence a um volume próprio (lição 26).
